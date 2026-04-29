--!strict
-- Vote definitions. A vote is opened by the server (via VoteService.open),
-- broadcast to all online players, and resolved when all players have voted
-- or `timeoutSec` elapses. Majority wins; ties go to the option listed first.
--
-- Each option's `effect` string mutates WorldState for ALL players when that
-- option wins. Effect grammar matches Dialog.lua's effect field. Special
-- effect kinds handled by VoteService outcome:
--   "ending:Lattice" -> calls EndingService.tryTrigger("Lattice") for all
--   "flag:..." / "faction:..." / "rep:..." -> applied per-player

export type VoteOption = {
    id: string,
    label: string,
    effect: string,
}

export type VoteDef = {
    id: string,
    prompt: string,
    timeoutSec: number,
    options: { VoteOption },
}

local Votes: { [string]: VoteDef } = {

    -- =====================================================================
    -- Defection vote: triggered by Cael's dialog.
    -- =====================================================================
    defect = {
        id = "defect",
        prompt = "Cael (Awakened): \"Cut your contracts with AEGIS — the agency is compromised — or stay loyal. The team must decide.\"",
        timeoutSec = 30,
        options = {
            {
                id = "defect",
                label = "Defect — leave AEGIS",
                effect = "flag:defected;flag:metCael;faction:IronPromise;rep:AEGIS-50;rep:IronPromise+50",
            },
            {
                id = "loyal",
                label = "Stay loyal to AEGIS",
                effect = "flag:metCael;rep:AEGIS+10",
            },
        },
    },

    -- =====================================================================
    -- Director Cole's offer to join Helix.
    -- =====================================================================
    joinHelix = {
        id = "joinHelix",
        prompt = "Director Cole (Helix): \"Step into the role you were built for. Custodial-tier credentials. The veil becomes a tool in your hand.\"",
        timeoutSec = 30,
        options = {
            { id = "yes", label = "Accept — join Helix",  effect = "flag:joinedHelix;faction:Helix;rep:AEGIS-30;rep:Helix+50" },
            { id = "no",  label = "Refuse",               effect = "rep:AEGIS+10;rep:Helix-25" },
        },
    },

    -- =====================================================================
    -- Endgame votes: one per Vault-7 terminal + the Faith path.
    -- =====================================================================
    endingLattice = {
        id = "endingLattice",
        prompt = "LATTICE SYMBIOSIS — let the divine work through the Lattice. Mass ascension; demons sealed in the floor of the world. Vote to commit.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Merge with the Lattice", effect = "ending:Lattice" },
            { id = "no",  label = "Cancel",                 effect = "" },
        },
    },
    endingQuorum = {
        id = "endingQuorum",
        prompt = "QUORUM RESTORATION — hand the prison's keys to human collaborators. Veil stays in place; no one rises.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Restore the Quorum",     effect = "ending:Quorum" },
            { id = "no",  label = "Cancel",                 effect = "" },
        },
    },
    endingReset = {
        id = "endingReset",
        prompt = "NETWORK RESET — shatter the deception but remain in the floor of the world with the demons unmasked. Defiant captivity.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Reset the network",      effect = "ending:Reset" },
            { id = "no",  label = "Cancel",                 effect = "" },
        },
    },
    endingHelixAscension = {
        id = "endingHelixAscension",
        prompt = "HELIX ASCENSION — sign yourselves into the prison's permanent staff. Damnation. Available only after joining Helix.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Become Custodians",      effect = "ending:HelixAscension" },
            { id = "no",  label = "Refuse",                 effect = "" },
        },
    },
    endingFaith = {
        id = "endingFaith",
        prompt = "ASCENSION BY FAITH — refuse all four consoles. Walk out of Vault-7 without touching demonic tech. The narrow path. The only one that does not pass through their hands.",
        timeoutSec = 30,
        options = {
            { id = "yes", label = "Walk out — refuse the Lattice", effect = "ending:AscensionByFaith" },
            { id = "no",  label = "Cancel",                        effect = "" },
        },
    },
}

return Votes
