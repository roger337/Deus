--!strict
-- Voice line registry. Maps a stable string key to a Roblox audio asset ID + subtitle.
--
-- HOW TO ADD A VOICE LINE:
--   1. Upload your audio to Roblox (Studio -> Toolbox -> Audio -> "My Audio").
--   2. Copy the resulting asset URL: rbxassetid://<NUMBER>
--   3. Paste it into the `assetId` field below.
--
-- You can also paste in any audio asset ID you legitimately own/are licensed to use.
-- Keys with `assetId == ""` will play no sound but still display the subtitle.
--
-- Subtitles are intentionally short (1 line). Long dialog text lives in Dialog.lua;
-- subtitles here are only shown for *bark*-style voice lines (enemy alerts, etc.)
-- where there is no dialog UI on screen. For dialog tree lines, the dialog text in
-- Dialog.lua is the subtitle, and assetId is looked up via key "Dialog:<tree>:<node>".

export type VoiceLine = {
    assetId: string,        -- "" = silent fallback (subtitle only)
    subtitle: string?,      -- nil = use the dialog node's text instead
    duration: number,       -- seconds; subtitle stays this long
    volume: number?,
    pitch: number?,         -- PlaybackSpeed; <1 lower, >1 higher (Anna ~0.92)
    prefix: string?,        -- another VoiceLine key to play first (e.g. "Radio:crackle")
}

local VoiceLines: { [string]: VoiceLine } = {

    --[[ ============================================================
         DIALOG VOICES — keyed as "Dialog:<treeId>:<nodeId>"
         These play when DialogService shows the matching node.
         Subtitle is taken from the dialog text, so leave nil here.
         ============================================================ ]]

    -- Paul Denton: low, calm. pitch 0.95.
    ["Dialog:PaulDenton:intro"]        = { assetId = "", duration = 8, pitch = 0.95 },
    ["Dialog:PaulDenton:where"]        = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:PaulDenton:who"]          = { assetId = "", duration = 5, pitch = 0.95 },
    ["Dialog:PaulDenton:accept"]       = { assetId = "", duration = 2, pitch = 0.95 },

    -- Dr. Reyes: neutral, warm. pitch 1.05.
    ["Dialog:JaimeReyes:intro"]        = { assetId = "", duration = 8, pitch = 1.05 },
    ["Dialog:JaimeReyes:supplies"]     = { assetId = "", duration = 2, pitch = 1.05 },
    ["Dialog:JaimeReyes:extras"]       = { assetId = "", duration = 4, pitch = 1.05 },

    -- Anna Navarre: nano-aug throat, faintly robotic. pitch 0.92.
    ["Dialog:AnnaNavarre:intro"]       = { assetId = "", duration = 6, pitch = 0.92 },
    ["Dialog:AnnaNavarre:argue"]       = { assetId = "", duration = 4, pitch = 0.92 },
    ["Dialog:AnnaNavarre:leave"]       = { assetId = "", duration = 1, pitch = 0.92 },

    --[[ ============================================================
         ENEMY BARKS — short combat callouts.
         Subtitle is shown briefly if the player is nearby and audio
         is missing/silent.
         ============================================================ ]]

    -- All NSF combat barks come over the radio: prefix with a brief crackle.
    ["NSF:spotted"]    = { assetId = "", subtitle = "[NSF] Hostile! Take him down!",      duration = 2.5, prefix = "Radio:crackle" },
    ["NSF:investigate"]= { assetId = "", subtitle = "[NSF] Did you hear that?",           duration = 2.5, prefix = "Radio:crackle" },
    ["NSF:lostTarget"] = { assetId = "", subtitle = "[NSF] Where'd he go?",               duration = 2.5, prefix = "Radio:crackle" },
    ["NSF:reload"]     = { assetId = "", subtitle = "[NSF] Reloading!",                   duration = 1.5 },
    ["NSF:wounded"]    = { assetId = "", subtitle = "[NSF] I'm hit!",                     duration = 1.5 },
    ["NSF:death"]      = { assetId = "", subtitle = "",                                   duration = 1.5 },
    ["NSF:knockedOut"] = { assetId = "", subtitle = "",                                   duration = 1.5 },

    -- Idle patrol chatter. Picked at random by EnemyAI patrol step.
    ["NSF:idle1"]      = { assetId = "", subtitle = "[NSF] All quiet on this side.",     duration = 2.5, prefix = "Radio:crackle" },
    ["NSF:idle2"]      = { assetId = "", subtitle = "[NSF] Anything on your end?",       duration = 2.5, prefix = "Radio:crackle" },
    ["NSF:idle3"]      = { assetId = "", subtitle = "[NSF] Stay sharp, Denton's coming.", duration = 2.5, prefix = "Radio:crackle" },
    ["NSF:idle4"]      = { assetId = "", subtitle = "[NSF] Copy. Holding position.",     duration = 2.5, prefix = "Radio:crackle" },

    -- Radio chatter pre-cue (very short crackle, plays before NSF lines).
    ["Radio:crackle"]  = { assetId = "", subtitle = "",                                   duration = 0.4, volume = 0.5 },

    --[[ ============================================================
         AUTONOMOUS BOTS — security bot scans, spider bot warbles.
         Bots have a robotic pitch (0.7-0.85) and no radio prefix.
         ============================================================ ]]

    ["Bot:scan"]       = { assetId = "", subtitle = "",                                   duration = 1.5, pitch = 0.7 },
    ["Bot:alert"]      = { assetId = "", subtitle = "[BOT] HOSTILE DETECTED.",            duration = 2,   pitch = 0.7 },
    ["Bot:firing"]     = { assetId = "", subtitle = "",                                   duration = 0.4, pitch = 0.7 },
    ["Bot:lost"]       = { assetId = "", subtitle = "[BOT] TARGET LOST. RESUMING PATROL.", duration = 2.5, pitch = 0.7 },
    ["Bot:disabled"]   = { assetId = "", subtitle = "[BOT] CRITICAL FAILURE.",            duration = 1.5, pitch = 0.7 },
    ["Bot:emp"]        = { assetId = "", subtitle = "",                                   duration = 0.5, pitch = 0.6 },

    ["Spider:warble"]  = { assetId = "", subtitle = "",                                   duration = 1.0, pitch = 1.4 },
    ["Spider:strike"]  = { assetId = "", subtitle = "",                                   duration = 0.5, pitch = 1.4 },

    --[[ ============================================================
         MISSION / SYSTEM CUES — global, non-positional.
         ============================================================ ]]

    ["Mission:objectiveAdded"]    = { assetId = "", subtitle = "Objective added.",        duration = 2 },
    ["Mission:objectiveComplete"] = { assetId = "", subtitle = "Objective complete.",     duration = 2 },
    ["Mission:augInstalled"]      = { assetId = "", subtitle = "Augmentation installed.", duration = 2 },
    ["Mission:hackSuccess"]       = { assetId = "", subtitle = "Access granted.",         duration = 2 },
    ["Mission:hackFail"]          = { assetId = "", subtitle = "Access denied.",          duration = 2 },
    ["Mission:lockpickSuccess"]   = { assetId = "", subtitle = "",                        duration = 1 },

    --[[ ============================================================
         JC DENTON BARKS — when the player takes damage, picks up
         items, etc. (Optional, but DX-flavored.)
         ============================================================ ]]

    ["JC:hurt"]        = { assetId = "", subtitle = "",                                   duration = 1.0 },
    ["JC:lowHealth"]   = { assetId = "", subtitle = "[JC] I'm losing blood.",             duration = 2 },
    ["JC:itemPicked"]  = { assetId = "", subtitle = "",                                   duration = 0.6 },
}

return VoiceLines
