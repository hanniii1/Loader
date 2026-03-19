if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(math.random())

local routes = {
    [114640202062357] = {
        name = "Swing Obby For Brainrots",
        url = "https://api.luarmor.net/files/v4/loaders/99d5f951b48d089c55f94310cce9276e.lua",
    },
}

local route = routes[game.PlaceId]
if not route then
    return
end

getgenv().BigFrootLoaderState = getgenv().BigFrootLoaderState or {
    loaded = {}
}

local state = getgenv().BigFrootLoaderState
if state.loaded[route.name] then
    return
end

state.loaded[route.name] = true

local ok, source = pcall(function()
    return game:HttpGet(route.url)
end)

if not ok or not source then
    warn("[BigFroot Loader] Failed to fetch " .. route.name)
    state.loaded[route.name] = nil
    return
end

local runOk, err = pcall(function()
    loadstring(source)()
end)

if not runOk then
    warn("[BigFroot Loader] Failed to run " .. route.name .. ": " .. tostring(err))
    state.loaded[route.name] = nil
end
