-- ==========================================================
-- DS HUB v1.0 | RUNAWAYS | Auto Farm Credz
-- UI: Hub.lua
-- ==========================================================

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"
local SCRIPT_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/DSHUB.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = getgenv and getgenv() or _G

-- ----------------------------------------------------------
-- Hub loader
-- ----------------------------------------------------------
local function loadHub()
    local ok, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)

    if not ok or type(source) ~= "string" then
        error("[DS HUB] Hub.lua: " .. tostring(source))
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
    Version = "v1.0",
    ConfigFile = "DSHub_v1_0_Config.json",
})

env.DSHUB_CURRENT_WINDOW = Window

local AutoFarmTab = Window:CreateTab("🎟️ Auto Farm")

-- ----------------------------------------------------------
-- Persistent state
-- ----------------------------------------------------------
local ENABLED_KEY = "DSHUB_AUTOFARM_CREDZ_ENABLED"
local AFK_KEY = "DSHUB_AFK_MODE_ENABLED"
local PHASE_KEY = "DSHUB_AUTOFARM_CREDZ_PHASE"

local function readSetting(key)
    local value
    pcall(function()
        value = TeleportService:GetTeleportSetting(key)
    end)
    if value ~= nil then
        return value
    end
    return env[key]
end

local function writeSetting(key, value)
    env[key] = value
    pcall(function()
        TeleportService:SetTeleportSetting(key, value)
    end)
end

local function getQueue()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
end

local function queueResume()
    local queue = getQueue()
    if not queue then return false end

    local code = string.format([[
        local url = %q
        local ok, src = pcall(function()
            return game:HttpGet(url .. "?cb=" .. tostring(os.time()))
        end)
        if ok and type(src) == "string" then
            local fn = loadstring(src)
            if fn then pcall(fn) end
        end
    ]], SCRIPT_URL)

    return pcall(queue, code)
end

local enabled = readSetting(ENABLED_KEY) == true
local afkEnabled = readSetting(AFK_KEY) == true
local running = false

local setAFKState
local AFKToggleObject = nil

local WAIT_AFTER_SERVER_CHANGE = 5
local waitForNewServer = enabled and readSetting(PHASE_KEY) == "WaitingForServerTransition"

if waitForNewServer then
    writeSetting(PHASE_KEY, "ServerLoading")
    task.wait(WAIT_AFTER_SERVER_CHANGE)
end

local generation = (tonumber(env.DSHUB_CREDZ_GENERATION) or 0) + 1
env.DSHUB_CREDZ_GENERATION = generation

local function current()
    return enabled
        and running
        and env.DSHUB_CREDZ_GENERATION == generation
        and aliveWindow(Window)
end

-- ----------------------------------------------------------
-- AFK Mode System
-- ----------------------------------------------------------
local afkGui = nil
local afkTimerText = nil
local afkStartTime = os.time()

local function createAFKGui()
    if afkGui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DSHUB_AFK_Screen"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0.32, 0)
    title.BackgroundTransparency = 1
    title.Text = "DS HUB — AFK MODE"
    title.TextColor3 = Color3.fromRGB(0, 255, 127)
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local timer = Instance.new("TextLabel")
    timer.Size = UDim2.new(1, 0, 0, 60)
    timer.Position = UDim2.new(0, 0, 0.42, 0)
    timer.BackgroundTransparency = 1
    timer.Text = "Tempo AFK: 00:00:00"
    timer.TextColor3 = Color3.fromRGB(0, 255, 127)
    timer.TextSize = 36
    timer.Font = Enum.Font.Gotham
    timer.Parent = mainFrame

    local exitButton = Instance.new("TextButton")
    exitButton.Size = UDim2.new(0, 220, 0, 45)
    exitButton.Position = UDim2.new(0.5, -110, 0.62, 0)
    exitButton.BackgroundColor3 = Color3.fromRGB(20, 80, 40)
    exitButton.BorderSizePixel = 0
    exitButton.Text = "Desativar AFK Mode"
    exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    exitButton.TextSize = 16
    exitButton.Font = Enum.Font.GothamBold
    exitButton.Parent = mainFrame

    exitButton.MouseButton1Click:Connect(function()
        if AFKToggleObject and type(AFKToggleObject.Set) == "function" then
            AFKToggleObject:Set(false)
        else
            setAFKState(false)
        end
    end)

    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

    afkGui = gui
    afkTimerText = timer
end

local function destroyAFKGui()
    if afkGui then
        afkGui:Destroy()
        afkGui = nil
        afkTimerText = nil
    end
end

setAFKState = function(state)
    if state and not enabled then state = false end

    afkEnabled = state
    writeSetting(AFK_KEY, state)

    pcall(function() RunService:Set3dRenderingEnabled(not state) end)

    if state then
        createAFKGui()
        afkStartTime = os.time()
    else
        destroyAFKGui()
    end
end

task.spawn(function()
    while true do
        if afkEnabled and enabled and afkTimerText then
            local elapsed = os.time() - afkStartTime
            local hours = math.floor(elapsed / 3600)
            local mins = math.floor((elapsed % 3600) / 60)
            local secs = elapsed % 60
            afkTimerText.Text = string.format("Tempo AFK: %02d:%02d:%02d", hours, mins, secs)
        elseif afkEnabled and not enabled then
            setAFKState(false)
        end
        task.wait(1)
    end
end)

-- ----------------------------------------------------------
-- Noclip System
-- ----------------------------------------------------------
RunService.Stepped:Connect(function()
    if not enabled then return end
    local character = player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ----------------------------------------------------------
-- Remote & Object Helpers
-- ----------------------------------------------------------
local function fireFlow(...)
    local flow = ReplicatedStorage:FindFirstChild("FlowClient")
    local runner = flow and flow:FindFirstChild("ClientRunner")
    local event = runner and runner:FindFirstChild("Event")
    if not event then return false end

    local args = {...}
    return pcall(function() event:FireServer(unpack(args)) end)
end

local function removeHelicopters()
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") and object.Name == "Helicopter" then
            pcall(function() object:Destroy() end)
        end
    end
end

local function getFinalDoor()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
    local customsBuilding = customs and customs:FindFirstChild("CustomsBuilding")
    return customsBuilding and customsBuilding:FindFirstChild("FinalDoor")
end

local function getDoorRCFrame()
    local finalDoor = getFinalDoor()
    local doorR = finalDoor and finalDoor:FindFirstChild("DoorR", true)

    if not doorR then return nil end

    if doorR:IsA("BasePart") then
        return doorR.CFrame
    elseif doorR:IsA("Model") then
        local ok, pivot = pcall(doorR.GetPivot, doorR)
        if ok and pivot then return pivot end
    end
    return nil
end

local function getExactFinalPrompt()
    local finalDoor = getFinalDoor()
    if not finalDoor then return nil end

    local command = finalDoor:FindFirstChild("Command")
    local commandButton = command and command:FindFirstChild("CommandButton")
    local promptFolder = commandButton and commandButton:FindFirstChild("Prompt")

    if promptFolder then
        if promptFolder:IsA("ProximityPrompt") then return promptFolder end
        local prompt = promptFolder:FindFirstChildOfClass("ProximityPrompt")
        if prompt then return prompt end
    end

    for _, object in ipairs(finalDoor:GetDescendants()) do
        if object:IsA("ProximityPrompt") then
            return object
        end
    end
    return nil
end

-- ----------------------------------------------------------
-- Teleporte Correto com Sincronização do Servidor
-- ----------------------------------------------------------
local function forceServerTeleport(cframe, anchorAfter)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not root then return false end

    -- 1. Desancora para permitir a movimentação física
    root.Anchored = false
    
    -- 2. Zera as velocidades para o servidor não aplicar rollback por aceleração
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    -- 3. Move a posição do personagem
    character:PivotTo(cframe)
    root.CFrame = cframe

    -- 4. Aguarda o frame do servidor registrar a nova posição
    RunService.Heartbeat:Wait()

    -- 5. Aplica a ancoragem se solicitado
    if anchorAfter then
        root.CFrame = cframe
        root.Anchored = true
    end

    return true
end

local function fireFinalDoorPrompt()
    local prompt
    local deadline = os.clock() + 15

    while current() and os.clock() < deadline do
        prompt = getExactFinalPrompt()
        if prompt and prompt.Parent then break end
        task.wait(0.20)
    end

    if not prompt or not prompt.Parent then return false end

    if type(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt) end)
    end

    pcall(function()
        local duration = prompt.HoldDuration
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait(0.10)
        prompt:InputHoldEnd()
        prompt.HoldDuration = duration
    end)

    return true
end

local function parseTimerText(text)
    text = tostring(text or ""):gsub("<[^>]->", ""):gsub("[%s\194\160\226\128\175]+", " ")
    local minutes, seconds = text:match("(%d+)%s*:%s*(%d+)")
    if minutes and seconds then return tonumber(minutes) * 60 + tonumber(seconds) end
    local secs = text:match("(%d+)")
    if secs then return tonumber(secs) end
    return nil
end

local function getTimerLabel()
    local finalDoor = getFinalDoor()
    if not finalDoor then return nil end

    for _, object in ipairs(finalDoor:GetDescendants()) do
        if object.Name == "Time" and (object:IsA("TextLabel") or object:IsA("TextButton")) then
            return object
        end
    end
    return nil
end

-- ----------------------------------------------------------
-- Fluxo Solicitado
-- ----------------------------------------------------------
local function gamePhase()
    local map = workspace:FindFirstChild("Map")
    if not map then return false end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    
    -- STEP 1: Desativa o Anchored completamente no início
    if root then 
        root.Anchored = false 
    end

    removeHelicopters()
    fireFinalDoorPrompt()

    -- Espera o timer do jogo responder
    local timerStarted = false
    local timeout = os.clock() + 15
    while current() and os.clock() < timeout do
        local label = getTimerLabel()
        if label and label.Text ~= "" then
            timerStarted = true
            break
        end
        task.wait(0.2)
    end

    -- STEP 2: Quando o tempo começa, teleporta para DoorR e ATIVA o Anchored
    local doorCFrame = getDoorRCFrame()
    if doorCFrame then
        forceServerTeleport(doorCFrame, true)
    end

    -- STEP 3: Aguarda o tempo acabar ancorado na DoorR
    if timerStarted then
        while current() do
            local label = getTimerLabel()
            if label then
                local remaining = parseTimerText(label.Text)
                if remaining and remaining <= 1 then
                    break
                end
            end
            task.wait(0.2)
        end
    end

    -- STEP 4: Quando o tempo acaba, desativa Anchored e faz o teleporte final de vitória
    if root then 
        root.Anchored = false 
    end

    if doorCFrame then
        local victoryCFrame = doorCFrame * CFrame.new(0, 0, -10)
        forceServerTeleport(victoryCFrame, true)
    end

    -- Reinicia a partida / Próximo servidor
    task.wait(2)
    writeSetting(PHASE_KEY, "WaitingForServerTransition")
    queueResume()
    fireFlow("GameManager", "Replay")

    while current() do task.wait(1) end
    return true
end

local function lobbyPhase()
    if not workspace:FindFirstChild("Lobbies") then return false end

    writeSetting(PHASE_KEY, "LobbyPlay")
    queueResume()

    fireFlow("LobbyServer", "play")
    task.wait(2)

    writeSetting(PHASE_KEY, "LobbyCreate")
    queueResume()
    fireFlow("LobbyServer", "create", {
        car = "Claptima",
        permissions = "Friends",
        maxPlayers = 1,
    })

    local deadline = os.clock() + 90
    while current() and os.clock() < deadline do
        if workspace:FindFirstChild("Map") or not workspace:FindFirstChild("Lobbies") then break end
        task.wait(0.25)
    end

    return true
end

local function start()
    if running then return end
    running = true

    task.spawn(function()
        while current() do
            removeHelicopters()

            if lobbyPhase() then
                task.wait(0.5)
            elseif gamePhase() then
                task.wait(0.5)
            else
                task.wait(1)
            end
        end

        running = false
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
    end)
end

-- ----------------------------------------------------------
-- Toggles & UI
-- ----------------------------------------------------------
if type(Window.OnUnload) == "function" then
    Window:OnUnload(function()
        enabled = false
        running = false
        setAFKState(false)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
    end)
end

AutoFarmTab:CreateToggle(
    "Auto Farm Credz",
    enabled,
    function(value)
        enabled = value
        writeSetting(ENABLED_KEY, value)

        if value then
            removeHelicopters()
            queueResume()
            start()
            if afkEnabled then setAFKState(true) end
        else
            running = false
            writeSetting(PHASE_KEY, "Stopped")
            setAFKState(false)
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
        end
    end
)

AFKToggleObject = AutoFarmTab:CreateToggle(
    "AFK Mode (Economia)",
    afkEnabled,
    function(value)
        setAFKState(value)
    end
)

if enabled then
    removeHelicopters()
    if afkEnabled then setAFKState(true) end
    task.defer(start)
end

env.DSHUB_AUTOFARM_LOADED = true
return Window
