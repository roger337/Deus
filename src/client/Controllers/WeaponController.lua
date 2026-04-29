--!strict
-- Client-side weapon firing: predicts the trace, sends authoritative shot to server.
-- Server handles damage; we just play the visuals.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Weapons = require(Shared.Config.Weapons)
local Remotes = require(Shared.Remotes)

local WeaponController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local state = {
    equipped = nil :: string?,
    lastFire = 0,
    isAiming = false,
}

local function tracer(from: Vector3, to: Vector3, color: Color3?)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.Size = Vector3.new(0.15, 0.15, (from - to).Magnitude)
    p.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -p.Size.Z / 2)
    p.Color = color or Color3.fromRGB(255, 240, 180)
    p.Material = Enum.Material.Neon
    p.Transparency = 0.4
    p.Parent = Workspace
    task.delay(0.05, function() p:Destroy() end)
end

local function muzzleFlash(pos: Vector3)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.Size = Vector3.new(1, 1, 1)
    p.Position = pos
    p.Color = Color3.fromRGB(255, 200, 80)
    p.Material = Enum.Material.Neon
    p.Transparency = 0.4
    p.Parent = Workspace
    task.delay(0.06, function() p:Destroy() end)
end

local function castFromCamera(weaponDef): (Vector3, Vector3, RaycastResult?)
    local origin = camera.CFrame.Position
    local dir = camera.CFrame.LookVector

    local spread = weaponDef.spread
    if state.isAiming then spread *= 0.3 end
    dir = (dir + Vector3.new(
        (math.random() - 0.5) * spread * 2,
        (math.random() - 0.5) * spread * 2,
        (math.random() - 0.5) * spread * 2
    )).Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if player.Character then
        params.FilterDescendantsInstances = { player.Character }
    end
    local result = Workspace:Raycast(origin, dir * weaponDef.range, params)
    return origin, dir, result
end

function WeaponController.fire()
    local weaponId = state.equipped
    if not weaponId then return end
    local def = Weapons[weaponId]
    if not def then return end

    local now = os.clock()
    local cooldown = 60 / def.rpm
    if now - state.lastFire < cooldown then return end
    state.lastFire = now

    local origin, dir, hit = castFromCamera(def)
    local hitPos = hit and hit.Position or (origin + dir * def.range)
    local hitInst = hit and hit.Instance

    tracer(origin, hitPos)
    muzzleFlash(origin + dir * 2)

    local fireEv = Remotes.get("FireWeapon") :: RemoteEvent
    fireEv:FireServer(weaponId, origin, dir, hitPos, hitInst)
end

local firing = false
local function tryAutoFire()
    while firing do
        local weaponId = state.equipped
        if not weaponId then break end
        local def = Weapons[weaponId]
        if not def or not def.automatic then break end
        WeaponController.fire()
        task.wait(60 / def.rpm)
    end
end

function WeaponController.setEquipped(itemId: string?)
    state.equipped = itemId
end

function WeaponController.start()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            firing = true
            local weaponId = state.equipped
            local def = weaponId and Weapons[weaponId]
            if def then
                if def.automatic then
                    task.spawn(tryAutoFire)
                else
                    WeaponController.fire()
                end
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            state.isAiming = true
            camera.FieldOfView = 50
        elseif input.KeyCode == Enum.KeyCode.R then
            local rl = Remotes.get("ReloadWeapon") :: RemoteEvent
            rl:FireServer(state.equipped)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            firing = false
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            state.isAiming = false
            camera.FieldOfView = 70
        end
    end)
end

return WeaponController
