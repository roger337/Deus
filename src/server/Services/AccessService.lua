--!strict
-- Lobby access control.
--
-- Players join into the Lobby map. They're held there (LevelManager refuses
-- the AegisTower transition without access) until either:
--   1. Their team is in AccessConfig.PreApprovedTeams (auto-grant on request),
--   2. The owner approves their pending request via the Owner Console, or
--   3. They previously had access on a prior session (DataStore-persisted).
--
-- Per-user record (DataStore key = userId):
--   { approved: bool, team: string?, requestedAt: number?, approvedAt: number? }
--
-- Pending requests are also tracked in a server-wide ordered queue so the
-- Owner Console can list them. The queue is in memory only (rebuilt on
-- server start by scanning recently-active users).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local AccessConfig = require(Shared.Config.AccessConfig)

local AccessService = {}

local STORE_NAME = "AegisVeilAccess_v1"
local store: DataStore? = nil
do
    local ok, ds = pcall(function() return DataStoreService:GetDataStore(STORE_NAME) end)
    if ok then store = ds end
end

type AccessRecord = {
    approved: boolean,
    team: string?,
    requestedAt: number?,
    approvedAt: number?,
}

local cache: { [number]: AccessRecord } = {}
local pending: { { userId: number, name: string, team: string, requestedAt: number } } = {}

local function retry<T>(fn: () -> T, attempts: number): (boolean, any)
    for i = 1, attempts do
        local ok, result = pcall(fn)
        if ok then return true, result end
        task.wait(2 ^ (i - 1))
    end
    return false, nil
end

local function load(userId: number): AccessRecord
    if cache[userId] then return cache[userId] end
    local rec: AccessRecord = { approved = false }
    if store then
        local _, payload = retry(function()
            return (store :: DataStore):GetAsync(tostring(userId))
        end, 2)
        if typeof(payload) == "table" then
            rec = {
                approved = payload.approved == true,
                team = payload.team,
                requestedAt = payload.requestedAt,
                approvedAt = payload.approvedAt,
            }
        end
    end
    cache[userId] = rec
    return rec
end

local function save(userId: number, rec: AccessRecord)
    cache[userId] = rec
    if not store then return end
    retry(function()
        (store :: DataStore):SetAsync(tostring(userId), rec)
        return true
    end, 2)
end

function AccessService.hasAccess(player: Player): boolean
    if AccessConfig.isAdmin(player.UserId) then return true end
    return load(player.UserId).approved
end

function AccessService.request(player: Player, team: string)
    team = team:gsub("^%s*(.-)%s*$", "%1"):sub(1, 32)
    if team == "" then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "Team name required.")
        return
    end
    local rec = load(player.UserId)
    if rec.approved then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "You already have access.")
        return
    end
    rec.team = team
    rec.requestedAt = os.time()
    save(player.UserId, rec)

    -- Auto-approve pre-listed teams.
    if AccessConfig.isPreApprovedTeam(team) then
        AccessService.grant(player.UserId, "auto-approved")
        return
    end

    -- Add to in-memory pending queue (dedup by userId).
    for i, entry in ipairs(pending) do
        if entry.userId == player.UserId then
            pending[i] = { userId = player.UserId, name = player.Name, team = team, requestedAt = rec.requestedAt }
            return
        end
    end
    table.insert(pending, { userId = player.UserId, name = player.Name, team = team, requestedAt = rec.requestedAt })
    local notify = Remotes.get("Notify") :: RemoteEvent
    notify:FireClient(player, "Request submitted. Awaiting owner approval.")
end

function AccessService.grant(userId: number, source: string?)
    local rec = load(userId)
    rec.approved = true
    rec.approvedAt = os.time()
    save(userId, rec)
    -- Remove from pending.
    for i = #pending, 1, -1 do
        if pending[i].userId == userId then
            table.remove(pending, i)
        end
    end
    -- Notify the user if online.
    local p = Players:GetPlayerByUserId(userId)
    if p then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(p, string.format("Access granted%s. Proceed to AEGIS Tower.",
            source and (" (" .. source .. ")") or ""))
        AccessService.replicateTo(p)
    end
end

function AccessService.revoke(userId: number)
    local rec = load(userId)
    rec.approved = false
    rec.approvedAt = nil
    save(userId, rec)
    local p = Players:GetPlayerByUserId(userId)
    if p then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(p, "Your access has been revoked.")
        AccessService.replicateTo(p)
    end
end

function AccessService.listPending(): { { userId: number, name: string, team: string, requestedAt: number } }
    local out = {}
    for _, entry in ipairs(pending) do
        table.insert(out, entry)
    end
    return out
end

function AccessService.replicateTo(player: Player)
    local rec = load(player.UserId)
    local ev = Remotes.get("AccessUpdate") :: RemoteEvent
    ev:FireClient(player, {
        approved = rec.approved,
        team = rec.team,
        isAdmin = AccessConfig.isAdmin(player.UserId),
    })
end

function AccessService.init()
    local reqEv = Remotes.get("RequestAccess") :: RemoteEvent
    reqEv.OnServerEvent:Connect(function(player, team)
        if typeof(team) == "string" then
            AccessService.request(player, team)
        end
    end)

    local grantEv = Remotes.get("AdminGrantAccess") :: RemoteEvent
    grantEv.OnServerEvent:Connect(function(player, targetUserId)
        if not AccessConfig.isAdmin(player.UserId) then return end
        if typeof(targetUserId) == "number" then
            AccessService.grant(targetUserId, "owner-approved")
        end
    end)

    local revokeEv = Remotes.get("AdminRevokeAccess") :: RemoteEvent
    revokeEv.OnServerEvent:Connect(function(player, targetUserId)
        if not AccessConfig.isAdmin(player.UserId) then return end
        if typeof(targetUserId) == "number" then
            AccessService.revoke(targetUserId)
        end
    end)

    local listFn = Remotes.get("AdminListPending") :: RemoteFunction
    listFn.OnServerInvoke = function(player)
        if not AccessConfig.isAdmin(player.UserId) then return {} end
        return AccessService.listPending()
    end
end

return AccessService
