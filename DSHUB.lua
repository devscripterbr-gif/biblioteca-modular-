-- DS HUB v1.0 | Auto Farm Credz
-- Somente uma aba e uma função.

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"
local SCRIPT_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/DSHUB.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = getgenv and getgenv() or _G

local function loadHub()
    local ok, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)

    if not ok or type(source) ~= "string" then
        error("[DS HUB] Não conseguiu baixar Hub.lua: " .. tostring(source))
    end

    local fn, compileError = loadstring(source)

    if not fn then
        error("[DS HUB] Hub.lua não compilou: " .. tostring(compileError))
    end

    local ran, library = pcall(fn)

    if not ran or type(library) ~= "table" or type(library.Init) ~= "function" then
        error("[DS HUB] Hub.lua não retornou Library.Init.")
    end

    return library
end

-- Uma nova execução substitui o estado antigo.
env.DSHUB_CREDZ_GENERATION = (tonumber(env.DSHUB_CREDZ_GENERATION) or 0) + 1
local generation = env.DSHUB_CREDZ_GENERATION

local Library = loadHub()

local Window = Library.Init({
    Name = "DS Hub",
    Version = "v1.0",
    ConfigFile = "DSHub_v1_0_Config.json",
})

env.DSHUB_CURRENT_WINDOW = Window

local AutoFarmTab = Window:CreateTab("🎟️ Auto Farm")

local function alive()
    return env.DSHUB_CREDZ_GENERATION == generation
        and Window
        and not Window.Unloaded
end

local ENABLED_KEY = "DSHUB_AUTOFARM_CREDZ_ENABLED"
local PHASE_KEY = "DSHUB_AUTOFARM_CREDZ_PHASE"

local function readSetting(key)
    local value

    local ok = pcall(function()
        value = TeleportService:GetTeleportSetting(key)
    end)

    if ok and value ~= nil then
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

local function queueResume()
    local queue

    if type(queue_on_teleport) == "function" then
        queue = queue_on_teleport
    elseif type(queueonteleport) == "function" then
        queue = queueonteleport
    elseif type(syn) == "table" and type(syn.queue_on_teleport) == "function" then
        queue = syn.queue_on_teleport
    elseif type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then
        queue = fluxus.queue_on_teleport
    end

    if not queue then
        return false
    end

    local code = string.format([[
        local url = %q
        local ok, source = pcall(function()
            return game:HttpGet(url .. "?cb=" .. tostring(os.time()))
        end)
        if ok and type(source) == "string" then
            local fn = loadstring(source)
            if fn then
                pcall(fn)
            end
        end
    ]], SCRIPT_URL)

    local ok = pcall(queue, code)
    return ok
end

local function getFlowEvent()
    local flowClient = ReplicatedStorage:FindFirstChild("FlowClient")
    local clientRunner = flowClient and flowClient:FindFirstChild("ClientRunner")
    return clientRunner and clientRunner:FindFirstChild("Event")
end

local function fireFlow(...)
    local event = getFlowEvent()

    if not event then
        return false, "FlowClient.ClientRunner.Event não encontrado"
    end

    local ok, err = pcall(function()
        event:FireServer(...)
    end)

    return ok, err
end

local function notify(text, duration)
    Window:Notify({
        Title = "DS HUB v1.0",
        Description = text,
        Time = duration or 4,
    })
end

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
        if humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

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
        return 0
    end

    local ok, flow = pcall(require, flowModule)

    if not ok or not flow.NPCs or type(flow.NPCs.Damage) ~= "function" then
        return 0
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return 0
    end

    local count = 0

    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("Humanoid") then
            local npc = object:FindFirstAncestorWhichIsA("Model")
            local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

            if object.Health > 0
                and npcRoot
                and (npcRoot.Position - root.Position).Magnitude <= radius
            then
                local hit = pcall(
                    flow.NPCs.Damage,
                    object,
                    object.Health + 1
                )

                if hit then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- ==========================================================
-- End-game teleport chain, based on the old RUNAWAYS helpers.
-- ==========================================================

local teleports = {}

local function stream(position)
    pcall(function()
        player:RequestStreamAroundAsync(position, 5)
    end)
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
                    local value = tonumber(
                        currentObject.Name:match("^Border_(-?[%d%.]+)$")
                    )

                    if value then
                        return value
                    end

                    currentObject = currentObject.Parent
                end
            end
        end
    end

    return nil
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

    return nil
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
                        return pivot:PointToWorldSpace(
                            Vector3.new(-44.4001, 4.65, -16.5)
                        )
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

    return Vector3.new(
        best.X,
        best.Y + 30,
        endZ - direction * 35
    )
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
    params.FilterDescendantsInstances =
        player.Character and {player.Character} or {}

    local result = workspace:Raycast(
        position + Vector3.yAxis * 20,
        Vector3.new(0, -60, 0),
        params
    )

    if result then
        position = Vector3.new(
            position.X,
            result.Position.Y + 3.25,
            position.Z
        )
    end

    return CFrame.lookAt(
        position,
        Vector3.new(
            holderCFrame.Position.X,
            position.Y,
            holderCFrame.Position.Z
        ),
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
        if humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            RunService.Heartbeat:Wait()
        end

        root.CFrame = destination
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
    local direction = (
        not start or endZ >= start.Position.Z
    ) and 1 or -1

    local prompt = self:GetEndPrompt()

    if prompt then
        local destination = self:GetEndPromptDestination(prompt, direction)

        if destination and self:Move(destination) then
            return true
        end
    end

    local anchor = self:GetEndAnchor(endZ, direction)
    stream(anchor)

    prompt = self:GetEndPrompt()

    if prompt then
        local destination = self:GetEndPromptDestination(prompt, direction)

        if destination and self:Move(destination) then
            return true
        end
    end

    local ok = self:Move(
        CFrame.lookAt(
            anchor,
            anchor + Vector3.new(0, 0, direction),
            Vector3.yAxis
        )
    )

    if not ok then
        return false, "Fallback teleport failed"
    end

    local expires = os.clock() + 12

    while os.clock() < expires do
        prompt = self:GetEndPrompt()

        if prompt then
            local destination = self:GetEndPromptDestination(prompt, direction)

            if destination and self:Move(destination) then
                return true
            end
        end

        task.wait(0.2)
    end

    return false, "End gate prompt unavailable"
end

-- ==========================================================
-- Credz state machine.
-- ==========================================================

local savedEnabled = readSetting(ENABLED_KEY)
local enabled = type(savedEnabled) == "boolean" and savedEnabled or false
local running = false

local function current()
    return alive() and enabled and not Window.Unloaded
end

local function waitUntil(seconds)
    local deadline = os.clock() + seconds

    while current() and os.clock() < deadline do
        task.wait(0.1)
    end

    return current()
end

local function waitForGameOrLobbyChange(seconds)
    local deadline = os.clock() + seconds

    while current() and os.clock() < deadline do
        local mapNow = workspace:FindFirstChild("Map")
        local lobbiesNow = workspace:FindFirstChild("Lobbies")

        if mapNow or not lobbiesNow then
            return
        end

        task.wait(0.25)
    end
end

local function lobbyPhase()
    local lobbies = workspace:FindFirstChild("Lobbies")

    if not lobbies then
        return false
    end

    writeSetting(PHASE_KEY, "LobbyPlay")
    notify("Lobbies encontrado.")

    queueResume()

    local ok, err = fireFlow(
        "LobbyServer",
        "play"
    )

    if not ok then
        notify("LobbyServer/play: " .. tostring(err), 6)
        task.wait(2)
        return true
    end

    if not waitUntil(3) then
        return true
    end

    writeSetting(PHASE_KEY, "LobbyCreate")
    queueResume()

    ok, err = fireFlow(
        "LobbyServer",
        "create",
        {
            car = "Claptima",
            permissions = "Friends",
            maxPlayers = 1
        }
    )

    if not ok then
        notify("LobbyServer/create: " .. tostring(err), 6)
        task.wait(2)
        return true
    end

    notify("Lobby criada. Aguardando entrada no jogo.")

    -- Não repete play/create enquanto a mesma pasta Lobbies ainda existe.
    -- Espera a transição para Map ou a saída de Lobbies.
    waitForGameOrLobbyChange(90)

    return true
end

local function gamePhase()
    local map = workspace:FindFirstChild("Map")

    if not map then
        return false
    end

    writeSetting(PHASE_KEY, "GameEnd")
    notify("Map encontrado. Indo para o fim.")

    local ok, err = teleports:ToEnd()

    if not ok then
        notify("Teleporte para o fim: " .. tostring(err), 6)
        return true
    end

    if not waitUntil(0.5) then
        return true
    end

    writeSetting(PHASE_KEY, "Farm")

    if not teleportCharacter(
        Vector3.new(463, 1797, 83540)
    ) then
        notify("Falha ao chegar no ponto de farm.", 6)
        return true
    end

    notify("Farmando NPCs em 300 studs por 2 minutos.")

    local deadline = os.clock() + 120

    while current() and os.clock() < deadline do
        killNPCs(300)
        task.wait(0.15)
    end

    if not current() then
        return true
    end

    writeSetting(PHASE_KEY, "Replay")

    teleportCharacter(
        Vector3.new(1060, 2287, 83726)
    )

    if not waitUntil(3) then
        return true
    end

    queueResume()

    local replayOk, replayError = fireFlow(
        "GameManager",
        "Replay"
    )

    if not replayOk then
        notify("GameManager/Replay: " .. tostring(replayError), 6)
    else
        notify("Replay enviado.")
    end

    local deadline = os.clock() + 90

    while current() and os.clock() < deadline do
        local lobbiesNow = workspace:FindFirstChild("Lobbies")
        local mapNow = workspace:FindFirstChild("Map")

        if lobbiesNow or not mapNow then
            break
        end

        task.wait(0.25)
    end

    return true
end

local function start()
    if running then
        return
    end

    running = true

    task.spawn(function()
        notify("Auto Farm Credz iniciado.", 3)

        while current() do
            if lobbyPhase() then
                task.wait(0.5)
            elseif gamePhase() then
                task.wait(0.5)
            else
                task.wait(1)
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
        writeSetting(ENABLED_KEY, value)

        if value then
            queueResume()
            start()
            notify("Auto Farm Credz ativado.", 3)
        else
            writeSetting(PHASE_KEY, "Stopped")
            notify("Auto Farm Credz desativado.", 3)
        end
    end
)

Window:Notify({
    Title = "DS HUB v1.0",
    Description = enabled
        and "🎟️ Auto Farm Credz restaurado."
        or "🎟️ Auto Farm Credz pronto.",
    Time = 3,
})

if enabled then
    task.defer(start)
end

env.DSHUB_AUTOFARM_LOADED = true
print("[DS HUB] v1.0 carregado: 🎟️ Auto Farm / Auto Farm Credz")

return Window
