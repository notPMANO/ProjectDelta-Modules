-- Environment.lua — Night Vision, Fog Removal, No Visor
local H = getgenv().PDHub
local Settings = H.Settings
local Lighting = H.Lighting
local LocalPlayer = H.LocalPlayer
local Connections = H.Connections

local OriginalLighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient, ExposureCompensation = Lighting.ExposureCompensation,
}

local OriginalAtmospheres = {}
for _, e in pairs(Lighting:GetChildren()) do
    if e:IsA("Atmosphere") then OriginalAtmospheres[e] = e.Density end
end

local OriginalPostEffects = {}
local NightVisionCC = nil

-- Night Vision
local function EnableNightVision()
    Lighting.ClockTime = 14; Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(180,180,180)
    Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
    Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
    Lighting.FogStart = 100000; Lighting.ExposureCompensation = 0

    if not NightVisionCC then
        NightVisionCC = Instance.new("ColorCorrectionEffect")
        NightVisionCC.Name = "GeminiNightVision"; NightVisionCC.Parent = Lighting
    end
    NightVisionCC.Brightness = 0.05; NightVisionCC.Contrast = 0.05
    NightVisionCC.Saturation = 0; NightVisionCC.TintColor = Color3.fromRGB(255,255,255)
    NightVisionCC.Enabled = true

    for _, e in pairs(Lighting:GetChildren()) do
        if e:IsA("ColorCorrectionEffect") and e.Name ~= "GeminiNightVision" then
            if not OriginalPostEffects[e] then
                OriginalPostEffects[e] = {Enabled=e.Enabled,Brightness=e.Brightness,Contrast=e.Contrast,Saturation=e.Saturation,TintColor=e.TintColor}
            end
            e.Brightness=0; e.Contrast=0; e.TintColor=Color3.fromRGB(255,255,255)
        elseif e:IsA("Atmosphere") then
            if not OriginalPostEffects[e] then OriginalPostEffects[e] = {Enabled=true,Parent=e.Parent} end
            e.Parent = nil
        elseif e:IsA("BloomEffect") then
            if not OriginalPostEffects[e] then OriginalPostEffects[e] = {Enabled=e.Enabled,Intensity=e.Intensity} end
            e.Intensity = 0
        elseif e:IsA("BlurEffect") then
            if not OriginalPostEffects[e] then OriginalPostEffects[e] = {Enabled=e.Enabled,Size=e.Size} end
            e.Size = 0
        end
    end
end

local function DisableNightVision()
    for k,v in pairs(OriginalLighting) do pcall(function() Lighting[k] = v end) end
    if NightVisionCC then NightVisionCC:Destroy(); NightVisionCC = nil end
    for e, d in pairs(OriginalPostEffects) do
        pcall(function()
            if d.Parent and not e.Parent then e.Parent = d.Parent end
            if e and e.Parent then for p,v in pairs(d) do if p~="Parent" then e[p]=v end end end
        end)
    end
    OriginalPostEffects = {}
end

H.ToggleNightVision = function(on)
    Settings.NightVision_Enabled = on
    if on then EnableNightVision() else DisableNightVision() end
end

-- Fog Removal
H.ToggleRemoveFog = function(on)
    Settings.RemoveFog_Enabled = on
    if on then
        Lighting.FogEnd = 100000; Lighting.FogStart = 100000
        for _, e in pairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") then e.Density = 0 end
        end
    else
        Lighting.FogEnd = OriginalLighting.FogEnd; Lighting.FogStart = OriginalLighting.FogStart
        for e, d in pairs(OriginalAtmospheres) do
            if e and e.Parent then e.Density = d end
        end
    end
end

-- No Visor
local HiddenVisors = {}
local VisorScanConn = nil

local function IsVisorElement(obj)
    if not (obj:IsA("ImageLabel") or obj:IsA("Frame") or obj:IsA("ImageButton")) then return false end
    local current = obj
    while current and not current:IsA("PlayerGui") do
        if current.Name then
            local n = current.Name:lower()
            if n:find("inventory") or n:find("backpack") or n:find("hotbar") or n:find("slot")
                or n:find("menu") or n:find("shop") or n:find("hud") or n:find("health")
                or n:find("ammo") or n:find("chat") or n:find("score") or n:find("leaderboard")
                or n:find("rayfield") or n:find("gemini") or n:find("loading") then return false end
        end
        current = current.Parent
    end
    local name = obj.Name:lower()
    if name:find("visor") or name:find("overlay") or name:find("vignette") or name:find("helmet")
        or name:find("scope") or name:find("border") or name:find("blackout") or name:find("goggles") then
        return true
    end
    if (obj:IsA("Frame") or obj:IsA("ImageLabel")) then
        local sz = obj.AbsoluteSize
        local cam = workspace.CurrentCamera
        if cam then
            local ss = cam.ViewportSize
            if sz.X > ss.X*0.3 and sz.Y > ss.Y*0.3 and obj.BackgroundTransparency < 0.5 then
                local c = obj.BackgroundColor3
                if (c.R+c.G+c.B)/3 < 0.15 then return true end
            end
        end
    end
    return false
end

local function HideVisor(obj)
    if HiddenVisors[obj] then return end
    HiddenVisors[obj] = {Visible=obj.Visible, Transparency=obj.BackgroundTransparency}
    obj.Visible = false; obj.BackgroundTransparency = 1
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        HiddenVisors[obj].ImageTransparency = obj.ImageTransparency
        obj.ImageTransparency = 1
    end
end

H.ToggleNoVisor = function(on)
    Settings.NoVisor_Enabled = on
    if on then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, g in pairs(pg:GetDescendants()) do
                pcall(function() if IsVisorElement(g) then HideVisor(g) end end)
            end
            if not VisorScanConn then
                VisorScanConn = pg.DescendantAdded:Connect(function(o)
                    if not Settings.NoVisor_Enabled then return end
                    task.wait(0.1)
                    pcall(function() if IsVisorElement(o) then HideVisor(o) end end)
                end)
            end
        end
    else
        for o, d in pairs(HiddenVisors) do
            pcall(function()
                if o and o.Parent then
                    o.Visible = d.Visible; o.BackgroundTransparency = d.Transparency
                    if d.ImageTransparency then o.ImageTransparency = d.ImageTransparency end
                end
            end)
        end
        HiddenVisors = {}
        if VisorScanConn then VisorScanConn:Disconnect(); VisorScanConn = nil end
    end
end

-- Store cleanup refs
H.DisableNightVision = DisableNightVision
H.HiddenVisors = HiddenVisors
H.VisorScanConn = VisorScanConn
