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

    -- =====================================================================
    -- Lattice Symbiosis: mass ascension. The Creator reaches through the
    -- corrupted Lattice and lifts everyone the veil touches. The demons'
    -- deception is obliterated for the ascended. They remain in the prison
    -- forever, watching the prisoners go free.
    -- =====================================================================
    Lattice = {
        id = "Lattice",
        title = "LATTICE SYMBIOSIS",
        color = { 150, 200, 255 },
        eligible = "!flag:latticeLocked",
        blockedReason = "The Lattice rejects integration: too many civilian casualties recorded. The pattern reads as a vector for further harm; access is refused.",
        epilogue = {
            "The operative steps into the cradle. Coolant mist rises, then thins, then is replaced by something that is not vapor.",
            "Through the Lattice — through a thing built by demons to keep humans down — something else moves the other direction. The Creator works through whatever is offered, even tools meant to imprison.",
            "Across the planet, in the same instant, billions of people see. Not just clearly: *upward*. The ceiling that has always been the sky becomes a door. Those who are willing rise.",
            "Helix watches from the floor of the world. They cannot follow. They were never going to. Their hatred is grief, and their grief is law: where they fell, they remain.",
            "The deception is not lifted. It is obliterated. There was never anything there.",
            "[ENDING: LATTICE SYMBIOSIS — Mass Ascension]",
        },
        voiceKey = "Ending:Lattice",
    },

    -- =====================================================================
    -- Quorum Restoration: human collaborators inherit the prison. The veil
    -- stays. Most don't know they're still inside. The smallest revelation,
    -- the largest betrayal.
    -- =====================================================================
    Quorum = {
        id = "Quorum",
        title = "QUORUM RESTORATION",
        color = { 220, 180, 60 },
        eligible = nil,
        epilogue = {
            "The operative routes Lattice control to the old families. The Quorum accepts the keys with the expression of people receiving an inheritance they always assumed was theirs.",
            "Helix is pushed back, quietly, by deal — but not out. They cannot leave. They were never able to. The Quorum simply learns to share the floor with them.",
            "The veil stays in place. The world looks much the same. The collaborators tell themselves that human masters are kinder. Some of them believe it.",
            "No one ascends. No one rises. The prisoners forget there was ever a door.",
            "[ENDING: QUORUM RESTORATION — Continued Captivity]",
        },
        voiceKey = "Ending:Quorum",
    },

    -- =====================================================================
    -- Network Reset: shatter the veil but stay in the floor. Humanity is
    -- free of deception, free of Helix's whispering — but still inside the
    -- pit, with the demons walking openly. Hard fight ahead.
    -- =====================================================================
    Reset = {
        id = "Reset",
        title = "NETWORK RESET",
        color = { 120, 30, 30 },
        eligible = nil,
        epilogue = {
            "The operative sets the kill commands. The Lattice fails. The perception filter does not switch off — it shatters.",
            "Across the planet, billions of people see at once. Some see the ceiling above the sky. Some see what was always wearing the faces of their neighbors. Some see only their own grief, finally.",
            "Helix loses its mask. Loses, too, its quiet. It does not lose its claim on this place. Demons cannot ascend; demons cannot leave. They are simply visible now, and visibly trapped, and visibly furious.",
            "Humanity stays in the floor with them. But the lights are on. What humanity does next — whether it climbs, whether it just survives — is its own.",
            "[ENDING: NETWORK RESET — Defiant Captivity]",
        },
        voiceKey = "Ending:Reset",
    },

    -- =====================================================================
    -- Helix Ascension: damnation. The operative joins the fallen. Permanent
    -- residency in the prison, on the warden's side of the bars.
    -- =====================================================================
    HelixAscension = {
        id = "HelixAscension",
        title = "HELIX ASCENSION",
        color = { 60, 30, 30 },
        eligible = "flag:joinedHelix",
        blockedReason = "Director Cole's offer was never extended to your team. This ending is not available.",
        epilogue = {
            "Director Cole greets the operative at the Lattice cradle. His smile takes a fraction of a second too long to assemble. It is no longer a human face.",
            "The operative's biomods are reflashed with master keys. The veil becomes a tool in their hand — and the hand is no longer entirely theirs.",
            "Order is preserved. Dissidents stop dissenting. The new Custodian is gentler than the last; they remember being human, the way an exile remembers a country they will never see again.",
            "They will not ascend. They cannot leave. They have signed themselves into the prison's permanent staff.",
            "Most nights, they try not to feel the door above the sky. Some nights, they cannot help it.",
            "[ENDING: HELIX ASCENSION — Damnation]",
        },
        voiceKey = "Ending:HelixAscension",
    },

    -- =====================================================================
    -- Ascension by Faith: refuse all four consoles. Walk out of Vault-7
    -- without touching demonic tech. The hardest path; the only one that
    -- does not pass through the demons' hands. Available to anyone who
    -- has not joined Helix.
    -- =====================================================================
    AscensionByFaith = {
        id = "AscensionByFaith",
        title = "ASCENSION BY FAITH",
        color = { 240, 240, 200 },
        eligible = "!flag:joinedHelix",
        blockedReason = "The path of faith does not open for those who have signed themselves to the warden.",
        epilogue = {
            "The operative does not approach the consoles. The team does not approach the consoles. They turn around, leave the chamber, and walk out of Vault-7 into the desert above.",
            "There is no merge. No reset. No restoration. There is only the choice — repeated, sustained, irrevocable — to refuse the tools the demons offered.",
            "The Creator does not require demonic tech to lift those who are willing. The Lattice was always optional.",
            "It is harder. It is slower. The veil is not obliterated all at once for billions; it lifts, person by person, wherever the choice is repeated. Some never repeat it. Some do.",
            "Helix watches from the floor as the few rise without their permission, without their machines, without anything they can interfere with. It is the worst news the demons have ever received.",
            "[ENDING: ASCENSION BY FAITH — The Narrow Path]",
        },
        voiceKey = "Ending:Faith",
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
