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
local generation = (tonumber(env.DSHUB_CREDZ_GENERATION) or 0) + 1
env.DSHUB_CREDZ_GENERATION = generation

local function current()
    return enabled
        and running
        and env.DSHUB_CREDZ_GENERATION == generation
        and aliveWindow(Window)
end

-- ----------------------------------------------------------
-- Player freeze: movement is disabled while automation runs.
-- Teleports still move the character by CFrame/PivotTo.
-- ----------------------------------------------------------
local frozenCharacter = nil
local frozenHumanoid = nil
local frozenValues = nil

local function freezePlayer()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then
        return false
    end

    if frozenCharacter == character and frozenHumanoid == humanoid then
        humanoid.WalkSpeed = 0
        humanoid.AutoRotate = false
        pcall(function() humanoid.UseJumpPower = true end)
        pcall(function() humanoid.JumpPower = 0 end)
        pcall(function() humanoid.JumpHeight = 0 end)
        pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
        return true
    end

    frozenCharacter = character
    frozenHumanoid = humanoid
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
    pcall(function() humanoid.UseJumpPower = true end)
    pcall(function() humanoid.JumpPower = 0 end)
    pcall(function() humanoid.JumpHeight = 0 end)
    pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)

    return true
end

local function unfreezePlayer()
    if frozenHumanoid and frozenHumanoid.Parent and frozenValues then
        local h = frozenHumanoid
        pcall(function() h.WalkSpeed = frozenValues.WalkSpeed end)
        pcall(function() h.AutoRotate = frozenValues.AutoRotate end)
        pcall(function() h.UseJumpPower = frozenValues.UseJumpPower end)
        pcall(function() h.JumpPower = frozenValues.JumpPower end)
        pcall(function() h.JumpHeight = frozenValues.JumpHeight end)
        pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Jumping, frozenValues.JumpingEnabled) end)
    end

    frozenCharacter = nil
    frozenHumanoid = nil
    frozenValues = nil
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

RunService.Heartbeat:Connect(function()
    if not enabled or not frozenHumanoid or not frozenHumanoid.Parent then
        return
    end

    pcall(function()
        frozenHumanoid.WalkSpeed = 0
        frozenHumanoid.AutoRotate = false
        frozenHumanoid.JumpPower = 0
        frozenHumanoid.JumpHeight = 0
    end)

    local root = frozenCharacter and frozenCharacter:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
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

local flowCache = nil
local function getFlowModule()
    if flowCache then
        return flowCache
    end

    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")
    if not flowModule then
        return nil
    end

    local ok, flow = pcall(require, flowModule)
    if ok and type(flow) == "table" then
        flowCache = flow
        return flow
    end
end

-- ----------------------------------------------------------
-- Character teleport
-- ----------------------------------------------------------
local function teleportCharacter(position)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    pcall(function()
        player:RequestStreamAroundAsync(position, 8)
    end)

    local ok = pcall(function()
        character:PivotTo(CFrame.new(position))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return ok
end

-- ----------------------------------------------------------
-- NPC damage
-- ----------------------------------------------------------
local function killNPCs(radius)
    local folder = workspace:FindFirstChild("NPCs")
    local flow = getFlowModule()

    if not folder or not flow or not flow.NPCs or type(flow.NPCs.Damage) ~= "function" then
        return 0
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return 0
    end

    local count = 0

    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("Humanoid") and object.Health > 0 then
            local npc = object:FindFirstAncestorWhichIsA("Model")
            local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

            if npcRoot and (npcRoot.Position - root.Position).Magnitude <= radius then
                local ok = pcall(flow.NPCs.Damage, object, object.Health + 1)
                if ok then
                    count += 1
                end
            end
        end
    end

    return count
end

-- ----------------------------------------------------------
-- Exact old RUNAWAYS end teleport chain, with 3 load teleports.
-- ----------------------------------------------------------
local teleports = {}

local function stream(position)
    pcall(function()
        player:RequestStreamAroundAsync(position, 5)
    end)
end

function teleports:GetRoadNear(z)
    local map = workspace:FindFirstChild("Map")
    if not map then
        return nil
    end

    local best, bestDistance, bestArea = nil, math.huge, 0

    for _, part in map:GetDescendants() do
        local name = part.Name:lower()
        local parentName = part.Parent and part.Parent.Name:lower()

        if part:IsA("BasePart")
            and (name == "road" or name == "sideroad" or parentName == "road")
            and not name:find("pathfinding", 1, true)
            and part.CanCollide
            and part.Transparency < 0.95
        then
            local distance = math.max(
                math.abs(part.Position.Z - z) - math.max(part.Size.X, part.Size.Z) * 0.5,
                0
            )
            local area = part.Size.X * part.Size.Z

            if distance < bestDistance or distance == bestDistance and area > bestArea then
                best = part
                bestDistance = distance
                bestArea = area
            end
        end
    end

    if bestDistance <= 2000 then
        return best
    end
end

function teleports:GetEndZ()
    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")
    local gui = flowModule and flowModule:FindFirstChild("Gui")
    local distanceModule = gui and gui:FindFirstChild("DistanceToBorderClient")

    if distanceModule then
        local ok, module = pcall(require, distanceModule)
        if ok and type(module) == "table" then
            local callback = module.SetEndPos_event or module.SetEndPos

            if type(callback) == "function"
                and debug
                and type(debug.getupvalues) == "function"
            then
                local got, upvalues = pcall(debug.getupvalues, callback)
                if got and type(upvalues) == "table" then
                    for _, value in pairs(upvalues) do
                        if type(value) == "number" and math.abs(value) > 1000 then
                            return value
                        end
                    end
                end
            end
        end
    end

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
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}

    local result = workspace:Raycast(
        position + Vector3.yAxis * 20,
        Vector3.new(0, -60, 0),
        params
    )

    if result then
        position = Vector3.new(position.X, result.Position.Y + 3.25, position.Z)
    end

    return CFrame.lookAt(
        position,
        Vector3.new(holderCFrame.Position.X, position.Y, holderCFrame.Position.Z),
        Vector3.yAxis
    )
end

function teleports:Move(destination)
    if typeof(destination) ~= "CFrame" then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    local camera = workspace.CurrentCamera
    local oldType = camera and camera.CameraType
    local oldSubject = camera and camera.CameraSubject
    local oldCFrame = camera and camera.CFrame

    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = oldCFrame
    end

    local ok = pcall(function()
        character:PivotTo(destination)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end)

    if camera and camera.Parent then
        camera.CameraSubject = oldSubject
        camera.CameraType = oldType
        camera.CFrame = oldCFrame
    end

    return ok
end

local function moveThreeTimes(destination)
    for i = 1, 3 do
        if not current() then
            return false
        end

        -- 1 segundo antes de cada teleporte = 3 segundos totais de carregamento.
        task.wait(1)

        if not current() then
            return false
        end

        if not teleports:Move(destination) then
            return false
        end
    end

    return true
end

function teleports:ToEnd()
    local endZ = self:GetEndZ()
    if not endZ then
        return false, "End position unavailable"
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false, "Character unavailable"
    end

    local start = workspace:FindFirstChildOfClass("SpawnLocation")
    local direction = (not start or endZ >= start.Position.Z) and 1 or -1

    local prompt = self:GetEndPrompt()
    if prompt then
        local destination = self:GetEndPromptDestination(prompt, direction)
        if destination and moveThreeTimes(destination) then
            return true
        end
    end

    local anchor = self:GetEndAnchor(endZ, direction)
    stream(anchor)

    -- Anchor is used once to force the final area to stream in.
    if not teleports:Move(
        CFrame.lookAt(anchor, anchor + Vector3.new(0, 0, direction), Vector3.yAxis)
    ) then
        return false, "Fallback teleport failed"
    end

    local expires = os.clock() + 12
    while os.clock() < expires and current() do
        prompt = self:GetEndPrompt()
        if prompt then
            local destination = self:GetEndPromptDestination(prompt, direction)
            if destination and moveThreeTimes(destination) then
                return true
            end
        end
        task.wait(0.2)
    end

    return false, "End gate prompt unavailable"
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

local function waitForMap(seconds)
    local deadline = os.clock() + seconds
    while current() and os.clock() < deadline do
        if workspace:FindFirstChild("Map") then
            return true
        end
        task.wait(0.25)
    end
    return workspace:FindFirstChild("Map") ~= nil
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

    if not waitSeconds(3) then
        return true
    end

    writeSetting(PHASE_KEY, "LobbyCreate")
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

    -- Não repete play/create até a pasta Lobbies desaparecer ou Map aparecer.
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
    if not map then
        return false
    end

    writeSetting(PHASE_KEY, "GameEnd")

    local ok = teleports:ToEnd()
    if not ok then
        -- Dá tempo para a estrutura do fim aparecer antes de tentar novamente.
        task.wait(1)
        return true
    end

    if not waitSeconds(0.5) then
        return true
    end

    writeSetting(PHASE_KEY, "Farm")

    if not teleportCharacter(Vector3.new(463, 1797, 83540)) then
        task.wait(1)
        return true
    end

    local deadline = os.clock() + 120
    while current() and os.clock() < deadline do
        killNPCs(300)
        task.wait(0.15)
    end

    if not current() then
        return true
    end

    writeSetting(PHASE_KEY, "Replay")

    teleportCharacter(Vector3.new(1060, 2287, 83726))
    if not waitSeconds(3) then
        return true
    end

    queueResume()
    fireFlow("GameManager", "Replay")

    -- Dá espaço para o replay trocar a cena antes da próxima passagem.
    waitForMap(90)
    return true
end

local function start()
    if running then
        return
    end

    running = true
    freezePlayer()

    task.spawn(function()
        while current() do
            freezePlayer()

            if lobbyPhase() then
                task.wait(0.5)
            elseif gamePhase() then
                task.wait(0.5)
            else
                task.wait(1)
            end
        end

        running = false
        if not enabled then
            unfreezePlayer()
        end
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
    freezePlayer()
    task.defer(start)
end

env.DSHUB_AUTOFARM_LOADED = true
return Window
