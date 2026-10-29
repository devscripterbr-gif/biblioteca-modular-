-- ============================================================
-- DSHUB.lua — Farm Hub (auto-contido)
-- Uso: loadstring(game:HttpGet(".../DSHUB.lua"))()
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

-- [3] Carrega a biblioteca de UI via loadstring
local LIB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/main/Hub.lua"

local DSHubLibrary
do
    local ok, src = pcall(game.HttpGet, game, LIB_URL)
    if not ok or not src or src == "" then
        warn("[DS HUB] Falha ao baixar biblioteca:", LIB_URL)
        return
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[DS HUB] Erro compilando biblioteca:", err)
        return
    end
    local ok2, lib = pcall(fn)
    if not ok2 or type(lib) ~= "table" or not lib.Init then
        warn("[DS HUB] Biblioteca inválida (sem Init).")
        return
    end
    DSHubLibrary = lib
    _G.DSHubLibrary = lib
end

-- [4] Modules do jogo
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
if not Modules then
    warn("[DS HUB] Módulos do jogo não encontrados!")
    return
end

local VoxelLookup   = require(Modules:WaitForChild("VoxelLookup"))
local ItemStates    = require(Modules.Databanks:WaitForChild("ItemStates"))
local ItemData      = require(Modules.Databanks:WaitForChild("ItemData"))
local FishingModule = require(Modules.Tools.Fishing)
local GlobalData    = require(Modules.Databanks:WaitForChild("GlobalData"))

-- [5] Flags globais
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

-- [6] Remotes
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

-- [7] GC do cache
task.spawn(function()
    while task.wait(30) do
        if _G.DSHub_Kill then break end
        Cache = {}
        collectgarbage("collect")
    end
end)

-- [8] Hook de pesca
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

-- [9] ProcessBlock
local function ProcessBlock(block, rootPos, ActiveRemotes, curTime)
    if isTeleporting or _G.DSHub_Kill then return end

    local blockWorldPos
    if block:IsA("BasePart") then
        blockWorldPos = block.Position
    elseif block:IsA("Model") then
        blockWorldPos = block:GetPivot().Position
    end
    if not blockWorldPos then return end

    local dist = (blockWorldPos - rootPos).Magnitude

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

    local vPos = block:GetAttribute("VoxelPosition")
    if not vPos then return end

    local st = block:GetAttribute("State")
    local key = tostring(vPos)
    local lowerName = string.lower(block.Name)
    local itemID = block:GetAttribute("ID")
    local info = itemID and ItemData.IDLookup[itemID] and ItemData[ItemData.IDLookup[itemID]]

    local isTree = (info and (info.TYPE == "Tree" or info.TYPE == "Log"))
                or string.find(lowerName, "tree")
                or string.find(lowerName, "wood")
                or string.find(lowerName, "log")

    if _G.AutoHarvest and not isTree and dist <= 18 and (st == ItemStates.RIPE or st == ItemStates.READY) then
        task.spawn(function() pcall(function() ActiveRemotes.Harvest:InvokeServer(vPos) end) end)
    end

    if _G.AutoMine and dist <= 20 then
        local typeStr = info and string.lower(info.TYPE or "") or ""
        local metaStr = info and string.lower(info.META_TYPE or "") or ""
        if string.find(lowerName,"ore") or string.find(lowerName,"copper") or string.find(lowerName,"rock")
        or string.find(lowerName,"stone") or string.find(typeStr,"rock") or string.find(typeStr,"ore")
        or string.find(metaStr,"rock") or string.find(metaStr,"ore") or block:GetAttribute("IsOre") then
            local mKey = key .. "_m"
            if not Cache[mKey] or (curTime - Cache[mKey] > 0.2) then
                Cache[mKey] = curTime
                task.spawn(function() pcall(function() ActiveRemotes.Mine:InvokeServer(vPos) end) end)
            end
        end
    end

    if _G.AutoWater and dist <= 18 and block.Name == "Farmland" and st ~= ItemStates.WATERED and st ~= ItemStates.PERFECT then
        local wKey = key .. "_w"
        if not Cache[wKey] or (curTime - Cache[wKey] > 0.45) then
            Cache[wKey] = curTime
            task.spawn(function() pcall(function() ActiveRemotes.Water:InvokeServer(vPos) end) end)
        end
    end

    if _G.AutoFertilize and dist <= 18 and block.Name == "Farmland" and st ~= ItemStates.FERTILIZED and st ~= ItemStates.PERFECT then
        local fKey = key .. "_f"
        if not Cache[fKey] or (curTime - Cache[fKey] > 0.5) then
            Cache[fKey] = curTime
            task.spawn(function() pcall(function() ActiveRemotes.Fertilize:InvokeServer(vPos) end) end)
        end
    end

    if _G.AutoFarm and dist <= 18 and block.Name == "Farmland" then
        local x, y, z = tostring(vPos.X), tostring(vPos.Y + 1), tostring(vPos.Z)
        if not (VoxelLookup[x] and VoxelLookup[x][y] and VoxelLookup[x][y][z]) then
            local pKey = key .. "_p"
            if not Cache[pKey] or (curTime - Cache[pKey] > 0.5) then
                Cache[pKey] = curTime
                task.spawn(function()
                    pcall(function() ActiveRemotes.Plant:InvokeServer(Vector3.new(vPos.X, vPos.Y+1, vPos.Z)) end)
                end)
            end
        end
    end

    if _G.AutoChop and dist <= 20 and isTree and not IsFruitTree(block) then
        local cKey = key .. "_c"
        if not Cache[cKey] or (curTime - Cache[cKey] > 0.2) then
            Cache[cKey] = curTime
            task.spawn(function() pcall(function() ActiveRemotes.Chop:InvokeServer(vPos) end) end)
        end
    end
end

-- [10] Loop principal
task.spawn(function()
    local now = tick
    while task.wait(0.03) do
        if _G.DSHub_Kill then break end
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
            for i = 1, #children do
                ProcessBlock(children[i], rootPos, ActiveRemotes, curTime)
            end
        end)
    end
end)

-- [11] UI via DSHubLibrary
local Hub = DSHubLibrary.Init({
    Name       = "DS HUB FS",
    Version    = "v2.1",
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

print("[DS HUB] Iniciado via loadstring ✔")
