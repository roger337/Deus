--!strict
-- Receives PlayVoice cues from the server.
-- For each cue: looks up the asset from VoiceLines, creates a Sound (3D if
-- positional, flat if global), plays it, and shows a subtitle caption.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local VoiceLines = require(Shared.Config.VoiceLines)
local Theme = require(script.Parent.Parent.UI.Theme)

local VoiceController = {}

local player = Players.LocalPlayer

local subtitleQueue: { { text: string, duration: number, expires: number } } = {}
local subtitleLabel: TextLabel? = nil

local function buildSubtitleUI(): TextLabel
    if subtitleLabel then return subtitleLabel end
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "VoiceSubtitles"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = pg

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 1)
    container.Position = UDim2.new(0.5, 0, 1, -160)
    container.Size = UDim2.fromOffset(700, 60)
    container.BackgroundTransparency = 1
    container.Parent = sg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.BackgroundTransparency = 0.4
    lbl.BorderSizePixel = 0
    lbl.Font = Theme.Font
    lbl.TextSize = 18
    lbl.TextColor3 = Theme.Text
    lbl.TextStrokeTransparency = 0.5
    lbl.TextWrapped = true
    lbl.Text = ""
    lbl.Visible = false
    lbl.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = lbl

    subtitleLabel = lbl
    return lbl
end

local function showSubtitle(text: string, duration: number)
    if text == "" then return end
    local lbl = buildSubtitleUI()
    local entry = { text = text, duration = duration, expires = os.clock() + duration }
    table.insert(subtitleQueue, entry)
    lbl.Text = text
    lbl.Visible = true
    task.delay(duration, function()
        -- Remove this entry; show the next-most-recent unexpired one.
        for i = #subtitleQueue, 1, -1 do
            if subtitleQueue[i] == entry then
                table.remove(subtitleQueue, i)
                break
            end
        end
        local now = os.clock()
        local nextEntry = nil
        for i = #subtitleQueue, 1, -1 do
            if subtitleQueue[i].expires > now then
                nextEntry = subtitleQueue[i]
                break
            end
        end
        if nextEntry then
            lbl.Text = nextEntry.text
        else
            lbl.Visible = false
        end
    end)
end

local function playSound(line, position: Vector3?)
    if not line.assetId or line.assetId == "" then return end
    local sound = Instance.new("Sound")
    sound.SoundId = line.assetId
    sound.Volume = line.volume or 1
    sound.PlaybackSpeed = line.pitch or 1
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMaxDistance = 100
    sound.RollOffMinDistance = 10

    local parent: Instance
    if position then
        local emitter = Instance.new("Part")
        emitter.Anchored = true
        emitter.CanCollide = false
        emitter.Transparency = 1
        emitter.Size = Vector3.new(0.1, 0.1, 0.1)
        emitter.Position = position
        emitter.Parent = Workspace
        sound.Parent = emitter
        parent = emitter
    else
        sound.Parent = Workspace
        parent = sound
    end

    sound:Play()
    sound.Ended:Connect(function()
        if parent:IsA("Part") then parent:Destroy() else sound:Destroy() end
    end)
    -- Fallback cleanup in case Ended doesn't fire (e.g. invalid asset).
    task.delay((line.duration or 5) + 2, function()
        if parent.Parent then
            if parent:IsA("Part") then parent:Destroy() else sound:Destroy() end
        end
    end)
end

-- Resolves the subtitle text. For Dialog:* keys with no explicit subtitle,
-- DialogUI is already showing the line, so we don't double-show. For bark/system
-- keys, prefer the explicit subtitle.
local function resolveSubtitle(voiceKey: string, line): string?
    if line.subtitle ~= nil then return line.subtitle end
    -- Dialog keys: DialogUI already shows the text; no extra subtitle here.
    if string.sub(voiceKey, 1, 7) == "Dialog:" then return "" end
    return nil
end

function VoiceController.start()
    local ev = Remotes.get("PlayVoice") :: RemoteEvent
    ev.OnClientEvent:Connect(function(payload: any)
        local key = payload.voiceKey
        local line = VoiceLines[key]
        if not line then return end

        -- Optional prefix (e.g. radio crackle). Play it inline; the main line
        -- follows after the prefix's `duration`. For the silent fallback we
        -- still respect timing so subtitle ordering matches voiced playback.
        if line.prefix then
            local prefixLine = VoiceLines[line.prefix]
            if prefixLine then
                playSound(prefixLine, payload.position)
                task.wait(prefixLine.duration or 0.4)
            end
        end

        playSound(line, payload.position)
        local sub = resolveSubtitle(key, line)
        if sub and sub ~= "" then
            showSubtitle(sub, line.duration or 3)
        end
    end)
end

return VoiceController
