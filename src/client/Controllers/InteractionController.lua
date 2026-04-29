--!strict
-- Detects what the player is looking at and shows an "[E] Interact" prompt.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

local InteractionController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local PROMPT_RANGE = 12

local current: Instance? = nil

local function findTarget(): Instance?
    local origin = camera.CFrame.Position
    local dir = camera.CFrame.LookVector
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if player.Character then
        params.FilterDescendantsInstances = { player.Character }
    end
    local res = Workspace:Raycast(origin, dir * PROMPT_RANGE, params)
    if not res or not res.Instance then return nil end
    local inst: Instance = res.Instance
    if inst:GetAttribute("InteractionType") then return inst end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:GetAttribute("InteractionType") then return model end
    return nil
end

local function buildPrompt(): (ScreenGui, TextLabel)
    local pg = player:WaitForChild("PlayerGui")
    local existing = pg:FindFirstChild("InteractionPrompt")
    if existing then
        return existing :: ScreenGui, (existing:FindFirstChildWhichIsA("TextLabel") :: TextLabel)
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "InteractionPrompt"
    sg.ResetOnSpawn = false
    sg.Parent = pg
    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.fromScale(0.5, 0.55)
    lbl.Size = UDim2.fromOffset(360, 36)
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.BackgroundTransparency = 0.4
    lbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 18
    lbl.Visible = false
    lbl.Parent = sg
    return sg, lbl
end

function InteractionController.start()
    local _, label = buildPrompt()

    RunService.RenderStepped:Connect(function()
        local target = findTarget()
        current = target
        if target then
            local kind = target:GetAttribute("InteractionType")
            local text = "[E] Interact"
            if kind == "NPC" then text = "[E] Talk to " .. (target:GetAttribute("Name") or target.Name)
            elseif kind == "Pickup" then text = "[E] Pick up " .. tostring(target:GetAttribute("ItemId"))
            elseif kind == "Door" then
                if target:GetAttribute("Locked") then text = "[E] Lockpick door"
                else text = "[E] Open door" end
            elseif kind == "Hack" then text = "[E] Hack terminal"
            elseif kind == "MedBot" then text = "[E] Use Med Bot"
            elseif kind == "Transition" then text = "[E] Travel" end
            label.Text = text
            label.Visible = true
        else
            label.Visible = false
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.E and current then
            local ev = Remotes.get("InteractWith") :: RemoteEvent
            ev:FireServer(current)
        end
    end)
end

return InteractionController
