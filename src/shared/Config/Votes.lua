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
    -- Endgame votes: one per Vault-7 terminal.
    -- =====================================================================
    endingLattice = {
        id = "endingLattice",
        prompt = "LATTICE SYMBIOSIS — share the Lattice with humanity. The veil comes off, for everyone, at once. Vote to commit.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Merge with the Lattice", effect = "ending:Lattice" },
            { id = "no",  label = "Cancel",                 effect = "" },
        },
    },
    endingQuorum = {
        id = "endingQuorum",
        prompt = "QUORUM RESTORATION — hand control to the human collaborators. Veil stays. Familiar masters in charge.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Restore the Quorum",     effect = "ending:Quorum" },
            { id = "no",  label = "Cancel",                 effect = "" },
        },
    },
    endingReset = {
        id = "endingReset",
        prompt = "NETWORK RESET — destroy the Lattice. Veil collapses violently; mass disorientation. Humanity is alone.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Reset the network",      effect = "ending:Reset" },
            { id = "no",  label = "Cancel",                 effect = "" },
        },
    },
    endingHelixAscension = {
        id = "endingHelixAscension",
        prompt = "HELIX ASCENSION — accept Director Cole's offer. Available only after meeting Cole and joining Helix.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Become a Custodian",     effect = "ending:HelixAscension" },
            { id = "no",  label = "Refuse",                 effect = "" },
        },
    },
}

return Votes
