local SCRIPT_ID = "18094583217895890396"
local SCRIPT_NAME = "BigFroot Pet Snipe"
local LOADER_URL = "https://cdn.jsdelivr.net/gh/hanniii1/Loader@main/bfpetsnipe.lua"
local KEY_FILE = "BFPetSnipeKeyNew.txt"
local KEY_URL = nil 

local function trim(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function setKeyGlobals(key)
	pcall(function() lp_key = key end)
	pcall(function() _G.lp_key = key end)
	if getgenv then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" then
			pcall(function() env.lp_key = key end)
		end
	end
end


local function runProtected(key)
	setKeyGlobals(key)
	return pcall(function()
		loadstring(game:HttpGet(LOADER_URL))()
	end)
end

local function readSavedKey()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then
		return ""
	end
	local okExists, exists = pcall(isfile, KEY_FILE)
	if not okExists or not exists then
		return ""
	end
	local okRead, value = pcall(readfile, KEY_FILE)
	if not okRead or type(value) ~= "string" then
		return ""
	end
	return trim(value)
end

local function saveKey(key)
	if type(writefile) == "function" then
		pcall(writefile, KEY_FILE, key)
	end
end


local carried = (type(lp_key) == "string" and lp_key ~= "" and lp_key ~= "x") and lp_key or nil
local existing = carried or readSavedKey()
if existing ~= "" then
	local okSdk, sdk = pcall(function()
		return loadstring(game:HttpGet("https://sdk.luaprot.net/"))()
	end)
	if okSdk and type(sdk) == "table" then
		sdk.scriptId = SCRIPT_ID
		local okChk, res = pcall(function()
			return sdk:checkKey(existing)
		end)
		if okChk and type(res) == "table" and res.status == "VALID" then
			saveKey(existing) 
			runProtected(existing)
			return
		end
	end
end


local keySystem = loadstring(game:HttpGet("https://sdk.luaprot.net/key-ui.lua"))()
keySystem.scriptId = SCRIPT_ID
keySystem.scriptName = SCRIPT_NAME
keySystem.keyURL = KEY_URL
keySystem.validCallback = function(key)
	saveKey(key)
	runProtected(key)
end
keySystem:show()
