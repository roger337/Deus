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
    pitch: number?,
}

local VoiceLines: { [string]: VoiceLine } = {

    --[[ ============================================================
         DIALOG VOICES — keyed as "Dialog:<treeId>:<nodeId>"
         These play when DialogService shows the matching node.
         Subtitle is taken from the dialog text, so leave nil here.
         ============================================================ ]]

    ["Dialog:PaulDenton:intro"]        = { assetId = "", duration = 8 },
    ["Dialog:PaulDenton:where"]        = { assetId = "", duration = 5 },
    ["Dialog:PaulDenton:who"]          = { assetId = "", duration = 5 },
    ["Dialog:PaulDenton:accept"]       = { assetId = "", duration = 2 },

    ["Dialog:JaimeReyes:intro"]        = { assetId = "", duration = 8 },
    ["Dialog:JaimeReyes:supplies"]     = { assetId = "", duration = 2 },
    ["Dialog:JaimeReyes:extras"]       = { assetId = "", duration = 4 },

    ["Dialog:AnnaNavarre:intro"]       = { assetId = "", duration = 6 },
    ["Dialog:AnnaNavarre:argue"]       = { assetId = "", duration = 4 },
    ["Dialog:AnnaNavarre:leave"]       = { assetId = "", duration = 1 },

    --[[ ============================================================
         ENEMY BARKS — short combat callouts.
         Subtitle is shown briefly if the player is nearby and audio
         is missing/silent.
         ============================================================ ]]

    ["NSF:spotted"]    = { assetId = "", subtitle = "[NSF] Hostile! Take him down!",      duration = 2.5 },
    ["NSF:investigate"]= { assetId = "", subtitle = "[NSF] Did you hear that?",           duration = 2.5 },
    ["NSF:lostTarget"] = { assetId = "", subtitle = "[NSF] Where'd he go?",               duration = 2.5 },
    ["NSF:reload"]     = { assetId = "", subtitle = "[NSF] Reloading!",                   duration = 1.5 },
    ["NSF:wounded"]    = { assetId = "", subtitle = "[NSF] I'm hit!",                     duration = 1.5 },
    ["NSF:death"]      = { assetId = "", subtitle = "",                                   duration = 1.5 },
    ["NSF:knockedOut"] = { assetId = "", subtitle = "",                                   duration = 1.5 },

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
