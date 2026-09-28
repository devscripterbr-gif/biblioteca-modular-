-- ==========================================================
-- DS HUB | Anime Dice / Gaming Spirit
-- DSHUB.lua (standalone UI + recovered functions)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = (getgenv and getgenv()) or _G

local function aliveWindow(window)
    return window and not window.Unloaded
end

local Library = (function()
-- DS HUB v1.0 | Hub.lua
-- Biblioteca de interface. Não contém lógica de jogo.

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    player = Players.PlayerAdded:Wait()
end

local function getParent()
    local ok, hui = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
    end)

    if ok and hui then
        return hui
    end

    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)

    if okCore and core then
        return core
    end

    return player:WaitForChild("PlayerGui")
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
end

function Library.Init(options)
    options = options or {}

    local parent = getParent()

    local old = parent:FindFirstChild("DSHUB_V1_0")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DSHUB_V1_0"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999

    local okParent = pcall(function()
        gui.Parent = parent
    end)

    if not okParent or not gui.Parent then
        error("DS HUB: não foi possível criar a ScreenGui.")
    end

    local main = Instance.new("Frame")
    main.Name = "Window"
    main.Size = UDim2.fromOffset(430, 230)
    main.Position = UDim2.new(0.5, -215, 0.5, -115)
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BorderSizePixel = 0
    main.Visible = true
    main.Parent = gui
    corner(main, 10)

    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(0, 255, 100)
    outline.Thickness = 1
    outline.Parent = main

    local bar = Instance.new("Frame")
    bar.Name = "TopBar"
    bar.Size = UDim2.new(1, 0, 0, 40)
    bar.BackgroundColor3 = Color3.fromRGB(7, 7, 7)
    bar.BorderSizePixel = 0
    bar.Parent = main
    corner(bar, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -105, 1, 0)
    title.Position = UDim2.fromOffset(12, 0)
    title.BackgroundTransparency = 1
    title.Text = tostring(options.Name or "DS Hub")
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bar

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.fromOffset(45, 40)
    ver.Position = UDim2.fromOffset(85, 0)
    ver.BackgroundTransparency = 1
    ver.Text = tostring(options.Version or "v1.0")
    ver.TextColor3 = Color3.fromRGB(170, 255, 195)
    ver.Font = Enum.Font.GothamBold
    ver.TextSize = 11
    ver.TextXAlignment = Enum.TextXAlignment.Left
    ver.Parent = bar

    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.fromOffset(30, 30)
    minimize.Position = UDim2.new(1, -68, 0.5, -15)
    minimize.BackgroundTransparency = 1
    minimize.Text = "—"
    minimize.TextColor3 = Color3.fromRGB(180, 180, 180)
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 15
    minimize.Parent = bar

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(30, 30)
    close.Position = UDim2.new(1, -35, 0.5, -15)
    close.BackgroundTransparency = 1
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(180, 180, 180)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 11
    close.Parent = bar

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 135, 1, -48)
    sidebar.Position = UDim2.fromOffset(6, 46)
    sidebar.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    corner(sidebar, 8)

    local sideList = Instance.new("UIListLayout")
    sideList.Padding = UDim.new(0, 5)
    sideList.Parent = sidebar

    local sidePad = Instance.new("UIPadding")
    sidePad.PaddingTop = UDim.new(0, 7)
    sidePad.PaddingLeft = UDim.new(0, 5)
    sidePad.PaddingRight = UDim.new(0, 5)
    sidePad.Parent = sidebar

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -147, 1, -48)
    pages.Position = UDim2.fromOffset(147, 46)
    pages.BackgroundTransparency = 1
    pages.Parent = main

    local window = {
        ScreenGui = gui,
        Main = main,
        Tabs = {},
        Options = {},
        Toggles = {},
        Unloaded = false,
    }

    function window:Notify(info)
        info = info or {}

        local toast = Instance.new("Frame")
        toast.Size = UDim2.fromOffset(275, 58)
        toast.Position = UDim2.new(1, -8, 0, 8)
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        toast.BorderSizePixel = 0
        toast.ZIndex = 500
        toast.Parent = gui
        corner(toast, 8)

        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(0, 255, 100)
        s.Thickness = 1
        s.Parent = toast

        local a = Instance.new("TextLabel")
        a.Size = UDim2.new(1, -14, 0, 18)
        a.Position = UDim2.fromOffset(7, 4)
        a.BackgroundTransparency = 1
        a.Text = tostring(info.Title or "DS HUB")
        a.TextColor3 = Color3.fromRGB(0, 255, 100)
        a.Font = Enum.Font.GothamBold
        a.TextSize = 10
        a.TextXAlignment = Enum.TextXAlignment.Left
        a.ZIndex = 501
        a.Parent = toast

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -14, 0, 28)
        b.Position = UDim2.fromOffset(7, 24)
        b.BackgroundTransparency = 1
        b.Text = tostring(info.Description or "")
        b.TextColor3 = Color3.fromRGB(240, 240, 240)
        b.Font = Enum.Font.Gotham
        b.TextSize = 9
        b.TextWrapped = true
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.ZIndex = 501
        b.Parent = toast

        task.delay(tonumber(info.Time) or 3, function()
            if toast.Parent then
                toast:Destroy()
            end
        end)
    end

    function window:CreateTab(tabName, icon)
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 34)
        tabButton.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        tabButton.BackgroundTransparency = (#self.Tabs == 0) and 0.7 or 1
        tabButton.BorderSizePixel = 0
        tabButton.Text = tostring(icon or "•") .. "  " .. tostring(tabName)
        tabButton.TextColor3 = (#self.Tabs == 0)
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(145, 155, 145)
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextSize = 10
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.Parent = sidebar
        corner(tabButton, 7)

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = (#self.Tabs == 0)
        page.Parent = pages

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 7)
        list.Parent = page

        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
        end)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 5)
        pad.PaddingLeft = UDim.new(0, 3)
        pad.PaddingRight = UDim.new(0, 5)
        pad.Parent = page

        local tab = {
            Page = page,
            Button = tabButton,
        }

        function tab:CreateToggle(id, defaultValue, callback)
            local option = {
                Value = defaultValue == true,
                Default = defaultValue == true,
            }

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 48)
            card.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            card.BorderSizePixel = 0
            card.Parent = page
            corner(card, 8)

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(20, 45, 25)
            stroke.Thickness = 1
            stroke.Parent = card

            local text = Instance.new("TextLabel")
            text.Size = UDim2.new(1, -72, 1, 0)
            text.Position = UDim2.fromOffset(11, 0)
            text.BackgroundTransparency = 1
            text.Text = tostring(id)
            text.TextColor3 = Color3.fromRGB(245, 245, 245)
            text.Font = Enum.Font.GothamMedium
            text.TextSize = 10
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.Parent = card

            local switch = Instance.new("Frame")
            switch.Size = UDim2.fromOffset(40, 22)
            switch.Position = UDim2.new(1, -52, 0.5, -11)
            switch.BackgroundColor3 = option.Value
                and Color3.fromRGB(0, 255, 100)
                or Color3.fromRGB(25, 25, 25)
            switch.BorderSizePixel = 0
            switch.Parent = card
            corner(switch, 11)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position = option.Value
                and UDim2.new(1, -19, 0.5, -8)
                or UDim2.fromOffset(3, 3)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch
            corner(knob, 8)

            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.Parent = card

            function option:SetValue(value)
                self.Value = value == true

                switch.BackgroundColor3 = self.Value
                    and Color3.fromRGB(0, 255, 100)
                    or Color3.fromRGB(25, 25, 25)

                knob.Position = self.Value
                    and UDim2.new(1, -19, 0.5, -8)
                    or UDim2.fromOffset(3, 3)

                if callback then
                    task.spawn(callback, self.Value)
                end
            end

            hit.MouseButton1Click:Connect(function()
                option:SetValue(not option.Value)
            end)

            window.Options[id] = option
            window.Toggles[id] = option

            return option
        end

        table.insert(self.Tabs, tab)

        tabButton.MouseButton1Click:Connect(function()
            for _, item in ipairs(self.Tabs) do
                item.Page.Visible = false
                item.Button.BackgroundTransparency = 1
                item.Button.TextColor3 = Color3.fromRGB(145, 155, 145)
            end

            page.Visible = true
            tabButton.BackgroundTransparency = 0.7
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)

        return tab
    end

    local dragging = false
    local dragStart
    local startPosition

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    local minimized = false

    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        sidebar.Visible = not minimized
        pages.Visible = not minimized
        main.Size = minimized
            and UDim2.fromOffset(430, 40)
            or UDim2.fromOffset(430, 230)
        minimize.Text = minimized and "+" or "—"
    end)

    close.MouseButton1Click:Connect(function()
        window:Unload()
    end)

    function window:Unload()
        if self.Unloaded then
            return
        end

        self.Unloaded = true

        if gui.Parent then
            gui:Destroy()
        end
    end

    return window
end
    return Library
end)()

local Window = Library.Init({
    Name = "DS Hub",
    Version = "AD v1",
    ConfigFile = "DSHub_AnimeDice_Config.json",
})

env.DSHUB_CURRENT_WINDOW = Window
local MainTab = Window:CreateTab("🎲 Anime Dice")


--[[
    Anime Dice / Gaming Spirit
    FUNCTION RECOVERY

    Source: LuaObfuscator.com Alpha 0.10.9 VM payload from the uploaded file.

    This file contains the recovered game-facing functions in readable Luau.
    The VM hides original local names, but the service/remotes, constants and
    control flow below are reconstructed from the decoded bytecode.
]]


local function waitChild(parent, name)
    return parent and parent:WaitForChild(name)
end

local function safeCall(fn, ...)
    return pcall(fn, ...)
end

-- ================================================================
-- Recovered service/module references
-- ================================================================

local Network = waitChild(ReplicatedStorage, "Network")

local RollService = waitChild(Network, "RollService")
local RollRE = waitChild(RollService, "RE")
local SetAutoRoll = waitChild(RollRE, "SetAutoRoll")

local PlotService = waitChild(Network, "PlotService")
local PlotRE = waitChild(PlotService, "RE")
local CollectBalance = waitChild(PlotRE, "CollectBalance")
local EquipBest = waitChild(PlotRE, "EquipBest")

local RebirthService = waitChild(Network, "RebirthService")
local RebirthRE = waitChild(RebirthService, "RE")
local Rebirth = waitChild(RebirthRE, "Rebirth")

local Framework = waitChild(ReplicatedStorage, "Framework")
local Features = waitChild(Framework, "Features")

local DiceModule = waitChild(waitChild(Features, "Rolling"), "Dice")
local DataControllerModule = waitChild(waitChild(Features, "Data"), "DataController")

local Packages = waitChild(ReplicatedStorage, "Packages")
local PackageNetwork = waitChild(Packages, "Network")

local ClientCommModule = waitChild(PackageNetwork, "ClientComm")
local ClientComm
local DiceShopService
local BuyDice
local EquipDice

if ClientCommModule then
    local ok, result = pcall(require, ClientCommModule)
    if ok and result and type(result.new) == "function" then
        pcall(function()
            ClientComm = result.new(PackageNetwork)
            DiceShopService = ClientComm:GetSignal("DiceShopService")
            BuyDice = DiceShopService:GetSignal("BuyDice")
            EquipDice = DiceShopService:GetSignal("EquipDice")
        end)
    end
end

-- Upgrades signals recovered from the main chunk.
local UpgradesFolder = waitChild(Features, "Upgrades")
local UpgradeModule = UpgradesFolder and waitChild(UpgradesFolder, "Upgrades")
local UpgradeClient
local BuyUpgrade

if UpgradeModule then
    local ok, result = pcall(require, UpgradeModule)
    if ok and result then
        pcall(function()
            UpgradeClient = result.Client
            if UpgradeClient and type(UpgradeClient.GetSignal) == "function" then
                BuyUpgrade = UpgradeClient:GetSignal(Network, "BuyUpgrade")
            end
        end)
    end
end

-- Alternative shape used by some versions of the same client module.
if not BuyUpgrade and UpgradeModule then
    local ok, result = pcall(require, UpgradeModule)
    if ok and result and type(result.GetSignal) == "function" then
        pcall(function()
            BuyUpgrade = result:GetSignal("BuyUpgrade")
        end)
    end
end

-- ================================================================
-- AUTO ROLL
-- ================================================================

function SetAutoRollState(value)
    value = value == true

    if not SetAutoRoll then
        return false
    end

    return pcall(function()
        SetAutoRoll:FireServer(value)
    end)
end

-- ================================================================
-- BUY BEST DICE
-- ================================================================
--
-- Recovered facts:
--   * calls GetAll()
--   * reads OwnedDice and Money
--   * builds a list with name + data
--   * sorts primarily by data.luck, then by data.price
--   * uses ipairs over the sorted list
--   * buys through BuyDice:Fire(name)
--   * waits 0.3 seconds
--   * equips through EquipDice:Fire(name)
--

local function getDataController()
    if not DataControllerModule then
        return nil
    end

    local ok, controller = pcall(require, DataControllerModule)
    if ok then
        return controller
    end
end

local function getAllPlayerData()
    local controller = getDataController()

    if controller and type(controller.GetAll) == "function" then
        local ok, data = pcall(function()
            return controller:GetAll()
        end)
        if ok and type(data) == "table" then
            return data
        end
    end

    return nil
end

function BuyBestDiceOnce()
    if not BuyDice or not EquipDice then
        return false
    end

    local allData = getAllPlayerData()
    if type(allData) ~= "table" then
        return false
    end

    local ownedDice = allData.OwnedDice
    if type(ownedDice) ~= "table" then
        return false
    end

    local candidates = {}

    for name, data in pairs(ownedDice) do
        if type(data) == "table" then
            table.insert(candidates, {
                name = name,
                data = data,
            })
        end
    end

    table.sort(candidates, function(a, b)
        local aLuck = tonumber(a.data and a.data.luck) or 0
        local bLuck = tonumber(b.data and b.data.luck) or 0

        if aLuck ~= bLuck then
            return aLuck > bLuck
        end

        local aPrice = tonumber(a.data and a.data.price) or 0
        local bPrice = tonumber(b.data and b.data.price) or 0
        return aPrice > bPrice
    end)

    local money = tonumber(allData.Money)
    if not money then
        return false
    end

    for _, dice in ipairs(candidates) do
        local price = tonumber(dice.data and dice.data.price)

        if price and price <= money then
            local okBuy = pcall(function()
                BuyDice:Fire(dice.name)
            end)

            if okBuy then
                task.wait(0.3)

                pcall(function()
                    EquipDice:Fire(dice.name)
                end)
            end

            return okBuy
        end
    end

    return false
end

-- ================================================================
-- COLLECT CASH
-- ================================================================

function CollectCashOnce()
    if not CollectBalance then
        return false
    end

    return pcall(function()
        CollectBalance:FireServer()
    end)
end

-- ================================================================
-- AUTO REBIRTH
-- ================================================================

function RebirthOnce()
    if not Rebirth then
        return false
    end

    return pcall(function()
        Rebirth:FireServer()
    end)
end

-- ================================================================
-- AUTO EQUIP BEST
-- ================================================================

function EquipBestOnce()
    if not EquipBest then
        return false
    end

    return pcall(function()
        EquipBest:FireServer()
    end)
end

-- ================================================================
-- AUTO UPGRADE
-- ================================================================
--
-- The decoded bytecode explicitly contains:
--   Upgrades:GetChildren()
--   upgrade.Upgrades
--   upgrade.price
--   BuyUpgrade:Fire(...)
--
-- The VM obscures the exact shape of the argument list after the price
-- comparison, so the function below preserves the observable operation and
-- provides the two client-module calling conventions seen in the bytecode.

local function getUpgradeContainer()
    return UpgradesFolder and UpgradesFolder:FindFirstChild("Upgrades")
end

local function getUpgradePrice(upgrade)
    if not upgrade then
        return nil
    end

    local price = upgrade:GetAttribute("price")
    if price ~= nil then
        return tonumber(price)
    end

    local value = upgrade:FindFirstChild("price")
    if value then
        return tonumber(value.Value)
    end

    local ok, property = pcall(function()
        return upgrade.price
    end)

    if ok then
        return tonumber(property)
    end
end

function AutoUpgradeOnce(money)
    local folder = getUpgradeContainer()
    if not folder or not BuyUpgrade then
        return false
    end

    if money == nil then
        local data = getAllPlayerData()
        money = data and tonumber(data.Money)
    end

    if not money then
        return false
    end

    local upgraded = false

    for _, upgrade in ipairs(folder:GetChildren()) do
        local price = getUpgradePrice(upgrade)

        if price and price <= money then
            local ok = pcall(function()
                BuyUpgrade:Fire(upgrade)
            end)

            upgraded = upgraded or ok
        end
    end

    return upgraded
end

-- ================================================================
-- SELL ALL
-- ================================================================
--
-- Recovered object chain from the payload:
--   require(Framework.Features.Selling.SellUtil)
--   require(...ClientComm...)
--   ClientComm.new(Network)
--   SellService
--   GetFunction("SellInventory")
--   CreateSummary
--   Inventory.Slots
--   ipairs / table.insert / slot.key / totalUnits
--
-- The inventory-summary construction is the portion where the VM removes
-- enough source-level information that the exact original table literal cannot
-- be reproduced with certainty. The implementation below follows the same
-- data flow instead of inventing additional game remotes.

local SellUtilModule = waitChild(waitChild(Features, "Selling"), "SellUtil")
local SellUtil

if SellUtilModule then
    pcall(function()
        SellUtil = require(SellUtilModule)
    end)
end

local function getSellService()
    if not PackageNetwork or not ClientCommModule then
        return nil
    end

    local ok, commModule = pcall(require, ClientCommModule)
    if not ok or not commModule or type(commModule.new) ~= "function" then
        return nil
    end

    local okComm, comm = pcall(function()
        return commModule.new(Network)
    end)

    if not okComm or not comm then
        return nil
    end

    local okService, service = pcall(function()
        return comm:GetFunction("SellService")
    end)

    if okService then
        return service
    end
end

local function getInventorySlots()
    local data = getAllPlayerData()
    if type(data) == "table" and type(data.Inventory) == "table" then
        return data.Inventory.Slots
    end

    local inventory = player:FindFirstChild("Inventory")
    return inventory and inventory:FindFirstChild("Slots")
end

function SellAllOnce()
    if not SellUtil then
        return false
    end

    local sellService = getSellService()
    if not sellService then
        return false
    end

    local sellInventory
    local okFunction = pcall(function()
        sellInventory = sellService:GetFunction("SellInventory")
    end)

    if not okFunction or not sellInventory then
        return false
    end

    local slots = getInventorySlots()
    if not slots then
        return false
    end

    local sales = {}
    local totalUnits = 0

    for _, slot in ipairs(slots) do
        if type(slot) == "table" and slot.key ~= nil then
            local units = tonumber(slot.totalUnits) or tonumber(slot.units) or 1
            totalUnits = totalUnits + units
            table.insert(sales, {
                key = slot.key,
                totalUnits = units,
            })
        end
    end

    if totalUnits <= 0 then
        return false
    end

    local summary = sales

    if type(SellUtil.CreateSummary) == "function" then
        local okSummary, result = pcall(function()
            return SellUtil.CreateSummary({
                sales = sales,
                totalUnits = totalUnits,
            })
        end)
        if okSummary and result ~= nil then
            summary = result
        end
    end

    local okSell = pcall(function()
        if type(sellInventory) == "function" then
            sellInventory(summary)
        elseif sellInventory.InvokeServer then
            sellInventory:InvokeServer(summary)
        end
    end)

    return okSell
end


-- ==========================================================
-- Toggle / loop manager
-- ==========================================================

local loops = {
    BuyBestDice = false,
    CollectCash = false,
    AutoRebirth = false,
    AutoUpgrade = false,
    AutoEquipBest = false,
    SellAll = false,
}

local function startLoop(name, callback, delay)
    loops[name] = true

    task.spawn(function()
        while loops[name] and aliveWindow(Window) do
            pcall(callback)
            task.wait(delay)
        end
    end)
end

local function stopAll()
    pcall(function()
        SetAutoRollState(false)
    end)

    for key in pairs(loops) do
        loops[key] = false
    end
end

local function addToggle(label, callback)
    -- Formato do Hub.lua atual: CreateToggle(text, default, callback)
    local ok, option = pcall(function()
        return MainTab:CreateToggle(label, false, callback)
    end)

    if ok then
        return option
    end

    -- Compatibilidade com bibliotecas que usam tabela de configuração.
    local okTable, optionTable = pcall(function()
        return MainTab:CreateToggle(label, {
            Text = label,
            Default = false,
            Callback = callback,
        })
    end)

    if okTable then
        return optionTable
    end

    warn("[DS HUB] Falha ao criar toggle: " .. tostring(label))
end

addToggle("Auto Roll", function(value)
    SetAutoRollState(value)
end)

addToggle("Buy Best Dice", function(value)
    loops.BuyBestDice = value
    if value then
        startLoop("BuyBestDice", BuyBestDiceOnce, 1)
    end
end)

addToggle("Collect Cash", function(value)
    loops.CollectCash = value
    if value then
        startLoop("CollectCash", CollectCashOnce, 1)
    end
end)

addToggle("Auto Rebirth", function(value)
    loops.AutoRebirth = value
    if value then
        startLoop("AutoRebirth", RebirthOnce, 1)
    end
end)

addToggle("Auto Upgrade", function(value)
    loops.AutoUpgrade = value
    if value then
        startLoop("AutoUpgrade", AutoUpgradeOnce, 0.2)
    end
end)

addToggle("Auto Equip Best", function(value)
    loops.AutoEquipBest = value
    if value then
        startLoop("AutoEquipBest", EquipBestOnce, 0.5)
    end
end)

addToggle("Sell All", function(value)
    loops.SellAll = value
    if value then
        startLoop("SellAll", SellAllOnce, 1.5)
    end
end)

if type(Window.OnUnload) == "function" then
    Window:OnUnload(function()
        stopAll()
    end)
end

env.DSHUB_ANIMEDICE_LOADED = true
return Window
