--!strict
-- Resolves weapon hits requested by clients. Server is authoritative on damage.
-- Clients send a hit candidate; we sanity-check range/line-of-sight before applying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Weapons = require(Shared.Config.Weapons)
local WeaponMods = require(Shared.Config.WeaponMods)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local SkillService = require(script.Parent.SkillService)
local AugService = require(script.Parent.AugService)
local InventoryService = require(script.Parent.InventoryService)
local VoiceService = require(script.Parent.VoiceService)
local WorldState = require(script.Parent.Parent.WorldState)

local CombatService = {}

local RECENT_FIRE: { [Player]: number } = {}

local function ammoIdFor(ammoType: string?): string?
    if not ammoType then return nil end
    return "Ammo" .. ammoType
end

local function isHumanoidEnemy(model: Instance?): (Humanoid?, boolean)
    if not model then return nil, false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return nil, false end
    -- enemies are tagged on the model
    local isEnemy = model:GetAttribute("Faction") == "NSF"
    return hum, isEnemy
end

function CombatService.applyDamageToHumanoid(
    attacker: Player?,
    targetModel: Model,
    weaponId: string,
    headshot: boolean,
    nonLethalOnly: boolean
)
    local baseDef = Weapons[weaponId]
    if not baseDef then return end
    local def = baseDef
    if attacker then
        local stackMods = InventoryService.getStackMods(attacker, weaponId)
        def = WeaponMods.applyMods(baseDef, stackMods)
    end
    local hum, isEnemy = isHumanoidEnemy(targetModel)
    if not hum then return end

    local damage = def.damage
    if attacker then
        damage *= SkillService.multiplier(attacker, def.skill)
    end
    if headshot then
        damage *= def.headshotMult
    end

    local lethal = not (nonLethalOnly or def.id == "RiotProd" or def.id == "MiniCrossbow")
    if not lethal then
        -- Tranq / prod path: apply "stamina" damage tracked on humanoid via attribute.
        local stamina = (targetModel:GetAttribute("Stamina") or hum.MaxHealth) - damage
        targetModel:SetAttribute("Stamina", stamina)
        if stamina <= 0 then
            -- knock out: ragdoll-ish — set walkspeed 0, disable AI tag, flag KO
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            targetModel:SetAttribute("KnockedOut", true)
            if attacker and isEnemy then
                local data = PlayerData.get(attacker)
                data.knockouts += 1
                InventoryService.replicateStats(attacker)
            end
        end
    else
        hum:TakeDamage(damage)
        if hum.Health <= 0 and attacker then
            local faction = targetModel:GetAttribute("Faction")
            local data = PlayerData.get(attacker)
            data.nonLethalRun = false
            if faction == "NSF" or faction == "Hostile" then
                data.kills += 1
                WorldState.bumpCounter(attacker, "kills", 1)
                if targetModel.Name == "Anna Navarre" or targetModel:GetAttribute("CharacterId") == "Anna" then
                    WorldState.setFlag(attacker, "killedAnna", true)
                end
            elseif faction == "Civilian" then
                WorldState.bumpCounter(attacker, "civiliansKilled", 1)
                WorldState.adjustReputation(attacker, "Civilian", -10)
                WorldState.adjustReputation(attacker, "UNATCO", -5)
                local notify = Remotes.get("Notify") :: RemoteEvent
                notify:FireClient(attacker, "[!] Civilian killed.")
            end
            InventoryService.replicateStats(attacker)
        end
    end
end

function CombatService.tryFire(player: Player, weaponId: string, origin: Vector3, direction: Vector3, hitPos: Vector3?, hitInstance: Instance?)
    local baseDef = Weapons[weaponId]
    if not baseDef then return end
    local data = PlayerData.get(player)
    if data.equipped ~= weaponId then return end

    -- Apply installed mods to produce effective stats for THIS shot.
    local stackMods = InventoryService.getStackMods(player, weaponId)
    local def = WeaponMods.applyMods(baseDef, stackMods)

    -- rate limit (uses effective rpm in case a future mod tweaks it)
    local now = os.clock()
    local last = RECENT_FIRE[player] or 0
    local cooldown = 60 / def.rpm
    if now - last < cooldown - 0.02 then return end
    RECENT_FIRE[player] = now

    -- ammo check
    local ammoId = ammoIdFor(def.ammoType)
    if ammoId then
        if not InventoryService.has(player, ammoId, 1) then
            local notify = Remotes.get("Notify") :: RemoteEvent
            notify:FireClient(player, "Out of ammo.")
            return
        end
        InventoryService.remove(player, ammoId, 1)
    end

    -- line-of-sight check: re-cast from server side and confirm the same target.
    if hitPos and hitInstance then
        local dist = (hitPos - origin).Magnitude
        if dist > def.range * 1.1 then return end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local char = player.Character
        if char then
            raycastParams.FilterDescendantsInstances = { char }
        end
        local ray = Workspace:Raycast(origin, (hitPos - origin).Unit * math.min(def.range, dist + 5), raycastParams)
        if not ray or not ray.Instance then return end

        -- Accept the shot if the server's raycast hits the same model the client reported.
        local clientModel = hitInstance:FindFirstAncestorOfClass("Model") or hitInstance
        local serverModel = ray.Instance:FindFirstAncestorOfClass("Model") or ray.Instance
        if clientModel ~= serverModel then return end

        local model = hitInstance:FindFirstAncestorOfClass("Model")
        if model then
            local isHead = hitInstance.Name == "Head"
            local nonLethal = (def.id == "MiniCrossbow") or (def.id == "RiotProd")
            CombatService.applyDamageToHumanoid(player, model, weaponId, isHead, nonLethal)
        end
    end
end

function CombatService.applyDamageToPlayer(player: Player, amount: number, source: string?)
    local data = PlayerData.get(player)
    -- Aug: ballistic protection
    if source == "ballistic" then
        local mag = AugService.passiveMagnitude(player, "BallisticProtection")
        if mag then amount *= mag end
    elseif source == "explosive" or source == "fire" or source == "gas" then
        local mult = SkillService.multiplier(player, "Environmental")
        amount *= mult
    elseif source == "emp" then
        local mag = AugService.passiveMagnitude(player, "EMPShield")
        if mag then amount *= mag end
    end
    local prevHealth = data.health
    data.health = math.max(0, data.health - amount)
    InventoryService.replicateStats(player)
    local fb = Remotes.get("DamageFeedback") :: RemoteEvent
    fb:FireClient(player, amount, source)

    -- "I'm hit" bark, with a louder one if we just crossed below 25 HP.
    if amount >= 8 then
        VoiceService.playFor(player, "JC:hurt")
    end
    if prevHealth >= 25 and data.health < 25 and data.health > 0 then
        VoiceService.playFor(player, "JC:lowHealth")
    end

    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = data.health end
    end
end

function CombatService.init()
    local fireEv = Remotes.get("FireWeapon") :: RemoteEvent
    fireEv.OnServerEvent:Connect(function(player, weaponId, origin, direction, hitPos, hitInstance)
        if typeof(weaponId) ~= "string" then return end
        if typeof(origin) ~= "Vector3" then return end
        if typeof(direction) ~= "Vector3" then return end
        CombatService.tryFire(player, weaponId, origin, direction, hitPos, hitInstance)
    end)
end

return CombatService
