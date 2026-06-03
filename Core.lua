-- Core.lua — Services, settings, shared state, Rayfield window
-- All other modules read from getgenv().PDHub

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Project Delta Hub",
    LoadingTitle = "Loading...",
    ConfigurationSaving = { Enabled = true, FolderName = "GeminiDeltaHub" },
    KeySystem = true,
    KeySettings = {
        Title = "Authentication",
        Subtitle = "Enter Key to access the hub",
        Note = "Key: 123",
        FileName = "GeminiDeltaKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"123"}
    }
})

local Settings = {
    ESP_Enabled = false, Aimbot_Enabled = false, Smoothness = 0.2,
    FOV_Radius = 300, FOV_Visible = false,
    VisibleColor = Color3.fromRGB(50, 255, 50),
    NotVisibleColor = Color3.fromRGB(255, 50, 50),
    PrioritizeVisible = true, PrioritizeProximity = true,
    NPC_ESP_Enabled = false, NPC_Aimbot_Enabled = false,
    NPCVisibleColor = Color3.fromRGB(255, 105, 180),
    NPCNotVisibleColor = Color3.fromRGB(170, 50, 255),
    DeadColor = Color3.fromRGB(255, 255, 0),
    CorpseESP_Enabled = false,
    ESP_MaxDist = 500, NPC_ESP_MaxDist = 500,
    NightVision_Enabled = false, RemoveFog_Enabled = false,
    AimbotTarget = "Head", Prediction_Enabled = false, NoVisor_Enabled = false
}

local Connections = {}
local Unloaded = false
local ESP_Holder = Instance.new("Folder")
ESP_Holder.Name = "Gemini_Unified"
pcall(function() ESP_Holder.Parent = CoreGui end)
if not ESP_Holder.Parent then
    ESP_Holder.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function IsPlayerVisible(targetCharacter)
    local myCharacter = LocalPlayer.Character
    if not myCharacter then return false end
    local myHead = myCharacter:FindFirstChild("Head")
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not myHead or not targetHead then return false end
    Camera = workspace.CurrentCamera
    if not Camera then return false end
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetHead.Position - rayOrigin).Unit * (targetHead.Position - rayOrigin).Magnitude
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {myCharacter}
    local result = workspace:Raycast(rayOrigin, rayDirection, params)
    if result then
        if result.Instance:IsDescendantOf(targetCharacter) then return true end
        return false
    end
    return true
end

getgenv().PDHub = {
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    CoreGui = CoreGui, Lighting = Lighting, LocalPlayer = LocalPlayer,
    Camera = Camera, Rayfield = Rayfield, Window = Window,
    Settings = Settings, Connections = Connections, ESP_Holder = ESP_Holder,
    Unloaded = Unloaded, Aiming = false, NPC_Highlights = {},
    IsPlayerVisible = IsPlayerVisible,
    Tabs = {
        Render = Window:CreateTab("Render", 4483362458),
        Aimbot = Window:CreateTab("Aimbot", 4483362458),
        Options = Window:CreateTab("Options", 4483362458),
        Info = Window:CreateTab("Credits", 4483362458),
    },
    SetUnloaded = function(val) Unloaded = val; getgenv().PDHub.Unloaded = val end,
}
