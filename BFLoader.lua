if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(math.random())

local function trim(v)
    return tostring(v or ""):match("^%s*(.-)%s*$") or ""
end

local function envOf(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, env = pcall(fn, ...)
    return ok and type(env) == "table" and env or nil
end

local genv = envOf(getgenv)
local cenv = envOf(getfenv, 1)

local function pick(...)
    for _, key in ipairs({...}) do
        if cenv and cenv[key] ~= nil then
            return cenv[key]
        end
        if rawget(_G, key) ~= nil then
            return rawget(_G, key)
        end
        if genv and genv[key] ~= nil then
            return genv[key]
        end
    end
end

local function setKey(key)
    key = trim(key)
    if key == "" then
        return
    end
    script_key, SCRIPT_KEY = key, key
    _G.script_key, _G.SCRIPT_KEY = key, key
    if genv then
        genv.script_key, genv.SCRIPT_KEY = key, key
    end
end

local routes = {
    [114640202062357] = { "Swing Obby For Brainrots", "https://api.luarmor.net/files/v4/loaders/99d5f951b48d089c55f94310cce9276e.lua" },
    [130594398886540] = { "Garden Horizons", "https://api.luarmor.net/files/v4/loaders/069acf492628081651416f39de947b77.lua" },
    [7856269159] = { "Anime Overload", "https://api.luarmor.net/files/v4/loaders/e6153c73e2d96eb2d2d95cc9eb9bd94b.lua" },
    [80353351682367] = { "Anime Overload", "https://api.luarmor.net/files/v4/loaders/e6153c73e2d96eb2d2d95cc9eb9bd94b.lua" },
    [126297188712308] = { "Anime Overload", "https://api.luarmor.net/files/v4/loaders/e6153c73e2d96eb2d2d95cc9eb9bd94b.lua" },
    [97365843755210] = { "Cut Grass For Brainrots", "https://api.luarmor.net/files/v4/loaders/52f46b7e492243b23953d2c7611e1c44.lua" },
    [124473577469410] = { "Be a Lucky Block", "https://api.luarmor.net/files/v4/loaders/eb83fa1cc2d982f694566e45ad865313.lua" },
}

local route = routes[game.PlaceId]
if not route then
    return
end

setKey(pick("script_key", "SCRIPT_KEY"))

local scriptId = route[2]:match("/loaders/([%w]+)%.lua")
if scriptId then
    _G.LUARMOR_SCRIPT_ID, _G.BIGFROOT_LUARMOR_SCRIPT_ID = scriptId, scriptId
    if genv then
        genv.LUARMOR_SCRIPT_ID, genv.BIGFROOT_LUARMOR_SCRIPT_ID = scriptId, scriptId
    end
end

local state = (genv and genv.BigFrootLoaderState) or { loaded = {} }
if genv then
    genv.BigFrootLoaderState = state
end

if state.loaded[route[1]] then
    return
end
state.loaded[route[1]] = true

local ok, src = pcall(game.HttpGet, game, route[2])
if ok and src and pcall(loadstring(src)) then
    return
end

state.loaded[route[1]] = nil
