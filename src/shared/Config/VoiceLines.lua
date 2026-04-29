--!strict
-- Voice line registry. Maps a stable string key to a Roblox audio asset ID
-- + subtitle.
--
-- HOW TO ADD A VOICE LINE:
--   1. Upload your audio to Roblox (Studio -> Toolbox -> Audio -> "My Audio").
--   2. Copy the resulting asset URL: rbxassetid://<NUMBER>
--   3. Paste it into the `assetId` field below.
--
-- Keys with `assetId == ""` play no sound but still display the subtitle.
-- All audio you upload must be your own work or properly licensed.
--
-- For dialog-tree voice keys, the dialog text shown by DialogUI is the
-- subtitle, so leave `subtitle` nil here.

export type VoiceLine = {
    assetId: string,
    subtitle: string?,
    duration: number,
    volume: number?,
    pitch: number?,
    prefix: string?,
}

local VoiceLines: { [string]: VoiceLine } = {

    --[[ ============================================================
         DIALOG VOICES — keyed as "Dialog:<treeId>:<nodeId>"
         ============================================================ ]]

    -- Marcus Hale: tired middle-management. Pitch 0.95.
    ["Dialog:MarcusHale:intro_default"]   = { assetId = "", duration = 9, pitch = 0.95 },
    ["Dialog:MarcusHale:intro_pacifist"]  = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:intro_civkiller"] = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:intro_vega_killed"] = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:intro_vega_spared"] = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:intro_defected"]  = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:where"]           = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:who"]             = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:what"]            = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:MarcusHale:accept"]          = { assetId = "", duration = 2, pitch = 0.95 },

    -- Dr. Halberg: warm. Pitch 1.05.
    ["Dialog:InesHalberg:intro"]              = { assetId = "", duration = 8, pitch = 1.05 },
    ["Dialog:InesHalberg:lore"]               = { assetId = "", duration = 6, pitch = 1.05 },
    ["Dialog:InesHalberg:lore_theories"]      = { assetId = "", duration = 6, pitch = 1.05 },
    ["Dialog:InesHalberg:intro_cloak"]        = { assetId = "", duration = 6, pitch = 1.05 },
    ["Dialog:InesHalberg:intro_truesight"]    = { assetId = "", duration = 6, pitch = 1.05 },
    ["Dialog:InesHalberg:intro_regen"]        = { assetId = "", duration = 6, pitch = 1.05 },
    ["Dialog:InesHalberg:intro_strength"]     = { assetId = "", duration = 4, pitch = 1.05 },
    ["Dialog:InesHalberg:intro_armor"]        = { assetId = "", duration = 4, pitch = 1.05 },
    ["Dialog:InesHalberg:supplies"]           = { assetId = "", duration = 2, pitch = 1.05 },
    ["Dialog:InesHalberg:extras"]             = { assetId = "", duration = 4, pitch = 1.05 },

    -- Vega: faintly synthetic from heavy biomod use. Pitch 0.92.
    ["Dialog:Vega:intro"]            = { assetId = "", duration = 6, pitch = 0.92 },
    ["Dialog:Vega:argue"]            = { assetId = "", duration = 4, pitch = 0.92 },
    ["Dialog:Vega:confront"]         = { assetId = "", duration = 4, pitch = 0.92 },
    ["Dialog:Vega:hostile"]          = { assetId = "", duration = 2, pitch = 0.92 },
    ["Dialog:Vega:spared"]           = { assetId = "", duration = 2, pitch = 0.92 },
    ["Dialog:Vega:leave"]            = { assetId = "", duration = 1, pitch = 0.92 },
    ["Dialog:Vega:intro_strength"]   = { assetId = "", duration = 4, pitch = 0.92 },
    ["Dialog:Vega:intro_cloak"]      = { assetId = "", duration = 4, pitch = 0.92 },
    ["Dialog:Vega:post_killed"]      = { assetId = "", duration = 2 },
    ["Dialog:Vega:post_spared"]      = { assetId = "", duration = 4, pitch = 0.92 },

    -- Director Cole: too smooth. Pitch 0.88, slightly off-tempo cadence.
    ["Dialog:DirectorCole:intro"]         = { assetId = "", duration = 8, pitch = 0.88 },
    ["Dialog:DirectorCole:offer"]         = { assetId = "", duration = 8, pitch = 0.88 },
    ["Dialog:DirectorCole:refuse"]        = { assetId = "", duration = 4, pitch = 0.88 },
    ["Dialog:DirectorCole:intro_again"]   = { assetId = "", duration = 3, pitch = 0.88 },
    ["Dialog:DirectorCole:post_join"]     = { assetId = "", duration = 4, pitch = 0.88 },

    -- Cael: sharp, urgent. Pitch 1.0.
    ["Dialog:Cael:intro"]            = { assetId = "", duration = 9 },
    ["Dialog:Cael:stall"]            = { assetId = "", duration = 3 },
    ["Dialog:Cael:defect_open"]      = { assetId = "", duration = 5 },
    ["Dialog:Cael:loyal"]            = { assetId = "", duration = 3 },
    ["Dialog:Cael:intro_again"]      = { assetId = "", duration = 2 },
    ["Dialog:Cael:intro_defected"]   = { assetId = "", duration = 8 },
    ["Dialog:Cael:intro_targeting"]  = { assetId = "", duration = 6 },

    --[[ ============================================================
         HOSTILE BARKS — short combat callouts.
         ============================================================ ]]

    -- All hostile combat barks come over a radio: prefix with brief crackle.
    ["Hostile:spotted"]    = { assetId = "", subtitle = "[HOSTILE] Contact! Engage!",        duration = 2.5, prefix = "Radio:crackle" },
    ["Hostile:investigate"]= { assetId = "", subtitle = "[HOSTILE] Did you hear that?",       duration = 2.5, prefix = "Radio:crackle" },
    ["Hostile:lostTarget"] = { assetId = "", subtitle = "[HOSTILE] Where'd they go?",         duration = 2.5, prefix = "Radio:crackle" },
    ["Hostile:reload"]     = { assetId = "", subtitle = "[HOSTILE] Reloading!",               duration = 1.5 },
    ["Hostile:wounded"]    = { assetId = "", subtitle = "[HOSTILE] I'm hit!",                 duration = 1.5 },
    ["Hostile:death"]      = { assetId = "", subtitle = "",                                    duration = 1.5 },
    ["Hostile:knockedOut"] = { assetId = "", subtitle = "",                                    duration = 1.5 },

    -- Idle patrol chatter.
    ["Hostile:idle1"]      = { assetId = "", subtitle = "[HOSTILE] All quiet on this side.",  duration = 2.5, prefix = "Radio:crackle" },
    ["Hostile:idle2"]      = { assetId = "", subtitle = "[HOSTILE] Anything on your end?",    duration = 2.5, prefix = "Radio:crackle" },
    ["Hostile:idle3"]      = { assetId = "", subtitle = "[HOSTILE] Stay sharp.",              duration = 2.5, prefix = "Radio:crackle" },
    ["Hostile:idle4"]      = { assetId = "", subtitle = "[HOSTILE] Copy. Holding position.",  duration = 2.5, prefix = "Radio:crackle" },

    -- Radio chatter pre-cue (very short crackle).
    ["Radio:crackle"]      = { assetId = "", subtitle = "",                                    duration = 0.4, volume = 0.5 },

    --[[ ============================================================
         AUTONOMOUS BOTS
         ============================================================ ]]

    ["Bot:scan"]           = { assetId = "", subtitle = "",                                    duration = 1.5, pitch = 0.7 },
    ["Bot:alert"]          = { assetId = "", subtitle = "[BOT] HOSTILE DETECTED.",             duration = 2,   pitch = 0.7 },
    ["Bot:firing"]         = { assetId = "", subtitle = "",                                    duration = 0.4, pitch = 0.7 },
    ["Bot:lost"]           = { assetId = "", subtitle = "[BOT] TARGET LOST. RESUMING PATROL.", duration = 2.5, pitch = 0.7 },
    ["Bot:disabled"]       = { assetId = "", subtitle = "[BOT] CRITICAL FAILURE.",             duration = 1.5, pitch = 0.7 },
    ["Bot:emp"]            = { assetId = "", subtitle = "",                                    duration = 0.5, pitch = 0.6 },
    ["Spider:warble"]      = { assetId = "", subtitle = "",                                    duration = 1.0, pitch = 1.4 },
    ["Spider:strike"]      = { assetId = "", subtitle = "",                                    duration = 0.5, pitch = 1.4 },

    --[[ ============================================================
         MISSION / SYSTEM CUES
         ============================================================ ]]

    ["Mission:objectiveAdded"]    = { assetId = "", subtitle = "Objective added.",         duration = 2 },
    ["Mission:objectiveComplete"] = { assetId = "", subtitle = "Objective complete.",      duration = 2 },
    ["Mission:augInstalled"]      = { assetId = "", subtitle = "Biomod installed.",        duration = 2 },
    ["Mission:hackSuccess"]       = { assetId = "", subtitle = "Access granted.",          duration = 2 },
    ["Mission:hackFail"]          = { assetId = "", subtitle = "Access denied.",           duration = 2 },
    ["Mission:lockpickSuccess"]   = { assetId = "", subtitle = "",                          duration = 1 },

    -- Endings (each plays as the epilogue UI fades in).
    ["Ending:Lattice"]            = { assetId = "", subtitle = "",                          duration = 6, pitch = 1.0 },
    ["Ending:Quorum"]             = { assetId = "", subtitle = "",                          duration = 6, pitch = 0.95 },
    ["Ending:Reset"]              = { assetId = "", subtitle = "",                          duration = 6, pitch = 0.85 },
    ["Ending:HelixAscension"]     = { assetId = "", subtitle = "",                          duration = 6, pitch = 0.7 },

    --[[ ============================================================
         OPERATIVE BARKS — when the player takes damage etc.
         ============================================================ ]]

    ["Operative:hurt"]       = { assetId = "", subtitle = "",                                duration = 1.0 },
    ["Operative:lowHealth"]  = { assetId = "", subtitle = "[OP] I'm losing blood.",          duration = 2 },
    ["Operative:itemPicked"] = { assetId = "", subtitle = "",                                duration = 0.6 },
}

return VoiceLines
