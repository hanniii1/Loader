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
    [97365843755210] = { "Cut Grass For Brainrots", "https://api.luarmor.net/files/v4/loaders/52f46b7e492243b23953d2c7611e1c44.lua" },
    [124473577469410] = { "Be a Lucky Block", "https://api.luarmor.net/files/v4/loaders/eb83fa1cc2d982f694566e45ad865313.lua" },
    [82397737462020] = { "Shrink for Brainrot", "https://api.luarmor.net/files/v4/loaders/3a4dea3e62ef5f49d0301fcadcb796e5.lua" },
    [7798947148] = { "Anime Final Quest", "https://api.luarmor.net/files/v4/loaders/992facee57df35654157a7d040aa16fd.lua" },
    [77393318863643] = { "Aura Ascension Ahh game", "https://api.jnkie.com/api/v1/luascripts/public/6a5f9cea79d13310ce5e282d6b13a4ea81c63b565a488719070775678cffc6a2/download" },
    [105626692504093] = { "Be a Brainrot", "https://api.luarmor.net/files/v4/loaders/2467a31cffe47ea62651b0f9197a8100.lua" },
    [112259901434347] = { "+1 Speed be a Lucky Block!", "https://api.luarmor.net/files/v4/loaders/d0f4c13d54d518c47c4e06d2fe8ba534.lua"},
    [9802644580] = { "Summon Heroes", "https://api.luarmor.net/files/v4/loaders/4736e7dbf7040c8cbf738f5a7c465f88.lua"},
    [8937254139] = { "Dungeon Hunters", "https://api.luarmor.net/files/v4/loaders/96a47eae49cdce186b82f27466a233db.lua"},
    [9833422940] = { "Unbox a Factory", "https://api.luarmor.net/files/v4/loaders/a974d391286695dcf54c134194860bee.lua"},
    [9073513091] = { "Anime Apocalypse", "https://api.luarmor.net/files/v4/loaders/63f05e6d8ec9ff5cdb72620492a06b7b.lua"}, 
    [8966502575] = { "Anime Reversal", "https://api.luarmor.net/files/v4/loaders/c95fc83170e2c97e0a06c6d6f23e74a6.lua"},
    [10032271327] = { "Anime World Fighters", "https://api.luarmor.net/files/v4/loaders/87e72a93771433a6438c356156ad2ed0.lua"},
    [138064211947107] = { "Unbox a Car", "https://api.luarmor.net/files/v4/loaders/a974d391286695dcf54c134194860bee.lua" },
    [9610561918] = { "Knife Farm", "https://api.luarmor.net/files/v4/loaders/ad5cca7cb4a373b3f12a55e1a974247e.lua" },
    [10004244222] = { "Kick a Lucky Block", "https://api.luarmor.net/files/v4/loaders/3ef6c0d255ef20d5c9ea2416d784c1ab.lua" },
    [9792947201] = { "Slime RNG", "https://api.luarmor.net/files/v4/loaders/0910ebdb1ba97ae86eee29570e60cf26.lua"},
    [10016841656] = { "Noob Tower Defense", "https://api.luarmor.net/files/v4/loaders/b83acbbb777878cbf813d68fb39ca95e.lua"},
    [6409513651] = { "Anime Warrior III", "https://api.luarmor.net/files/v4/loaders/7c5ad6d6d9907dc52339b6992c69929f.lua"},
    [10039338037] = { "Build A Ring Farm", "https://api.luarmor.net/files/v4/loaders/0c4926532de4a165261afd5cdef461e8.lua"},
}
local route = routes[game.PlaceId] or routes[game.GameId]
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
