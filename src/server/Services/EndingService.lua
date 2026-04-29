--!strict
-- The four Vault-7 endings. Each ending terminal carries an `EndingId`
-- attribute ("Lattice" | "Quorum" | "Reset" | "HelixAscension"). When a
-- team vote on the corresponding ending passes, EndingService validates
-- eligibility and fires `ShowEnding` to every player with the right
-- epilogue text.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local WorldState = require(script.Parent.Parent.WorldState)

local EndingService = {}

export type EndingDef = {
    id: string,
    title: string,
    color: { number },
    eligible: string?,
    blockedReason: string?,
    epilogue: { string },
    voiceKey: string?,
}

local Endings: { [string]: EndingDef } = {
    Lattice = {
        id = "Lattice",
        title = "LATTICE SYMBIOSIS",
        color = { 150, 200, 255 },
        eligible = "!flag:latticeLocked",
        blockedReason = "The Lattice rejects integration: too many civilian casualties recorded. The pattern reads as a vector for further harm; access is refused.",
        epilogue = {
            "The operative steps into the Lattice cradle. Coolant mist coils around the merge harness.",
            "For the first time the perception filter is not something happening *to* humans — it becomes a thing humans share, can read, can refuse. Around the world, in the same instant, billions of people see clearly. Some weep. Some stop their cars in the middle of the road. Some keep working as if nothing happened.",
            "Helix's custodial network is severed by mutual consent.",
            "What humanity does next is its own to decide. For the first time in centuries.",
            "[ENDING: LATTICE SYMBIOSIS]",
        },
        voiceKey = "Ending:Lattice",
    },
    Quorum = {
        id = "Quorum",
        title = "QUORUM RESTORATION",
        color = { 220, 180, 60 },
        eligible = nil,
        epilogue = {
            "The operative routes Lattice control to the old families. The Quorum convenes, smiles, accepts the keys.",
            "Helix is ejected from the planet within a generation — quietly, by deal, not by force. The veil stays in place. The world looks much the same. The masters are simply human again.",
            "It is a smaller cage. It is still a cage.",
            "The operative tells themself that smaller is better. Most nights, they believe it.",
            "[ENDING: QUORUM RESTORATION]",
        },
        voiceKey = "Ending:Quorum",
    },
    Reset = {
        id = "Reset",
        title = "NETWORK RESET",
        color = { 120, 30, 30 },
        eligible = nil,
        epilogue = {
            "The operative sets the kill commands. The Lattice fails section by section. The perception filter does not switch off — it shatters.",
            "Across the planet, billions of people see, all at once, things their nervous systems were never tuned to hold. Cities go dark. Markets close. Hospitals fill.",
            "It will be a hard century. Maybe a hard millennium. But humanity will choose what comes next on its own — without Helix, without the Quorum, without anyone whispering inside its head.",
            "Whether they choose well — that is up to them.",
            "[ENDING: NETWORK RESET]",
        },
        voiceKey = "Ending:Reset",
    },
    HelixAscension = {
        id = "HelixAscension",
        title = "HELIX ASCENSION",
        color = { 60, 30, 30 },
        eligible = "flag:joinedHelix",
        blockedReason = "Director Cole's offer was never extended to your team. This ending is not available.",
        epilogue = {
            "Director Cole greets the operative at the Lattice cradle. His smile takes a fraction of a second too long to assemble.",
            "The operative's biomods are reflashed with Custodial master keys. The veil becomes a tool in their hand — not something done to them, but something they do, now, to others.",
            "Order is preserved. Dissidents stop dissenting. The new Custodian is gentler than the last; they remember being human.",
            "Most nights, they tell themself the world is safer this way.",
            "[ENDING: HELIX ASCENSION]",
        },
        voiceKey = "Ending:HelixAscension",
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
