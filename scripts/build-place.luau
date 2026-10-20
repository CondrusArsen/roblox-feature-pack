--!strict
-- Builds a playable place: the map from Testovoe.rbxl + the code from default.project.json.
-- Usage (from the repo root): lune run scripts/build-place
-- Output: build/FeaturePack.rbxl
--
-- Testovoe.rbxl still contains the original submission's scripts and RemoteEvents.
-- They are stripped here so they do not run next to the Rojo-managed code.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

type Instance = roblox.Instance

local MAP = "Testovoe.rbxl"
local CODE = "build/code.rbxl"
local OUTPUT = "build/FeaturePack.rbxl"
local LEGACY_REMOTES = { KillEvent = true, ClickEvent = true, StoreEvent = true }
local MERGE_INTO = { StarterPlayerScripts = true, StarterCharacterScripts = true }

if not fs.isDir("build") then
	fs.writeDir("build")
end

local rojo = process.exec("rojo", { "build", "default.project.json", "--output", CODE })
if not rojo.ok then
	error("rojo build failed:\n" .. rojo.stderr)
end

local map = roblox.deserializePlace(fs.readFile(MAP))
local code = roblox.deserializePlace(fs.readFile(CODE))

local removed = {}
for _, instance in map:GetDescendants() do
	local isLegacyScript = instance:IsA("LuaSourceContainer")
	local isLegacyRemote = instance.ClassName == "RemoteEvent" and LEGACY_REMOTES[instance.Name] == true
	if isLegacyScript or isLegacyRemote then
		table.insert(removed, instance:GetFullName())
		instance.Parent = nil
	end
end

local function merge(target: Instance, source: Instance)
	for _, child in source:GetChildren() do
		local existing = target:FindFirstChild(child.Name)
		if existing and existing.ClassName == child.ClassName and MERGE_INTO[child.ClassName] then
			merge(existing, child)
		else
			if existing and existing.ClassName == child.ClassName then
				existing.Parent = nil
			end
			child:Clone().Parent = target
		end
	end
end

for _, service in code:GetChildren() do
	if #service:GetChildren() > 0 then
		merge(map:GetService(service.ClassName), service)
	end
end

fs.writeFile(OUTPUT, roblox.serializePlace(map))

print("Removed legacy instances:")
for _, name in removed do
	print("  " .. name)
end
print("Wrote " .. OUTPUT)
