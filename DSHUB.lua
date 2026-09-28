-- ==========================================================
-- DS HUB | Anime Dice / Gaming Spirit
-- DSHUB.lua
-- UI: Hub.lua
-- ==========================================================

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = (getgenv and getgenv()) or _G

local function loadHub()
    local ok, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)
    if not ok or type(source) ~= "string" then
        error("[DS HUB] Falha ao carregar Hub.lua: " .. tostring(source))
    end
    local fn, compileError = loadstring(source)
    if not fn then
        error("[DS HUB] Hub.lua não compilou: " .. tostring(compileError))
    end
    local ran, library = pcall(fn)
    if not ran or type(library) ~= "table" or type(library.Init) ~= "function" then
        error("[DS HUB] Hub.lua inválido.")
    end
    return library
end

local function aliveWindow(window)
    return window and not window.Unloaded
end

local Library = loadHub()
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local function waitChild(parent, name)
    return parent and parent:FindFirstChild(name)
end

local function safeCall(fn, ...)
    return pcall(fn, ...)
end

-- ================================================================
-- Recovered service/module references
-- Resolução sob demanda para o Hub não ficar preso esperando objetos.
-- ================================================================

local Network
local RollService
local RollRE
local SetAutoRoll

local PlotService
local PlotRE
local CollectBalance
local EquipBest

local RebirthService
local RebirthRE
local Rebirth

local Framework
local Features
local DiceModule
local DataControllerModule
local Packages
local PackageNetwork
local ClientCommModule

local ClientComm
local DiceShopService
local BuyDice
local EquipDice

local UpgradesFolder
local UpgradeModule
local UpgradeClient
local BuyUpgrade

local SellUtilModule
local SellUtil

local function resolveServices()
    Network = Network or ReplicatedStorage:FindFirstChild("Network")

    RollService = RollService or (Network and Network:FindFirstChild("RollService"))
    RollRE = RollRE or (RollService and RollService:FindFirstChild("RE"))
    SetAutoRoll = SetAutoRoll or (RollRE and RollRE:FindFirstChild("SetAutoRoll"))

    PlotService = PlotService or (Network and Network:FindFirstChild("PlotService"))
    PlotRE = PlotRE or (PlotService and PlotService:FindFirstChild("RE"))
    CollectBalance = CollectBalance or (PlotRE and PlotRE:FindFirstChild("CollectBalance"))
    EquipBest = EquipBest or (PlotRE and PlotRE:FindFirstChild("EquipBest"))

    RebirthService = RebirthService or (Network and Network:FindFirstChild("RebirthService"))
    RebirthRE = RebirthRE or (RebirthService and RebirthService:FindFirstChild("RE"))
    Rebirth = Rebirth or (RebirthRE and RebirthRE:FindFirstChild("Rebirth"))

    Framework = Framework or ReplicatedStorage:FindFirstChild("Framework")
    Features = Features or (Framework and Framework:FindFirstChild("Features"))

    local rolling = Features and Features:FindFirstChild("Rolling")
    DiceModule = DiceModule or (rolling and rolling:FindFirstChild("Dice"))

    local dataFolder = Features and Features:FindFirstChild("Data")
    DataControllerModule = DataControllerModule or (dataFolder and dataFolder:FindFirstChild("DataController"))

    Packages = Packages or ReplicatedStorage:FindFirstChild("Packages")
    PackageNetwork = PackageNetwork or (Packages and Packages:FindFirstChild("Network"))
    ClientCommModule = ClientCommModule or (PackageNetwork and PackageNetwork:FindFirstChild("ClientComm"))

    if not ClientComm and ClientCommModule then
        local ok, result = pcall(require, ClientCommModule)
        if ok and result and type(result.new) == "function" then
            local okNew, comm = pcall(function()
                return result.new(PackageNetwork)
            end)

            if okNew and comm then
                ClientComm = comm
                pcall(function()
                    DiceShopService = ClientComm:GetSignal("DiceShopService")
                    BuyDice = DiceShopService and DiceShopService:GetSignal("BuyDice")
                    EquipDice = DiceShopService and DiceShopService:GetSignal("EquipDice")
                end)
            end
        end
    end

    UpgradesFolder = UpgradesFolder or (Features and Features:FindFirstChild("Upgrades"))
    UpgradeModule = UpgradeModule or (UpgradesFolder and UpgradesFolder:FindFirstChild("Upgrades"))

    if not BuyUpgrade and UpgradeModule then
        local ok, result = pcall(require, UpgradeModule)

        if ok and result then
            pcall(function()
                UpgradeClient = result.Client
                if UpgradeClient and type(UpgradeClient.GetSignal) == "function" then
                    BuyUpgrade = UpgradeClient:GetSignal(Network, "BuyUpgrade")
                end
            end)

            if not BuyUpgrade and type(result.GetSignal) == "function" then
                pcall(function()
                    BuyUpgrade = result:GetSignal("BuyUpgrade")
                end)
            end
        end
    end

    SellUtilModule = SellUtilModule
        or (Features
        and Features:FindFirstChild("Selling")
        and Features.Selling:FindFirstChild("SellUtil"))

    if not SellUtil and SellUtilModule then
        pcall(function()
            SellUtil = require(SellUtilModule)
        end)
    end
end

local function resolveWithRetry(timeout)
    local deadline = os.clock() + (timeout or 8)

    repeat
        resolveServices()

        if Network then
            return true
        end

        task.wait(0.15)
    until os.clock() >= deadline

    return false
end

-- Tenta logo no início, mas nunca bloqueia a criação da interface.
task.spawn(function()
    resolveWithRetry(8)
end)

-- ================================================================
-- AUTO ROLL
-- ================================================================

function SetAutoRollState(value)
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
-- Toggle/loop manager
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
    SetAutoRollState(false)
    for key in pairs(loops) do
        loops[key] = false
    end
end

local function addToggle(label, callback)
    -- Formato usado pelo Hub.lua atual.
    local ok, option = pcall(function()
        return MainTab:CreateToggle(label, false, callback)
    end)

    if ok and option then
        return option
    end

    -- Compatibilidade com hubs que usam tabela de configuração.
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

    warn("[DS HUB] Não foi possível criar o toggle '" .. tostring(label) .. "'.")
    return nil
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

ion waitChild(parent, name)
    return parent and parent:FindFirstChild(name)
end

local function safeCall(fn, ...)
    return pcall(fn, ...)
end

-- ================================================================
-- Recovered service/module references
-- Resolução sob demanda para o Hub não ficar preso esperando objetos.
-- ================================================================

local Network
local RollService
local RollRE
local SetAutoRoll

local PlotService
local PlotRE
local CollectBalance
local EquipBest

local RebirthService
local RebirthRE
local Rebirth

local Framework
local Features
local DiceModule
local DataControllerModule
local Packages
local PackageNetwork
local ClientCommModule

local ClientComm
local DiceShopService
local BuyDice
local EquipDice

local UpgradesFolder
local UpgradeModule
local UpgradeClient
local BuyUpgrade

local SellUtilModule
local SellUtil

local function resolveServices()
    Network = Network or ReplicatedStorage:FindFirstChild("Network")

    RollService = RollService or (Network and Network:FindFirstChild("RollService"))
    RollRE = RollRE or (RollService and RollService:FindFirstChild("RE"))
    SetAutoRoll = SetAutoRoll or (RollRE and RollRE:FindFirstChild("SetAutoRoll"))

    PlotService = PlotService or (Network and Network:FindFirstChild("PlotService"))
    PlotRE = PlotRE or (PlotService and PlotService:FindFirstChild("RE"))
    CollectBalance = CollectBalance or (PlotRE and PlotRE:FindFirstChild("CollectBalance"))
    EquipBest = EquipBest or (PlotRE and PlotRE:FindFirstChild("EquipBest"))

    RebirthService = RebirthService or (Network and Network:FindFirstChild("RebirthService"))
    RebirthRE = RebirthRE or (RebirthService and RebirthService:FindFirstChild("RE"))
    Rebirth = Rebirth or (RebirthRE and RebirthRE:FindFirstChild("Rebirth"))

    Framework = Framework or ReplicatedStorage:FindFirstChild("Framework")
    Features = Features or (Framework and Framework:FindFirstChild("Features"))

    local rolling = Features and Features:FindFirstChild("Rolling")
    DiceModule = DiceModule or (rolling and rolling:FindFirstChild("Dice"))

    local dataFolder = Features and Features:FindFirstChild("Data")
    DataControllerModule = DataControllerModule or (dataFolder and dataFolder:FindFirstChild("DataController"))

    Packages = Packages or ReplicatedStorage:FindFirstChild("Packages")
    PackageNetwork = PackageNetwork or (Packages and Packages:FindFirstChild("Network"))
    ClientCommModule = ClientCommModule or (PackageNetwork and PackageNetwork:FindFirstChild("ClientComm"))

    if not ClientComm and ClientCommModule then
        local ok, result = pcall(require, ClientCommModule)
        if ok and result and type(result.new) == "function" then
            local okNew, comm = pcall(function()
                return result.new(PackageNetwork)
            end)

            if okNew and comm then
                ClientComm = comm
                pcall(function()
                    DiceShopService = ClientComm:GetSignal("DiceShopService")
                    BuyDice = DiceShopService and DiceShopService:GetSignal("BuyDice")
                    EquipDice = DiceShopService and DiceShopService:GetSignal("EquipDice")
                end)
            end
        end
    end

    UpgradesFolder = UpgradesFolder or (Features and Features:FindFirstChild("Upgrades"))
    UpgradeModule = UpgradeModule or (UpgradesFolder and UpgradesFolder:FindFirstChild("Upgrades"))

    if not BuyUpgrade and UpgradeModule then
        local ok, result = pcall(require, UpgradeModule)

        if ok and result then
            pcall(function()
                UpgradeClient = result.Client
                if UpgradeClient and type(UpgradeClient.GetSignal) == "function" then
                    BuyUpgrade = UpgradeClient:GetSignal(Network, "BuyUpgrade")
                end
            end)

            if not BuyUpgrade and type(result.GetSignal) == "function" then
                pcall(function()
                    BuyUpgrade = result:GetSignal("BuyUpgrade")
                end)
            end
        end
    end

    SellUtilModule = SellUtilModule
        or (Features
        and Features:FindFirstChild("Selling")
        and Features.Selling:FindFirstChild("SellUtil"))

    if not SellUtil and SellUtilModule then
        pcall(function()
            SellUtil = require(SellUtilModule)
        end)
    end
end

local function resolveWithRetry(timeout)
    local deadline = os.clock() + (timeout or 8)

    repeat
        resolveServices()

        if Network then
            return true
        end

        task.wait(0.15)
    until os.clock() >= deadline

    return false
end

-- Tenta logo no início, mas nunca bloqueia a criação da interface.
task.spawn(function()
    resolveWithRetry(8)
end)

-- ================================================================
-- AUTO ROLL
-- ================================================================

function SetAutoRollState(value)
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
    resolveServices()
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
-- Toggle/loop manager
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
    SetAutoRollState(false)
    for key in pairs(loops) do
        loops[key] = false
    end
end

MainTab:CreateToggle("Auto Roll", false, function(value)
    SetAutoRollState(value)
end)

MainTab:CreateToggle("Buy Best Dice", false, function(value)
    loops.BuyBestDice = value
    if value then
        startLoop("BuyBestDice", BuyBestDiceOnce, 1)
    end
end)

MainTab:CreateToggle("Collect Cash", false, function(value)
    loops.CollectCash = value
    if value then
        startLoop("CollectCash", CollectCashOnce, 1)
    end
end)

MainTab:CreateToggle("Auto Rebirth", false, function(value)
    loops.AutoRebirth = value
    if value then
        startLoop("AutoRebirth", RebirthOnce, 1)
    end
end)

MainTab:CreateToggle("Auto Upgrade", false, function(value)
    loops.AutoUpgrade = value
    if value then
        startLoop("AutoUpgrade", AutoUpgradeOnce, 0.2)
    end
end)

MainTab:CreateToggle("Auto Equip Best", false, function(value)
    loops.AutoEquipBest = value
    if value then
        startLoop("AutoEquipBest", EquipBestOnce, 0.5)
    end
end)

MainTab:CreateToggle("Sell All", false, function(value)
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
