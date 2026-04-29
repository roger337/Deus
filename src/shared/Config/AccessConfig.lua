--!strict
-- Access control for the lobby gate.
--
-- HOW TO CONFIGURE:
--   1. Set `AdminUserIds` to the Roblox userId(s) of the game owner. The
--      owner sees an "Owner Console" in the lobby that lets them approve
--      pending team requests.
--   2. (Optional) Pre-populate `PreApprovedTeams` with team names that
--      should be auto-granted access without owner review. Useful for
--      friend groups you've already vetted.
--
-- The owner can still grant access in-game via the Owner Console regardless
-- of the pre-approval list.

local AccessConfig = {}

-- Replace with the owner's actual Roblox UserId(s) before publishing.
-- e.g. AccessConfig.AdminUserIds = { 123456789 }
AccessConfig.AdminUserIds = {} :: { number }

-- Team names that bypass owner review (auto-approved on request).
AccessConfig.PreApprovedTeams = {} :: { string }

-- How long a pending request stays in the queue before being expired.
AccessConfig.RequestTtlSeconds = 7 * 24 * 3600  -- 7 days

function AccessConfig.isAdmin(userId: number): boolean
    for _, id in ipairs(AccessConfig.AdminUserIds) do
        if id == userId then return true end
    end
    return false
end

function AccessConfig.isPreApprovedTeam(team: string): boolean
    local needle = string.lower(team)
    for _, t in ipairs(AccessConfig.PreApprovedTeams) do
        if string.lower(t) == needle then return true end
    end
    return false
end

return AccessConfig
