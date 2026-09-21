-- ==========================================
-- DSHubLibrary - Módulo UI Completo (Hub.lua)
-- Borda Fina: 0.8px | Cantos Protegidos
-- ==========================================

local DSHubLibrary = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local THEME = {
    Background = Color3.fromRGB(0, 0, 0),
    TopBar     = Color3.fromRGB(5, 5, 5),
    Sidebar    = Color3.fromRGB(3, 3, 3),
    Card       = Color3.fromRGB(10, 10, 10),
    CardBorder = Color3.fromRGB(20, 30, 20),
    Accent     = Color3.fromRGB(0, 255, 100),
    Text       = Color3.fromRGB(255, 255, 255),
    SubText    = Color3.fromRGB(150, 160, 150),
    ToggleOff  = Color3.fromRGB(20, 20, 20),
    Separator  = Color3.fromRGB(15, 15, 15)
}

local function createTween(instance, duration, properties, style, direction)
    return TweenService:Create(instance, TweenInfo.new(
        duration, 
        style or Enum.EasingStyle.Quad, 
        direction or Enum.EasingDirection.Out
    ), properties)
end

local function addCorner(parent, radius)
    local corner = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", parent)
    corner.CornerRadius = UDim.new(0, radius or 12)
    return corner
end

local function createLabel(parent, size, pos, text, color, font, textSize, align)
    local label = Instance.new("TextLabel", parent)
    label.Size = size
    label.Position = pos
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or THEME.Text
    label.Font = font or Enum.Font.GothamBold
    label.TextSize = textSize or 10
    if align then label.TextXAlignment = align end
    return label
end

function DSHubLibrary.Init(options)
    options = options or {}
    local hubName = options.Name or "DS HUB"
    local versionText = options.Version or "v1.0"
    local configFile = options.ConfigFile or "DSHub_Config_v1_0.json"
    local onCloseCallback = options.OnClose

    local canWrite = typeof(writefile) == "function"
    local canRead = typeof(readfile) == "function"
    local canCheck = typeof(isfile) == "function"

    local function SaveSavedData(data)
        if canWrite then
            pcall(function()
                writefile(configFile, HttpService:JSONEncode(data))
            end)
        end
    end

    local function LoadSavedData()
        if canRead and canCheck then
            local success, result = pcall(function()
                if isfile(configFile) then
                    return HttpService:JSONDecode(readfile(configFile))
                end
            end)
            if success and type(result) == "table" then return result end
        end
        return nil
    end

    local savedData = LoadSavedData() or {
        NormalPosX = 0, NormalPosY = 0, NormalScaleX = 0.5, NormalScaleY = 0.5,
        MinPosX = 0, MinPosY = 0, MinScaleX = 0.5, MinScaleY = 0.5,
        Toggles = {}
    }

    local ParentGui = nil
    if typeof(gethui) == "function" then
        ParentGui = gethui()
    else
        local success, core = pcall(function() return game:GetService("CoreGui") end)
        ParentGui = (success and core) and core or LocalPlayer:WaitForChild("PlayerGui")
    end

    local oldUI = ParentGui:FindFirstChild("DSHUB_V1_0") or ParentGui:FindFirstChild("DSHub_UI")
    if oldUI then oldUI:Destroy() end

    local oldBlur = Lighting:FindFirstChild("DSHub_CinematicBlur_v1_0")
    if oldBlur then oldBlur:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DSHUB_V1_0"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = ParentGui

    local MainContainer = Instance.new("Frame", ScreenGui)
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(0, 560, 0, 350)
    MainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    MainContainer.Position = savedData.NormalScaleX and UDim2.new(savedData.NormalScaleX, savedData.NormalPosX, savedData.NormalScaleY, savedData.NormalPosY) or UDim2.new(0.5, 0, 0.5, 0)
    MainContainer.BackgroundTransparency = 1
    MainContainer.Visible = false

    local Main = Instance.new("CanvasGroup", MainContainer)
    Main.Name = "MainFrame"
    Main.Size = UDim2.new(1, 0, 1, 0)
    Main.BackgroundColor3 = THEME.Background
    Main.BorderSizePixel = 0
    addCorner(Main, 12)

    local BorderFrame = Instance.new("Frame", MainContainer)
    BorderFrame.Name = "BorderFrame"
    BorderFrame.Size = UDim2.new(1, 0, 1, 0)
    BorderFrame.BackgroundTransparency = 1
    BorderFrame.ZIndex = 20
    addCorner(BorderFrame, 12)

    local MainStroke = Instance.new("UIStroke", BorderFrame)
    MainStroke.Color = THEME.Accent
    MainStroke.Thickness = 0.8
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local function PlayIntro(onComplete)
        local Blur = Instance.new("BlurEffect", Lighting)
        Blur.Name = "DSHub_CinematicBlur_v1_0"
        Blur.Size = 0

        local IntroOverlay = Instance.new("Frame", ScreenGui)
        IntroOverlay.Size = UDim2.new(1, 0, 1, 0)
        IntroOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        IntroOverlay.BackgroundTransparency = 1
        IntroOverlay.ZIndex = 800

        local ScannerLine = Instance.new("Frame", IntroOverlay)
        ScannerLine.Size = UDim2.new(1, 0, 0, 2)
        ScannerLine.Position = UDim2.new(0, 0, 0, -10)
        ScannerLine.BackgroundColor3 = THEME.Accent
        ScannerLine.BorderSizePixel = 0
        ScannerLine.ZIndex = 801

        local IntroCard = Instance.new("CanvasGroup", IntroOverlay)
        IntroCard.Size = UDim2.new(0, 340, 0, 190)
        IntroCard.AnchorPoint = Vector2.new(0.5, 0.5)
        IntroCard.Position = UDim2.new(0.5, 0, 0.5, 0)
        IntroCard.BackgroundColor3 = THEME.Background
        IntroCard.GroupTransparency = 1
        IntroCard.ZIndex = 802
        addCorner(IntroCard, 16)

        local CardStroke = Instance.new("UIStroke", IntroCard)
        CardStroke.Color = THEME.Accent
        CardStroke.Thickness = 0.8
        CardStroke.Transparency = 1

        local CoreSymbol = Instance.new("Frame", IntroCard)
        CoreSymbol.Size = UDim2.new(0, 48, 0, 48)
        CoreSymbol.AnchorPoint = Vector2.new(0.5, 0.5)
        CoreSymbol.Position = UDim2.new(0.5, 0, 0.32, 0)
        CoreSymbol.BackgroundColor3 = THEME.Card
        CoreSymbol.ZIndex = 803
        addCorner(CoreSymbol, 12)

        local SymbolStroke = Instance.new("UIStroke", CoreSymbol)
        SymbolStroke.Color = THEME.Accent
        SymbolStroke.Thickness = 0.8

        local SymbolText = createLabel(CoreSymbol, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "DS", THEME.Accent, Enum.Font.GothamBold, 18)
        SymbolText.ZIndex = 804

        createLabel(IntroCard, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0.55, 0), hubName, THEME.Text, Enum.Font.GothamBold, 16).ZIndex = 803
        local StatusSub = createLabel(IntroCard, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0.70, 0), "INITIALIZING CORE...", THEME.Accent, Enum.Font.Code, 10)
        StatusSub.ZIndex = 803

        task.spawn(function()
            createTween(Blur, 0.8, {Size = 24}):Play()
            createTween(IntroOverlay, 0.6, {BackgroundTransparency = 0.3}):Play()
            createTween(IntroCard, 0.7, {GroupTransparency = 0}, Enum.EasingStyle.Back):Play()
            createTween(CardStroke, 0.6, {Transparency = 0}):Play()
            createTween(ScannerLine, 1.2, {Position = UDim2.new(0, 0, 1, 10)}):Play()

            task.wait(0.6)
            StatusSub.Text = "LOADING SCRIPT MODULES..."
            task.wait(0.6)
            StatusSub.Text = "CONNECTING TO GAME ENVIRONMENT..."
            task.wait(0.6)
            StatusSub.Text = "INITIALIZING " .. hubName .. "..."
            task.wait(0.6)
            StatusSub.Text = "READY [" .. versionText .. "]"
            
            createTween(CoreSymbol, 0.6, {Rotation = 360}):Play()
            task.wait(0.5)

            createTween(IntroCard, 0.5, {Size = UDim2.new(0, 370, 0, 210), GroupTransparency = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            createTween(IntroOverlay, 0.5, {BackgroundTransparency = 1}):Play()
            createTween(Blur, 0.5, {Size = 0}):Play()

            task.wait(0.5)
            IntroOverlay:Destroy()
            Blur:Destroy()

            if onComplete then onComplete() end
        end)
    end

    local InnerWrapper = Instance.new("Frame", Main)
    InnerWrapper.Size = UDim2.new(1, 0, 1, 0)
    InnerWrapper.BackgroundTransparency = 1
    InnerWrapper.ClipsDescendants = true

    local TopBar = Instance.new("Frame", InnerWrapper)
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = THEME.TopBar
    TopBar.BorderSizePixel = 0
    addCorner(TopBar, 10)

    local TopBarDivider = Instance.new("Frame", TopBar)
    TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
    TopBarDivider.Position = UDim2.new(0, 0, 1, -1)
    TopBarDivider.BackgroundColor3 = THEME.Separator
    TopBarDivider.BorderSizePixel = 0

    local Title = createLabel(TopBar, UDim2.new(0, 240, 1, 0), UDim2.new(0, 12, 0, 0), hubName .. ' <font color="#00FF64">' .. versionText .. '</font>', THEME.Text, Enum.Font.GothamBold, 13, Enum.TextXAlignment.Left)
    Title.RichText = true

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = THEME.SubText
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12

    CloseBtn.MouseButton1Click:Connect(function() 
        if onCloseCallback then onCloseCallback() end
        createTween(MainContainer, 0.25, {Size = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
        task.wait(0.25)
        ScreenGui:Destroy()
    end)

    local isMinimized = false
    local normalSize = UDim2.new(0, 560, 0, 350)
    local compactSize = UDim2.new(0, 190, 0, 38)

    local currentNormalPos = UDim2.new(savedData.NormalScaleX or 0.5, savedData.NormalPosX or 0, savedData.NormalScaleY or 0.5, savedData.NormalPosY or 0)
    local currentMinPos = UDim2.new(savedData.MinScaleX or savedData.NormalScaleX or 0.5, savedData.MinPosX or savedData.NormalPosX or 0, savedData.MinScaleY or savedData.NormalScaleY or 0.5, savedData.MinPosY or savedData.NormalPosY or 0)

    local function SaveCurrentPosition()
        if isMinimized then
            currentMinPos = MainContainer.Position
            savedData.MinPosX, savedData.MinPosY = currentMinPos.X.Offset, currentMinPos.Y.Offset
            savedData.MinScaleX, savedData.MinScaleY = currentMinPos.X.Scale, currentMinPos.Y.Scale
        else
            currentNormalPos = MainContainer.Position
            savedData.NormalPosX, savedData.NormalPosY = currentNormalPos.X.Offset, currentNormalPos.Y.Offset
            savedData.NormalScaleX, savedData.NormalScaleY = currentNormalPos.X.Scale, currentNormalPos.Y.Scale
        end
        SaveSavedData(savedData)
    end

    local function MakeDraggable(gui, handle)
        local dragging, dragStart, startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = gui.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        SaveCurrentPosition()
                        if conn then conn:Disconnect() end
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                
                local camera = workspace.CurrentCamera
                if camera then
                    local viewportSize = camera.ViewportSize
                    local absSize = gui.AbsoluteSize
                    local halfW, halfH = absSize.X / 2, absSize.Y / 2
                    
                    local maxOffsetX = (viewportSize.X / 2) - halfW
                    local minOffsetX = -(viewportSize.X / 2) + halfW
                    local maxOffsetY = (viewportSize.Y / 2) - halfH
                    local minOffsetY = -(viewportSize.Y / 2) + halfH
                    
                    if maxOffsetX < minOffsetX then maxOffsetX, minOffsetX = 0, 0 end
                    if maxOffsetY < minOffsetY then maxOffsetY, minOffsetY = 0, 0 end
                    
                    newX = math.clamp(newX, minOffsetX, maxOffsetX)
                    newY = math.clamp(newY, minOffsetY, maxOffsetY)
                end
                
                gui.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                if isMinimized then currentMinPos = gui.Position else currentNormalPos = gui.Position end
            end
        end)
    end

    local MinimizeBtn = Instance.new("TextButton", TopBar)
    MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    MinimizeBtn.Position = UDim2.new(1, -60, 0.5, -13)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Text = "—"
    MinimizeBtn.TextColor3 = THEME.SubText
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 12

    local Sidebar = Instance.new("Frame", InnerWrapper)
    Sidebar.Size = UDim2.new(0, 130, 1, -38)
    Sidebar.Position = UDim2.new(0, 0, 0, 38)
    Sidebar.BackgroundColor3 = THEME.Sidebar
    Sidebar.BorderSizePixel = 0
    addCorner(Sidebar, 10)

    local SidebarDivider = Instance.new("Frame", Sidebar)
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BackgroundColor3 = THEME.Separator
    SidebarDivider.BorderSizePixel = 0

    local TabHolder = Instance.new("Frame", Sidebar)
    TabHolder.Size = UDim2.new(1, 0, 1, -44)
    TabHolder.BackgroundTransparency = 1

    local TabList = Instance.new("UIListLayout", TabHolder)
    TabList.Padding = UDim.new(0, 5)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local TabPadding = Instance.new("UIPadding", TabHolder)
    TabPadding.PaddingTop = UDim.new(0, 8)

    local ProfileCard = Instance.new("Frame", Sidebar)
    ProfileCard.Size = UDim2.new(0.88, 0, 0, 34)
    ProfileCard.Position = UDim2.new(0.06, 0, 1, -38)
    ProfileCard.BackgroundColor3 = THEME.Card
    ProfileCard.BorderSizePixel = 0
    addCorner(ProfileCard, 8)

    local ProfileCardStroke = Instance.new("UIStroke", ProfileCard)
    ProfileCardStroke.Color = THEME.CardBorder
    ProfileCardStroke.Thickness = 0.8

    local ProfileAvatar = Instance.new("ImageLabel", ProfileCard)
    ProfileAvatar.Size = UDim2.new(0, 24, 0, 24)
    ProfileAvatar.Position = UDim2.new(0, 5, 0.5, -12)
    ProfileAvatar.BackgroundTransparency = 1
    pcall(function()
        ProfileAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    addCorner(ProfileAvatar, 12)

    createLabel(ProfileCard, UDim2.new(1, -34, 0, 12), UDim2.new(0, 32, 0, 4), LocalPlayer.DisplayName, THEME.Text, Enum.Font.GothamBold, 9, Enum.TextXAlignment.Left)
    local ProfileStatus = createLabel(ProfileCard, UDim2.new(1, -34, 0, 10), UDim2.new(0, 32, 0, 18), "60 FPS • 30ms", THEME.Accent, Enum.Font.GothamMedium, 8, Enum.TextXAlignment.Left)

    task.spawn(function()
        local lastTime = os.clock()
        local frameCount = 0
        RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local currentTime = os.clock()
            if currentTime - lastTime >= 1 then
                local fps = math.floor(frameCount / (currentTime - lastTime))
                local ping = 0
                pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
                ProfileStatus.Text = string.format("%d FPS • %dms", fps, ping)
                frameCount = 0
                lastTime = currentTime
            end
        end)
    end)

    local ContentContainer = Instance.new("Frame", InnerWrapper)
    ContentContainer.Size = UDim2.new(1, -140, 1, -44)
    ContentContainer.Position = UDim2.new(0, 135, 0, 42)
    ContentContainer.BackgroundTransparency = 1

    MakeDraggable(MainContainer, TopBar)

    MinimizeBtn.MouseButton1Click:Connect(function()
        SaveCurrentPosition()
        isMinimized = not isMinimized

        local targetSize = isMinimized and compactSize or normalSize
        local targetPos = isMinimized and currentMinPos or currentNormalPos

        if isMinimized then
            Sidebar.Visible = false
            ContentContainer.Visible = false
            TopBarDivider.Visible = false
            Title.Size = UDim2.new(0, 95, 1, 0)
            MainContainer.Position = targetPos
            createTween(MainContainer, 0.25, {Size = compactSize}, Enum.EasingStyle.Quart):Play()
            MinimizeBtn.Text = "+"
        else
            Title.Size = UDim2.new(0, 240, 1, 0)
            TopBarDivider.Visible = true
            MainContainer.Position = targetPos
            createTween(MainContainer, 0.25, {Size = normalSize}, Enum.EasingStyle.Quart):Play()
            task.wait(0.12)
            Sidebar.Visible = true
            ContentContainer.Visible = true
            MinimizeBtn.Text = "—"
        end
        SaveCurrentPosition()
    end)

    local Window = { Tabs = {} }

    function Window:CreateTab(tabName, iconText)
        local TabBtn = Instance.new("TextButton", TabHolder)
        TabBtn.Size = UDim2.new(0.92, 0, 0, 32)
        TabBtn.BackgroundColor3 = THEME.Card
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        addCorner(TabBtn, 8)

        local IconLabel = createLabel(TabBtn, UDim2.new(0, 20, 1, 0), UDim2.new(0, 6, 0, 0), iconText or "⚡", THEME.SubText, Enum.Font.GothamBold, 12)
        local TextLabel = createLabel(TabBtn, UDim2.new(1, -28, 1, 0), UDim2.new(0, 28, 0, 0), tabName, THEME.SubText, Enum.Font.GothamMedium, 10, Enum.TextXAlignment.Left)

        local Page = Instance.new("ScrollingFrame", ContentContainer)
        Page.Size = UDim2.new(1, -4, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = THEME.Accent
        Page.BorderSizePixel = 0
        Page.ClipsDescendants = true
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0, 6)

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 8)
        end)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                createTween(t.Btn, 0.15, {BackgroundTransparency = 1}):Play()
                createTween(t.Text, 0.15, {TextColor3 = THEME.SubText}):Play()
                createTween(t.Icon, 0.15, {TextColor3 = THEME.SubText}):Play()
            end
            Page.Visible = true
            createTween(TabBtn, 0.15, {BackgroundTransparency = 0.8}):Play()
            createTween(TextLabel, 0.15, {TextColor3 = THEME.Text}):Play()
            createTween(IconLabel, 0.15, {TextColor3 = THEME.Accent}):Play()
        end)

        if #Window.Tabs == 0 then
            Page.Visible = true
            TabBtn.BackgroundTransparency = 0.8
            TextLabel.TextColor3 = THEME.Text
            IconLabel.TextColor3 = THEME.Accent
        end

        local TabElements = {Page = Page, Btn = TabBtn, Text = TextLabel, Icon = IconLabel}

        function TabElements:CreateToggle(title, defaultState, callback)
            if savedData.Toggles[title] ~= nil then
                defaultState = savedData.Toggles[title]
            else
                savedData.Toggles[title] = defaultState
                SaveSavedData(savedData)
            end

            local state = defaultState or false
            local ToggleCard = Instance.new("Frame", Page)
            ToggleCard.Size = UDim2.new(0.98, 0, 0, 36)
            ToggleCard.BackgroundColor3 = THEME.Card
            addCorner(ToggleCard, 8)

            local ToggleStroke = Instance.new("UIStroke", ToggleCard)
            ToggleStroke.Color = THEME.CardBorder
            ToggleStroke.Thickness = 0.8

            createLabel(ToggleCard, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 10, 0, 0), title, THEME.Text, Enum.Font.GothamMedium, 10, Enum.TextXAlignment.Left)

            local Switch = Instance.new("Frame", ToggleCard)
            Switch.Size = UDim2.new(0, 34, 0, 18)
            Switch.Position = UDim2.new(1, -40, 0.5, -9)
            Switch.BackgroundColor3 = state and THEME.Accent or THEME.ToggleOff
            addCorner(Switch, 9)

            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, 14, 0, 14)
            Circle.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            addCorner(Circle, 7)

            local Btn = Instance.new("TextButton", ToggleCard)
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.Text = ""

            if state and callback then task.spawn(function() callback(state) end) end

            Btn.MouseButton1Click:Connect(function()
                state = not state
                savedData.Toggles[title] = state
                SaveSavedData(savedData)

                createTween(Switch, 0.15, {BackgroundColor3 = state and THEME.Accent or THEME.ToggleOff}):Play()
                createTween(Circle, 0.15, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                if callback then callback(state) end
            end)
        end

        table.insert(Window.Tabs, TabElements)
        return TabElements
    end

    PlayIntro(function()
        MainContainer.Visible = true
    end)

    -- DS HUB v1.0 public runtime / compatibility layer.
    -- The library owns the window/tabs; feature controls are built here.
    local runtime = Window
    runtime.Library = DSHubLibrary
    runtime.ScreenGui = ScreenGui
    runtime.Options = {}
    runtime.Toggles = {}
    runtime.IsMobile = UserInputService.TouchEnabled
    runtime.Unloaded = false
    runtime._unloadCallbacks = {}

    -- ------------------------------------------------------------
    -- Notifications: compact DS HUB toast, no giant black rectangle.
    -- ------------------------------------------------------------
    local notifyHolder = Instance.new("Frame", ScreenGui)
    notifyHolder.Name = "DSHubNotifications"
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.AnchorPoint = Vector2.new(1, 0)
    notifyHolder.Position = UDim2.new(1, -14, 0, 48)
    notifyHolder.Size = UDim2.new(0, 300, 1, -62)
    notifyHolder.ZIndex = 2000

    local notifyLayout = Instance.new("UIListLayout", notifyHolder)
    notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    notifyLayout.Padding = UDim.new(0, 7)

    function runtime:Notify(info)
        info = info or {}

        local toast = Instance.new("Frame", notifyHolder)
        toast.Size = UDim2.new(1, 0, 0, 64)
        toast.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        toast.BackgroundTransparency = 0.03
        toast.BorderSizePixel = 0
        toast.ZIndex = 2001
        addCorner(toast, 10)

        local stroke = Instance.new("UIStroke", toast)
        stroke.Color = THEME.Accent
        stroke.Thickness = 1

        local title = createLabel(
            toast,
            UDim2.new(1, -20, 0, 17),
            UDim2.new(0, 10, 0, 7),
            tostring(info.Title or "DS HUB"),
            THEME.Accent,
            Enum.Font.GothamBold,
            10,
            Enum.TextXAlignment.Left
        )
        title.ZIndex = 2002

        local description = createLabel(
            toast,
            UDim2.new(1, -20, 0, 32),
            UDim2.new(0, 10, 0, 27),
            tostring(info.Description or ""),
            THEME.Text,
            Enum.Font.Gotham,
            9,
            Enum.TextXAlignment.Left
        )
        description.TextWrapped = true
        description.ZIndex = 2002

        task.delay(tonumber(info.Time) or 4, function()
            if toast.Parent then
                createTween(
                    toast,
                    0.18,
                    {BackgroundTransparency = 1}
                ):Play()

                task.wait(0.18)

                if toast.Parent then
                    toast:Destroy()
                end
            end
        end)

        return toast
    end

    -- ------------------------------------------------------------
    -- Option registry.
    -- ------------------------------------------------------------
    local function clone(value)
        if type(value) ~= "table" then
            return value
        end

        local result = {}

        for key, item in pairs(value) do
            result[key] = item
        end

        return result
    end

    local function registerOption(id, defaultValue, kind, callback, metadata)
        local option = {
            Id = id,
            Default = clone(defaultValue),
            Value = clone(defaultValue),
            Kind = kind,
            Callback = callback,
            Meta = metadata or {},
        }

        function option:SetValue(value)
            self.Value = clone(value)

            if self._update then
                pcall(self._update, self.Value)
            end

            if self.Callback then
                pcall(self.Callback, self.Value)
            end
        end

        function option:SetValues(values)
            self.Values = values or {}

            if self._refreshValues then
                pcall(self._refreshValues)
            end
        end

        runtime.Options[id] = option

        if kind == "toggle" then
            runtime.Toggles[id] = option
        end

        return option
    end

    -- ------------------------------------------------------------
    -- Stable group box.
    -- Avoid AutomaticSize feedback loops that produced the huge
    -- empty rectangles seen in the previous version.
    -- ------------------------------------------------------------
    local function createGroup(parent, title)
        local group = Instance.new("Frame", parent)
        group.Name = "DSHubGroup"
        group.Size = UDim2.new(1, -4, 0, 46)
        group.BackgroundColor3 = THEME.Card
        group.BorderSizePixel = 0
        group.ClipsDescendants = false
        group.ZIndex = 10
        addCorner(group, 10)

        local stroke = Instance.new("UIStroke", group)
        stroke.Color = THEME.CardBorder
        stroke.Thickness = 0.8

        local header = createLabel(
            group,
            UDim2.new(1, -18, 0, 20),
            UDim2.new(0, 9, 0, 6),
            tostring(title or "Section"),
            THEME.Accent,
            Enum.Font.GothamBold,
            10,
            Enum.TextXAlignment.Left
        )
        header.ZIndex = 11

        local content = Instance.new("Frame", group)
        content.Name = "Content"
        content.Position = UDim2.new(0, 9, 0, 29)
        content.Size = UDim2.new(1, -18, 0, 1)
        content.BackgroundTransparency = 1
        content.ClipsDescendants = false
        content.ZIndex = 11

        local layout = Instance.new("UIListLayout", content)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 5)

        local padding = Instance.new("UIPadding", content)
        padding.PaddingBottom = UDim.new(0, 9)

        local function resize()
            local contentHeight = layout.AbsoluteContentSize.Y + 9
            content.Size = UDim2.new(1, -18, 0, math.max(contentHeight, 1))
            group.Size = UDim2.new(1, -4, 0, 36 + contentHeight)
        end

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
        task.defer(resize)

        return group, content
    end

    local function createControls(parent, title)
        local _, content = createGroup(parent, title)

        local api = {
            _content = content,
        }

        function api:RefreshSides()
            if self._refreshLayout then
                pcall(self._refreshLayout)
            end
        end

        function api:AddLabel(text)
            local label = createLabel(
                content,
                UDim2.new(1, 0, 0, 20),
                UDim2.new(),
                tostring(text or ""),
                THEME.SubText,
                Enum.Font.Gotham,
                9,
                Enum.TextXAlignment.Left
            )
            label.TextWrapped = true

            function label:SetText(value)
                self.Text = tostring(value or "")
            end

            function label:AddKeyPicker()
                return self
            end

            function label:AddColorPicker()
                return self
            end

            return label
        end

        function api:AddDivider()
            local divider = Instance.new("Frame", content)
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.BackgroundColor3 = THEME.Separator
            divider.BorderSizePixel = 0
            divider.ZIndex = 12
            return divider
        end

        function api:AddButton(buttonInfo, callback)
            local info = type(buttonInfo) == "table" and buttonInfo or nil
            local text = info and (info.Text or info.Name) or buttonInfo
            local action = callback
                or (info and (info.Func or info.Callback or info.Action))

            local button = Instance.new("TextButton", content)
            button.Size = UDim2.new(1, 0, 0, 30)
            button.BackgroundColor3 = THEME.ToggleOff
            button.BorderSizePixel = 0
            button.Text = tostring(text or "Button")
            button.TextColor3 = THEME.Text
            button.Font = Enum.Font.GothamMedium
            button.TextSize = 9
            button.AutoButtonColor = false
            button.ZIndex = 12
            addCorner(button, 8)

            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = Color3.fromRGB(18, 30, 18)
            end)

            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = THEME.ToggleOff
            end)

            button.MouseButton1Click:Connect(function()
                if type(action) == "function" then
                    task.spawn(function()
                        pcall(action)
                    end)
                end
            end)

            return button
        end

        function api:AddToggle(id, info)
            info = info or {}

            local option = registerOption(
                id,
                info.Default == true,
                "toggle",
                info.Callback,
                info
            )

            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundTransparency = 1
            row.ZIndex = 12

            local label = createLabel(
                row,
                UDim2.new(1, -54, 1, 0),
                UDim2.new(),
                tostring(info.Text or id),
                THEME.Text,
                Enum.Font.GothamMedium,
                9,
                Enum.TextXAlignment.Left
            )
            label.ZIndex = 13

            local switch = Instance.new("Frame", row)
            switch.Size = UDim2.new(0, 34, 0, 18)
            switch.Position = UDim2.new(1, -34, 0.5, -9)
            switch.BackgroundColor3 = option.Value and THEME.Accent or THEME.ToggleOff
            switch.BorderSizePixel = 0
            switch.ZIndex = 13
            addCorner(switch, 9)

            local circle = Instance.new("Frame", switch)
            circle.Size = UDim2.new(0, 14, 0, 14)
            circle.Position = option.Value
                and UDim2.new(1, -16, 0.5, -7)
                or UDim2.new(0, 2, 0.5, -7)
            circle.BackgroundColor3 = Color3.new(1, 1, 1)
            circle.BorderSizePixel = 0
            circle.ZIndex = 14
            addCorner(circle, 7)

            local click = Instance.new("TextButton", row)
            click.Size = UDim2.new(1, 0, 1, 0)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.ZIndex = 15

            option._update = function(value)
                switch.BackgroundColor3 = value
                    and THEME.Accent
                    or THEME.ToggleOff

                circle.Position = value
                    and UDim2.new(1, -16, 0.5, -7)
                    or UDim2.new(0, 2, 0.5, -7)
            end

            click.MouseButton1Click:Connect(function()
                option:SetValue(not option.Value)
            end)

            function option:AddColorPicker(colorId, colorInfo)
                colorInfo = colorInfo or {}

                local colorOption = registerOption(
                    colorId,
                    colorInfo.Default or Color3.fromRGB(0, 255, 100),
                    "color",
                    colorInfo.Callback,
                    colorInfo
                )

                self.ColorPicker = colorOption
                return self
            end

            function option:AddKeyPicker(keyId, keyInfo)
                self.KeyPicker = {
                    Id = keyId,
                    Default = keyInfo and keyInfo.Default,
                    Text = keyInfo and keyInfo.Text,
                    SyncToggleState = keyInfo and keyInfo.SyncToggleState,
                    Mode = keyInfo and keyInfo.Mode,
                }

                return self
            end

            if option.Value and option.Callback then
                task.defer(option.Callback, option.Value)
            end

            return option
        end

        function api:AddSlider(id, info)
            info = info or {}

            local minimum = tonumber(info.Min) or 0
            local maximum = tonumber(info.Max) or 100
            local default = tonumber(info.Default) or minimum

            local option = registerOption(
                id,
                default,
                "slider",
                info.Callback,
                info
            )

            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 42)
            row.BackgroundTransparency = 1
            row.ZIndex = 12

            local nameLabel = createLabel(
                row,
                UDim2.new(0.68, 0, 0, 16),
                UDim2.new(),
                tostring(info.Text or id),
                THEME.Text,
                Enum.Font.GothamMedium,
                9,
                Enum.TextXAlignment.Left
            )
            nameLabel.ZIndex = 13

            local valueLabel = createLabel(
                row,
                UDim2.new(0.32, 0, 0, 16),
                UDim2.new(0.68, 0, 0, 0),
                tostring(default) .. tostring(info.Suffix or ""),
                THEME.Accent,
                Enum.Font.GothamBold,
                9,
                Enum.TextXAlignment.Right
            )
            valueLabel.ZIndex = 13

            local bar = Instance.new("Frame", row)
            bar.Position = UDim2.new(0, 0, 0, 25)
            bar.Size = UDim2.new(1, 0, 0, 8)
            bar.BackgroundColor3 = THEME.ToggleOff
            bar.BorderSizePixel = 0
            bar.ZIndex = 13
            addCorner(bar, 4)

            local fill = Instance.new("Frame", bar)
            fill.BackgroundColor3 = THEME.Accent
            fill.BorderSizePixel = 0
            fill.ZIndex = 14
            addCorner(fill, 4)

            local dragging = false

            local function setFromX(x)
                local alpha = math.clamp(
                    (x - bar.AbsolutePosition.X)
                    / math.max(bar.AbsoluteSize.X, 1),
                    0,
                    1
                )

                local value = minimum + (maximum - minimum) * alpha
                local rounding = tonumber(info.Rounding)

                if rounding then
                    local factor = 10 ^ rounding
                    value = math.floor(value * factor + 0.5) / factor
                end

                option:SetValue(value)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging
                    and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    )
                then
                    setFromX(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    dragging = false
                end
            end)

            option._update = function(value)
                local alpha = math.clamp(
                    (tonumber(value) - minimum)
                    / math.max(maximum - minimum, 1),
                    0,
                    1
                )

                fill.Size = UDim2.new(alpha, 0, 1, 0)
                valueLabel.Text = tostring(value) .. tostring(info.Suffix or "")
            end

            option._update(default)

            return option
        end

        function api:AddDropdown(id, info)
            info = info or {}

            local values = info.Values or {}
            local multi = info.Multi == true
            local default = info.Default

            local defaultValue

            if multi then
                defaultValue = type(default) == "table" and clone(default) or {}
            elseif type(default) == "number" then
                defaultValue = values[default] or values[1] or "None"
            else
                defaultValue = default or values[1] or "None"
            end

            local option = registerOption(
                id,
                defaultValue,
                "dropdown",
                info.Callback,
                info
            )

            option.Values = values

            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 36)
            row.BackgroundTransparency = 1
            row.ZIndex = 12

            local nameLabel = createLabel(
                row,
                UDim2.new(0.38, 0, 1, 0),
                UDim2.new(),
                tostring(info.Text or id),
                THEME.Text,
                Enum.Font.GothamMedium,
                9,
                Enum.TextXAlignment.Left
            )
            nameLabel.ZIndex = 13

            local button = Instance.new("TextButton", row)
            button.Position = UDim2.new(0.38, 0, 0.5, -13)
            button.Size = UDim2.new(0.62, 0, 0, 26)
            button.BackgroundColor3 = THEME.ToggleOff
            button.BorderSizePixel = 0
            button.TextColor3 = THEME.Text
            button.Font = Enum.Font.Gotham
            button.TextSize = 8
            button.AutoButtonColor = false
            button.ZIndex = 20
            addCorner(button, 7)

            local popup = Instance.new("Frame", row)
            popup.Visible = false
            popup.Position = UDim2.new(0.38, 0, 1, 2)
            popup.Size = UDim2.new(0.62, 0, 0, 150)
            popup.BackgroundColor3 = THEME.Background
            popup.BorderSizePixel = 0
            popup.ZIndex = 1000
            popup.ClipsDescendants = true
            addCorner(popup, 8)

            local popupStroke = Instance.new("UIStroke", popup)
            popupStroke.Color = THEME.Accent
            popupStroke.Thickness = 1

            local scroll = Instance.new("ScrollingFrame", popup)
            scroll.Size = UDim2.new(1, -6, 1, -6)
            scroll.Position = UDim2.new(0, 3, 0, 3)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = THEME.Accent
            scroll.ZIndex = 1001

            local list = Instance.new("UIListLayout", scroll)
            list.Padding = UDim.new(0, 3)

            local function displayValue(value)
                if multi then
                    local count = 0

                    for _, selected in pairs(value or {}) do
                        if selected then
                            count += 1
                        end
                    end

                    return count == 0 and "None" or (tostring(count) .. " selected")
                end

                return tostring(value or "None")
            end

            local function rebuild()
                for _, child in ipairs(scroll:GetChildren()) do
                    if not child:IsA("UIListLayout") then
                        child:Destroy()
                    end
                end

                for _, value in ipairs(option.Values or {}) do
                    local item = Instance.new("TextButton", scroll)
                    item.Size = UDim2.new(1, 0, 0, 26)
                    item.BackgroundColor3 = THEME.Card
                    item.BorderSizePixel = 0
                    item.TextColor3 = THEME.Text
                    item.Font = Enum.Font.Gotham
                    item.TextSize = 8
                    item.Text = tostring(value)
                    item.ZIndex = 1002
                    item.AutoButtonColor = false
                    addCorner(item, 6)

                    item.MouseEnter:Connect(function()
                        item.BackgroundColor3 = Color3.fromRGB(15, 32, 15)
                    end)

                    item.MouseLeave:Connect(function()
                        item.BackgroundColor3 = THEME.Card
                    end)

                    item.MouseButton1Click:Connect(function()
                        if multi then
                            local selected = clone(option.Value or {})

                            if selected[value] then
                                selected[value] = nil
                            else
                                selected[value] = true
                            end

                            option:SetValue(selected)
                        else
                            option:SetValue(value)
                            popup.Visible = false
                        end
                    end)
                end

                scroll.CanvasSize = UDim2.new(
                    0,
                    0,
                    0,
                    list.AbsoluteContentSize.Y + 6
                )

                button.Text = displayValue(option.Value)
            end

            option._update = function(value)
                button.Text = displayValue(value)
            end

            option._refreshValues = rebuild
            option:SetValues(values)

            button.MouseButton1Click:Connect(function()
                popup.Visible = not popup.Visible
            end)

            return option
        end

        function api:AddInput(id, info)
            info = info or {}

            local option = registerOption(
                id,
                tostring(info.Default or ""),
                "input",
                info.Callback,
                info
            )

            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 54)
            row.BackgroundTransparency = 1
            row.ZIndex = 12

            local label = createLabel(
                row,
                UDim2.new(1, 0, 0, 16),
                UDim2.new(),
                tostring(info.Text or id),
                THEME.Text,
                Enum.Font.GothamMedium,
                9,
                Enum.TextXAlignment.Left
            )
            label.ZIndex = 13

            local input = Instance.new("TextBox", row)
            input.Size = UDim2.new(1, 0, 0, 30)
            input.Position = UDim2.new(0, 0, 0, 20)
            input.BackgroundColor3 = THEME.ToggleOff
            input.BorderSizePixel = 0
            input.TextColor3 = THEME.Text
            input.PlaceholderColor3 = THEME.SubText
            input.Font = Enum.Font.Gotham
            input.TextSize = 8
            input.Text = tostring(option.Value)
            input.PlaceholderText = tostring(info.Placeholder or "")
            input.ZIndex = 13
            addCorner(input, 7)

            input.FocusLost:Connect(function()
                option:SetValue(input.Text)
            end)

            option._update = function(value)
                if not input:IsFocused() then
                    input.Text = tostring(value)
                end
            end

            return option
        end

        function api:AddLeftGroupbox(groupTitle)
            return createControls(parent, groupTitle)
        end

        function api:AddRightGroupbox(groupTitle)
            return createControls(parent, groupTitle)
        end

        function api:AddLeftTabbox()
            local wrapper = {}

            function wrapper:AddTab(tabTitle)
                return createControls(parent, tabTitle)
            end

            return wrapper
        end

        function api:AddRightTabbox()
            return self:AddLeftTabbox()
        end

        return api
    end

    -- Attach the advanced API to direct Window:CreateTab results.
    local originalCreateTab = runtime.CreateTab

    local function attachTab(tab)
        function tab:AddLeftGroupbox(title)
            return createControls(tab.Page, title)
        end

        function tab:AddRightGroupbox(title)
            return createControls(tab.Page, title)
        end

        function tab:AddLeftTabbox()
            local wrapper = {}

            function wrapper:AddTab(title)
                return createControls(tab.Page, title)
            end

            return wrapper
        end

        function tab:AddRightTabbox()
            return tab:AddLeftTabbox()
        end

        return tab
    end

    runtime.CreateTab = function(self, tabName, iconText)
        return attachTab(originalCreateTab(self, tabName, iconText))
    end

    for _, tab in ipairs(Window.Tabs) do
        attachTab(tab)
    end

    runtime.AddTab = runtime.CreateTab

    function runtime:OnUnload(callback)
        if type(callback) == "function" then
            table.insert(self._unloadCallbacks, callback)
        end
    end

    function runtime:Unload()
        if self.Unloaded then
            return
        end

        self.Unloaded = true

        for _, callback in ipairs(self._unloadCallbacks) do
            pcall(callback)
        end

        if self.ScreenGui and self.ScreenGui.Parent then
            self.ScreenGui:Destroy()
        end
    end

    local closing = false
    CloseBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        runtime:Unload()
    end)
    PlayIntro(function() MainContainer.Visible=true end)
    return runtime
end


-- ============================================================

return DSHubLibrary
