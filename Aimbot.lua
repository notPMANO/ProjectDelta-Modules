-- Aimbot.lua — Aimbot + FOV circle
local H = getgenv().PDHub
local Players, LocalPlayer = H.Players, H.LocalPlayer
local RunService, UserInputService = H.RunService, H.UserInputService
local Settings, Connections = H.Settings, H.Connections
local Camera = workspace.CurrentCamera

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 64
FOVCircle.Filled = false; FOVCircle.Transparency = 0.8; FOVCircle.Visible = false
H.FOVCircle = FOVCircle

Connections["FOVUpdate"] = RunService.RenderStepped:Connect(function()
    if H.Unloaded then return end
    Camera = workspace.CurrentCamera
    if Camera then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Settings.FOV_Radius
        FOVCircle.Visible = Settings.FOV_Visible and Settings.Aimbot_Enabled
    end
end)

local function GetBestTarget()
    Camera = workspace.CurrentCamera
    if not Camera then return nil end
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local candidates = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local hum = player.Character:FindFirstChild("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if head and hum and root and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local sd = (Vector2.new(pos.X, pos.Y) - Center).Magnitude
                    if sd < Settings.FOV_Radius then
                        table.insert(candidates, {
                            character = player.Character,
                            worldDist = (myRoot.Position - root.Position).Magnitude,
                            screenDist = sd,
                            visible = H.IsPlayerVisible(player.Character),
                            isNPC = false
                        })
                    end
                end
            end
        end
    end

    if Settings.NPC_Aimbot_Enabled then
        for npcModel, _ in pairs(H.NPC_Highlights) do
            if npcModel and npcModel.Parent then
                local head = npcModel:FindFirstChild("Head")
                local hum = npcModel:FindFirstChildOfClass("Humanoid")
                local root = npcModel:FindFirstChild("HumanoidRootPart") or npcModel.PrimaryPart
                if head and hum and root and hum.Health > 0 then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local sd = (Vector2.new(pos.X, pos.Y) - Center).Magnitude
                        if sd < Settings.FOV_Radius then
                            table.insert(candidates, {
                                character = npcModel,
                                worldDist = (myRoot.Position - root.Position).Magnitude,
                                screenDist = sd,
                                visible = H.IsPlayerVisible(npcModel),
                                isNPC = true
                            })
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b)
        if Settings.PrioritizeVisible and a.visible ~= b.visible then return a.visible end
        if Settings.PrioritizeProximity then return a.worldDist < b.worldDist end
        return a.screenDist < b.screenDist
    end)
    return candidates[1].character
end

local function GetAimPart(character)
    if Settings.AimbotTarget == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    end
    return character:FindFirstChild("Head")
end

RunService:BindToRenderStep("UnifiedAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if H.Unloaded then return end
    if H.Aiming and Settings.Aimbot_Enabled then
        local targetChar = GetBestTarget()
        local aimPart = targetChar and GetAimPart(targetChar)
        if aimPart then
            Camera = workspace.CurrentCamera
            if Camera then
                local currentCF = Camera.CFrame
                local targetPos = aimPart.Position
                if Settings.Prediction_Enabled then
                    local dist = (currentCF.Position - targetPos).Magnitude
                    if dist > 350 then
                        targetPos = targetPos + Vector3.new(0, (dist - 350) * 0.007, 0)
                    end
                end
                Camera.CFrame = currentCF:Lerp(CFrame.lookAt(currentCF.Position, targetPos), Settings.Smoothness)
            end
        end
    end
end)

Connections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, gp)
    if H.Unloaded then return end
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton2 then H.Aiming = true end
end)
Connections["InputEnded"] = UserInputService.InputEnded:Connect(function(input)
    if H.Unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then H.Aiming = false end
end)
