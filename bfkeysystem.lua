-- uh hi
local SharedEnv = type(getgenv) == "function" and getgenv() or _G

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local KeySystem = {
    ActivePrompt = nil,
    Connections = {},
    Theme = {
        Background = Color3.fromRGB(13, 15, 13),
        Panel = Color3.fromRGB(18, 20, 18),
        Element = Color3.fromRGB(32, 36, 32),
        HoveredElement = Color3.fromRGB(42, 45, 39),
        Accent = Color3.fromRGB(255, 140, 0),
        AccentHover = Color3.fromRGB(255, 164, 42),
        Text = Color3.fromRGB(238, 241, 236),
        MutedText = Color3.fromRGB(146, 150, 142),
        Outline = Color3.fromRGB(66, 69, 60),
        WarmOutline = Color3.fromRGB(94, 73, 42),
        Danger = Color3.fromRGB(255, 96, 96),
    },
    Animation = {
        Time = 0.22,
        Style = Enum.EasingStyle.Exponential,
        Direction = Enum.EasingDirection.Out,
    },
}

KeySystem.__index = KeySystem

function KeySystem:Trim(value)
    if value == nil then
        return ""
    end

    local text = tostring(value)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

function KeySystem:Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

function KeySystem:Tween(instance, properties, info)
    if not instance then
        return nil
    end

    local tweenInfo = info or TweenInfo.new(self.Animation.Time, self.Animation.Style, self.Animation.Direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function KeySystem:Connect(signal, callback)
    local connection = signal:Connect(callback)
    self.Connections[#self.Connections + 1] = connection
    return connection
end

function KeySystem:ProtectGui(gui)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    elseif protectgui then
        pcall(protectgui, gui)
    end
end

function KeySystem:GetGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    if CoreGui then
        return CoreGui
    end

    local player = Players.LocalPlayer
    while not player do
        task.wait()
        player = Players.LocalPlayer
    end

    return player:WaitForChild("PlayerGui")
end

function KeySystem:DisconnectAll(connections)
    for _, connection in ipairs(connections or {}) do
        if typeof(connection) == "RBXScriptConnection" then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
end

function KeySystem:GetCalculatedRayPosition(position, normal, origin, direction)
    local denominator = normal:Dot(direction)
    if math.abs(denominator) < 0.0001 then
        return nil
    end

    local distance = -normal:Dot(origin - position) / denominator
    return origin + (direction * distance)
end

function KeySystem:CleanupBlur(prompt)
    local items = prompt and prompt.Items
    if not items then
        return
    end

    if items.BlurEffect then
        pcall(function()
            items.BlurEffect:Destroy()
        end)
        items.BlurEffect = nil
    end

    if items.BlurPart then
        pcall(function()
            items.BlurPart:Destroy()
        end)
        items.BlurPart = nil
    end
end

function KeySystem:CleanupStaleBlur()
    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name == "BigFrootKeySystemBlur" then
            pcall(function()
                child:Destroy()
            end)
        end
    end

    local camera = workspace.CurrentCamera
    if camera then
        for _, child in ipairs(camera:GetChildren()) do
            if child.Name == "BigFrootKeySystemBlurPart" then
                pcall(function()
                    child:Destroy()
                end)
            end
        end
    end
end

function KeySystem:MakeGlass(panel, prompt)
    local camera = workspace.CurrentCamera
    if not camera or not panel or not prompt then
        return
    end

    local part = self:Create("Part", {
        Name = "BigFrootKeySystemBlurPart",
        Material = Enum.Material.Glass,
        Transparency = 1,
        Reflectance = 1,
        CastShadow = false,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        Size = Vector3.new(1, 1, 1) * 0.01,
        Color = Color3.fromRGB(0, 0, 0),
        Parent = camera,
    })

    local mesh = self:Create("BlockMesh", {
        Parent = part,
    })

    local depthOfField = self:Create("DepthOfFieldEffect", {
        Name = "BigFrootKeySystemBlur",
        Parent = Lighting,
        Enabled = true,
        FarIntensity = 0,
        FocusDistance = 0,
        InFocusRadius = 1000,
        NearIntensity = 0,
    })

    prompt.Items.BlurPart = part
    prompt.Items.BlurMesh = mesh
    prompt.Items.BlurEffect = depthOfField

    local function hideBlur()
        mesh.Offset = Vector3.new(0, 0, 0)
        mesh.Scale = Vector3.new(0, 0, 0)
        part.Transparency = 1
        depthOfField.NearIntensity = 0
    end

    local connection = RunService.RenderStepped:Connect(function()
        if prompt.Closed or not panel.Parent then
            hideBlur()
            return
        end

        camera = workspace.CurrentCamera
        if not camera then
            hideBlur()
            return
        end

        if part.Parent ~= camera then
            part.Parent = camera
        end

        local size = panel.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            hideBlur()
            return
        end

        depthOfField.NearIntensity = math.min(depthOfField.NearIntensity + 0.12, 1)
        part.Transparency = 0.97
        part.Size = Vector3.new(1, 1, 1) * 0.01

        local corner0 = panel.AbsolutePosition
        local corner1 = corner0 + size
        local ray0 = camera:ScreenPointToRay(corner0.X, corner0.Y, 1)
        local ray1 = camera:ScreenPointToRay(corner1.X, corner1.Y, 1)
        local origin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
        local normal = camera.CFrame.LookVector

        local position0 = self:GetCalculatedRayPosition(origin, normal, ray0.Origin, ray0.Direction)
        local position1 = self:GetCalculatedRayPosition(origin, normal, ray1.Origin, ray1.Direction)
        if not position0 or not position1 then
            hideBlur()
            return
        end

        position0 = camera.CFrame:PointToObjectSpace(position0)
        position1 = camera.CFrame:PointToObjectSpace(position1)

        local blurSize = position1 - position0
        local center = (position0 + position1) / 2

        mesh.Offset = center
        mesh.Scale = blurSize / 0.0101
        part.CFrame = camera.CFrame
    end)

    prompt.Connections[#prompt.Connections + 1] = connection
end

function KeySystem:Prompt(options)
    options = options or {}

    if self.ActivePrompt and self.ActivePrompt.Close then
        self.ActivePrompt:Close()
    end

    local guiParent = self:GetGuiParent()
    local oldPrompt = guiParent:FindFirstChild("BigFrootKeySystemPrompt")
    if oldPrompt then
        pcall(function()
            oldPrompt:Destroy()
        end)
    end
    self:CleanupStaleBlur()

    local prompt = {
        Library = self,
        Connections = {},
        Closed = false,
        Submitting = false,
        Items = {},
    }

    local theme = self.Theme
    local isMobile = UserInputService.TouchEnabled == true
    local panelHeight = isMobile and 238 or 226
    local panelWidth = isMobile and 0.92 or 0.86
    local panelPadding = isMobile and 14 or 16

    local screenGui = self:Create("ScreenGui", {
        Name = "BigFrootKeySystemPrompt",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
    })
    prompt.Items.ScreenGui = screenGui
    self:ProtectGui(screenGui)

    local overlay = self:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = screenGui,
    })
    prompt.Items.Overlay = overlay

    local panel = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 12),
        Size = UDim2.new(panelWidth, 0, 0, panelHeight),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = overlay,
    })
    prompt.Items.Panel = panel

    self:Create("UISizeConstraint", {
        MinSize = Vector2.new(304, panelHeight),
        MaxSize = Vector2.new(468, panelHeight),
        Parent = panel,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = panel,
    })

    local shadow = self:Create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "http://www.roblox.com/asset/?id=18245826428",
        ImageColor3 = theme.Accent,
        ImageTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        ScaleType = Enum.ScaleType.Slice,
        Size = UDim2.new(1, 22, 1, 22),
        SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
        ZIndex = panel.ZIndex - 1,
        Parent = panel,
    })
    prompt.Items.Shadow = shadow

    local stroke = self:Create("UIStroke", {
        Color = theme.WarmOutline,
        Thickness = 1,
        Transparency = 1,
        Parent = panel,
    })
    prompt.Items.Stroke = stroke

    local scale = self:Create("UIScale", {
        Scale = 0.965,
        Parent = panel,
    })
    prompt.Items.Scale = scale

    local content = self:Create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = panel,
    })

    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, panelPadding),
        PaddingBottom = UDim.new(0, panelPadding),
        PaddingLeft = UDim.new(0, panelPadding + 2),
        PaddingRight = UDim.new(0, panelPadding + 2),
        Parent = content,
    })

    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content,
    })

    local header = self:Create("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = content,
    })

    local badge = self:Create("Frame", {
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0.35,
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(0, 1),
        Parent = header,
    })
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = badge,
    })
    local badgeStroke = self:Create("UIStroke", {
        Color = theme.WarmOutline,
        Thickness = 1,
        Transparency = 0.28,
        Parent = badge,
    })
    self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "BF",
        TextColor3 = theme.Accent,
        TextSize = 16,
        Parent = badge,
    })

    self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 22, 0, 4),
        Parent = badge,
    })

    local title = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(50, 0),
        Size = UDim2.new(1, -50, 0, 22),
        Font = Enum.Font.GothamBold,
        RichText = true,
        Text = options.Title or '<font color="rgb(255, 140, 0)">Big</font>Froot Key System',
        TextColor3 = theme.Text,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = header,
    })

    local subtitle = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(51, 25),
        Size = UDim2.new(1, -51, 0, 19),
        Font = Enum.Font.GothamMedium,
        Text = options.Subtitle or "Luarmor Access",
        TextColor3 = theme.MutedText,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = header,
    })

    local status = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Size = UDim2.new(1, -24, 0, 22),
        Font = Enum.Font.Gotham,
        Text = options.Status or "Enter your Luarmor key to continue.",
        TextColor3 = theme.MutedText,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = content,
    })
    prompt.Items.Status = status

    local inputFrame = self:Create("Frame", {
        LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Parent = content,
    })
    prompt.Items.InputFrame = inputFrame
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = inputFrame,
    })
    local inputStroke = self:Create("UIStroke", {
        Color = theme.Outline,
        Thickness = 1,
        Transparency = 0.58,
        Parent = inputFrame,
    })
    prompt.Items.InputStroke = inputStroke

    local input = self:Create("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.Code,
        PlaceholderText = options.Placeholder or "Paste your key here",
        PlaceholderColor3 = theme.MutedText,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = self:Trim(options.InitialKey),
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = inputFrame,
    })
    prompt.Items.Input = input

    local buttonRow = self:Create("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = content,
    })

    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = buttonRow,
    })

    local getKey = self:Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        LayoutOrder = 1,
        Size = UDim2.new(0.38, -5, 1, 0),
        Text = "Get Key",
        TextColor3 = theme.Text,
        TextSize = 14,
        Parent = buttonRow,
    })
    prompt.Items.GetKey = getKey

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = getKey,
    })
    local getKeyStroke = self:Create("UIStroke", {
        Color = theme.Outline,
        Thickness = 1,
        Transparency = 0.58,
        Parent = getKey,
    })

    local submit = self:Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        LayoutOrder = 2,
        Size = UDim2.new(0.62, -5, 1, 0),
        Text = "Validate Key",
        TextColor3 = Color3.fromRGB(22, 22, 19),
        TextSize = 14,
        Parent = buttonRow,
    })
    prompt.Items.Submit = submit

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = submit,
    })
    local submitStroke = self:Create("UIStroke", {
        Color = Color3.fromRGB(255, 190, 88),
        Thickness = 1,
        Transparency = 0.42,
        Parent = submit,
    })

    self:MakeGlass(panel, prompt)

    function prompt:SetStatus(message, color)
        status.Text = tostring(message or "")
        status.TextColor3 = color or theme.MutedText
    end

    function prompt:SetSubmitting(value)
        self.Submitting = value == true
        submit.Text = self.Submitting and "Checking..." or "Validate Key"
        submit.AutoButtonColor = false
        self.Library:Tween(submit, {
            BackgroundColor3 = self.Submitting and theme.AccentHover or theme.Accent,
            BackgroundTransparency = self.Submitting and 0.18 or 0,
        })
        self.Library:Tween(submitStroke, {
            Transparency = self.Submitting and 0.7 or 0.42,
        })
    end

    function prompt:Close()
        if self.Closed then
            return
        end

        self.Closed = true
        self.Library:DisconnectAll(self.Connections)
        self.Library.ActivePrompt = nil

        pcall(function()
            self.Library:Tween(scale, {Scale = 0.975})
            self.Library:Tween(panel, {Position = UDim2.new(0.5, 0, 0.5, 12), BackgroundTransparency = 1})
            self.Library:Tween(overlay, {BackgroundTransparency = 1})
        self.Library:Tween(stroke, {Transparency = 1})
            self.Library:Tween(shadow, {ImageTransparency = 1})
            if self.Items.BlurEffect then
                self.Library:Tween(self.Items.BlurEffect, {NearIntensity = 0})
            end
        end)

        task.delay(0.24, function()
            self.Library:CleanupBlur(self)
            if screenGui then
                pcall(function()
                    screenGui:Destroy()
                end)
            end
        end)
    end

    function prompt:GetKey()
        return self.Library:Trim(input.Text)
    end

    local function track(connection)
        prompt.Connections[#prompt.Connections + 1] = connection
        return connection
    end

    local function hoverButton(button, strokeObject, normalColor, hoverColor, normalStrokeTransparency, hoverStrokeTransparency)
        track(button.MouseEnter:Connect(function()
            if prompt.Submitting and button == submit then
                return
            end
            self:Tween(button, {BackgroundColor3 = hoverColor, BackgroundTransparency = 0})
            if strokeObject then
                self:Tween(strokeObject, {Color = theme.WarmOutline, Transparency = hoverStrokeTransparency or 0.34})
            end
        end))

        track(button.MouseLeave:Connect(function()
            if prompt.Submitting and button == submit then
                return
            end
            self:Tween(button, {BackgroundColor3 = normalColor, BackgroundTransparency = button == submit and 0 or 0.04})
            if strokeObject then
                self:Tween(strokeObject, {
                    Color = button == submit and Color3.fromRGB(255, 190, 88) or theme.Outline,
                    Transparency = normalStrokeTransparency or 0.58,
                })
            end
        end))
    end

    hoverButton(getKey, getKeyStroke, theme.Element, theme.HoveredElement, 0.58, 0.34)
    hoverButton(submit, submitStroke, theme.Accent, theme.AccentHover, 0.42, 0.22)

    track(input.Focused:Connect(function()
        self:Tween(inputFrame, {BackgroundColor3 = theme.HoveredElement, BackgroundTransparency = 0})
        self:Tween(inputStroke, {Color = theme.Accent, Transparency = 0.25})
        self:Tween(badgeStroke, {Color = theme.Accent, Transparency = 0.18})
    end))

    track(input.FocusLost:Connect(function(enterPressed)
        self:Tween(inputFrame, {BackgroundColor3 = theme.Element, BackgroundTransparency = 0.04})
        self:Tween(inputStroke, {Color = theme.Outline, Transparency = 0.58})
        self:Tween(badgeStroke, {Color = theme.WarmOutline, Transparency = 0.28})

        if enterPressed then
            prompt.SubmitKey()
        end
    end))

    local function setStatus(message, color)
        prompt:SetStatus(message, color)
    end

    local function close()
        prompt:Close()
    end

    function prompt.SubmitKey()
        if prompt.Submitting or prompt.Closed then
            return
        end

        prompt:SetSubmitting(true)
        prompt:SetStatus(options.CheckingStatus or "Checking key...")

        task.spawn(function()
            local ok, result = pcall(function()
                if type(options.OnSubmit) == "function" then
                    return options.OnSubmit(prompt:GetKey(), setStatus, close, prompt)
                end
            end)

            if not ok then
                prompt:SetStatus("Key submit failed: " .. tostring(result), theme.Danger)
            end

            if not prompt.Closed then
                prompt:SetSubmitting(false)
            end
        end)
    end

    track(getKey.MouseButton1Click:Connect(function()
        local invite = self:Trim(options.Discord or options.URL or "")
        if invite == "" then
            prompt:SetStatus("No key link configured.", theme.Danger)
            return
        end

        if setclipboard then
            pcall(setclipboard, invite)
            prompt:SetStatus("Discord invite copied. Paste your key here after you get it.")
        else
            prompt:SetStatus("Discord: " .. invite)
        end
    end))

    track(submit.MouseButton1Click:Connect(prompt.SubmitKey))

    screenGui.Parent = guiParent
    self.ActivePrompt = prompt

    task.defer(function()
        self:Tween(overlay, {BackgroundTransparency = 0.26})
        self:Tween(panel, {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.08})
        self:Tween(scale, {Scale = 1})
        self:Tween(stroke, {Transparency = 0.32})
        self:Tween(shadow, {ImageTransparency = 0.72})
    end)

    return prompt
end

SharedEnv.BigFrootKeySystem = KeySystem
return KeySystem
