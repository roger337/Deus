--!strict
-- Dialog trees with predicate-based gating and side effects.
--
-- DialogOption fields:
--   text         display string
--   next         next node id (or nil if terminal/end_)
--   end_         true = closes the dialog
--   requires     predicate string (see WorldState.evaluate); option only
--                shown when predicate is true. Examples:
--                  "flag:defected"             defected = true
--                  "!flag:defected"            haven't defected
--                  "counter:civiliansKilled<3" pacifist enough
--                  "faction:NSF"               currently NSF-aligned
--   grants       { itemId } to add to inventory
--   completes    objective id to advance to completion
--   starts       objective id to start
--   effect       declarative WorldState mutation; one of:
--                  "flag:name"           sets flag true
--                  "!flag:name"          sets flag false
--                  "faction:X"           switches faction
--                  "rep:F+N" / "rep:F-N" reputation delta
--                  "hostile:Anna"        flips Anna NPC to hostile (handled in code)
--                effects can be chained with ";" inside a single string.
--
-- DialogTree.selectStart: optional list of { when=predicate, node=startNodeId }.
-- Evaluated in order; first match wins. Falls back to .start otherwise.

export type DialogOption = {
    text: string,
    next: string?,
    grants: { string }?,
    completes: string?,
    starts: string?,
    requires: string?,
    effect: string?,
    end_: boolean?,
}

export type DialogNode = {
    speaker: string,
    text: string,
    options: { DialogOption },
}

export type DialogStartVariant = {
    when: string,           -- predicate; first match wins
    node: string,
}

export type DialogTree = {
    npc: string,
    portrait: string?,
    start: string,
    selectStart: { DialogStartVariant }?,
    nodes: { [string]: DialogNode },
}

local Dialog: { [string]: DialogTree } = {

    -- =====================================================================
    -- Paul Denton: greeting variants by behavior. Reactive to civilian
    -- harm and overall lethality.
    -- =====================================================================
    PaulDenton = {
        npc = "Paul Denton",
        start = "intro_default",
        selectStart = {
            { when = "counter:civiliansKilled>=3", node = "intro_civkiller" },
            { when = "flag:killedAnna",            node = "intro_anna_killed" },
            { when = "flag:sparedAnna",            node = "intro_anna_spared" },
            { when = "flag:defected",              node = "intro_defected" },
            { when = "counter:kills==0;counter:civiliansKilled==0", node = "intro_pacifist" },
        },
        nodes = {
            intro_default = {
                speaker = "Paul Denton",
                text = "JC. UNATCO sent word — the NSF have stolen a shipment of Ambrosia from the docks. Recover all five vials. Lethal force is authorized, but discretion is preferred.",
                options = {
                    { text = "Where are they hiding it?", next = "where" },
                    { text = "Who are the NSF?", next = "who" },
                    { text = "Understood. I'll get to work.", next = "accept", starts = "RecoverAmbrosia", end_ = true },
                },
            },
            intro_pacifist = {
                speaker = "Paul Denton",
                text = "JC. Reports say not a single body to clean up at the docks. Impressive. Keep that up — UNATCO needs operatives who can think before they shoot.",
                options = {
                    { text = "Mission?", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_civkiller = {
                speaker = "Paul Denton",
                text = "JC, the body count from the docks includes civilians. Manderley is asking questions I can't answer. Rein it in. We can't have a UNATCO agent making us look like the NSF.",
                options = {
                    { text = "It was a complicated situation.", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_anna_killed = {
                speaker = "Paul Denton",
                text = "Anna's dead. Manderley's furious. I... can't say I'm surprised, given how she spoke to you. But there will be consequences. Stay sharp.",
                options = {
                    { text = "She drew first.", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_anna_spared = {
                speaker = "Paul Denton",
                text = "Anna told me about your... disagreement. She walked away from it, which is more restraint than I'd have expected from her. Whatever you said, it stuck.",
                options = {
                    { text = "Mission?", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_defected = {
                speaker = "Paul Denton",
                text = "[Paul Denton avoids your gaze.] You shouldn't be here, JC. UNATCO has flagged you as a defector. Get out — I'll buy you what time I can.",
                options = {
                    { text = "Come with me.", next = "defect_recruit" },
                    { text = "[Leave]", end_ = true },
                },
            },
            defect_recruit = {
                speaker = "Paul Denton",
                text = "Maybe. Not yet. Find me later.",
                options = {
                    { text = "Understood.", end_ = true },
                },
            },
            where = {
                speaker = "Paul Denton",
                text = "Statue of Liberty. Their commander has fortified the upper levels. Watch for snipers on the rooftops.",
                options = {
                    { text = "Got it.", next = "intro_default" },
                },
            },
            who = {
                speaker = "Paul Denton",
                text = "The National Secessionist Forces. Domestic terrorists, mostly. Don't underestimate them — they're well-armed and well-funded.",
                options = {
                    { text = "Understood.", next = "intro_default" },
                },
            },
            accept = {
                speaker = "Paul Denton",
                text = "Good hunting, brother.",
                options = {
                    { text = "[End conversation]", end_ = true },
                },
            },
        },
    },

    JaimeReyes = {
        npc = "Dr. Jaime Reyes",
        start = "intro",
        nodes = {
            intro = {
                speaker = "Dr. Reyes",
                text = "JC. I have a fresh batch of medkits and a bio-cell ready for you. Your nano-augmentations need maintenance — try not to die out there.",
                options = {
                    { text = "I'll take supplies.", next = "supplies", grants = { "Medkit", "Medkit", "Biocell" } },
                    { text = "Anything else for me?", next = "extras" },
                    { text = "[Leave]", end_ = true },
                },
            },
            supplies = {
                speaker = "Dr. Reyes",
                text = "Stay alive, JC.",
                options = {
                    { text = "Thanks.", end_ = true },
                },
            },
            extras = {
                speaker = "Dr. Reyes",
                text = "I had a canister come in — install one new aug, on the house.",
                options = {
                    { text = "Appreciated.", next = "supplies", grants = { "AugCanister" } },
                    { text = "Maybe later.", next = "intro" },
                },
            },
        },
    },

    -- =====================================================================
    -- Anna Navarre: confrontation path. The "Stand down" option flips her
    -- to hostile via the `effect = "hostile:Anna"` declarative field.
    -- =====================================================================
    AnnaNavarre = {
        npc = "Anna Navarre",
        start = "intro",
        selectStart = {
            { when = "flag:killedAnna",  node = "post_killed" },
            { when = "flag:sparedAnna",  node = "post_spared" },
        },
        nodes = {
            intro = {
                speaker = "Anna Navarre",
                text = "Denton. You're soft. The NSF aren't enemies — they're targets. Eliminate them and be done with it.",
                options = {
                    { text = "Not every situation calls for lethal force.", next = "argue" },
                    { text = "Stand down, Anna. I won't ask twice.", next = "confront" },
                    { text = "I'll handle it my way.", next = "leave", end_ = true },
                },
            },
            argue = {
                speaker = "Anna Navarre",
                text = "Your way will get you killed. Don't say I didn't warn you.",
                options = {
                    { text = "Walk away from this.", next = "spared", effect = "flag:sparedAnna", end_ = true },
                    { text = "[Leave]", end_ = true },
                },
            },
            confront = {
                speaker = "Anna Navarre",
                text = "Bold. Foolish. Last chance, Denton — back down, or I'll put you down.",
                options = {
                    { text = "Try it.", next = "hostile", effect = "hostile:Anna", end_ = true },
                    { text = "[Back down]", next = "intro" },
                },
            },
            hostile = {
                speaker = "Anna Navarre",
                text = "[Anna's nano-aug eyes flash. She moves to draw.]",
                options = { { text = "[End]", end_ = true } },
            },
            spared = {
                speaker = "Anna Navarre",
                text = "...we'll speak again, Denton.",
                options = { { text = "[End]", end_ = true } },
            },
            leave = {
                speaker = "Anna Navarre",
                text = "...",
                options = { { text = "[Leave]", end_ = true } },
            },
            post_killed = {
                speaker = "[radio silence]",
                text = "[She's dead. There is no reply.]",
                options = { { text = "[End]", end_ = true } },
            },
            post_spared = {
                speaker = "Anna Navarre",
                text = "Denton. Whatever you said before, I haven't forgotten it. Don't make me regret walking away.",
                options = { { text = "[End]", end_ = true } },
            },
        },
    },

    -- =====================================================================
    -- Tracer Tong: the defection moment.
    -- =====================================================================
    TracerTong = {
        npc = "Tracer Tong",
        start = "intro",
        selectStart = {
            { when = "flag:defected", node = "intro_defected" },
            { when = "flag:metTracerTong", node = "intro_again" },
        },
        nodes = {
            intro = {
                speaker = "Tracer Tong",
                text = "JC Denton. I knew your father. UNATCO is not what you think it is — they answer to MJ12. Cut your strings, and I'll show you the truth. The choice is the team's, not yours alone.",
                options = {
                    { text = "Call a team vote on defection.", effect = "vote:defect", end_ = true },
                    { text = "I need time to think.", next = "stall", effect = "flag:metTracerTong" },
                },
            },
            stall = {
                speaker = "Tracer Tong",
                text = "Time is what you don't have. They will come for you whether you choose or not. Find me when you're ready.",
                options = { { text = "[Leave]", end_ = true } },
            },
            defect_yes = {
                speaker = "Tracer Tong",
                text = "Welcome to the resistance, JC. Burn the badge. There is no going back.",
                options = { { text = "[End]", end_ = true } },
            },
            loyal = {
                speaker = "Tracer Tong",
                text = "[He shakes his head sadly.] Your blindness is your choice. Goodbye, Denton.",
                options = { { text = "[End]", end_ = true } },
            },
            intro_again = {
                speaker = "Tracer Tong",
                text = "Made up your mind yet?",
                options = {
                    { text = "Call a team vote on defection.", effect = "vote:defect", end_ = true },
                    { text = "Not yet.", next = "stall" },
                },
            },
            intro_defected = {
                speaker = "Tracer Tong",
                text = "JC. Helios is at Area 51. Three terminals, three fates. The choice is yours — but choose carefully. Your hands are not as clean as you might believe.",
                options = {
                    { text = "[End]", end_ = true },
                },
            },
        },
    },
}

return Dialog
