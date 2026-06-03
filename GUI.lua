-- GUI.lua — Rayfield toggles, sliders, buttons for all features
local H = getgenv().PDHub
local Settings = H.Settings
local Rayfield = H.Rayfield
local RT = H.Tabs.Render
local AT = H.Tabs.Aimbot
local IT = H.Tabs.Info

-- ===== RENDER TAB =====
RT:CreateSection("Player ESP")
RT:CreateToggle({ Name = "Enable ESP", CurrentValue = false, Callback = function(v)
    Settings.ESP_Enabled = v
    Rayfield:Notify({Title="ESP", Content=v and "ESP Enabled" or "ESP Disabled", Duration=2})
end })
RT:CreateSlider({ Name = "Player ESP Max Distance", Range = {50,2000}, Increment = 50,
    Suffix = "m", CurrentValue = 500, Callback = function(v) Settings.ESP_MaxDist = v end })

RT:CreateSection("NPC ESP")
RT:CreateToggle({ Name = "Enable NPC ESP", CurrentValue = false, Callback = function(v)
    Settings.NPC_ESP_Enabled = v
    if v and H.ScanForNPCs then task.spawn(H.ScanForNPCs) end
    Rayfield:Notify({Title="NPC ESP", Content=v and "NPC ESP Enabled" or "NPC ESP Disabled", Duration=2})
end })
RT:CreateSlider({ Name = "NPC ESP Max Distance", Range = {50,2000}, Increment = 50,
    Suffix = "m", CurrentValue = 500, Callback = function(v) Settings.NPC_ESP_MaxDist = v end })

RT:CreateSection("Corpse ESP")
RT:CreateToggle({ Name = "Enable Corpse ESP", CurrentValue = false, Callback = function(v)
    Settings.CorpseESP_Enabled = v
    Rayfield:Notify({Title="Corpse ESP", Content=v and "Showing dead bodies" or "Corpse ESP Disabled", Duration=2})
end })

RT:CreateSection("Environment")
RT:CreateToggle({ Name = "Night Vision", CurrentValue = false, Callback = function(v)
    H.ToggleNightVision(v)
    Rayfield:Notify({Title="Night Vision", Content=v and "Enabled" or "Disabled", Duration=2})
end })
RT:CreateToggle({ Name = "Remove Fog", CurrentValue = false, Callback = function(v)
    H.ToggleRemoveFog(v)
    Rayfield:Notify({Title="Fog", Content=v and "Fog Removed" or "Fog Restored", Duration=2})
end })
RT:CreateToggle({ Name = "No Visor", CurrentValue = false, Callback = function(v)
    H.ToggleNoVisor(v)
    Rayfield:Notify({Title="Visor", Content=v and "Visor Removed" or "Visor Restored", Duration=2})
end })

-- ===== AIMBOT TAB =====
AT:CreateSection("Player Aimbot")
AT:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v)
    Settings.Aimbot_Enabled = v
    Rayfield:Notify({Title="Aimbot", Content=v and "Aimbot Enabled" or "Aimbot Disabled", Duration=2})
end })

AT:CreateSection("NPC Aimbot")
AT:CreateToggle({ Name = "Enable NPC Aimbot", CurrentValue = false, Callback = function(v)
    Settings.NPC_Aimbot_Enabled = v
    Rayfield:Notify({Title="NPC Aimbot", Content=v and "Enabled" or "Disabled", Duration=2})
end })

AT:CreateSection("Aimbot Settings")
AT:CreateDropdown({ Name = "Aimbot Target", Options = {"Head","Torso"}, CurrentOption = {"Head"},
    MultiOption = false, Callback = function(v)
    Settings.AimbotTarget = v[1] or v
    Rayfield:Notify({Title="Target", Content="Aiming at: "..(v[1] or v), Duration=2})
end })
AT:CreateToggle({ Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) Settings.FOV_Visible = v end })
AT:CreateSlider({ Name = "FOV Radius", Range = {50,800}, Increment = 10,
    Suffix = "Px", CurrentValue = 300, Callback = function(v) Settings.FOV_Radius = v end })
AT:CreateToggle({ Name = "Prioritize Visible", CurrentValue = true, Callback = function(v) Settings.PrioritizeVisible = v end })
AT:CreateToggle({ Name = "Prioritize Proximity", CurrentValue = true, Callback = function(v) Settings.PrioritizeProximity = v end })
AT:CreateSlider({ Name = "Smoothness", Range = {0.1,1}, Increment = 0.1,
    Suffix = "Smooth", CurrentValue = 0.2, Callback = function(v) Settings.Smoothness = v end })
AT:CreateToggle({ Name = "Prediction (Bullet Drop)", CurrentValue = false, Callback = function(v)
    Settings.Prediction_Enabled = v
    Rayfield:Notify({Title="Prediction", Content=v and "Enabled" or "Disabled", Duration=2})
end })

-- ===== CREDITS + UNLOAD =====
IT:CreateParagraph({ Title = "Credits", Content = "Project Delta Hub\nModular Edition" })
IT:CreateButton({ Name = "Unload Hub", Callback = function()
    H.SetUnloaded(true); H.Aiming = false
    for _, c in pairs(H.Connections) do pcall(function() if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end) end
    pcall(function() H.RunService:UnbindFromRenderStep("UnifiedAimbot") end)
    pcall(function() if H.FOVCircle then H.FOVCircle:Remove() end end)
    pcall(function() if Settings.NightVision_Enabled then H.DisableNightVision() end end)
    pcall(function() if Settings.RemoveFog_Enabled then H.ToggleRemoveFog(false) end end)
    pcall(function() if Settings.NoVisor_Enabled then H.ToggleNoVisor(false) end end)
    pcall(function() H.ESP_Holder:Destroy() end)
    pcall(function() Rayfield:Destroy() end)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Hub", Text = "Unloaded!", Duration = 3
    })
end })

Rayfield:LoadConfiguration()
