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
    MainContainer.Size = UDim2.new(0, 400, 0, 250)
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
    local normalSize = UDim2.new(0, 400, 0, 250)
    local compactSize = UDim2.new(0, 170, 0, 38)

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
    Sidebar.Size = UDim2.new(0, 112, 1, -38)
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
    ContentContainer.Size = UDim2.new(1, -122, 1, -44)
    ContentContainer.Position = UDim2.new(0, 117, 0, 42)
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

    -- DS HUB v1.0 public runtime.
    -- Init() returns this Window object directly.
    local runtime=Window
    runtime.Library=DSHubLibrary
    runtime.ScreenGui=ScreenGui
    runtime.Options={}
    runtime.Toggles={}
    runtime.IsMobile=UserInputService.TouchEnabled
    runtime.Unloaded=false
    runtime._unloadCallbacks={}

        -- Notificações desativadas. A API permanece para compatibilidade.
    function runtime:Notify(_)
        return false
    end

    local function clone(v) if type(v)~='table' then return v end local t={} for k,x in pairs(v) do t[k]=x end return t end
    local function reg(id,default,kind,cb,meta)
        local o={Default=clone(default),Value=clone(default),Kind=kind,Callback=cb,Meta=meta or {}}
        function o:SetValue(v) self.Value=clone(v); if self._update then pcall(self._update,self.Value) end; if self.Callback then pcall(self.Callback,self.Value) end end
        function o:SetValues(v) self.Values=v or {}; if self._refresh then pcall(self._refresh) end end
        runtime.Options[id]=o; if kind=='toggle' then runtime.Toggles[id]=o end
        return o
    end

    local function box(parent,title)
        local f=Instance.new('Frame',parent); f.Size=UDim2.new(1,-4,0,40); f.AutomaticSize=Enum.AutomaticSize.Y; f.BackgroundColor3=THEME.Card; f.BorderSizePixel=0; addCorner(f,9)
        local st=Instance.new('UIStroke',f); st.Color=THEME.CardBorder; st.Thickness=.8
        createLabel(f,UDim2.new(1,-16,0,18),UDim2.new(0,8,0,5),tostring(title or 'Section'),THEME.Accent,Enum.Font.GothamBold,10,Enum.TextXAlignment.Left)
        local c=Instance.new('Frame',f); c.Position=UDim2.new(0,8,0,26); c.Size=UDim2.new(1,-16,0,10); c.AutomaticSize=Enum.AutomaticSize.Y; c.BackgroundTransparency=1
        local l=Instance.new('UIListLayout',c); l.Padding=UDim.new(0,5)
        local p=Instance.new('UIPadding',c); p.PaddingBottom=UDim.new(0,8)
        return f,c
    end

    local function controls(parent,title)
        local _,c=box(parent,title); local api={Sides={{Size=UDim2.new(1,0,1,0)},{Visible=true}}}
        function api:RefreshSides() end
        function api:AddLabel(t)
            local l=createLabel(c,UDim2.new(1,0,0,20),UDim2.new(),tostring(t or ''),THEME.SubText,Enum.Font.Gotham,9,Enum.TextXAlignment.Left); l.TextWrapped=true
            return {AddKeyPicker=function(self)return self end,AddColorPicker=function(self)return self end}
        end
        function api:AddDivider() local d=Instance.new('Frame',c); d.Size=UDim2.new(1,0,0,1); d.BackgroundColor3=THEME.Separator; d.BorderSizePixel=0; return d end
        function api:AddButton(t,cb)
            local text=type(t)=='table' and (t.Text or t.Name) or t; local b=Instance.new('TextButton',c); b.Size=UDim2.new(1,0,0,29); b.BackgroundColor3=THEME.ToggleOff; b.BorderSizePixel=0; b.Text=tostring(text or 'Button'); b.TextColor3=THEME.Text; b.Font=Enum.Font.GothamMedium; b.TextSize=9; addCorner(b,7); b.MouseButton1Click:Connect(function() if cb then task.spawn(cb) end end); return b
        end
        function api:AddToggle(id,info)
            info=info or {}; local o=reg(id,info.Default==true,'toggle',info.Callback,info); local row=Instance.new('Frame',c); row.Size=UDim2.new(1,0,0,32); row.BackgroundTransparency=1
            createLabel(row,UDim2.new(1,-48,1,0),UDim2.new(),tostring(info.Text or id),THEME.Text,Enum.Font.GothamMedium,9,Enum.TextXAlignment.Left)
            local sw=Instance.new('Frame',row); sw.Size=UDim2.new(0,34,0,18); sw.Position=UDim2.new(1,-34,.5,-9); sw.BackgroundColor3=o.Value and THEME.Accent or THEME.ToggleOff; sw.BorderSizePixel=0; addCorner(sw,9)
            local ci=Instance.new('Frame',sw); ci.Size=UDim2.new(0,14,0,14); ci.Position=o.Value and UDim2.new(1,-16,.5,-7) or UDim2.new(0,2,.5,-7); ci.BackgroundColor3=Color3.new(1,1,1); ci.BorderSizePixel=0; addCorner(ci,7)
            local bt=Instance.new('TextButton',row); bt.Size=UDim2.new(1,0,1,0); bt.BackgroundTransparency=1; bt.Text=''
            o._update=function(v) sw.BackgroundColor3=v and THEME.Accent or THEME.ToggleOff; ci.Position=v and UDim2.new(1,-16,.5,-7) or UDim2.new(0,2,.5,-7) end
            bt.MouseButton1Click:Connect(function() o:SetValue(not o.Value) end)
            function o:AddColorPicker(id2,info2) info2=info2 or {}; reg(id2,info2.Default or Color3.new(1,1,1),'color',nil,info2); return o end
            function o:AddKeyPicker() return o end
            if o.Value and o.Callback then task.spawn(o.Callback,o.Value) end
            return o
        end
        function api:AddSlider(id,info)
            info=info or {}; local mn=tonumber(info.Min) or 0; local mx=tonumber(info.Max) or 100; local def=tonumber(info.Default) or mn; local o=reg(id,def,'slider',info.Callback,info)
            local row=Instance.new('Frame',c); row.Size=UDim2.new(1,0,0,37); row.BackgroundTransparency=1; createLabel(row,UDim2.new(.68,0,0,15),UDim2.new(),tostring(info.Text or id),THEME.Text,Enum.Font.GothamMedium,9,Enum.TextXAlignment.Left)
            local vl=createLabel(row,UDim2.new(.32,0,0,15),UDim2.new(.68,0,0,0),tostring(def)..tostring(info.Suffix or ''),THEME.Accent,Enum.Font.GothamBold,9,Enum.TextXAlignment.Right)
            local bar=Instance.new('Frame',row); bar.Position=UDim2.new(0,0,0,22); bar.Size=UDim2.new(1,0,0,8); bar.BackgroundColor3=THEME.ToggleOff; bar.BorderSizePixel=0; addCorner(bar,4)
            local fill=Instance.new('Frame',bar); fill.BackgroundColor3=THEME.Accent; fill.BorderSizePixel=0; addCorner(fill,4)
            local drag=false
            local function setx(x) local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1); local v=mn+(mx-mn)*a; local r=tonumber(info.Rounding); if r then local f=10^r; v=math.floor(v*f+.5)/f end; o:SetValue(v) end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; setx(i.Position.X) end end)
            UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setx(i.Position.X) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
            o._update=function(v) fill.Size=UDim2.new(math.clamp((tonumber(v)-mn)/math.max(mx-mn,1),0,1),0,1,0); vl.Text=tostring(v)..tostring(info.Suffix or '') end; o._update(def)
            return o
        end
        function api:AddDropdown(id,info)
            info=info or {}; local vals=info.Values or {}; local multi=info.Multi==true; local def=info.Default
            local dv=multi and (type(def)=='table' and clone(def) or {}) or (type(def)=='number' and (vals[def] or vals[1] or 'None') or def or vals[1] or 'None')
            local o=reg(id,dv,'dropdown',info.Callback,info); o.Values=vals
            local row=Instance.new('Frame',c); row.Size=UDim2.new(1,0,0,34); row.BackgroundTransparency=1; createLabel(row,UDim2.new(.38,0,1,0),UDim2.new(),tostring(info.Text or id),THEME.Text,Enum.Font.GothamMedium,9,Enum.TextXAlignment.Left)
            local b=Instance.new('TextButton',row); b.Position=UDim2.new(.38,0,.5,-13); b.Size=UDim2.new(.62,0,0,26); b.BackgroundColor3=THEME.ToggleOff; b.BorderSizePixel=0; b.TextColor3=THEME.Text; b.Font=Enum.Font.Gotham; b.TextSize=8; addCorner(b,7)
            local pop=Instance.new('Frame',row); pop.Visible=false; pop.Position=UDim2.new(.38,0,1,0); pop.Size=UDim2.new(.62,0,0,130); pop.BackgroundColor3=THEME.Background; pop.BorderSizePixel=0; pop.ZIndex=50; addCorner(pop,8); local ps=Instance.new('UIStroke',pop); ps.Color=THEME.Accent; ps.Thickness=.8
            local sc=Instance.new('ScrollingFrame',pop); sc.Size=UDim2.new(1,-6,1,-6); sc.Position=UDim2.new(0,3,0,3); sc.BackgroundTransparency=1; sc.BorderSizePixel=0; sc.ScrollBarThickness=2; sc.ScrollBarImageColor3=THEME.Accent
            local ll=Instance.new('UIListLayout',sc); ll.Padding=UDim.new(0,3)
            local function disp(v) if multi then local n=0; for _ in pairs(v or {}) do n+=1 end; return n==0 and 'None' or (tostring(n)..' selected') end; return tostring(v or 'None') end
            local function rebuild()
                for _,ch in ipairs(sc:GetChildren()) do if not ch:IsA('UIListLayout') then ch:Destroy() end end
                for _,v in ipairs(o.Values or {}) do local it=Instance.new('TextButton',sc); it.Size=UDim2.new(1,0,0,24); it.BackgroundColor3=THEME.Card; it.BorderSizePixel=0; it.TextColor3=THEME.Text; it.Font=Enum.Font.Gotham; it.TextSize=8; it.Text=tostring(v); addCorner(it,5); it.MouseButton1Click:Connect(function() if multi then local t=clone(o.Value or {}); if t[v] then t[v]=nil else t[v]=true end; o:SetValue(t) else o:SetValue(v); pop.Visible=false end end) end
                b.Text=disp(o.Value)
            end
            function o:SetValues(v) self.Values=v or {}; rebuild() end
            function o:SetValue(v) self.Value=clone(v); b.Text=disp(self.Value); if self.Callback then pcall(self.Callback,self.Value) end end
            b.MouseButton1Click:Connect(function() pop.Visible=not pop.Visible end); rebuild(); return o
        end
        function api:AddInput(id,info)
            info=info or {}; local o=reg(id,tostring(info.Default or ''),'input',info.Callback,info); local row=Instance.new('Frame',c); row.Size=UDim2.new(1,0,0,50); row.BackgroundTransparency=1; createLabel(row,UDim2.new(1,0,0,16),UDim2.new(),tostring(info.Text or id),THEME.Text,Enum.Font.GothamMedium,9,Enum.TextXAlignment.Left)
            local tb=Instance.new('TextBox',row); tb.Size=UDim2.new(1,0,0,28); tb.Position=UDim2.new(0,0,0,19); tb.BackgroundColor3=THEME.ToggleOff; tb.BorderSizePixel=0; tb.TextColor3=THEME.Text; tb.PlaceholderColor3=THEME.SubText; tb.Font=Enum.Font.Gotham; tb.TextSize=8; tb.Text=tostring(o.Value); tb.PlaceholderText=tostring(info.Placeholder or ''); addCorner(tb,7); tb.FocusLost:Connect(function() o:SetValue(tb.Text) end); return o
        end
        function api:AddLeftGroupbox(t) return controls(c,t) end; function api:AddRightGroupbox(t) return controls(c,t) end
        function api:AddLeftTabbox() local w={}; function w:AddTab(t) return controls(c,t) end; return w end
        function api:AddRightTabbox() return self:AddLeftTabbox() end
        return api
    end

    local cw={Tabs={}}
    function cw:AddTab(name,icon)
        local b=Window:CreateTab(name,icon)
        local t=controls(b.Page,name)
        t.Page=b.Page; t.Btn=b.Btn; t.Text=b.Text; t.Icon=b.Icon
        self.Tabs[#self.Tabs+1]=t
        return t
    end
    function runtime:AddTab(name,icon)
        return cw:AddTab(name,icon)
    end
    function runtime:CreateWindow()
        return cw
    end
    function runtime:OnUnload(fn) if type(fn)=='function' then table.insert(self._unloadCallbacks,fn) end end
    function runtime:Unload()
        if self.Unloaded then return end; self.Unloaded=true
        for _,fn in ipairs(self._unloadCallbacks) do pcall(fn) end
        if self.ScreenGui and self.ScreenGui.Parent then self.ScreenGui:Destroy() end
    end

    -- Compatibilidade para scripts que usam diretamente:
    -- Window:CreateTab(...):AddLeftGroupbox / AddRightGroupbox / AddLeftTabbox
    local rawCreateTab = runtime.CreateTab

    local function attachTabCompat(tab)
        function tab:AddLeftGroupbox(title)
            return controls(tab.Page, title)
        end

        function tab:AddRightGroupbox(title)
            return controls(tab.Page, title)
        end

        function tab:AddLeftTabbox()
            local boxTab = {}
            function boxTab:AddTab(title)
                return controls(tab.Page, title)
            end
            return boxTab
        end

        function tab:AddRightTabbox()
            return tab:AddLeftTabbox()
        end

        return tab
    end

    runtime.CreateTab = function(self, name, icon)
        local tab = rawCreateTab(self, name, icon)
        return attachTabCompat(tab)
    end

    for _, tab in ipairs(Window.Tabs) do
        attachTabCompat(tab)
    end

    runtime.AddTab = runtime.CreateTab

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
