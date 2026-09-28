-- ==========================================================
-- DS HUB | Anime Dice / Gaming Spirit
-- DSHUB.lua - versão corrigida
-- ==========================================================

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = (getgenv and getgenv()) or _G

-- ==========================================================
-- CARREGA A UI
-- ==========================================================

local function loadHub()
    local ok, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)

    if not ok or type(source) ~= "string" then
        error("[DS HUB] Falha ao baixar Hub.lua: " .. tostring(source))
    end

    if type(loadstring) ~= "function" then
        error("[DS HUB] Este executor não possui loadstring.")
    end

    local fn, err = loadstring(source)
    if not fn then
        error("[DS HUB] Hub.lua não compilou: " .. tostring(err))
    end

    local okRun, library = pcall(fn)
    if not okRun then
        error("[DS HUB] Erro no Hub.lua: " .. tostring(library))
    end

    if type(library) ~= "table" or type(library.Init) ~= "function" then
        error("[DS HUB] Biblioteca inválida.")
    end

    return library
end

local Library = loadHub()

local Window = Library.Init({
    Name = "DS Hub",
    Version = "AD v2",
    ConfigFile = "DSHub_AnimeDice_Config.json",
})

env.DSHUB_CURRENT_WINDOW = Window

local MainTab = Window:CreateTab("Anime Dice", "🎲")

-- ==========================================================
-- ESTADO
-- ==========================================================

local running = true

local loops = {
    BuyBestDice = false,
    CollectCash = false,
    AutoRebirth = false,
    AutoUpgrade = false,
    AutoEquipBest = false,
    SellAll = false,
}

-- ==========================================================
-- REFERÊNCIAS
-- ==========================================================

local Network
local Framework
local Features

local RollRE
local SetAutoRollRemote

local PlotRE
local CollectBalanceRemote
local EquipBestRemote

local RebirthRE
local RebirthRemote

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

local resolving = false

-- ==========================================================
-- UTILITÁRIOS
-- ==========================================================

local function findChild(parent, name)
    if not parent then
        return nil
    end

    local ok, result = pcall(function()
        return parent:FindFirstChild(name)
    end)

    return ok and result or nil
end

local function getMoney(data)
    if type(data) ~= "table" then
        return nil
    end

    for _, key in ipairs({"Money", "Cash", "Coins", "Balance"}) do
        local value = tonumber(data[key])
        if value then
            return value
        end
    end

    return nil
end

-- Aceita RemoteEvent, RemoteFunction e os wrappers usados pelo ClientComm.
local function invokeRemote(remote, ...)
    if not remote then
        return false, "remote inexistente"
    end

    local args = table.pack(...)

    local ok, result = pcall(function()
        if typeof(remote) == "Instance" then
            if remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args, 1, args.n))
                return true
            elseif remote:IsA("RemoteFunction") then
                return remote:InvokeServer(table.unpack(args, 1, args.n))
            end
        end

        if type(remote) == "function" then
            return remote(table.unpack(args, 1, args.n))
        end

        if type(remote.Fire) == "function" then
            return remote:Fire(table.unpack(args, 1, args.n))
        end

        if type(remote.Invoke) == "function" then
            return remote:Invoke(table.unpack(args, 1, args.n))
        end

        if type(remote.Call) == "function" then
            return remote:Call(table.unpack(args, 1, args.n))
        end

        if type(remote.Send) == "function" then
            return remote:Send(table.unpack(args, 1, args.n))
        end

        error("objeto não possui Fire/Invoke/Call/Send")
    end)

    if ok then
        return true, result
    end

    return false, result
end

local function getDataController()
    if not DataControllerModule then
        return nil
    end

    local ok, controller = pcall(require, DataControllerModule)
    if ok and controller then
        return controller
    end

    return nil
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
-- RESOLUÇÃO DOS SERVIÇOS
-- ==========================================================

local function resolveClientComm()
    if ClientComm then
        return ClientComm
    end

    if not ClientCommModule then
        return nil
    end

    local ok, module = pcall(require, ClientCommModule)
    if not ok or type(module) ~= "table" or type(module.new) ~= "function" then
        return nil
    end

    -- O ClientComm pertence a Packages.Network. O script antigo
    -- usava Network em Sell All, o que fazia essa parte falhar.
    local constructors = {
        PackageNetwork,
        ReplicatedStorage,
        Network,
    }

    for _, parent in ipairs(constructors) do
        if parent then
            local okNew, comm = pcall(function()
                return module.new(parent)
            end)

            if okNew and comm then
                ClientComm = comm
                return comm
            end
        end
    end

    return nil
end

local function resolveServices()
    if not running or resolving then
        return
    end

    resolving = true

    pcall(function()
        Network = Network or findChild(ReplicatedStorage, "Network")

        if Network then
            local rollService = findChild(Network, "RollService")
            local rollFolder = findChild(rollService, "RE")
            RollRE = RollRE or rollFolder

            SetAutoRollRemote = SetAutoRollRemote
                or findChild(rollFolder, "SetAutoRoll")

            local plotService = findChild(Network, "PlotService")
            PlotRE = PlotRE or findChild(plotService, "RE")

            CollectBalanceRemote = CollectBalanceRemote
                or findChild(PlotRE, "CollectBalance")

            EquipBestRemote = EquipBestRemote
                or findChild(PlotRE, "EquipBest")

            local rebirthService = findChild(Network, "RebirthService")
            RebirthRE = RebirthRE or findChild(rebirthService, "RE")

            RebirthRemote = RebirthRemote
                or findChild(RebirthRE, "Rebirth")
        end

        Framework = Framework or findChild(ReplicatedStorage, "Framework")
        Features = Features or findChild(Framework, "Features")

        if Features then
            local dataFolder = findChild(Features, "Data")
            DataControllerModule = DataControllerModule
                or findChild(dataFolder, "DataController")

            UpgradesFolder = UpgradesFolder or findChild(Features, "Upgrades")
            UpgradeModule = UpgradeModule
                or findChild(UpgradesFolder, "Upgrades")

            local selling = findChild(Features, "Selling")
            SellUtilModule = SellUtilModule
                or findChild(selling, "SellUtil")
        end

        Packages = Packages or findChild(ReplicatedStorage, "Packages")
        PackageNetwork = PackageNetwork
            or findChild(Packages, "Network")

        ClientCommModule = ClientCommModule
            or findChild(PackageNetwork, "ClientComm")

        local comm = resolveClientComm()

        if comm then
            pcall(function()
                DiceShopService = DiceShopService
                    or comm:GetSignal("DiceShopService")

                if DiceShopService then
                    BuyDiceRemote = BuyDiceRemote
                        or DiceShopService:GetSignal("BuyDice")

                    EquipDiceRemote = EquipDiceRemote
                        or DiceShopService:GetSignal("EquipDice")
                end
            end)
        end

        -- Primeiro tenta a API do módulo de upgrades.
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

        -- Fallback para uma RemoteEvent/RemoteFunction tradicional.
        if not BuyUpgradeRemote and Network then
            local upgradeService = findChild(Network, "UpgradeService")
                or findChild(Network, "UpgradesService")

            local upgradeRE = findChild(upgradeService, "RE")

            BuyUpgradeRemote = findChild(upgradeRE, "BuyUpgrade")
                or findChild(upgradeService, "BuyUpgrade")
        end

        if SellUtilModule and not SellUtil then
            pcall(function()
                SellUtil = require(SellUtilModule)
            end)
        end
    end)

    resolving = false
end

task.spawn(function()
    local deadline = os.clock() + 15

    while running and os.clock() < deadline do
        resolveServices()

        if Network and DataControllerModule then
            break
        end

        task.wait(0.2)
    end
end)

-- ==========================================================
-- AUTO ROLL
-- ==========================================================

local function setAutoRoll(value)
    resolveServices()

    local ok = invokeRemote(SetAutoRollRemote, value == true)

    if not ok then
        return false
    end

    return true
end

-- ==========================================================
-- BUY BEST DICE
-- ==========================================================

local function getDiceTables(data)
    if type(data) ~= "table" then
        return {}
    end

    local result = {}

    -- Preferências: dados de loja/itens disponíveis.
    for _, key in ipairs({
        "DiceShop",
        "ShopDice",
        "Dice",
        "AvailableDice",
        "OwnedDice",
    }) do
        if type(data[key]) == "table" then
            result[#result + 1] = data[key]
        end
    end

    return result
end

local function buildDiceCandidates(data)
    local candidates = {}
    local seen = {}

    for _, diceTable in ipairs(getDiceTables(data)) do
        for name, diceData in pairs(diceTable) do
            if type(diceData) == "table" and not seen[name] then
                local price = tonumber(
                    diceData.price
                    or diceData.Price
                    or diceData.cost
                    or diceData.Cost
                )

                local luck = tonumber(
                    diceData.luck
                    or diceData.Luck
                    or diceData.multiplier
                    or diceData.Multiplier
                    or diceData.chance
                ) or 0

                local owned = diceData.owned
                if owned == nil then
                    owned = diceData.Owned
                end

                candidates[#candidates + 1] = {
                    name = tostring(name),
                    price = price,
                    luck = luck,
                    owned = owned == true,
                }

                seen[name] = true
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.luck ~= b.luck then
            return a.luck > b.luck
        end

        return (a.price or 0) > (b.price or 0)
    end)

    return candidates
end

local function buyBestDiceOnce()
    resolveServices()

    if not BuyDiceRemote then
        return false
    end

    local data = getAllPlayerData()
    local money = getMoney(data)

    if not data or not money then
        return false
    end

    local candidates = buildDiceCandidates(data)

    for _, candidate in ipairs(candidates) do
        -- Se o jogo informa que já possui o dado, não tenta comprá-lo.
        if not candidate.owned and candidate.price and candidate.price <= money then
            local ok = invokeRemote(BuyDiceRemote, candidate.name)

            if ok then
                task.wait(0.25)

                if EquipDiceRemote then
                    invokeRemote(EquipDiceRemote, candidate.name)
                end

                return true
            end
        end
    end

    return false
end

-- ==========================================================
-- COLLECT CASH
-- ==========================================================

local function collectCashOnce()
    resolveServices()

    return invokeRemote(CollectBalanceRemote)
end

-- ==========================================================
-- REBIRTH
-- ==========================================================

local function rebirthOnce()
    resolveServices()

    return invokeRemote(RebirthRemote)
end

-- ==========================================================
-- EQUIP BEST
-- ==========================================================

local function equipBestOnce()
    resolveServices()

    return invokeRemote(EquipBestRemote)
end

-- ==========================================================
-- AUTO UPGRADE
-- ==========================================================

local function getUpgradePrice(value)
    if value == nil then
        return nil
    end

    if type(value) == "number" then
        return value
    end

    if type(value) == "table" then
        return tonumber(
            value.price
            or value.Price
            or value.cost
            or value.Cost
        )
    end

    if typeof(value) == "Instance" then
        local attribute = value:GetAttribute("price")
            or value:GetAttribute("Price")
            or value:GetAttribute("cost")
            or value:GetAttribute("Cost")

        if attribute ~= nil then
            return tonumber(attribute)
        end

        local obj = findChild(value, "price")
            or findChild(value, "Price")
            or findChild(value, "cost")
            or findChild(value, "Cost")

        if obj and obj:IsA("ValueBase") then
            return tonumber(obj.Value)
        end
    end

    return nil
end

local function getUpgradeCandidates()
    resolveServices()

    local result = {}

    -- Caso exista uma pasta real de upgrades.
    if UpgradesFolder then
        local container = findChild(UpgradesFolder, "Upgrades")

        if container and container:IsA("Folder") then
            for _, child in ipairs(container:GetChildren()) do
                result[#result + 1] = {
                    id = child.Name,
                    object = child,
                    price = getUpgradePrice(child),
                }
            end
        end
    end

    -- Caso Upgrades seja um ModuleScript, usa os dados exportados.
    if UpgradeModule then
        local ok, module = pcall(require, UpgradeModule)

        if ok and type(module) == "table" then
            local source = module.Upgrades
                or module.Data
                or module.List
                or module

            if type(source) == "table" then
                for id, value in pairs(source) do
                    local price = getUpgradePrice(value)

                    if price then
                        result[#result + 1] = {
                            id = tostring(id),
                            object = value,
                            price = price,
                        }
                    end
                end
            end
        end
    end

    table.sort(result, function(a, b)
        return (a.price or math.huge) < (b.price or math.huge)
    end)

    return result
end

local function autoUpgradeOnce()
    resolveServices()

    if not BuyUpgradeRemote then
        return false
    end

    local data = getAllPlayerData()
    local money = getMoney(data)

    if not money then
        return false
    end

    local upgraded = false

    for _, upgrade in ipairs(getUpgradeCandidates()) do
        if upgrade.price and upgrade.price <= money then
            -- Primeiro tenta o identificador, que é o formato mais comum.
            local ok = invokeRemote(BuyUpgradeRemote, upgrade.id)

            -- Se falhar e houver objeto, tenta o objeto como fallback.
            if not ok and upgrade.object ~= nil then
                ok = invokeRemote(BuyUpgradeRemote, upgrade.object)
            end

            if ok then
                upgraded = true
                task.wait(0.08)
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

    local comm = resolveClientComm()
    if not comm then
        return nil
    end

    local ok, service = pcall(function()
        return comm:GetFunction("SellService")
    end)

    if ok and service then
        return service
    end

    return nil
end

local function getInventorySlots()
    local data = getAllPlayerData()

    if type(data) == "table"
        and type(data.Inventory) == "table"
        and type(data.Inventory.Slots) == "table" then

        return data.Inventory.Slots
    end

    local inventory = player:FindFirstChild("Inventory")
    return inventory and inventory:FindFirstChild("Slots")
end

local function sellAllOnce()
    resolveServices()

    local sellService = getSellService()
    if not sellService then
        return false
    end

    local okFunction, sellInventory = pcall(function()
        return sellService:GetFunction("SellInventory")
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

    local function addSlot(slot)
        if type(slot) ~= "table" or slot.key == nil then
            return
        end

        local units = tonumber(
            slot.totalUnits
            or slot.units
            or slot.amount
            or slot.Amount
        ) or 1

        if units <= 0 then
            return
        end

        totalUnits = totalUnits + units

        sales[#sales + 1] = {
            key = slot.key,
            totalUnits = units,
        }
    end

    -- Corrige o caso em que Slots é um dicionário, não um array.
    if type(slots) == "table" then
        for _, slot in pairs(slots) do
            addSlot(slot)
        end
    elseif typeof(slots) == "Instance" then
        for _, slot in ipairs(slots:GetChildren()) do
            local key = slot:GetAttribute("key") or slot.Name
            local units = slot:GetAttribute("totalUnits")
                or slot:GetAttribute("units")
                or 1

            addSlot({
                key = key,
                totalUnits = units,
            })
        end
    end

    if totalUnits <= 0 then
        return false
    end

    local summary = sales

    if type(SellUtil) == "table"
        and type(SellUtil.CreateSummary) == "function" then

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

    return invokeRemote(sellInventory, summary)
end

-- ==========================================================
-- LOOPS
-- ==========================================================

local function startLoop(name, callback, delay)
    if loops[name] then
        return
    end

    loops[name] = true

    task.spawn(function()
        while running and loops[name] and not Window.Unloaded do
            local ok, err = pcall(callback)

            if not ok then
                warn("[DS HUB][" .. name .. "] " .. tostring(err))
            end

            task.wait(delay)
        end
    end)
end

local function setLoop(name, value, callback, delay)
    loops[name] = value == true

    if loops[name] then
        startLoop(name, callback, delay)
    end
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
-- UI
-- ==========================================================

MainTab:CreateToggle("Auto Roll", false, function(value)
    setAutoRoll(value)
end)

MainTab:CreateToggle("Buy Best Dice", false, function(value)
    setLoop("BuyBestDice", value, buyBestDiceOnce, 1)
end)

MainTab:CreateToggle("Collect Cash", false, function(value)
    setLoop("CollectCash", value, collectCashOnce, 1)
end)

MainTab:CreateToggle("Auto Rebirth", false, function(value)
    setLoop("AutoRebirth", value, rebirthOnce, 1)
end)

MainTab:CreateToggle("Auto Upgrade", false, function(value)
    setLoop("AutoUpgrade", value, autoUpgradeOnce, 0.25)
end)

MainTab:CreateToggle("Auto Equip Best", false, function(value)
    setLoop("AutoEquipBest", value, equipBestOnce, 0.6)
end)

MainTab:CreateToggle("Sell All", false, function(value)
    setLoop("SellAll", value, sellAllOnce, 1.5)
end)

if type(Window.OnUnload) == "function" then
    Window:OnUnload(function()
        stopAll()
    end)
end

env.DSHUB_ANIMEDICE_LOADED = true

return Window
