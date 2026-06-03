-- Project Delta Hub — Modular Loader
-- This is the only script you need to run. It pulls all modules from GitHub.
local base = "https://raw.githubusercontent.com/notPMANO/ProjectDelta-Modules/main/"
local function load(name) loadstring(game:HttpGet(base .. name))() end

load("Core.lua")
load("ESP.lua")
load("Aimbot.lua")
load("Environment.lua")
load("GUI.lua")
