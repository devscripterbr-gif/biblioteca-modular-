-- ============================================================
-- DSHUB_ALL.lua — Farm Hub unificado (auto-contido)
-- FS v2.1 BETA (Mobile Optimized / Anti-Freeze / Fast Farm)
-- ============================================================

-- [1] Mata instância anterior
if _G.DSHub_Running then
    _G.DSHub_Kill = true
    task.wait(0.15)
end
_G.DSHub_Running = true
_G.DSHub_Kill = false

-- [2] Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

-- [3] Modules do jogo (Com respiro para não dar Timeout no Delta)
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
    warn("[DS HUB] Módulos do jogo não encontrados!")
    return
end

task.wait(0.2)
local VoxelLookup   = require(Modules:WaitForChild("VoxelLookup"))
task.wait(0.2)
local ItemStates    = require(Modules.Databanks:WaitForChild("ItemStates"))
task.wait(0.2)
local ItemData      = require(Modules.Databanks:WaitForChild("ItemData"))
task.wait(0.2)
local FishingModule = require(Modules.Tools.Fishing)
task.wait(0.2)
local GlobalData    = require(Modules.Databanks:WaitForChild("GlobalData"))

-- [4] Flags globais
_G.AutoFarm      = false
_G.AutoHarvest   = false
_G.AutoWater     = false
_G.AutoFertilize = false
_G.AutoMine      = false
_G.AutoChop      = false
_G.AutoApple     = false
_G.AutoFishing   = false

local Cache = {}
local isTeleporting = false
local Remotes = {}

-- [5] Remotes
local function GetRemotes()
    if Remotes.Mine and Remotes.Mine.Parent then return Remotes end
    local Relay = ReplicatedStorage:FindFirstChild("Relay")
    local BlocksRelay = Relay and Relay:FindFirstChild("Blocks")
    if BlocksRelay then
        Remotes = {
            Plant     = BlocksRelay:FindFirstChild("PlantCrop"),
            Harvest   = BlocksRelay:FindFirstChild("HarvestCrop"),
            Water     = BlocksRelay:FindFirstChild("WaterBlock"),
            Chop      = BlocksRelay:FindFirstChild("ChopTree"),
            Mine      = BlocksRelay:FindFirstChild("MineBlock"),
            Fertilize = BlocksRelay:FindFirstChild("FertilizeBlock")
        }
    end
    return Remotes
end

local function IsFruitTree(block)
    local name = string.lower(block.Name)
    if string.find(name, "apple") or string.find(name, "fruit") then return true end
    if block:FindFirstChild("Fruit") then return true end
    return false
end

local function AdvancedGhostFill(targetPos, prompt)
    if isTeleporting or not fireproximityprompt then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    isTeleporting = true
    local oldPos = root.CFrame

    task.spawn(function()
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3.5, 0))
            task.wait(0.18)
            if prompt and prompt.Parent then fireproximityprompt(prompt) end
            task.wait(0.08)
            root.CFrame = oldPos
            root.AssemblyLinearVelocity = Vector3.zero
        end)
        task.wait(0.2)
        isTeleporting = false
    end)
end

-- [6] GC do cache
task.spawn(function()
    while task.wait(30) do
        if _G.DSHub_Kill then break end
        Cache = {}
    end
end)

-- [7] Hook de pesca
if not _G.DSHub_FishingHooked then
    _G.DSHub_FishingHooked = true
    local autoYanking = false
    local oldUpdate = FishingModule.Update
    FishingModule.Update = function(self, dt)
        oldUpdate(self, dt)
        if _G.AutoFishing and not _G.DSHub_Kill then
            local hFish = GlobalData.hookedFish
            if hFish and hFish:GetAttribute("Hooked") and self.casted and not autoYanking then
                autoYanking = true
                task.spawn(function()
                    task.wait(0.02)
                    self:PrimaryInput(Enum.UserInputState.End, true)
                    task.wait(0.65)
                    autoYanking = false
                end)
            end
        end
    end
end

-- [8] ProcessBlock (Otimizado e Rápido)
local function ProcessBlock(block, rootPos, ActiveRemotes, curTime)
    if isTeleporting or _G.DSHub_Kill then return end

    local blockWorldPos
    if block:IsA("BasePart") then
        blockWorldPos = block.Position
    elseif block:IsA("Model") then
        blockWorldPos = block:GetPivot().Position
    else
        return
    end

    local dist = (blockWorldPos - rootPos).Magnitude
    if dist > 22 then return end

    if _G.AutoApple and block.Name == "Apple Tree" then
        local pp = block:FindFirstChild("PromptPart")
        local prompt = pp and pp:FindFirstChildOfClass("ProximityPrompt")
        if prompt and (pp.Position - rootPos).Magnitude <= 20 then
            local pKey = tostring(pp.Position)
            if not Cache[pKey] or (curTime - Cache[pKey] > 0.8) then
                Cache[pKey] = curTime
                fireproximityprompt(prompt)
            end
        end
    end

    if not (_G.AutoHarvest or _G.AutoMine or _G.AutoWater
         or _G.AutoFertilize or _G.AutoFarm or _G.AutoChop) then
        return
    end

    local vPos = block:GetAttribute("VoxelPosition")
    if not vPos then return end

    local st = block:GetAttribute("State")
    local key = tostring(vPos)
    local isFarmland = (block.Name == "Farmland")
    local isTree = false
    
    if _G.AutoChop or _G.AutoHarvest then
        local lowerName = string.lower(block.Name)
        local itemID = block:GetAttribute("ID")
        local info = itemID and ItemData.IDLookup[itemID] and ItemData[ItemData.IDLookup[itemID]]
        isTree = (info and (info.TYPE == "Tree" or info.TYPE == "Log"))
               or string.find(lowerName, "tree")
               or string.find(lowerName, "wood")
               or string.find(lowerName, "log")
    end

    -- Função para enviar comando com cooldown e repetição (cliques rápidos)
    local function SendRequest(remote, args, cacheKey, cooldown, repeats)
        if not Cache[cacheKey] or (curTime - Cache[cacheKey] > cooldown) then
            Cache[cacheKey] = curTime
            task.spawn(function()
                for i = 1, (repeats or 1) do
                    pcall(function() remote:InvokeServer(args) end)
                    if repeats and i < repeats then task.wait(0.05) end
                end
            end)
        end
    end

    -- AUTO HARVEST: 0.2s de cooldown (Rápido)
    if _G.AutoHarvest and not isTree and (st == ItemStates.RIPE or st == ItemStates.READY) then
        SendRequest(ActiveRemotes.Harvest, vPos, key .. "_h", 0.2, 1)
    end

    -- AUTO MINE: 0.15s de cooldown e 3 batidas (Quebra rápido)
    if _G.AutoMine and not isFarmland then
        local typeStr = block:GetAttribute("ID") and string.lower(ItemData[ItemData.IDLookup[block:GetAttribute("ID")]].TYPE or "") or ""
        if string.find(string.lower(block.Name),"ore") or string.find(string.lower(block.Name),"rock") or string.find(string.lower(block.Name),"stone") or string.find(typeStr,"rock") or string.find(typeStr,"ore") or block:GetAttribute("IsOre") then
            SendRequest(ActiveRemotes.Mine, vPos, key .. "_m", 0.15, 3)
        end
    end

    if isFarmland then
        if _G.AutoWater and st ~= ItemStates.WATERED and st ~= ItemStates.PERFECT then
            SendRequest(ActiveRemotes.Water, vPos, key .. "_w", 0.35, 1)
        end
        
        if _G.AutoFertilize and st ~= ItemStates.FERTILIZED and st ~= ItemStates.PERFECT then
            SendRequest(ActiveRemotes.Fertilize, vPos, key .. "_f", 0.35, 1)
        end

        if _G.AutoFarm then
            local x, y, z = tostring(vPos.X), tostring(vPos.Y + 1), tostring(vPos.Z)
            if not (VoxelLookup[x] and VoxelLookup[x][y] and VoxelLookup[x][y][z]) then
                SendRequest(ActiveRemotes.Plant, Vector3.new(vPos.X, vPos.Y+1, vPos.Z), key .. "_p", 0.35, 1)
            end
        end
    end

    -- AUTO CHOP: 0.15s de cooldown e 3 batidas (Derruba rápido)
    if _G.AutoChop and isTree and not IsFruitTree(block) then
        SendRequest(ActiveRemotes.Chop, vPos, key .. "_c", 0.15, 3)
    end
end

-- [9] Loop principal (Respiro mantido para não travar)
task.spawn(function()
    local now = tick
    while true do
        if _G.DSHub_Kill then break end

        local anyActive = _G.AutoFarm or _G.AutoHarvest or _G.AutoWater
                       or _G.AutoFertilize or _G.AutoMine or _G.AutoChop
                       or _G.AutoApple

        if not anyActive then
            task.wait(0.5)
        else
            task.wait(0.1) 
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root or isTeleporting then return end

                local blocks = workspace:FindFirstChild("LoadedBlocks")
                if not blocks then return end

                local ActiveRemotes = GetRemotes()
                if not ActiveRemotes.Mine then return end

                local curTime = now()
                local rootPos = root.Position

                if _G.AutoWater then
                    for _, b in pairs(blocks:GetChildren()) do
                        if b.Name == "Stone Well" and (b:GetAttribute("AlternativeState") or 0) > 0 then
                            local rp = b:FindFirstChild("Root")
                            if rp and (rp.Position - rootPos).Magnitude < 60 then
                                if not Cache["Well"] or (curTime - Cache["Well"] > 3) then
                                    Cache["Well"] = curTime
                                    AdvancedGhostFill(rp.Position, rp:FindFirstChildOfClass("ProximityPrompt"))
                                end
                                break
                            end
                        end
                    end
                end

                local children = blocks:GetChildren()
                for i, child in ipairs(children) do
                    ProcessBlock(child, rootPos, ActiveRemotes, curTime)
                    
                    -- Respiro para o celular não congelar (a cada 50 blocos)
                    if i % 50 == 0 then
                        task.wait()
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- DSHubLibrary - Módulo UI
-- ==========================================

local DSHubLibrary = {}

local HubPlayers        = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local HubLocalPlayer    = HubPlayers.LocalPlayer or HubPlayers.PlayerAdded:Wait()

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
        ParentGui = (success and core) and core or HubLocalPlayer:WaitForChild("PlayerGui")
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

    local Main = Instance.new("Frame", MainContainer)
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
        local IntroOverlay = Instance.new("Frame", ScreenGui)
        IntroOverlay.Size = UDim2.new(1, 0, 1, 0)
        IntroOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        IntroOverlay.BackgroundTransparency = 1
        IntroOverlay.ZIndex = 800

        local IntroCard = Instance.new("Frame", IntroOverlay)
        IntroCard.Size = UDim2.new(0, 340, 0, 190)
        IntroCard.AnchorPoint = Vector2.new(0.5, 0.5)
        IntroCard.Position = UDim2.new(0.5, 0, 0.5, 0)
        IntroCard.BackgroundColor3 = THEME.Background
        IntroCard.BackgroundTransparency = 1
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
            createTween(IntroOverlay, 0.6, {BackgroundTransparency = 0.3}):Play()
            createTween(IntroCard, 0.7, {BackgroundTransparency = 0}, Enum.EasingStyle.Back):Play()
            createTween(CardStroke, 0.6, {Transparency = 0}):Play()

            task.wait(0.3)
            StatusSub.Text = "LOADING SCRIPT MODULES..."
            task.wait(0.3)
            StatusSub.Text = "CONNECTING TO GAME ENVIRONMENT..."
            task.wait(0.3)
            StatusSub.Text = "INITIALIZING " .. hubName .. "..."
            task.wait(0.3)
            StatusSub.Text = "READY [" .. versionText .. "]"

            createTween(CoreSymbol, 0.6, {Rotation = 360}):Play()
            task.wait(0.4)

            createTween(IntroCard, 0.5, {Size = UDim2.new(0, 370, 0, 210), BackgroundTransparency = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            createTween(IntroOverlay, 0.5, {BackgroundTransparency = 1}):Play()

            task.wait(0.5)
            IntroOverlay:Destroy()

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
        ProfileAvatar.Image = HubPlayers:GetUserThumbnailAsync(HubLocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    addCorner(ProfileAvatar, 12)

    createLabel(ProfileCard, UDim2.new(1, -34, 0, 12), UDim2.new(0, 32, 0, 4), HubLocalPlayer.DisplayName, THEME.Text, Enum.Font.GothamBold, 9, Enum.TextXAlignment.Left)
    local ProfileStatus = createLabel(ProfileCard, UDim2.new(1, -34, 0, 10), UDim2.new(0, 32, 0, 18), "60 FPS • 30ms", THEME.Accent, Enum.Font.GothamMedium, 8, Enum.TextXAlignment.Left)

    task.spawn(function()
        local lastTime = os.clock()
        local frameCount = 0
        RunService.Heartbeat:Connect(function()
            frameCount = frameCount + 1
            local currentTime = os.clock()
            if currentTime - lastTime >= 1 then
                local fps = math.floor(frameCount / (currentTime - lastTime))
                local ping = 0
                pcall(function() ping = math.floor(HubLocalPlayer:GetNetworkPing() * 1000) end)
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

        if next(Window.Tabs) == nil then
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

    local runtime = Window
    runtime.Library = DSHubLibrary
    runtime.ScreenGui = ScreenGui
    runtime.Options = {}
    runtime.Toggles = {}
    runtime.IsMobile = UserInputService.TouchEnabled
    runtime.Unloaded = false
    runtime._unloadCallbacks = {}

    function runtime:Notify(_) return false end

    function runtime:OnUnload(fn)
        if type(fn) == 'function' then table.insert(self._unloadCallbacks, fn) end
    end

    function runtime:Unload()
        if self.Unloaded then return end
        self.Unloaded = true
        for _, fn in ipairs(self._unloadCallbacks) do pcall(fn) end
        if self.ScreenGui and self.ScreenGui.Parent then self.ScreenGui:Destroy() end
    end

    local closing = false
    CloseBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        runtime:Unload()
    end)

    PlayIntro(function() MainContainer.Visible = true end)
    return runtime
end

-- ==========================================
-- [10] UI — criação das abas e toggles
-- ==========================================

local Hub = DSHubLibrary.Init({
    Name       = "DS HUB",
    Version    = "FS v2.1 BETA",
    ConfigFile = "DSHub_Config_v2_1.json",
})

Hub:OnUnload(function()
    _G.DSHub_Kill = true
    _G.DSHub_Running = false
end)

-- Aba: Plantio
local FarmTab = Hub:CreateTab("Plantio", "🌱")
FarmTab:CreateToggle("Auto Plantar",  false, function(s) _G.AutoFarm      = s end)
FarmTab:CreateToggle("Auto Colher",   false, function(s) _G.AutoHarvest   = s end)
FarmTab:CreateToggle("Auto Regar",    false, function(s) _G.AutoWater     = s end)
FarmTab:CreateToggle("Auto Adubar",   false, function(s) _G.AutoFertilize = s end)

-- Aba: Coleta
local GatherTab = Hub:CreateTab("Coleta", "⛏️")
GatherTab:CreateToggle("Auto Minerar", false, function(s) _G.AutoMine  = s end)
GatherTab:CreateToggle("Auto Cortar",  false, function(s) _G.AutoChop  = s end)
GatherTab:CreateToggle("Auto Maçãs",   false, function(s) _G.AutoApple = s end)

-- Aba: Outros
local MiscTab = Hub:CreateTab("Outros", "🎣")
MiscTab:CreateToggle("Auto Pesca", false, function(s) _G.AutoFishing = s end)

print("[DS HUB] Carregado ✔ (FS v2.1 BETA)")
