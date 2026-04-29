--!strict
-- The three Area 51 endings. Each ending terminal carries an `EndingId`
-- attribute ("Helios" | "Illuminati" | "DarkAge"). When the player interacts
-- with one, EndingService validates eligibility and fires `ShowEnding` to
-- the client with the right epilogue text.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local WorldState = require(script.Parent.Parent.WorldState)

local EndingService = {}

export type EndingDef = {
    id: string,
    title: string,
    color: { number },          -- {R, G, B}
    eligible: string?,          -- predicate; nil = always eligible
    blockedReason: string?,
    epilogue: { string },       -- paragraphs of epilogue text
    voiceKey: string?,
}

local Endings: { [string]: EndingDef } = {
    Helios = {
        id = "Helios",
        title = "MERGE WITH HELIOS",
        color = { 150, 200, 255 },
        eligible = "!flag:heliosLocked",
        blockedReason = "HELIOS rejects integration: too many civilian casualties registered. The AI will not bond with a flawed vessel.",
        epilogue = {
            "JC Denton steps into the bay. Coolant mist rises around the merge cradle.",
            "He hears HELIOS for the first time without a wire — a chorus of every voice on every network, all at once.",
            "When the merge completes there is no JC, and there is no HELIOS. There is something else. Something wiser. Something kinder, perhaps.",
            "Humanity will know it soon enough.",
            "[ENDING: HELIOS MERGE]",
        },
        voiceKey = "Ending:Helios",
    },
    Illuminati = {
        id = "Illuminati",
        title = "RESTORE THE ILLUMINATI",
        color = { 220, 180, 60 },
        eligible = nil,
        epilogue = {
            "JC routes the Helios uplink through the old Illuminati relay. Morgan Everett's voice cuts in on the secure channel.",
            "\"Welcome back, JC. The world will be... quieter, now. Older orders will keep it.\"",
            "MJ12 burns. The new world looks much like the old one, ruled from the shadows by men who know better.",
            "JC Denton tells himself that some things are worth preserving.",
            "[ENDING: ILLUMINATI]",
        },
        voiceKey = "Ending:Illuminati",
    },
    DarkAge = {
        id = "DarkAge",
        title = "TRIGGER THE DARK AGE",
        color = { 120, 30, 30 },
        eligible = nil,
        epilogue = {
            "JC sets the Aquinas overrides. The global communications backbone fails section by section.",
            "Banks close. Markets stop. Governments fragment to whichever city still has power.",
            "It will be a hard century. Maybe a hard millennium. But humanity will choose what comes next, without HELIOS, without Illuminati, without MJ12.",
            "Whether they choose well — that is up to them.",
            "[ENDING: DARK AGE]",
        },
        voiceKey = "Ending:DarkAge",
    },
}

EndingService.Endings = Endings

function EndingService.tryTrigger(player: Player, endingId: string): boolean
    local def = Endings[endingId]
    if not def then return false end

    if def.eligible and not WorldState.evaluate(player, def.eligible) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, def.blockedReason or "This ending is not available.")
        return false
    end

    -- Set the canonical flag.
    WorldState.setFlag(player, "chosen" .. endingId, true)

    local ev = Remotes.get("ShowEnding") :: RemoteEvent
    ev:FireClient(player, {
        id = def.id,
        title = def.title,
        color = def.color,
        epilogue = def.epilogue,
    })
    return true
end

return EndingService
