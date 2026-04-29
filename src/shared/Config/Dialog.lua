--!strict
-- Branching dialog trees for NPCs. Each node has speaker text and player options.
-- Options can grant items, set objectives, or change relationships.

export type DialogOption = {
    text: string,
    next: string?,
    grants: { string }?,        -- item ids to grant
    completes: string?,         -- objective id to complete
    starts: string?,            -- objective id to start
    requires: string?,          -- objective id required to show this option
    end_: boolean?,
}

export type DialogNode = {
    speaker: string,
    text: string,
    options: { DialogOption },
}

export type DialogTree = {
    npc: string,
    portrait: string?,
    start: string,
    nodes: { [string]: DialogNode },
}

local Dialog: { [string]: DialogTree } = {
    PaulDenton = {
        npc = "Paul Denton",
        portrait = "rbxasset://textures/face.png",
        start = "intro",
        nodes = {
            intro = {
                speaker = "Paul Denton",
                text = "JC. UNATCO sent word — the NSF have stolen a shipment of Ambrosia from the docks. Recover all five vials. Lethal force is authorized, but discretion is preferred.",
                options = {
                    { text = "Where are they hiding it?", next = "where" },
                    { text = "Who are the NSF?", next = "who" },
                    { text = "Understood. I'll get to work.", next = "accept", starts = "RecoverAmbrosia", end_ = true },
                },
            },
            where = {
                speaker = "Paul Denton",
                text = "Statue of Liberty. Their commander has fortified the upper levels. Watch for snipers on the rooftops.",
                options = {
                    { text = "Got it.", next = "intro" },
                },
            },
            who = {
                speaker = "Paul Denton",
                text = "The National Secessionist Forces. Domestic terrorists, mostly. Don't underestimate them — they're well-armed and well-funded.",
                options = {
                    { text = "Understood.", next = "intro" },
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
    AnnaNavarre = {
        npc = "Anna Navarre",
        start = "intro",
        nodes = {
            intro = {
                speaker = "Anna Navarre",
                text = "Denton. You're soft. The NSF aren't enemies — they're targets. Eliminate them and be done with it.",
                options = {
                    { text = "Not every situation calls for lethal force.", next = "argue" },
                    { text = "I'll handle it my way.", next = "leave", end_ = true },
                },
            },
            argue = {
                speaker = "Anna Navarre",
                text = "Your way will get you killed. Don't say I didn't warn you.",
                options = {
                    { text = "[Leave]", end_ = true },
                },
            },
            leave = {
                speaker = "Anna Navarre",
                text = "...",
                options = {
                    { text = "[Leave]", end_ = true },
                },
            },
        },
    },
}

return Dialog
