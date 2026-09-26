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
    if type(queue_on_teleport) == "function" then
        return queue_on_teleport
    end
    if type(queueonteleport) == "function" then
        return queueonteleport
    end
    if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then
        return syn.queue_on_teleport
    end
    if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then
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
            return game:HttpGet(url .. "?cb=" .. tostring(os.time()))
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

local enabled = readSetting(ENABLED_KEY) == true
local running = false

local WAIT_AFTER_SERVER_CHANGE = 5
local waitForNewServer = enabled
    and readSetting(PHASE_KEY) == "WaitingForServerTransition"

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
-- Player freeze system
-- ----------------------------------------------------------
local frozenCharacter = nil
local frozenHumanoid = nil
local frozenRoot = nil
local frozenValues = nil
local frozenControls = nil

local function getPlayerControls()
    local playerScripts = player:FindFirstChild("PlayerScripts")
    local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")

    if not playerModule then
        return nil
    end

    local ok, module = pcall(require, playerModule)
    if not ok or not module or type(module.GetControls) ~= "function" then
        return nil
    end

    local okControls, controls = pcall(function()
        return module:GetControls()
    end)

    if okControls and controls then
        return controls
    end
end

local function freezePlayer()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root then
        return false
    end

    if frozenCharacter == character
        and frozenHumanoid == humanoid
        and frozenRoot == root
    then
        humanoid.WalkSpeed = 0
        humanoid.AutoRotate = false

        pcall(function()
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end)

        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        if frozenControls then
            pcall(function()
                frozenControls:Disable()
            end)
        end

        return true
    end

    frozenCharacter = character
    frozenHumanoid = humanoid
    frozenRoot = root

    frozenValues = {
        WalkSpeed = humanoid.WalkSpeed,
        AutoRotate = humanoid.AutoRotate,
        UseJumpPower = humanoid.UseJumpPower,
        JumpPower = humanoid.JumpPower,
        JumpHeight = humanoid.JumpHeight,
        JumpingEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping),
    }

    humanoid.WalkSpeed = 0
    humanoid.AutoRotate = false

    pcall(function()
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end)

    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    frozenControls = getPlayerControls()
    if frozenControls then
        pcall(function()
            frozenControls:Disable()
        end)
    end

    return true
end

local function unfreezePlayer()
    if frozenHumanoid and frozenHumanoid.Parent and frozenValues then
        local h = frozenHumanoid
        local r = frozenRoot

        pcall(function()
            h.WalkSpeed = frozenValues.WalkSpeed
            h.AutoRotate = frozenValues.AutoRotate
            h.UseJumpPower = frozenValues.UseJumpPower
            h.JumpPower = frozenValues.JumpPower
            h.JumpHeight = frozenValues.JumpHeight
            h:SetStateEnabled(Enum.HumanoidStateType.Jumping, frozenValues.JumpingEnabled)
        end)

        if r and r.Parent then
            pcall(function()
                r.Anchored = false
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    if frozenControls then
        pcall(function()
            frozenControls:Enable()
        end)
    end

    frozenCharacter = nil
    frozenHumanoid = nil
    frozenRoot = nil
    frozenValues = nil
    frozenControls = nil
end

player.CharacterAdded:Connect(function(character)
    if not enabled then
        return
    end

    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid and enabled then
            task.wait(0.25)
            freezePlayer()
        end
    end)
end)

-- Loop de controle e paralisia do personagem
RunService.Heartbeat:Connect(function()
    if not enabled or not frozenHumanoid or not frozenHumanoid.Parent then
        return
    end

    pcall(function()
        frozenHumanoid.WalkSpeed = 0
        frozenHumanoid.AutoRotate = false
        frozenHumanoid.JumpPower = 0
        frozenHumanoid.JumpHeight = 0
        frozenHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end)

    local root = frozenRoot
        or (frozenCharacter and frozenCharacter:FindFirstChild("HumanoidRootPart"))

    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if frozenControls then
        pcall(function()
            frozenControls:Disable()
        end)
    end
end)

-- ----------------------------------------------------------
-- Noclip System (Permite entrar na DoorR sem colisões)
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
-- Remote helpers
-- ----------------------------------------------------------
local function getFlowEvent()
    local flow = ReplicatedStorage:FindFirstChild("FlowClient")
    local runner = flow and flow:FindFirstChild("ClientRunner")
    return runner and runner:FindFirstChild("Event")
end

local function fireFlow(...)
    local event = getFlowEvent()
    if not event then
        return false, "FlowClient.ClientRunner.Event não encontrado"
    end

    local args = {...}
    return pcall(function()
        event:FireServer(unpack(args))
    end)
end

local function removeHelicopters()
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") and object.Name == "Helicopter" then
            pcall(function()
                object:Destroy()
            end)
        end
    end
end

-- ----------------------------------------------------------
-- Character teleport & Teleports Module
-- ----------------------------------------------------------
local teleports = {}

local function stream(position)
    pcall(function()
        player:RequestStreamAroundAsync(position, 5)
    end)
end

function teleports:GetEndZ()
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, object in ipairs(playerGui:GetDescendants()) do
            if object:IsA("TextLabel")
                and string.find(object.Text, "Mexico", 1, true)
            then
                local currentObject = object.Parent
                while currentObject and currentObject ~= playerGui do
                    local value = tonumber(currentObject.Name:match("^Border_(-?[%d%.]+)$"))
                    if value then
                        return value
                    end
                    currentObject = currentObject.Parent
                end
            end
        end
    end
end

function teleports:GetEndPrompt()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
    if not customs then
        return nil
    end

    local customsBuilding = customs:FindFirstChild("CustomsBuilding")
    local finalDoor = customsBuilding and customsBuilding:FindFirstChild("FinalDoor")
    local command = finalDoor and finalDoor:FindFirstChild("Command")
    local commandButton = command and command:FindFirstChild("CommandButton")
    local holder = commandButton and commandButton:FindFirstChild("Prompt")

    if holder then
        if holder:IsA("ProximityPrompt") then
            return holder
        end
        local direct = holder:FindFirstChildOfClass("ProximityPrompt")
        if direct then
            return direct
        end
    end

    for _, candidate in ipairs(customs:GetDescendants()) do
        if candidate:IsA("ProximityPrompt")
            and candidate.ActionText == "Activate"
            and candidate:FindFirstAncestor("FinalDoor")
        then
            return candidate
        end
    end
end

function teleports:GetEndAnchor(endZ, direction)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local source = root and root.Position or Vector3.new(500, 2000, endZ)

    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local best = source
    local bestDistance = math.huge

    if buildings then
        for _, building in ipairs(buildings:GetChildren()) do
            if building:IsA("Model") then
                local ok, pivot = pcall(building.GetPivot, building)
                if ok then
                    if building.Name == "CustomsFinal" then
                        return pivot:PointToWorldSpace(Vector3.new(-44.4001, 4.65, -16.5))
                    end

                    local distance = math.abs(endZ - pivot.Position.Z)
                    local side = (endZ - pivot.Position.Z) * direction
                    if side >= -500 and distance < bestDistance then
                        best = pivot.Position
                        bestDistance = distance
                    end
                end
            end
        end
    end

    return Vector3.new(best.X, best.Y + 30, endZ - direction * 35)
end

function teleports:GetEndPromptDestination(prompt, direction)
    local holder = prompt and prompt.Parent
    local holderCFrame

    if holder and holder:IsA("Attachment") then
        holderCFrame = holder.WorldCFrame
    elseif holder and holder:IsA("BasePart") then
        holderCFrame = holder.CFrame
    end

    if not holderCFrame then
        return nil
    end

    local outward = holderCFrame.LookVector
    if outward.Z * direction > 0 then
        outward = -outward
    end

    if math.abs(outward.Z) < 0.25 then
        outward = Vector3.new(0, 0, -direction)
    end

    local position = holderCFrame.Position + outward * 4
    return CFrame.lookAt(
        position,
        Vector3.new(holderCFrame.Position.X, position.Y, holderCFrame.Position.Z),
        Vector3.yAxis
    )
end

function teleports:Move(destination)
    if not current() or typeof(destination) ~= "CFrame" then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    local ok = pcall(function()
        root.Anchored = false
        
        if humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            RunService.Heartbeat:Wait()
        end

        character:PivotTo(destination)
        root.CFrame = destination

        for _ = 1, 8 do
            if not current() then break end
            root.CFrame = destination
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            RunService.Stepped:Wait()
        end
    end)

    return ok
end

local function moveThreeTimes(destination)
    for i = 1, 3 do
        if not current() then return false end
        task.wait(0.5)
        if not current() then return false end
        if not teleports:Move(destination) then return false end
    end
    return true
end

local function getFinalDoor()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
    local customsBuilding = customs and customs:FindFirstChild("CustomsBuilding")
    return customsBuilding and customsBuilding:FindFirstChild("FinalDoor")
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

-- ----------------------------------------------------------
-- Fast Timer Parser & Detector
-- ----------------------------------------------------------
local function parseTimerText(text)
    text = tostring(text or "")
    text = text:gsub("<[^>]->", "")
    text = text:gsub("[%s\194\160\226\128\175]+", " ")
    
    local minutes, seconds = text:match("(%d+)%s*[mM]%s*(%d+)%s*[sS]")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end

    minutes, seconds = text:match("(%d+)%s*:%s*(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end

    local onlySeconds = text:match("(%d+)%s*[sS]")
    if onlySeconds then
        return tonumber(onlySeconds)
    end

    local number = text:match("(%d+)")
    if number then
        return tonumber(number)
    end

    return nil
end

local function getTimerLabel()
    local finalDoor = getFinalDoor()
    if not finalDoor then return nil end

    local timerModel = finalDoor:FindFirstChild("Timer")
    local surfaceGui = timerModel and timerModel:FindFirstChild("SurfaceGui")
    local timerFrame = surfaceGui and surfaceGui:FindFirstChild("Timer")
    local timeLabel = timerFrame and timerFrame:FindFirstChild("Time")

    if timeLabel and (timeLabel:IsA("TextLabel") or timeLabel:IsA("TextButton")) then
        return timeLabel
    end

    for _, object in ipairs(finalDoor:GetDescendants()) do
        if object.Name == "Time" and (object:IsA("TextLabel") or object:IsA("TextButton")) then
            return object
        end
    end

    return nil
end

local function waitForTimerZero(timeout)
    local deadline = os.clock() + (timeout or 180)

    while current() and os.clock() < deadline do
        local label = getTimerLabel()
        if label and label.Parent then
            local remaining = parseTimerText(label.Text)
            
            if remaining ~= nil and remaining <= 2 then
                print("[DS HUB] Cronómetro em <= 2s! Disparando teleportes no servidor...")
                return true
            end
        end
        task.wait(0.05)
    end

    return false
end

-- ----------------------------------------------------------
-- Activation & Teleport Executions
-- ----------------------------------------------------------
local function fireFinalDoorPrompt()
    local prompt
    local deadline = os.clock() + 15

    while current() and os.clock() < deadline do
        prompt = getExactFinalPrompt()
        if prompt and prompt.Parent then break end
        task.wait(0.20)
    end

    if not prompt or not prompt.Parent then return false end

    for attempt = 1, 3 do
        if not current() then return false end

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

        task.wait(0.5)
        if not prompt.Enabled or not prompt.Parent then
            return true
        end
    end

    return true
end

local function teleportCFrame(destination)
    if typeof(destination) ~= "CFrame" then return false end
    pcall(function() player:RequestStreamAroundAsync(destination.Position, 12) end)
    return teleports:Move(destination)
end

local function runDoorRSideTeleports()
    local directions = {
        Vector3.new(0, 0, -10), -- Frente
        Vector3.new(0, 0, 10),  -- Trás
        Vector3.new(10, 0, 0),  -- Direita
        Vector3.new(-10, 0, 0), -- Esquerda
    }

    for idx, offsetDir in ipairs(directions) do
        if not current() then return false end

        local base = getDoorRCFrame()
        if not base then return false end

        local targetPosition = base.Position + (base.RightVector * offsetDir.X) + (base.LookVector * offsetDir.Z)
        local targetCFrame = CFrame.new(targetPosition) * base.Rotation

        print("[DS HUB] Teleporte real servidor " .. idx .. "/4...")
        
        teleportCFrame(targetCFrame)
        task.wait(0.50)

        base = getDoorRCFrame() or base
        teleportCFrame(base)
        task.wait(0.10)
    end

    return true
end

function teleports:ToEnd()
    local endZ = self:GetEndZ()
    if not endZ then return false, "End position unavailable" end

    local start = workspace:FindFirstChildOfClass("SpawnLocation")
    local direction = (not start or endZ >= start.Position.Z) and 1 or -1

    local prompt = self:GetEndPrompt()
    if prompt then
        local destination = self:GetEndPromptDestination(prompt, direction)
        if destination and moveThreeTimes(destination) then return true end
    end

    local anchor = self:GetEndAnchor(endZ, direction)
    stream(anchor)

    if not teleports:Move(CFrame.lookAt(anchor, anchor + Vector3.new(0, 0, direction), Vector3.yAxis)) then
        return false, "Fallback teleport failed"
    end

    local expires = os.clock() + 12
    while os.clock() < expires and current() do
        prompt = self:GetEndPrompt()
        if prompt then
            local destination = self:GetEndPromptDestination(prompt, direction)
            if destination and moveThreeTimes(destination) then return true end
        end
        task.wait(0.2)
    end

    return false, "End gate prompt unavailable"
end

local function waitForEndScreen()
    local deadline = os.clock() + 20
    while current() and os.clock() < deadline do
        local endScreen = workspace:FindFirstChild("EndScreen", true)
        if endScreen then return true end
        task.wait(0.25)
    end
    return true
end

local function waitForOpeningAnimationToFinish(timeout)
    task.wait(2)
    return current()
end

-- ----------------------------------------------------------
-- Process state machine
-- ----------------------------------------------------------
local function waitSeconds(seconds)
    local deadline = os.clock() + seconds
    while current() and os.clock() < deadline do
        task.wait(0.1)
    end
    return current()
end

local function lobbyPhase()
    if not workspace:FindFirstChild("Lobbies") then
        return false
    end

    writeSetting(PHASE_KEY, "LobbyPlay")
    queueResume()

    local ok = fireFlow("LobbyServer", "play")
    if not ok then
        task.wait(2)
        return true
    end

    if not waitSeconds(2) then return true end

    writeSetting(PHASE_KEY, "LobbyCreate")
    queueResume()
    fireFlow("LobbyServer", "create", {
        car = "Claptima",
        permissions = "Friends",
        maxPlayers = 1,
    })

    local deadline = os.clock() + 90
    while current() and os.clock() < deadline do
        if workspace:FindFirstChild("Map") or not workspace:FindFirstChild("Lobbies") then
            break
        end
        task.wait(0.25)
    end

    return true
end

local function gamePhase()
    local map = workspace:FindFirstChild("Map")
    if not map then return false end

    writeSetting(PHASE_KEY, "GameEnd")

    -- 1) Chega ao Command
    if not teleports:ToEnd() then
        task.wait(1)
        return true
    end

    if not waitSeconds(0.75) then return true end
    removeHelicopters()

    -- 2) Ativa a porta no Command
    writeSetting(PHASE_KEY, "ActivatingFinalDoor")
    fireFinalDoorPrompt()

    -- 3) Espera a porta abrir
    writeSetting(PHASE_KEY, "WaitingDoorOpening")
    waitForOpeningAnimationToFinish(15)
    if not waitSeconds(1) then return true end

    -- 4) Teleporta para a DoorR
    writeSetting(PHASE_KEY, "DoorR")
    local doorRCFrame = getDoorRCFrame()
    if doorRCFrame then
        teleportCFrame(doorRCFrame)
    end

    -- 5) Aguarda o tempo do temporizador chegar a <= 2s
    writeSetting(PHASE_KEY, "WaitingTime")
    waitForTimerZero(180)

    if not current() then return true end

    -- 6) Executa os 4 teleportes desancorados de 0.5s cada
    writeSetting(PHASE_KEY, "DoorRSideTeleports")
    runDoorRSideTeleports()

    if not current() then return true end

    -- 7) Espera pela EndScreen e envia o Replay
    writeSetting(PHASE_KEY, "WaitingEndScreen")
    waitForEndScreen()

    writeSetting(PHASE_KEY, "WaitingForServerTransition")
    queueResume()
    fireFlow("GameManager", "Replay")

    while current() do
        task.wait(1)
    end

    return true
end

local function start()
    if running then return end
    running = true
    freezePlayer()

    task.spawn(function()
        while current() do
            freezePlayer()
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
        if not enabled then unfreezePlayer() end
    end)
end

-- ----------------------------------------------------------
-- Toggle
-- ----------------------------------------------------------
if type(Window.OnUnload) == "function" then
    Window:OnUnload(function()
        enabled = false
        running = false
        unfreezePlayer()
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
            freezePlayer()
            queueResume()
            start()
        else
            running = false
            writeSetting(PHASE_KEY, "Stopped")
            unfreezePlayer()
        end
    end
)

if enabled then
    removeHelicopters()
    freezePlayer()
    task.defer(start)
end

env.DSHUB_AUTOFARM_LOADED = true
return Window
