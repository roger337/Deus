--!strict
-- Vote definitions. A vote is opened by the server (via VoteService.open),
-- broadcast to all online players, and resolved when all players have voted
-- or `timeoutSec` elapses. Majority wins; ties go to the option listed first.
--
-- Each option's `effect` string mutates WorldState for ALL players when that
-- option wins. Effect grammar matches Dialog.lua's effect field. Special
-- effect kinds handled by VoteService outcome:
--   "ending:Helios" -> calls EndingService.tryTrigger("Helios") for all players
--   "flag:..." / "faction:..." / "rep:..."  -> applied per-player

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
    -- Defection vote: triggered by Tracer Tong dialog.
    -- =====================================================================
    defect = {
        id = "defect",
        prompt = "Tracer Tong: \"Cut your strings from UNATCO and join the resistance — or stay loyal. The team must decide.\"",
        timeoutSec = 30,
        options = {
            {
                id = "defect",
                label = "Defect — leave UNATCO",
                effect = "flag:defected;flag:metTracerTong;faction:NSF;rep:UNATCO-50;rep:NSF+50",
            },
            {
                id = "loyal",
                label = "Stay loyal to UNATCO",
                effect = "flag:metTracerTong;rep:UNATCO+10",
            },
        },
    },

    -- =====================================================================
    -- Endgame votes: one per Area 51 terminal. Whichever ending wins gets
    -- played for every player simultaneously.
    -- =====================================================================
    endingHelios = {
        id = "endingHelios",
        prompt = "MERGE WITH HELIOS — vote to commit the team to this ending.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Merge with Helios", effect = "ending:Helios" },
            { id = "no",  label = "Cancel",            effect = "" },
        },
    },
    endingIlluminati = {
        id = "endingIlluminati",
        prompt = "RESTORE THE ILLUMINATI — vote to commit the team to this ending.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Restore Illuminati", effect = "ending:Illuminati" },
            { id = "no",  label = "Cancel",             effect = "" },
        },
    },
    endingDarkAge = {
        id = "endingDarkAge",
        prompt = "TRIGGER THE DARK AGE — vote to commit the team to this ending.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Trigger the Dark Age", effect = "ending:DarkAge" },
            { id = "no",  label = "Cancel",               effect = "" },
        },
    },
    endingMJ12Enforce = {
        id = "endingMJ12Enforce",
        prompt = "BECOME MJ12 ENFORCER — accept Walton Simons' offer. Available only after meeting Simons and accepting MJ12.",
        timeoutSec = 25,
        options = {
            { id = "yes", label = "Become MJ12 Enforcer", effect = "ending:MJ12Enforce" },
            { id = "no",  label = "Refuse",               effect = "" },
        },
    },

    -- Walton Simons' offer to join MJ12 — opens before the player ever
    -- reaches Area 51, so the MJ12 Enforcer ending is unlocked.
    joinMJ12 = {
        id = "joinMJ12",
        prompt = "Walton Simons: \"Step into the role you were built for. Join MJ12. The world will reshape itself in your image.\"",
        timeoutSec = 30,
        options = {
            { id = "yes", label = "Accept — join MJ12",  effect = "flag:joinedMJ12;faction:MJ12;rep:UNATCO-30;rep:MJ12+50" },
            { id = "no",  label = "Refuse — UNATCO is enough", effect = "rep:UNATCO+10;rep:MJ12-25" },
        },
    },
}

return Votes
