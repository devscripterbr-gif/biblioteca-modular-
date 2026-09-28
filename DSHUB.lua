-- ==========================================================
-- DS HUB | Anime Dice / Gaming Spirit
-- DSHUB.lua
-- Hub.lua continua sendo carregado do GitHub original.
-- ==========================================================

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = (getgenv and getgenv()) or _G

-- ==========================================================
-- CARREGA O HUB OFICIAL DO GITHUB
-- ==========================================================

local function loadHub()
    local okHttp, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)

    if not okHttp or type(source) ~= "string" then
        error("[DS HUB] Não foi possível carregar o Hub.lua: " .. tostring(source))
    end

    if type(loadstring) ~= "function" then
        error("[DS HUB] loadstring não está disponível neste executor.")
    end

    local fn, compileError = loadstring(source)

    if not fn then
        error("[DS HUB] Hub.lua não compilou: " .. tostring(compileError))
    end

    local okRun, library = pcall(fn)

    if not okRun then
        error("[DS HUB] Erro ao executar Hub.lua: " .. tostring(library))
    end

    if type(library) ~= "table" or type(library.Init) ~= "function" then
        error("[DS HUB] Hub.lua não retornou uma biblioteca válida.")
    end

    return library
end

local Library = loadHub()

-- A UI é criada antes de resolver qualquer módulo do jogo.
local Window = Library.Init({
    Name = "DS Hub",
    Version = "AD v1",
    ConfigFile = "DSHub_AnimeDice_Config.json",
})

env.DSHUB_CURRENT_WINDOW = Window

-- API confirmada do Hub.lua usado pelo projeto:
-- CreateTab(nome, ícone)
-- CreateToggle(id, estadoInicial, callback)
local MainTab = Window:CreateTab("Anime Dice", "🎲")

-- ==========================================================
-- ESTADO
-- ==========================================================

local loops = {
    BuyBestDice = false,
    CollectCash = false,
    AutoRebirth = false,
    AutoUpgrade = false,
    AutoEquipBest = false,
    SellAll = false,
}

local running = true

-- ==========================================================
-- REFERÊNCIAS
-- ==========================================================

local Network
local RollService
local RollRE
local SetAutoRollRemote

local PlotService
local PlotRE
local CollectBalanceRemote
local EquipBestRemote

local RebirthService
local RebirthRE
local RebirthRemote

local Framework
local Features
local DataControllerModule

local Packages
local PackageNetwork
local ClientCommModule
local ClientComm

local DiceShopService
local BuyDiceRemote
local EquipDiceRemote

local UpgradesFolder
local UpgradeModule
local BuyUpgradeRemote

local SellUtilModule
local SellUtil

-- ==========================================================
-- RESOLVE DOS OBJETOS DO JOGO
-- ==========================================================

local function resolveServices()
    if not running then
        return
    end

    Network = Network or ReplicatedStorage:FindFirstChild("Network")

    if Network then
        RollService = RollService or Network:FindFirstChild("RollService")
        RollRE = RollRE or (RollService and RollService:FindFirstChild("RE"))
        SetAutoRollRemote = SetAutoRollRemote
            or (RollRE and RollRE:FindFirstChild("SetAutoRoll"))

        PlotService = PlotService or Network:FindFirstChild("PlotService")
        PlotRE = PlotRE or (PlotService and PlotService:FindFirstChild("RE"))
        CollectBalanceRemote = CollectBalanceRemote
            or (PlotRE and PlotRE:FindFirstChild("CollectBalance"))
        EquipBestRemote = EquipBestRemote
            or (PlotRE and PlotRE:FindFirstChild("EquipBest"))

        RebirthService = RebirthService
            or Network:FindFirstChild("RebirthService")
        RebirthRE = RebirthRE
            or (RebirthService and RebirthService:FindFirstChild("RE"))
        RebirthRemote = RebirthRemote
            or (RebirthRE and RebirthRE:FindFirstChild("Rebirth"))
    end

    Framework = Framework or ReplicatedStorage:FindFirstChild("Framework")
    Features = Features or (Framework and Framework:FindFirstChild("Features"))

    if Features then
        local dataFolder = Features:FindFirstChild("Data")
        DataControllerModule = DataControllerModule
            or (dataFolder and dataFolder:FindFirstChild("DataController"))

        UpgradesFolder = UpgradesFolder or Features:FindFirstChild("Upgrades")
        UpgradeModule = UpgradeModule
            or (UpgradesFolder and UpgradesFolder:FindFirstChild("Upgrades"))

        local selling = Features:FindFirstChild("Selling")
        SellUtilModule = SellUtilModule
            or (selling and selling:FindFirstChild("SellUtil"))
    end

    Packages = Packages or ReplicatedStorage:FindFirstChild("Packages")
    PackageNetwork = PackageNetwork
        or (Packages and Packages:FindFirstChild("Network"))
    ClientCommModule = ClientCommModule
        or (PackageNetwork and PackageNetwork:FindFirstChild("ClientComm"))

    if ClientCommModule and not ClientComm then
        local ok, module = pcall(require, ClientCommModule)

        if ok and type(module) == "table" and type(module.new) == "function" then
            local okNew, comm = pcall(function()
                return module.new(PackageNetwork)
            end)

            if okNew and comm then
                ClientComm = comm

                pcall(function()
                    DiceShopService = ClientComm:GetSignal("DiceShopService")

                    if DiceShopService then
                        BuyDiceRemote = DiceShopService:GetSignal("BuyDice")
                        EquipDiceRemote = DiceShopService:GetSignal("EquipDice")
                    end
                end)
            end
        end
    end

    if UpgradeModule and not BuyUpgradeRemote then
        local ok, module = pcall(require, UpgradeModule)

        if ok and module then
            pcall(function()
                local client = module.Client

                if client and type(client.GetSignal) == "function" then
                    BuyUpgradeRemote = client:GetSignal(Network, "BuyUpgrade")
                end
            end)

            if not BuyUpgradeRemote and type(module.GetSignal) == "function" then
                pcall(function()
                    BuyUpgradeRemote = module:GetSignal("BuyUpgrade")
                end)
            end
        end
    end

    if SellUtilModule and not SellUtil then
        pcall(function()
            SellUtil = require(SellUtilModule)
        end)
    end
end

-- Resolver em segundo plano, sem bloquear a criação dos toggles.
task.spawn(function()
    local deadline = os.clock() + 10

    while running and os.clock() < deadline do
        resolveServices()

        if Network then
            break
        end

        task.wait(0.15)
    end
end)

-- ==========================================================
-- DATA
-- ==========================================================

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

-- ==========================================================
-- AUTO ROLL
-- ==========================================================

local function setAutoRoll(value)
    resolveServices()

    if not SetAutoRollRemote then
        return false
    end

    return pcall(function()
        SetAutoRollRemote:FireServer(value == true)
    end)
end

-- ==========================================================
-- BUY BEST DICE
-- ==========================================================

local function buyBestDiceOnce()
    resolveServices()

    if not BuyDiceRemote or not EquipDiceRemote then
        return false
    end

    local data = getAllPlayerData()

    if type(data) ~= "table" or type(data.OwnedDice) ~= "table" then
        return false
    end

    local candidates = {}

    for name, diceData in pairs(data.OwnedDice) do
        if type(diceData) == "table" then
            candidates[#candidates + 1] = {
                name = name,
                data = diceData,
            }
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

    local money = tonumber(data.Money)

    if not money then
        return false
    end

    for _, candidate in ipairs(candidates) do
        local price = tonumber(candidate.data and candidate.data.price)

        if price and price <= money then
            local okBuy = pcall(function()
                BuyDiceRemote:Fire(candidate.name)
            end)

            if okBuy then
                task.wait(0.3)

                pcall(function()
                    EquipDiceRemote:Fire(candidate.name)
                end)
            end

            return okBuy
        end
    end

    return false
end

-- ==========================================================
-- COLLECT CASH
-- ==========================================================

local function collectCashOnce()
    resolveServices()

    if not CollectBalanceRemote then
        return false
    end

    return pcall(function()
        CollectBalanceRemote:FireServer()
    end)
end

-- ==========================================================
-- AUTO REBIRTH
-- ==========================================================

local function rebirthOnce()
    resolveServices()

    if not RebirthRemote then
        return false
    end

    return pcall(function()
        RebirthRemote:FireServer()
    end)
end

-- ==========================================================
-- AUTO EQUIP BEST
-- ==========================================================

local function equipBestOnce()
    resolveServices()

    if not EquipBestRemote then
        return false
    end

    return pcall(function()
        EquipBestRemote:FireServer()
    end)
end

-- ==========================================================
-- AUTO UPGRADE
-- ==========================================================

local function getUpgradeContainer()
    resolveServices()

    return UpgradesFolder and UpgradesFolder:FindFirstChild("Upgrades")
end

local function getUpgradePrice(upgrade)
    if not upgrade then
        return nil
    end

    local attribute = upgrade:GetAttribute("price")

    if attribute ~= nil then
        return tonumber(attribute)
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

local function autoUpgradeOnce()
    local folder = getUpgradeContainer()

    if not folder or not BuyUpgradeRemote then
        return false
    end

    local data = getAllPlayerData()
    local money = data and tonumber(data.Money)

    if not money then
        return false
    end

    local upgraded = false

    for _, upgrade in ipairs(folder:GetChildren()) do
        local price = getUpgradePrice(upgrade)

        if price and price <= money then
            local ok = pcall(function()
                BuyUpgradeRemote:Fire(upgrade)
            end)

            if ok then
                upgraded = true
            end
        end
    end

    return upgraded
end

-- ==========================================================
-- SELL ALL
-- ==========================================================

local function getSellService()
    resolveServices()

    if not PackageNetwork or not ClientCommModule then
        return nil
    end

    local ok, module = pcall(require, ClientCommModule)

    if not ok or type(module) ~= "table" or type(module.new) ~= "function" then
        return nil
    end

    local okComm, comm = pcall(function()
        return module.new(Network)
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

    return nil
end

local function getInventorySlots()
    local data = getAllPlayerData()

    if type(data) == "table" and type(data.Inventory) == "table" then
        return data.Inventory.Slots
    end

    local inventory = player:FindFirstChild("Inventory")

    return inventory and inventory:FindFirstChild("Slots")
end

local function sellAllOnce()
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
            local units =
                tonumber(slot.totalUnits)
                or tonumber(slot.units)
                or 1

            totalUnits = totalUnits + units

            sales[#sales + 1] = {
                key = slot.key,
                totalUnits = units,
            }
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

    return pcall(function()
        if type(sellInventory) == "function" then
            sellInventory(summary)
        elseif sellInventory.InvokeServer then
            sellInventory:InvokeServer(summary)
        end
    end)
end

-- ==========================================================
-- LOOPS
-- ==========================================================

local function startLoop(name, callback, delay)
    loops[name] = true

    task.spawn(function()
        while running and loops[name] and not Window.Unloaded do
            pcall(callback)
            task.wait(delay)
        end
    end)
end

local function stopAll()
    running = false

    for name in pairs(loops) do
        loops[name] = false
    end

    pcall(function()
        setAutoRoll(false)
    end)
end

-- ==========================================================
-- TOGGLES
-- ==========================================================

MainTab:CreateToggle("Auto Roll", false, function(value)
    setAutoRoll(value)
end)

MainTab:CreateToggle("Buy Best Dice", false, function(value)
    loops.BuyBestDice = value == true

    if value then
        startLoop("BuyBestDice", buyBestDiceOnce, 1)
    end
end)

MainTab:CreateToggle("Collect Cash", false, function(value)
    loops.CollectCash = value == true

    if value then
        startLoop("CollectCash", collectCashOnce, 1)
    end
end)

MainTab:CreateToggle("Auto Rebirth", false, function(value)
    loops.AutoRebirth = value == true

    if value then
        startLoop("AutoRebirth", rebirthOnce, 1)
    end
end)

MainTab:CreateToggle("Auto Upgrade", false, function(value)
    loops.AutoUpgrade = value == true

    if value then
        startLoop("AutoUpgrade", autoUpgradeOnce, 0.2)
    end
end)

MainTab:CreateToggle("Auto Equip Best", false, function(value)
    loops.AutoEquipBest = value == true

    if value then
        startLoop("AutoEquipBest", equipBestOnce, 0.5)
    end
end)

MainTab:CreateToggle("Sell All", false, function(value)
    loops.SellAll = value == true

    if value then
        startLoop("SellAll", sellAllOnce, 1.5)
    end
end)

if type(Window.OnUnload) == "function" then
    Window:OnUnload(function()
        stopAll()
    end)
end

env.DSHUB_ANIMEDICE_LOADED = true

return Window
