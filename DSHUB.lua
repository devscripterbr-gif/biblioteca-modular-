-- DS HUB v1.0 | Auto Farm Credz
-- Funções ficam neste arquivo. A UI vem de Hub.lua.

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"
local SCRIPT_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/DSHUB.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = getgenv and getgenv() or _G

local function loadLibrary()
    local ok, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)

    if not ok then
        error("[DS HUB] HTTP Hub.lua: " .. tostring(source))
    end

    local fn, compileError = loadstring(source)

    if not fn then
        error("[DS HUB] compilação Hub.lua: " .. tostring(compileError))
    end

    local ran, library = pcall(fn)

    if not ran then
        error("[DS HUB] execução Hub.lua: " .. tostring(library))
    end

    if type(library) ~= "table" or type(library.Init) ~= "function" then
        error("[DS HUB] Hub.lua não retornou Init().")
    end

    return library
end

local Library = loadLibrary()

local Window = Library.Init({
    Name = "DS Hub",
    Version = "v1.0",
    ConfigFile = "DSHub_v1_0_Config.json",
})

-- Separado o Nome do Ícone para respeitar a assinatura de Hub.lua: CreateTab(tabName, icon)
local AutoFarmTab = Window:CreateTab("Auto Farm", "🎟️")

Window:Notify({
    Title = "DS HUB v1.0",
    Description = "Hub carregado.",
    Time = 3,
})

local ENABLED_KEY = "DSHUB_AUTOFARM_CREDZ_ENABLED"

local function readEnabled()
    local value

    pcall(function()
        value = TeleportService:GetTeleportSetting(ENABLED_KEY)
    end)

    if type(value) == "boolean" then
        return value
    end

    return env[ENABLED_KEY] == true
end

local function saveEnabled(value)
    env[ENABLED_KEY] = value == true

    pcall(function()
        TeleportService:SetTeleportSetting(
            ENABLED_KEY,
            value == true
        )
    end)
end

local function getQueue()
    if type(queue_on_teleport) == "function" then
        return queue_on_teleport
    end

    if type(queueonteleport) == "function" then
        return queueonteleport
    end

    if type(syn) == "table"
        and type(syn.queue_on_teleport) == "function"
    then
        return syn.queue_on_teleport
    end

    if type(fluxus) == "table"
        and type(fluxus.queue_on_teleport) == "function"
    then
        return fluxus.queue_on_teleport
    end
end

local function queueResume()
    local queue = getQueue()

    if not queue then
        return false
    end

    local code = string.format([[
        local url = %q
        local ok, src = pcall(function()
            return game:HttpGet(
                url .. "?cb=" .. tostring(os.time())
            )
        end)

        if ok and type(src) == "string" then
            local fn = loadstring(src)
            if fn then
                pcall(fn)
            end
        end
    ]], SCRIPT_URL)

    return pcall(queue, code)
end

local function getFlowEvent()
    local flow = ReplicatedStorage:FindFirstChild("FlowClient")
    local runner = flow and flow:FindFirstChild("ClientRunner")

    return runner and runner:FindFirstChild("Event")
end

-- CORREÇÃO DO ERRO DE VARARGS: Definido (...) e repassado via unpack()
local function fireFlow(...)
    local event = getFlowEvent()

    if not event then
        return false, "FlowClient.ClientRunner.Event não encontrado"
    end

    local args = { ... }
    return pcall(function()
        event:FireServer(unpack(args))
    end)
end

local function teleportPoint(position)
    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")
    local root = character
        and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root then
        return false
    end

    local ok = pcall(function()
        player:RequestStreamAroundAsync(position, 8)
        character:PivotTo(CFrame.new(position))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return ok
end

local function killNPCs(radius)
    local folder = workspace:FindFirstChild("NPCs")
    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")

    if not folder or not flowModule then
        return
    end

    local ok, flow = pcall(require, flowModule)

    if not ok
        or not flow.NPCs
        or type(flow.NPCs.Damage) ~= "function"
    then
        return
    end

    local character = player.Character
    local root = character
        and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("Humanoid") and object.Health > 0 then
            local npc = object:FindFirstAncestorWhichIsA("Model")
            local npcRoot = npc
                and npc:FindFirstChild("HumanoidRootPart")

            if npcRoot
                and (npcRoot.Position - root.Position).Magnitude <= radius
            then
                pcall(
                    flow.NPCs.Damage,
                    object,
                    object.Health + 1
                )
            end
        end
    end
end

local function toEnd()
    local map = workspace:FindFirstChild("Map")

    if not map then
        return false, "Map não encontrado"
    end

    local buildings = map:FindFirstChild("Buildings")
    local customs = buildings
        and buildings:FindFirstChild("CustomsFinal")

    if customs then
        local customsBuilding =
            customs:FindFirstChild("CustomsBuilding")

        local finalDoor =
            customsBuilding
            and customsBuilding:FindFirstChild("FinalDoor")

        local command =
            finalDoor
            and finalDoor:FindFirstChild("Command")

        local commandButton =
            command
            and command:FindFirstChild("CommandButton")

        local holder =
            commandButton
            and commandButton:FindFirstChild("Prompt")

        local prompt

        if holder then
            if holder:IsA("ProximityPrompt") then
                prompt = holder
            else
                prompt = holder:FindFirstChildOfClass("ProximityPrompt")
            end
        end

        if prompt then
            local parent = prompt.Parent
            local cf

            if parent and parent:IsA("Attachment") then
                cf = parent.WorldCFrame
            elseif parent and parent:IsA("BasePart") then
                cf = parent.CFrame
            end

            if cf then
                local destination = cf * CFrame.new(0, 0, -4)
                return teleportPoint(destination.Position)
            end
        end
    end

    return false, "End gate não encontrado"
end

local enabled = readEnabled()
local running = false

local function current()
    return enabled
        and not Window.Unloaded
end

local function startFarm()
    if running or not enabled then
        return
    end

    running = true

    task.spawn(function()
        while current() do
            local lobbies = workspace:FindFirstChild("Lobbies")

            if lobbies then
                queueResume()

                local ok = fireFlow(
                    "LobbyServer",
                    "play"
                )

                if ok then
                    task.wait(3)

                    if not current() then
                        break
                    end

                    queueResume()

                    fireFlow(
                        "LobbyServer",
                        "create",
                        {
                            car = "Claptima",
                            permissions = "Friends",
                            maxPlayers = 1,
                        }
                    )
                end

                task.wait(1)
            else
                local map = workspace:FindFirstChild("Map")

                if map then
                    toEnd()
                    task.wait(1)

                    teleportPoint(
                        Vector3.new(463, 1797, 83540)
                    )

                    local finish = os.clock() + 120

                    while current()
                        and os.clock() < finish
                    do
                        killNPCs(300)
                        task.wait(0.2)
                    end

                    if not current() then
                        break
                    end

                    teleportPoint(
                        Vector3.new(1060, 2287, 83726)
                    )

                    task.wait(3)

                    queueResume()

                    fireFlow(
                        "GameManager",
                        "Replay"
                    )

                    task.wait(1)
                else
                    task.wait(1)
                end
            end
        end

        running = false
    end)
end

AutoFarmTab:CreateToggle(
    "Auto Farm Credz",
    enabled,
    function(value)
        enabled = value
        saveEnabled(value)

        if value then
            queueResume()
            Window:Notify({
                Title = "DS HUB",
                Description = "Auto Farm Credz ativado.",
                Time = 3,
            })
            startFarm()
        else
            Window:Notify({
                Title = "DS HUB",
                Description = "Auto Farm Credz desativado.",
                Time = 3,
            })
        end
    end
)

env.DSHUB_AUTOFARM_LOADED = true

if enabled then
    task.defer(startFarm)
end

return Window
