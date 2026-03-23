if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(math.random())

local routes = {
    [114640202062357] = { "Swing Obby For Brainrots", "https://api.luarmor.net/files/v4/loaders/99d5f951b48d089c55f94310cce9276e.lua" },
    [130594398886540] = { "Garden Horizons", "https://api.luarmor.net/files/v4/loaders/069acf492628081651416f39de947b77.lua" },
    [7856269159] = { "Anime Overload", "https://api.luarmor.net/files/v4/loaders/e6153c73e2d96eb2d2d95cc9eb9bd94b.lua" },
    [80353351682367] = { "Anime Overload", "https://api.luarmor.net/files/v4/loaders/e6153c73e2d96eb2d2d95cc9eb9bd94b.lua" },
    [126297188712308] = { "Anime Overload", "https://api.luarmor.net/files/v4/loaders/e6153c73e2d96eb2d2d95cc9eb9bd94b.lua" },
    [97365843755210] = { "Cut Grass For Brainrots", "https://api.luarmor.net/files/v4/loaders/52f46b7e492243b23953d2c7611e1c44.lua" },
}

local route = routes[game.PlaceId]
if not route then return end

local state = getgenv().BigFrootLoaderState or { loaded = {} }
getgenv().BigFrootLoaderState = state

local name, url = route[1], route[2]
if state.loaded[name] then return end
state.loaded[name] = true

local ok, src = pcall(game.HttpGet, game, url)
if ok and src then
    local ran = pcall(loadstring(src))
    if ran then return end
end

state.loaded[name] = nil
