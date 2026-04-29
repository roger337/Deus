--!strict
-- Server-side voice cue dispatcher. Server fires a `PlayVoice` remote with a
-- voice key + optional source position; client looks up the asset and plays it.
--
-- We never ship the raw asset ID over the wire — the client already has the
-- VoiceLines table — so a key + position is all that's needed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local VoiceLines = require(Shared.Config.VoiceLines)

local VoiceService = {}

-- Throttle barks so an enemy doesn't spam the same line every tick.
local lastBarkTime: { [string]: number } = {}
local BARK_COOLDOWN = 4

local function ev(): RemoteEvent
    return Remotes.get("PlayVoice") :: RemoteEvent
end

function VoiceService.exists(voiceKey: string): boolean
    return VoiceLines[voiceKey] ~= nil
end

-- Play a global cue (no positional audio). All players hear it.
function VoiceService.playGlobal(voiceKey: string)
    if not VoiceLines[voiceKey] then return end
    local payload = { voiceKey = voiceKey }
    for _, player in ipairs(Players:GetPlayers()) do
        ev():FireClient(player, payload)
    end
end

-- Play a cue for a specific player only.
function VoiceService.playFor(player: Player, voiceKey: string, position: Vector3?)
    if not VoiceLines[voiceKey] then return end
    ev():FireClient(player, {
        voiceKey = voiceKey,
        position = position,
    })
end

-- Positional bark from a source instance. Players within `audibleRange` hear it.
function VoiceService.playFromInstance(source: Instance, voiceKey: string, audibleRange: number?)
    if not VoiceLines[voiceKey] then return end
    local pos: Vector3? = nil
    if source:IsA("BasePart") then
        pos = source.Position
    elseif source:IsA("Model") then
        local part = source.PrimaryPart or source:FindFirstChildWhichIsA("BasePart")
        if part then pos = part.Position end
    end
    local range = audibleRange or 80
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not hrp then continue end
        if pos and (hrp.Position - pos).Magnitude > range then continue end
        ev():FireClient(player, {
            voiceKey = voiceKey,
            position = pos,
        })
    end
end

-- Per-source throttled bark. Use this for enemy alerts so each NSF grunt only
-- yells one alert per cooldown window.
function VoiceService.bark(source: Instance, voiceKey: string)
    local key = source:GetDebugId() .. ":" .. voiceKey
    local now = os.clock()
    if (lastBarkTime[key] or 0) + BARK_COOLDOWN > now then return end
    lastBarkTime[key] = now
    VoiceService.playFromInstance(source, voiceKey)
end

return VoiceService
