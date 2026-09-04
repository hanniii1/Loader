--[[
-- vxq

feel free to use

]]

local SharedEnv = (type(getgenv) == "function" and getgenv()) or _G

if not LPH_OBFUSCATED then
    loadstring([[
        function LPH_ATTRIBUTES() end
        function VM() end
        function PRESET() end
        function TRANSFORM() end
    ]])()
end

local cloneref = cloneref or function(Object) return Object end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local GuiService = cloneref(game:GetService("GuiService"))

local SetThreadIdentity = setthreadidentity or setidentity or set_thread_identity
local function Cap()
    if SetThreadIdentity then
        pcall(SetThreadIdentity, 8)
    end
end
Cap()

local HasFS = type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function"

-- unload the previous instance so re-running is a clean reload
if SharedEnv.blushkey and type(SharedEnv.blushkey.Unload) == "function" then
    pcall(SharedEnv.blushkey.Unload, SharedEnv.blushkey)
end

local KeySystem = {
    Version = "1.0.0",
    Font = "rbxasset://fonts/families/Roboto.json",
    FontSize = 13,
    Theme = {
        Background = Color3.fromRGB(10, 10, 11),
        Panel      = Color3.fromRGB(16, 16, 18),
        Element    = Color3.fromRGB(25, 25, 28),
        Hover      = Color3.fromRGB(34, 34, 38),
        Outline    = Color3.fromRGB(36, 36, 40),
        Accent     = Color3.fromRGB(240, 166, 196),
        Text       = Color3.fromRGB(242, 238, 240),
        DimText    = Color3.fromRGB(138, 134, 138),
        Risky      = Color3.fromRGB(255, 86, 86),
        Success    = Color3.fromRGB(130, 220, 160),
    },
    Signals = {},
    Threads = {},
    ActivePrompt = nil,
}

--#region helpers
local function Trim(Value)
    return (tostring(Value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
KeySystem.Trim = Trim

function KeySystem:GetFont(Weight)
    local Weights = {
        Regular = Enum.FontWeight.Regular,
        Medium = Enum.FontWeight.Medium,
        SemiBold = Enum.FontWeight.SemiBold,
        Bold = Enum.FontWeight.Bold,
    }
    return Font.new(self.Font, Weights[Weight or "Regular"] or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

function KeySystem:Create(Class, Properties)
    LPH_ATTRIBUTES(VM(NONE))
    local Object = Instance.new(Class)
    if Object:IsA("GuiObject") then
        Object.BorderSizePixel = 0
    end
    if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
        Object.FontFace = self:GetFont(Properties.Weight)
        Object.TextSize = Properties.TextSize or self.FontSize
        Object.TextColor3 = self.Theme.Text
        Properties.Weight = nil
        if Object:IsA("TextButton") then
            Object.AutoButtonColor = false
        end
        if Object:IsA("TextBox") then
            Object.ClearTextOnFocus = false
        end
    end
    local Parent = Properties.Parent
    Properties.Parent = nil
    for Property, Value in Properties do
        Object[Property] = Value
    end
    Object.Name = "\0"
    Object.Parent = Parent
    return Object
end

function KeySystem:Corner(Object, Radius)
    return self:Create("UICorner", { CornerRadius = UDim.new(0, Radius or 8), Parent = Object })
end

function KeySystem:Tween(Object, Properties, Time, Style, Direction)
    local Tween = TweenService:Create(Object, TweenInfo.new(Time or 0.18, Style or Enum.EasingStyle.Quart, Direction or Enum.EasingDirection.Out), Properties)
    Tween:Play()
    return Tween
end

function KeySystem:Connect(Signal, Callback)
    local Connection = Signal:Connect(function(...)
        LPH_ATTRIBUTES(VM(NONE))
        Cap()
        return Callback(...)
    end)
    table.insert(self.Signals, Connection)
    return Connection
end

function KeySystem:Thread(Callback)
    local Thread = task.spawn(function()
        Cap()
        Callback()
    end)
    table.insert(self.Threads, Thread)
    return Thread
end

-- press feedback: shrink then spring back
function KeySystem:Pop(Object)
    local Scale = Object:FindFirstChildOfClass("UIScale") or self:Create("UIScale", { Parent = Object })
    Scale.Scale = 0.96
    self:Tween(Scale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
end

function KeySystem:Hover(Button, NormalColor, HoverColor)
    self:Connect(Button.MouseEnter, function()
        self:Tween(Button, { BackgroundColor3 = HoverColor }, 0.1)
    end)
    self:Connect(Button.MouseLeave, function()
        self:Tween(Button, { BackgroundColor3 = NormalColor }, 0.1)
    end)
end

-- native drop shadow with a stub when the executor's client predates UIShadow
function KeySystem:Shadow(Object, Color, Transparency, Blur, OffsetY)
    local Ok, Shadow = pcall(Instance.new, "UIShadow")
    if not Ok or not Shadow then
        return nil
    end
    Shadow.Name = "\0"
    Shadow.Color = Color
    Shadow.Transparency = Transparency
    Shadow.Offset = UDim2.fromOffset(0, OffsetY or 0)
    Shadow.Spread = UDim2.fromOffset(0, 0)
    Shadow.BlurRadius = UDim.new(0, Blur)
    Shadow.Parent = Object
    return Shadow
end

function KeySystem:Copy(Text)
    if type(setclipboard) == "function" then
        local Ok = pcall(setclipboard, Text)
        return Ok
    end
    return false
end

-- key file helpers -----------------------------------------------------------
function KeySystem:ReadSavedKey(Path)
    if not HasFS or not Path then
        return ""
    end
    local Ok, Exists = pcall(isfile, Path)
    if not Ok or not Exists then
        return ""
    end
    local OkRead, Value = pcall(readfile, Path)
    return (OkRead and type(Value) == "string") and Trim(Value) or ""
end

function KeySystem:SaveKey(Path, Key)
    if not HasFS or not Path then
        return false
    end
    local Folder = Path:match("^(.*)/[^/]+$")
    if Folder and type(makefolder) == "function" then
        local Current = ""
        for Part in Folder:gmatch("[^/]+") do
            Current = Current == "" and Part or (Current .. "/" .. Part)
            if not (isfolder and isfolder(Current)) then
                pcall(makefolder, Current)
            end
        end
    end
    return pcall(writefile, Path, Trim(Key))
end

function KeySystem:ClearKey(Path)
    if HasFS and Path and type(delfile) == "function" and isfile(Path) then
        pcall(delfile, Path)
    end
end
--#endregion

--#region luarmor
-- Optional Luarmor glue (the BigFroot loaders use it). The prompt itself is provider-agnostic.
KeySystem.LuarmorMessages = {
    KEY_VALID = "key valid.",
    KEY_HWID_LOCKED = "that key is linked to another HWID. reset it in the discord first.",
    KEY_EXPIRED = "that key expired. grab a new one.",
    KEY_BANNED = "that key is banned.",
    KEY_INCORRECT = "that key is wrong or was deleted.",
    KEY_INVALID = "that is not a valid key format.",
    SCRIPT_ID_INCORRECT = "the luarmor script id is wrong.",
    SCRIPT_ID_INVALID = "the luarmor script id is wrong.",
    INVALID_EXECUTOR = "luarmor does not support this executor.",
    SECURITY_ERROR = "luarmor security check failed.",
    TIME_ERROR = "your system clock is wrong.",
    UNKNOWN_ERROR = "luarmor returned an unknown error.",
}

-- one SDK per script id, downloaded on first use
local LuarmorApis = {}
function KeySystem:LuarmorApi(ScriptId)
    if LuarmorApis[ScriptId] then
        return LuarmorApis[ScriptId]
    end
    local Ok, Api = pcall(function()
        return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
    end)
    if not Ok or type(Api) ~= "table" or type(Api.check_key) ~= "function" then
        return nil
    end
    Api.script_id = ScriptId
    LuarmorApis[ScriptId] = Api
    return Api
end

function KeySystem:DescribeLuarmor(Status)
    if type(Status) ~= "table" then
        return "key check failed."
    end
    return self.LuarmorMessages[Status.code] or tostring(Status.message or Status.code or "invalid key.")
end

-- returns the status table when the key is valid, otherwise false + a message (+ the raw status)
function KeySystem:LuarmorCheck(ScriptId, Key)
    Key = Trim(Key)
    if Key == "" then
        return false, "type or paste a key first."
    end
    local Api = self:LuarmorApi(ScriptId)
    if not Api then
        return false, "could not reach luarmor. check your connection and try again."
    end
    local Ok, Status = pcall(function()
        Api.script_id = ScriptId
        return Api.check_key(Key)
    end)
    if not Ok or type(Status) ~= "table" then
        return false, "key check failed."
    end
    if Status.code == "KEY_VALID" then
        return Status, self.LuarmorMessages.KEY_VALID, Status
    end
    return false, self:DescribeLuarmor(Status), Status
end
--#endregion

--#region prompt
-- KeySystem:Prompt({
--     Title, Subtitle, Status, Placeholder, Key,
--     Discord, Premium,                -- links copied by the two secondary buttons
--     GetKeyText, PremiumText, SubmitText,
--     OnGetKey(prompt), OnPremium(prompt),   -- override the copy-to-clipboard behaviour
--     OnSubmit(key, setStatus, prompt) -> valid (bool), message (string?)
--     OnSuccess(key)                   -- after the success animation, prompt already closed
--     Glow = false,                    -- accent glow instead of the black drop shadow
--     Theme = { Accent = Color3 },     -- override any colour
-- })
function KeySystem:Prompt(Options)
    Options = Options or {}
    if self.ActivePrompt then
        self.ActivePrompt:Close(true)
    end
    local Theme = table.clone(self.Theme)
    for Key, Color in Options.Theme or {} do
        Theme[Key] = Color
    end

    local Prompt = { Closed = false, Submitting = false, Options = Options }
    local IsTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    local ScreenGui = self:Create("ScreenGui", {
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
    })
    Prompt.ScreenGui = ScreenGui
    self.ScreenGui = ScreenGui

    -- dimmed backdrop (a button so clicks never fall through to the game)
    local Backdrop = self:Create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = ScreenGui,
    })

    -- fit small viewports (phones) by scaling the card, never by reflowing it
    local Root = self:Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = Backdrop,
    })
    local RootScale = self:Create("UIScale", { Scale = 1, Parent = Root })

    local CardWidth = 360
    local Card = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(CardWidth, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Background,
        Parent = Root,
    })
    self:Corner(Card, 10)
    local CardScale = self:Create("UIScale", { Scale = 0.92, Parent = Card })
    local Shadow = self:Shadow(Card, Options.Glow and Theme.Accent or Color3.new(0, 0, 0), 1, Options.Glow and 36 or 28, Options.Glow and 0 or 6)
    local ShadowTarget = Options.Glow and 0.35 or 0.55
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18),
        PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
        Parent = Card,
    })
    self:Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Card })

    -- header: title + subtitle, like the sidebar brand block
    local Header = self:Create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1, Parent = Card })
    local Title = self:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = Options.Title or "blush.",
        TextSize = 17,
        Weight = "Bold",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })
    self:Create("TextLabel", {
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = Options.Subtitle or "key system",
        TextSize = 12,
        TextColor3 = Theme.DimText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })
    -- accent dot after the title, the same 8px pill the tab badges use
    local Dot = self:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, Title.TextBounds.X + 8, 0, 10),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Accent,
        Parent = Header,
    })
    self:Corner(Dot, 4)
    self:Shadow(Dot, Theme.Accent, 0.5, 8, 0)
    self:Connect(Title:GetPropertyChangedSignal("TextBounds"), function()
        Dot.Position = UDim2.new(0, Title.TextBounds.X + 8, 0, 10)
    end)

    -- separator
    self:Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Outline, LayoutOrder = 2, Parent = Card })

    -- status line
    local Status = self:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = Options.Status or "paste your key below, or grab one from the discord.",
        TextColor3 = Theme.DimText,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
        Parent = Card,
    })

    -- key input: element background, accent ring only while focused (no outline at rest)
    local InputBox = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Element,
        LayoutOrder = 4,
        Parent = Card,
    })
    self:Corner(InputBox, 6)
    local Ring = self:Create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 1, Parent = InputBox })
    local Input = self:Create("TextBox", {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = Trim(Options.Key or Options.InitialKey or ""),
        PlaceholderText = Options.Placeholder or "your key...",
        PlaceholderColor3 = Theme.DimText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = InputBox,
    })
    self:Connect(Input.Focused, function()
        self:Tween(Ring, { Transparency = 0.4 }, 0.12)
    end)
    self:Connect(Input.FocusLost, function(Enter)
        self:Tween(Ring, { Transparency = 1 }, 0.12)
        if Enter then
            Prompt:Submit()
        end
    end)

    -- primary: check key (accent, dark text, like the confirm button in blush. prompts)
    local Submit = self:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.Accent,
        Text = Options.SubmitText or "Check key",
        TextColor3 = Theme.Background,
        Weight = "SemiBold",
        LayoutOrder = 5,
        Parent = Card,
    })
    self:Corner(Submit, 6)
    local SubmitGlow = self:Shadow(Submit, Theme.Accent, 0.6, 10, 0)

    -- secondary row: get key | buy premium
    local Row = self:Create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 6, Parent = Card })
    local function Secondary(Text, X)
        local Button = self:Create("TextButton", {
            Position = UDim2.new(X, X > 0 and 4 or 0, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = Theme.Element,
            Text = Text,
            Weight = "Medium",
            Parent = Row,
        })
        self:Corner(Button, 6)
        self:Hover(Button, Theme.Element, Theme.Hover)
        return Button
    end
    local GetKey = Secondary(Options.GetKeyText or "Get key", 0)
    local Premium = Secondary(Options.PremiumText or "Buy premium", 0.5)

    -- footer hint
    self:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = Options.Footer or "your key is saved on this device after it checks out.",
        TextSize = 11,
        TextColor3 = Theme.DimText,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 7,
        Parent = Card,
    })

    -- viewport fit -------------------------------------------------------------
    local function Fit()
        local View = ScreenGui.AbsoluteSize
        if View.X <= 0 then
            return
        end
        local Scale = math.min(1, (View.X - 24) / CardWidth, (View.Y - 24) / math.max(Card.AbsoluteSize.Y / RootScale.Scale, 1))
        RootScale.Scale = math.clamp(Scale, 0.5, 1)
    end
    self:Connect(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), Fit)
    self:Connect(Card:GetPropertyChangedSignal("AbsoluteSize"), Fit)

    -- behaviour ----------------------------------------------------------------
    local StatusColors = { info = Theme.DimText, success = Theme.Success, error = Theme.Risky, accent = Theme.Accent }

    function Prompt:SetStatus(Message, Kind)
        Status.Text = tostring(Message or "")
        KeySystem:Tween(Status, { TextColor3 = StatusColors[Kind or "info"] or Theme.DimText }, 0.15)
    end

    function Prompt:GetKey()
        return Trim(Input.Text)
    end

    function Prompt:SetKey(Key)
        Input.Text = tostring(Key or "")
    end

    function Prompt:SetSubmitting(Value)
        self.Submitting = Value == true
        Submit.Text = self.Submitting and (Options.CheckingText or "Checking...") or (Options.SubmitText or "Check key")
        KeySystem:Tween(Submit, { BackgroundTransparency = self.Submitting and 0.4 or 0 }, 0.15)
        Input.TextEditable = not self.Submitting
    end

    -- wrong key: the input shakes sideways
    local function Shake()
        local Origin = InputBox.Position
        KeySystem:Thread(function()
            for _, Offset in { -6, 6, -4, 4, 0 } do
                InputBox.Position = Origin + UDim2.fromOffset(Offset, 0)
                task.wait(0.04)
            end
            InputBox.Position = Origin
        end)
    end

    function Prompt:Close(Instant)
        if self.Closed then
            return
        end
        self.Closed = true
        if KeySystem.ActivePrompt == self then
            KeySystem.ActivePrompt = nil
        end
        if Instant then
            ScreenGui:Destroy()
            return
        end
        KeySystem:Tween(Backdrop, { BackgroundTransparency = 1 }, 0.18)
        KeySystem:Tween(CardScale, { Scale = 0.94 }, 0.18)
        if Shadow then
            KeySystem:Tween(Shadow, { Transparency = 1 }, 0.18)
        end
        for _, Object in Card:GetDescendants() do
            if Object:IsA("GuiObject") then
                KeySystem:Tween(Object, { BackgroundTransparency = 1 }, 0.18)
                if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
                    KeySystem:Tween(Object, { TextTransparency = 1 }, 0.14)
                end
            end
        end
        KeySystem:Tween(Card, { BackgroundTransparency = 1 }, 0.18).Completed:Wait()
        ScreenGui:Destroy()
    end

    function Prompt:Submit()
        if self.Submitting or self.Closed then
            return
        end
        local Key = self:GetKey()
        if Key == "" then
            self:SetStatus("type or paste a key first.", "error")
            Shake()
            return
        end
        self:SetSubmitting(true)
        self:SetStatus(Options.CheckingStatus or "checking your key...", "accent")
        KeySystem:Thread(function()
            -- OnSubmit(key, setStatus, close, prompt):
            --   return true            -> success animation, close, OnSuccess(key)
            --   return false, message  -> red status + shake
            --   return nothing         -> the handler drove the prompt itself (setStatus / close)
            local Ok, Valid, Message = pcall(function()
                if type(Options.OnSubmit) == "function" then
                    return Options.OnSubmit(Key, function(Text, Kind)
                        self:SetStatus(Text, Kind)
                    end, function()
                        self:Close()
                    end, self)
                end
                return false, "no OnSubmit handler"
            end)
            if self.Closed then
                return
            end
            if not Ok then
                self:SetSubmitting(false)
                self:SetStatus("check failed: " .. tostring(Valid), "error")
                Shake()
                return
            end
            if Valid == nil then
                self:SetSubmitting(false)
                return
            end
            if Valid then
                self:SetStatus(Message or "key accepted, loading...", "success")
                Submit.Text = Options.SuccessText or "Welcome"
                KeySystem:Pop(Submit)
                task.wait(0.6)
                self:Close()
                if type(Options.OnSuccess) == "function" then
                    KeySystem:Thread(function()
                        Options.OnSuccess(Key)
                    end)
                end
            else
                self:SetSubmitting(false)
                self:SetStatus(Message or "that key is not valid.", "error")
                Shake()
            end
        end)
    end

    self:Connect(Submit.MouseButton1Click, function()
        self:Pop(Submit)
        Prompt:Submit()
    end)
    self:Connect(GetKey.MouseButton1Click, function()
        self:Pop(GetKey)
        if type(Options.OnGetKey) == "function" then
            return Options.OnGetKey(Prompt)
        end
        local Link = Trim(Options.Discord or "")
        if Link == "" then
            return Prompt:SetStatus("no key link configured.", "error")
        end
        if self:Copy(Link) then
            Prompt:SetStatus("discord invite copied. get your key there, then paste it here.", "accent")
        else
            Prompt:SetStatus("get your key at " .. Link, "accent")
        end
    end)
    self:Connect(Premium.MouseButton1Click, function()
        self:Pop(Premium)
        if type(Options.OnPremium) == "function" then
            return Options.OnPremium(Prompt)
        end
        local Link = Trim(Options.Premium or "")
        if Link == "" then
            return Prompt:SetStatus("no store link configured.", "error")
        end
        if self:Copy(Link) then
            Prompt:SetStatus("store link copied. premium keys skip the key system entirely.", "accent")
        else
            Prompt:SetStatus("buy premium at " .. Link, "accent")
        end
    end)

    -- show ---------------------------------------------------------------------
    ScreenGui.Parent = gethui()
    self.ActivePrompt = Prompt
    Fit()
    Card.BackgroundTransparency = 1
    task.defer(function()
        Cap()
        self:Tween(Backdrop, { BackgroundTransparency = 0.45 }, 0.2)
        self:Tween(Card, { BackgroundTransparency = 0 }, 0.2)
        self:Tween(CardScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Quint)
        if Shadow then
            self:Tween(Shadow, { Transparency = ShadowTarget }, 0.25)
        end
        if not IsTouch then
            task.wait(0.25)
            if not Prompt.Closed then
                Input:CaptureFocus()
            end
        end
    end)

    return Prompt
end
--#endregion

function KeySystem:Unload()
    if self.ActivePrompt then
        pcall(self.ActivePrompt.Close, self.ActivePrompt, true)
    end
    for _, Connection in self.Signals do
        pcall(Connection.Disconnect, Connection)
    end
    self.Signals = {}
    if self.ScreenGui then
        pcall(self.ScreenGui.Destroy, self.ScreenGui)
    end
end

SharedEnv.blushkey = KeySystem
return KeySystem
