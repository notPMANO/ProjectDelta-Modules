-- ESP.lua — Player ESP + NPC ESP
local H = getgenv().PDHub
local Players, LocalPlayer = H.Players, H.LocalPlayer
local Settings, Connections, ESP_Holder = H.Settings, H.Connections, H.ESP_Holder

local function CreateESP(player)
    if player == LocalPlayer then return end
    local function characterAdded(character)
        if H.Unloaded then return end
        local rootPart, head, humanoid
        for attempt = 1, 15 do
            if H.Unloaded or not character or not character.Parent then return end
            rootPart = character:FindFirstChild("HumanoidRootPart")
            head = character:FindFirstChild("Head")
            humanoid = character:FindFirstChildOfClass("Humanoid")
            if rootPart and head and humanoid then break end
            task.wait(2)
        end
        if not rootPart or not head or not humanoid then return end
        local hl = character:FindFirstChild("ESPHighlight")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "ESPHighlight"; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.Parent = character
        end
        local bg = Instance.new("BillboardGui")
        bg.Name = "ESPInfo"; bg.Adornee = head; bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0); bg.AlwaysOnTop = true; bg.Parent = ESP_Holder
        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = bg; textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1; textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold; textLabel.TextSize = 13
        task.spawn(function()
            while not H.Unloaded and character and character.Parent and bg and bg.Parent do
                pcall(function()
                    local tHum = character:FindFirstChildOfClass("Humanoid")
                    local isDead = tHum and tHum.Health <= 0
                    local color = isDead and Settings.DeadColor or (H.IsPlayerVisible(character) and Settings.VisibleColor or Settings.NotVisibleColor)
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local tRoot = character:FindFirstChild("HumanoidRootPart")
                    local dist = (myRoot and tRoot) and math.floor((myRoot.Position - tRoot.Position).Magnitude) or 0
                    local currentHead = character:FindFirstChild("Head")
                    if currentHead and bg.Adornee ~= currentHead then bg.Adornee = currentHead end
                    local inRange = dist <= Settings.ESP_MaxDist
                    hl.FillColor = color; hl.OutlineColor = color; textLabel.TextColor3 = color
                    local espOn = isDead and Settings.CorpseESP_Enabled or Settings.ESP_Enabled
                    hl.Enabled = espOn and inRange; bg.Enabled = espOn and inRange
                    if myRoot and tRoot and tHum then
                        local hp = math.floor(tHum.Health)
                        if isDead then textLabel.Text = string.format("%s\n[Corpse] [%d m]", player.Name, dist)
                        else
                            local vis = H.IsPlayerVisible(character) and "Visible" or "Hidden"
                            textLabel.Text = string.format("%s\n[HP:%d] [%d m] [%s]", player.Name, hp, dist, vis)
                        end
                    else textLabel.Text = player.Name end
                end)
                task.wait(0.1)
            end
            pcall(function() if hl then hl:Destroy() end; if bg then bg:Destroy() end end)
        end)
    end
    if player.Character then characterAdded(player.Character) end
    local conn = player.CharacterAdded:Connect(characterAdded)
    table.insert(Connections, conn)
end
for _, p in pairs(Players:GetPlayers()) do task.spawn(CreateESP, p) end
Connections["PlayerAdded"] = Players.PlayerAdded:Connect(CreateESP)

-- NPC ESP
local NPC_Highlights = H.NPC_Highlights
local function IsNPC(model)
    if not model:IsA("Model") or not model:FindFirstChildOfClass("Humanoid") then return false end
    for _, p in pairs(Players:GetPlayers()) do if p.Character == model then return false end end
    return true
end
local function ApplyNPC_ESP(model)
    if not IsNPC(model) or NPC_Highlights[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NPC_ESPHighlight"; hl.FillColor = Settings.NPCNotVisibleColor
    hl.OutlineColor = Settings.NPCNotVisibleColor; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.Parent = model
    local head = model:FindFirstChild("Head")
    local bg = Instance.new("BillboardGui")
    bg.Name = "NPC_ESPInfo"; bg.Adornee = head or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
    bg.Size = UDim2.new(0, 200, 0, 30); bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true; bg.Parent = ESP_Holder
    local tl = Instance.new("TextLabel")
    tl.Parent = bg; tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1
    tl.TextStrokeTransparency = 0; tl.Font = Enum.Font.GothamBold; tl.TextSize = 13
    tl.TextColor3 = Settings.NPCNotVisibleColor; tl.Text = "[NPC] " .. model.Name
    NPC_Highlights[model] = {highlight = hl, billboard = bg}
    task.spawn(function()
        while not H.Unloaded and model and model.Parent and bg and bg.Parent do
            pcall(function()
                local nHum = model:FindFirstChildOfClass("Humanoid")
                local isDead = nHum and nHum.Health <= 0
                local color = isDead and Settings.DeadColor or (H.IsPlayerVisible(model) and Settings.NPCVisibleColor or Settings.NPCNotVisibleColor)
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local nRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                local dist = (myRoot and nRoot) and math.floor((myRoot.Position - nRoot.Position).Magnitude) or 0
                local inRange = dist <= Settings.NPC_ESP_MaxDist
                hl.FillColor = color; hl.OutlineColor = color; tl.TextColor3 = color
                local espOn = isDead and Settings.CorpseESP_Enabled or Settings.NPC_ESP_Enabled
                hl.Enabled = espOn and inRange; bg.Enabled = espOn and inRange
                if myRoot and nRoot and nHum then
                    local hp = math.floor(nHum.Health)
                    local vis = H.IsPlayerVisible(model) and "Visible" or "Hidden"
                    tl.Text = isDead and string.format("[NPC] %s\n[Corpse] [%d m]", model.Name, dist) or string.format("[NPC] %s\n[HP:%d] [%d m] [%s]", model.Name, hp, dist, vis)
                end
            end)
            task.wait(0.2)
        end
        pcall(function() if hl then hl:Destroy() end; if bg then bg:Destroy() end end)
        NPC_Highlights[model] = nil
    end)
end
local function ScanForNPCs()
    for _, obj in pairs(workspace:GetDescendants()) do task.spawn(ApplyNPC_ESP, obj) end
end
H.ScanForNPCs = ScanForNPCs
task.spawn(ScanForNPCs)
Connections["NPCAdded"] = workspace.DescendantAdded:Connect(function(obj)
    if H.Unloaded then return end
    task.wait(1)
    if obj:IsA("Model") then task.spawn(ApplyNPC_ESP, obj) end
end)
