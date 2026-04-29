--!strict
-- Dialog trees for the AEGIS / Helix / Awakened setting.
--
-- WORLD PREMISE (read this before editing dialog):
--   Helix is a galactic custodial bureau that has quietly "managed" Earth
--   for centuries. Its primary tool is a global perception filter that
--   shapes what humans see and want. AEGIS is Earth's covert defense
--   agency — most of its members believe they are fighting an alien
--   threat, but AEGIS has been infiltrated. The Awakened are humans who
--   have pierced the veil and are working to expose Helix.
--
--   Augmentations (biomods) are reverse-engineered Helix tech. They are
--   the only known way to see through the perception filter — Cloak hides
--   you from the filter; Targeting / "True Sight" reveals which humans
--   are Helix-conditioned; Regeneration repairs the cellular damage the
--   filter inflicts when overridden.
--
-- DialogOption fields:
--   text         display string
--   next         next node id (nil if terminal/end_)
--   end_         true = closes the dialog
--   requires     predicate string (see WorldState.evaluate)
--   grants       { itemId } to add to inventory
--   completes    objective id to advance to completion
--   starts       objective id to start
--   effect       declarative WorldState mutation
--
-- DialogTree.selectStart: optional list of { when=predicate, node=id }.
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
    when: string,
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
    -- Marcus Hale: AEGIS contract handler. Believes wholeheartedly that
    -- AEGIS fights alien incursions. Doesn't know about the infiltration.
    -- =====================================================================
    MarcusHale = {
        npc = "Marcus Hale",
        start = "intro_default",
        selectStart = {
            { when = "counter:civiliansKilled>=3", node = "intro_civkiller" },
            { when = "flag:killedVega",            node = "intro_vega_killed" },
            { when = "flag:sparedVega",            node = "intro_vega_spared" },
            { when = "flag:defected",              node = "intro_defected" },
            { when = "counter:kills==0;counter:civiliansKilled==0", node = "intro_pacifist" },
        },
        nodes = {
            intro_default = {
                speaker = "Marcus Hale",
                text = "Operative. We have a problem. Last week a courier truck went off the books in Bayfront — five sample cases, sealed under Helix-Custodial classification. The Awakened claim to have them; they're broadcasting that the cases hold a 'perception agent' Helix was about to deploy in a worker district. Recover the cases. Lethal force authorized. Quietly.",
                options = {
                    { text = "Where are they keeping the cases?", next = "where" },
                    { text = "Who are the Awakened?", next = "who" },
                    { text = "What's a perception agent?", next = "what" },
                    { text = "Got it. I'll move out.", next = "accept", starts = "RecoverHelixVials", end_ = true },
                },
            },
            intro_pacifist = {
                speaker = "Marcus Hale",
                text = "Operative. Audit came back from your last contract. Zero casualties. I wasn't sure that was possible. The board doesn't know what to do with you. I do — keep going.",
                options = {
                    { text = "Brief me.", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_civkiller = {
                speaker = "Marcus Hale",
                text = "Three civilians on the last sweep. Three. Legal is calling them collateral. I shouldn't have to remind you what we're supposed to be protecting humans from.",
                options = {
                    { text = "It was complicated.", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_vega_killed = {
                speaker = "Marcus Hale",
                text = "Vega is dead. Her transponder went cold in the same district you ran. The board hasn't asked me directly. They will. Watch your back, operative.",
                options = {
                    { text = "She drew first.", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_vega_spared = {
                speaker = "Marcus Hale",
                text = "Vega filed a one-line report on your encounter. 'No further action required.' From her, that's a love letter. I don't know what you said to her. Whatever it was, it stuck.",
                options = {
                    { text = "Brief me.", next = "intro_default" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_defected = {
                speaker = "Marcus Hale",
                text = "[He doesn't look up from his terminal.] You shouldn't be in this building, operative. I'm going to get coffee. I won't see anything for the next two minutes. Use them.",
                options = {
                    { text = "[Leave quietly]", end_ = true },
                },
            },
            where = {
                speaker = "Marcus Hale",
                text = "Bayfront District. The old amusement pier — the one the city condemned after the seawall failed. The Awakened set up camp there six months ago. Their organizer holds the upper deck near the broken crane.",
                options = { { text = "Understood.", next = "intro_default" } },
            },
            who = {
                speaker = "Marcus Hale",
                text = "The Awakened. Underground network — ex-AEGIS, hackers, biomod tinkerers. They claim Helix isn't a corporation but something... else. Off-world. Frankly, I think they're paranoid. But they did blow up two pipelines, so 'peaceful' isn't the word.",
                options = { { text = "Got it.", next = "intro_default" } },
            },
            what = {
                speaker = "Marcus Hale",
                text = "Helix told us it's a workplace stress mediator. Aerosolized. Calms aggression in industrial populations. The Awakened say it does more than that. I haven't read the white paper. I'm not paid to.",
                options = { { text = "Got it.", next = "intro_default" } },
            },
            accept = {
                speaker = "Marcus Hale",
                text = "Stay sharp. And operative — try not to give Legal more work than necessary.",
                options = { { text = "[End]", end_ = true } },
            },
        },
    },

    -- =====================================================================
    -- Dr. Ines Halberg: AEGIS biomod technician. Aug-reactive — comments on
    -- whatever cybernetics the operative is currently running.
    -- =====================================================================
    InesHalberg = {
        npc = "Dr. Ines Halberg",
        start = "intro",
        selectStart = {
            { when = "aug:Cloak>=3",            node = "intro_cloak" },
            { when = "aug:Regeneration",        node = "intro_regen" },
            { when = "aug:CombatStrength>=2",   node = "intro_strength" },
            { when = "aug:BallisticProtection", node = "intro_armor" },
            { when = "aug:Targeting",           node = "intro_truesight" },
        },
        nodes = {
            intro = {
                speaker = "Dr. Halberg",
                text = "Operative. Your biomods need calibration. I have medkits and a power cell on the rack. Take what you need. Try to come back in one piece this time.",
                options = {
                    { text = "I'll take supplies.", next = "supplies", grants = { "Medkit", "Medkit", "Biocell" } },
                    { text = "Anything else for me?", next = "extras" },
                    { text = "Tell me about the biomods.", next = "lore" },
                    { text = "[Leave]", end_ = true },
                },
            },
            lore = {
                speaker = "Dr. Halberg",
                text = "Reverse-engineered, mostly. Off the wreckage we pulled out of the Sierras in '74. The chassis is human — the active layer is... not. Don't ask me where it came from originally. I have theories. AEGIS doesn't pay me to publish them.",
                options = {
                    { text = "Theories?", next = "lore_theories" },
                    { text = "[Back]", next = "intro" },
                },
            },
            lore_theories = {
                speaker = "Dr. Halberg",
                text = "Biomods don't just enhance. They override something. Run your Targeting aug in a crowd and tell me what it tags. Run Cloak and notice what it bends. The hardware does work the human nervous system was never built to do. I've stopped asking why.",
                options = {
                    { text = "[Back]", next = "intro" },
                },
            },
            intro_cloak = {
                speaker = "Dr. Halberg",
                text = "Refraction Veil at level three. My diagnostic rig only catches you two pixels at a time, and that's with active scanning. Whoever built this firmware knew exactly what filter it was bypassing.",
                options = {
                    { text = "Filter?", next = "lore_theories" },
                    { text = "Supplies?", next = "intro" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_truesight = {
                speaker = "Dr. Halberg",
                text = "Targeting / Smart-Sights is online. You'll start tagging people who don't quite read as human. Don't react to it in public. AEGIS has not officially acknowledged what the tags mean.",
                options = {
                    { text = "Supplies?", next = "intro" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_regen = {
                speaker = "Dr. Halberg",
                text = "Your Cellular Reweave is firing right now. That means something's chewing through your nervous tissue faster than your baseline can repair. Sit down. ...No, of course you won't. Take an extra power cell. Two.",
                options = {
                    { text = "Supplies?", next = "supplies", grants = { "Medkit", "Biocell", "Biocell" } },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_strength = {
                speaker = "Dr. Halberg",
                text = "Myomer Boost at level two. You can throw a man through a wall. Please don't, in this building.",
                options = {
                    { text = "Supplies?", next = "intro" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_armor = {
                speaker = "Dr. Halberg",
                text = "Your Kevlar Weave reads green. Doesn't make you bulletproof. Make better choices anyway.",
                options = {
                    { text = "Noted. Supplies?", next = "intro" },
                    { text = "[Leave]", end_ = true },
                },
            },
            supplies = {
                speaker = "Dr. Halberg",
                text = "Stay alive, operative.",
                options = { { text = "Thanks.", end_ = true } },
            },
            extras = {
                speaker = "Dr. Halberg",
                text = "I have a biomod chip. Yours, if you want it. Don't tell Inventory I said so.",
                options = {
                    { text = "Appreciated.", next = "supplies", grants = { "AugCanister" } },
                    { text = "Maybe later.", next = "intro" },
                },
            },
        },
    },

    -- =====================================================================
    -- Vega: AEGIS enforcer who has been quietly turned by Helix. The
    -- "Stand down" option flips her hostile.
    -- =====================================================================
    Vega = {
        npc = "Vega",
        start = "intro",
        selectStart = {
            { when = "flag:killedVega",       node = "post_killed" },
            { when = "flag:sparedVega",       node = "post_spared" },
            { when = "aug:CombatStrength>=2", node = "intro_strength" },
            { when = "aug:Cloak",             node = "intro_cloak" },
        },
        nodes = {
            intro = {
                speaker = "Vega",
                text = "Operative. The board reads me your reports. They are gentle. The Awakened are not protesters; they are an infection. Stop hesitating.",
                options = {
                    { text = "Not every contact calls for lethal force.", next = "argue" },
                    { text = "Stand down, Vega. Now.", next = "confront" },
                    { text = "I'll work it my way.", next = "leave", end_ = true },
                },
            },
            argue = {
                speaker = "Vega",
                text = "Your way ends with you in a body bag and AEGIS replacing the contract. Don't say I didn't warn you.",
                options = {
                    { text = "Walk away from this conversation.", next = "spared", effect = "flag:sparedVega", end_ = true },
                    { text = "[Leave]", end_ = true },
                },
            },
            confront = {
                speaker = "Vega",
                text = "Bold. Foolish. Last chance, operative — back down, or I will treat this as an assault on a corporate asset.",
                options = {
                    { text = "Try it.", next = "hostile", effect = "hostile:Vega", end_ = true },
                    { text = "[Back down]", next = "intro" },
                },
            },
            hostile = {
                speaker = "Vega",
                text = "[Vega's optical implants flare. Her hand drops to her sidearm. Something behind her eyes is not entirely her.]",
                options = { { text = "[End]", end_ = true } },
            },
            spared = {
                speaker = "Vega",
                text = "...we will speak again, operative.",
                options = { { text = "[End]", end_ = true } },
            },
            leave = {
                speaker = "Vega",
                text = "[She watches you go without a word. Without blinking.]",
                options = { { text = "[Leave]", end_ = true } },
            },
            intro_strength = {
                speaker = "Vega",
                text = "Myomer Boost. Level two. You enjoy hitting things that can't hit back. The right tool. Not the loudest one.",
                options = {
                    { text = "It works.", next = "intro" },
                    { text = "[Leave]", end_ = true },
                },
            },
            intro_cloak = {
                speaker = "Vega",
                text = "Refraction Veil. I can hear your power-cell hum from across the room. The veil is for humans, operative. I'm... less so.",
                options = {
                    { text = "Noted.", next = "intro" },
                    { text = "[Leave]", end_ = true },
                },
            },
            post_killed = {
                speaker = "[no signal]",
                text = "[Her transponder is offline. Whatever was riding her is gone with her.]",
                options = { { text = "[End]", end_ = true } },
            },
            post_spared = {
                speaker = "Vega",
                text = "Operative. I don't know what you said before, but I've been carrying it since. Don't make me regret walking away.",
                options = { { text = "[End]", end_ = true } },
            },
        },
    },

    -- =====================================================================
    -- Director Cole: Helix's senior human liaison on Earth. Possibly more
    -- than human; we don't say. Pitches the operative on becoming Helix's
    -- enforcer (the fourth ending path).
    -- =====================================================================
    DirectorCole = {
        npc = "Director Cole",
        start = "intro",
        selectStart = {
            { when = "flag:joinedHelix",     node = "post_join" },
            { when = "flag:metDirectorCole", node = "intro_again" },
        },
        nodes = {
            intro = {
                speaker = "Director Cole",
                text = "Operative. Off the record. AEGIS reports to a board. The board reports to me. I report to a chamber whose name your nervous system would not currently parse. The point is: you've been working for us already, and rather well. We'd like to use you properly.",
                options = {
                    { text = "What are you offering?", next = "offer", effect = "flag:metDirectorCole" },
                    { text = "Whatever you are, I'm done with it.", next = "refuse",
                        effect = "flag:metDirectorCole;rep:Helix-10", end_ = true },
                },
            },
            offer = {
                speaker = "Director Cole",
                text = "Custodial-tier credentials. Direct interface with the Lattice. You stop pulling triggers and start adjusting what humans want to see. The veil becomes a tool in your hand. Bring the proposal to your team — they vote on everything now, I understand.",
                options = {
                    { text = "Call a team vote on joining Helix.", effect = "vote:joinHelix", end_ = true },
                    { text = "Not yet.", next = "intro_again", end_ = true },
                },
            },
            refuse = {
                speaker = "Director Cole",
                text = "[He smiles, briefly. The smile takes a fraction of a second too long to assemble.] We will speak again, operative. Your kind always finds its way back to me, in the end.",
                options = { { text = "[Leave]", end_ = true } },
            },
            intro_again = {
                speaker = "Director Cole",
                text = "Reconsidered the offer, operative?",
                options = {
                    { text = "Open the team vote.", effect = "vote:joinHelix", end_ = true },
                    { text = "Not yet.", end_ = true },
                },
            },
            post_join = {
                speaker = "Director Cole",
                text = "Welcome to the Bureau, operative. The Helix Ascension console is waiting in Vault-7. Conclude things on your terms — which are, as you will discover, also ours.",
                options = { { text = "[Leave]", end_ = true } },
            },
        },
    },

    -- =====================================================================
    -- Cael: Awakened organizer. Pitches defection as a personal reckoning
    -- (the operative's sister was killed in a Helix cleanup) compounded by
    -- the cosmic stakes (AEGIS itself is compromised).
    -- =====================================================================
    Cael = {
        npc = "Cael",
        start = "intro",
        selectStart = {
            { when = "flag:defected",    node = "intro_defected" },
            { when = "aug:Targeting>=2", node = "intro_targeting" },
            { when = "flag:metCael",     node = "intro_again" },
        },
        nodes = {
            intro = {
                speaker = "Cael",
                text = "Operative. Two things. First: AEGIS told you your sister died in a transit accident. She didn't. A Helix cleanup crew did the scene-erasure. AEGIS approved the cover-up. I have the audit trail. Second: AEGIS is not the agency you think it is. Run your Targeting biomod here, in this room, and tell me what it tags about my left hand.",
                options = {
                    { text = "Show me the audit trail. I'm done with AEGIS.", next = "defect_open",
                        effect = "flag:metCael", end_ = true },
                    { text = "I need time to think.", next = "stall",
                        effect = "flag:metCael" },
                    { text = "I'll stay loyal to AEGIS.", next = "loyal",
                        effect = "flag:metCael;rep:AEGIS+10", end_ = true },
                },
            },
            stall = {
                speaker = "Cael",
                text = "Take all the time the schedule allows. Which is to say: not much. Find me when you're ready.",
                options = { { text = "[Leave]", end_ = true } },
            },
            defect_open = {
                speaker = "Cael",
                text = "Then bring it to your team. Defection is not a thing one person decides for four. Open the vote when you're ready.",
                options = {
                    { text = "Call a team vote on defection.", effect = "vote:defect", end_ = true },
                    { text = "Not yet.", end_ = true },
                },
            },
            loyal = {
                speaker = "Cael",
                text = "Then I hope your sister's name was worth the contract bonus.",
                options = { { text = "[End]", end_ = true } },
            },
            intro_again = {
                speaker = "Cael",
                text = "Made up your mind?",
                options = {
                    { text = "Call the team vote.", effect = "vote:defect", end_ = true },
                    { text = "Not yet.", next = "stall" },
                },
            },
            intro_defected = {
                speaker = "Cael",
                text = "Operative. The Lattice core is at Vault-7. Buried under the Sierras, four security tiers deep. Four terminals at the bottom, four fates. Your team picks one. Whatever you choose, the veil comes off — for you, for everyone, or for no one. Choose carefully.",
                options = { { text = "[End]", end_ = true } },
            },
            intro_targeting = {
                speaker = "Cael",
                text = "Your Smart-Sights are scanning me. Don't. I'm one of the few people in this room who reads as fully human. Save the dwell-pattern for the corporate floors. Helix-conditioned humans light up like fairground lights on level-two Targeting.",
                options = {
                    { text = "Apologies.", next = "intro" },
                    { text = "[End]", end_ = true },
                },
            },
        },
    },
}

return Dialog
