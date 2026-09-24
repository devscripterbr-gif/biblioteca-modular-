-- ==========================================================
-- DS HUB v1.0 | Auto Farm Credz
-- Somente: 🎟️ Auto Farm -> Auto Farm Credz
-- ==========================================================

local HUB_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/Hub.lua"
local SCRIPT_URL = "https://raw.githubusercontent.com/devscripterbr-gif/biblioteca-modular-/refs/heads/main/DSHUB.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = getgenv and getgenv() or _G

local function getLibrary()
    local ok, source = pcall(function()
        return game:HttpGet(HUB_URL .. "?cb=" .. tostring(os.time()))
    end)

    if not ok or type(source) ~= "string" then
        error("[DS HUB] Hub.lua: " .. tostring(source))
    end

    local fn, err = loadstring(source)

    if not fn then
        error("[DS HUB] Hub.lua compilação: " .. tostring(err))
    end

    local ran, library = pcall(fn)

    if not ran or type(library) ~= "table" or type(library.Init) ~= "function" then
        error("[DS HUB] Hub.lua não retornou uma Library válida.")
    end

    return library
end

env.DSHUB_AUTOFARM_GENERATION = (tonumber(env.DSHUB_AUTOFARM_GENERATION) or 0) + 1
local generation = env.DSHUB_AUTOFARM_GENERATION

local function current()
    return env.DSHUB_AUTOFARM_GENERATION == generation
end

local Library = getLibrary()

local Window = Library.Init({
    Name = "DS Hub",
    Version = "v1.0",
    ConfigFile = "DSHub_v1_0_Config.json",
})

local AutoFarmTab = Window:CreateTab("🎟️ Auto Farm")

local STATE_KEY = "DSHUB_AUTOFARM_CREDZ_ENABLED"

local function readState()
    local value

    pcall(function()
        value = TeleportService:GetTeleportSetting(STATE_KEY)
    end)

    if type(value) == "boolean" then
        return value
    end

    return env[STATE_KEY] == true
end

local function writeState(value)
    env[STATE_KEY] = value == true

    pcall(function()
        TeleportService:SetTeleportSetting(STATE_KEY, value == true)
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

    local ok = pcall(queue, code)
    return ok
end

local function flowEvent()
    local flow = ReplicatedStorage:FindFirstChild("FlowClient")
    local runner = flow and flow:FindFirstChild("ClientRunner")
    return runner and runner:FindFirstChild("Event")
end

local function fireFlow(...)
    local event = flowEvent()

    if not event then
        return false, "ClientRunner.Event não encontrado"
    end

    local ok, err = pcall(function()
        event:FireServer(...)
    end)

    return ok, err
end

local function teleportToPoint(position)
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

    for _, humanoid in folder:QueryDescendants("Humanoid") do
        local npc = humanoid:FindFirstAncestorWhichIsA("Model")
        local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

        if humanoid.Health > 0
            and npcRoot
            and (npcRoot.Position - root.Position).Magnitude <= radius
        then
            local hit = pcall(
                flow.NPCs.Damage,
                humanoid,
                humanoid.Health + 1
            )

            if hit then
                count += 1
            end
        end
    end

    return count
end

local teleports = {}

local function stream(position)
    pcall(function()
        player:RequestStreamAroundAsync(position, 5)
    end)
end

local function notify(text, duration)
    Window:Notify({
        Title = "DS HUB v1.0",
        Description = text,
        Time = duration or 4,
    })
end


function teleports:GetRoadNear(z)
    local map = workspace:FindFirstChild("Map")

    if not map then
        return
    end

    local best
    local bestDistance = math.huge
    local bestArea = 0

    for _, part in map:GetDescendants() do
        local name = part.Name:lower()
        local parentName = part.Parent and part.Parent.Name:lower()

        if part:IsA("BasePart")
            and (name == "road" or name == "sideroad" or parentName == "road")
            and not name:find("pathfinding", 1, true)
            and part.CanCollide
            and part.Transparency < 0.95
        then
            local distance = math.max(math.abs(part.Position.Z - z) - math.max(part.Size.X, part.Size.Z) * 0.5, 0)
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

function teleports:GetEndPrompt()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")

    if not customs then
        return
    end

    local customsBuilding = customs:FindFirstChild("CustomsBuilding")
    local finalDoor = customsBuilding and customsBuilding:FindFirstChild("FinalDoor")
    local command = finalDoor and finalDoor:FindFirstChild("Command")
    local commandButton = command and command:FindFirstChild("CommandButton")
    local holder = commandButton and commandButton:FindFirstChild("Prompt")
    local prompt = holder and (holder:IsA("ProximityPrompt") and holder or holder:FindFirstChildOfClass("ProximityPrompt"))

    if prompt then
        return prompt
    end

    local ok, candidates = pcall(customs.QueryDescendants, customs, "ProximityPrompt")

    if ok then
        for _, candidate in candidates do
            if candidate.ActionText == "Activate" and candidate:FindFirstAncestor("FinalDoor") then
                return candidate
            end
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
        for _, building in buildings:GetChildren() do
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
        return
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
    params.FilterDescendantsInstances = player.Character and { player.Character } or {}

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

function teleports:ParkEndVehicle(vehicle, endZ, direction)
    local chassis = getVehicleChassis(vehicle)

    if not chassis or not vehicle.Parent then
        return
    end

    local road = self:GetRoadNear(endZ)
    local position

    if road then
        position = Vector3.new(
            road.Position.X,
            road.Position.Y + road.Size.Y * 0.5 + 4.5,
            endZ - direction * 28
        )
    else
        local map = workspace:FindFirstChild("Map")
        local buildings = map and map:FindFirstChild("Buildings")
        local customs = buildings and buildings:FindFirstChild("CustomsFinal")
        local ok
        local pivot

        if customs then
            ok, pivot = pcall(customs.GetPivot, customs)
        end

        if ok then
            position = Vector3.new(pivot.Position.X, pivot.Position.Y + 5, endZ - direction * 28)
        end
    end

    if not position then
        return
    end

    local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)

    if look.Magnitude < 0.1 then
        look = Vector3.new(0, 0, direction)
    end

    self:Move(CFrame.lookAt(position, position + look.Unit, Vector3.yAxis), vehicle, false)
end

function teleports:Move(destination, subject, saveLast)
    if typeof(destination) ~= "CFrame" then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root or humanoid.Health <= 0 then
        notify("Character is unavailable.")
        return false
    end

    subject = subject or character

    local mover = subject == character and root or getVehicleChassis(subject)

    if not mover or not subject.Parent then
        notify("Teleport target is unavailable.")
        return false
    end

    local oldLast = self.LastPosition

    if saveLast ~= false then
        self.LastPosition = root.CFrame
    end

    local camera = workspace.CurrentCamera
    local cameraCFrame = camera and camera.CFrame
    local cameraSubject = camera and camera.CameraSubject
    local cameraType = camera and camera.CameraType

    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = cameraCFrame
    end

    local ok, message = pcall(function()
        if subject == character and humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            RunService.Heartbeat:Wait()
        end

        subject:PivotTo(destination * mover.CFrame:Inverse() * subject:GetPivot())
        mover.AssemblyLinearVelocity = Vector3.zero
        mover.AssemblyAngularVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end)

    if camera and camera.Parent then
        camera.CameraSubject = cameraSubject
        camera.CameraType = cameraType
        camera.CFrame = cameraCFrame
    end

    if not ok then
        self.LastPosition = oldLast
        notify("Teleport failed: " .. tostring(message))
        return false
    end

    return true
end

function teleports:GetEndZ()
    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")
    local gui = flowModule and flowModule:FindFirstChild("Gui")
    local distanceModule = gui and gui:FindFirstChild("DistanceToBorderClient")

    if distanceModule then
        local ok, module = pcall(require, distanceModule)

        if ok and type(module) == "table" then
            local callback = module.SetEndPos_event or module.SetEndPos

            if type(callback) == "function" and debug and type(debug.getupvalues) == "function" then
                local read, upvalues = pcall(debug.getupvalues, callback)

                if read and type(upvalues) == "table" then
                    if type(upvalues[1]) == "number" then
                        return upvalues[1]
                    end

                    for _, value in upvalues do
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
        for _, label in playerGui:GetDescendants() do
            if label:IsA("TextLabel") and label.Text:find("Mexico", 1, true) then
                local current = label.Parent

                while current and current ~= playerGui do
                    local value = tonumber(current.Name:match("^Border_(-?[%d%.]+)$"))

                    if value then
                        return value
                    end

                    current = current.Parent
                end
            end
        end
    end
end

function teleports:GetStartCFrame()
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")

    if not spawn or not spawn.Enabled then
        return
    end

    local excludes = { spawn }

    if player.Character then
        excludes[#excludes + 1] = player.Character
    end

    local parameters = RaycastParams.new()

    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = excludes
    parameters.RespectCanCollide = true

    local result = workspace:Raycast(spawn.Position + Vector3.yAxis * 6, -Vector3.yAxis * 20, parameters)
    local y = result and result.Position.Y + 3.5 or spawn.Position.Y + 3

    return CFrame.new(spawn.Position.X, y, spawn.Position.Z) * spawn.CFrame.Rotation
end

function teleports:ToEnd()
    task.spawn(function()
        local endZ = self:GetEndZ()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local vehicle = getCurrentVehicle()
        local mover = vehicle and getVehicleChassis(vehicle) or root

        if not endZ then
            notify("End position is unavailable.")
            return
        end

        if not humanoid or not mover or humanoid.Health <= 0 then
            notify("Character is unavailable.")
            return
        end

        local start = self:GetStartCFrame()
        local direction = (not start or endZ >= start.Position.Z) and 1 or -1
        local prompt = self:GetEndPrompt()

        if prompt then
            local destination = self:GetEndPromptDestination(prompt, direction)

            if destination then
                if vehicle then
                    self.LastPosition = root.CFrame
                    self:ParkEndVehicle(vehicle, endZ, direction)
                    self:Move(destination, nil, false)
                else
                    self:Move(destination)
                end

                return
            end
        end

        local position = self:GetEndAnchor(endZ, direction)

        stream(position)
        prompt = self:GetEndPrompt()

        if prompt then
            local destination = self:GetEndPromptDestination(prompt, direction)

            if destination then
                if vehicle then
                    self.LastPosition = root.CFrame
                    self:ParkEndVehicle(vehicle, endZ, direction)
                    self:Move(destination, nil, false)
                else
                    self:Move(destination)
                end

                return
            end
        end

        local road = self:GetRoadNear(endZ)

        if road then
            position = Vector3.new(
                road.Position.X,
                road.Position.Y + road.Size.Y * 0.5 + 8,
                endZ - direction * 35
            )
        end

        local look = vehicle and Vector3.new(mover.CFrame.LookVector.X, 0, mover.CFrame.LookVector.Z)
            or Vector3.new(0, 0, direction)

        if look.Magnitude < 0.1 then
            look = Vector3.new(0, 0, direction)
        end

        if not self:Move(CFrame.lookAt(position, position + look.Unit, Vector3.yAxis), vehicle or character) then
            return
        end

        mover = vehicle and getVehicleChassis(vehicle) or character:FindFirstChild("HumanoidRootPart")

        local anchored = mover and mover.Anchored

        if mover then
            mover.Anchored = true
        end

        local waited, found = pcall(function()
            local expires = os.clock() + 12
            local loaded
            local refined = false

            repeat
                loaded = self:GetEndPrompt()

                if not loaded and not refined then
                    local map = workspace:FindFirstChild("Map")
                    local buildings = map and map:FindFirstChild("Buildings")
                    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
                    local ok
                    local pivot

                    if customs then
                        ok, pivot = pcall(customs.GetPivot, customs)
                    end

                    if ok then
                        refined = true
                        stream(pivot.Position)
                        loaded = self:GetEndPrompt()
                    end
                end

                if not loaded then
                    task.wait(0.2)
                end
            until loaded or not character.Parent or os.clock() >= expires

            return loaded
        end)

        if mover and mover.Parent then
            mover.Anchored = anchored
        end

        if waited then
            prompt = found
        end

        if prompt then
            local destination = self:GetEndPromptDestination(prompt, direction)

            if destination then
                if vehicle then
                    self:ParkEndVehicle(vehicle, endZ, direction)
                end

                self:Move(destination, nil, false)
                return
            end
        end

        road = self:GetRoadNear(endZ)

        if road then
            if vehicle then
                self:ParkEndVehicle(vehicle, endZ, direction)
            else
                position = Vector3.new(
                    road.Position.X,
                    road.Position.Y + road.Size.Y * 0.5 + 8,
                    endZ - direction * 20
                )
                self:Move(CFrame.lookAt(position, position + Vector3.new(0, 0, direction), Vector3.yAxis), nil, false)
            end
        end

        notify("End gate button is unavailable.")
    end)
end


local enabled = readState()
local running = false

local function valid()
    return current() and enabled and not Window.Unloaded
end

local function waitValid(seconds)
    local expires = os.clock() + seconds

    while valid() and os.clock() < expires do
        task.wait(0.15)
    end

    return valid()
end

local function lobbyPhase()
    if not workspace:FindFirstChild("Lobbies") then
        return false
    end

    notify("Lobbies encontrado.")

    queueResume()

    local ok, err = fireFlow(
        "LobbyServer",
        "play"
    )

    if not ok then
        notify("LobbyServer/play: " .. tostring(err), 6)
        return true
    end

    if not waitValid(3) then
        return true
    end

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
    else
        notify("Lobby criada.")
    end

    return true
end

local function gamePhase()
    local map = workspace:FindFirstChild("Map")

    if not map then
        return false
    end

    notify("Map encontrado. Indo para o fim do jogo.")

    local ok = pcall(function()
        teleports:ToEnd()
    end)

    if not ok then
        notify("Falha no teleporte para o fim.", 6)
        return true
    end

    if not waitValid(1.5) then
        return true
    end

    if not teleportToPoint(Vector3.new(463, 1797, 83540)) then
        notify("Falha ao chegar na posição Credz.", 6)
        return true
    end

    notify("Farm de NPCs: 300 studs / 2 minutos.")

    local finish = os.clock() + 120

    while valid() and os.clock() < finish do
        killNPCs(300)
        task.wait(0.15)
    end

    if not valid() then
        return true
    end

    teleportToPoint(Vector3.new(1060, 2287, 83726))

    if not waitValid(3) then
        return true
    end

    queueResume()

    local replayOk, replayErr = fireFlow(
        "GameManager",
        "Replay"
    )

    if not replayOk then
        notify("GameManager/Replay: " .. tostring(replayErr), 6)
    else
        notify("Replay enviado.")
    end

    return true
end

local function start()
    if running then
        return
    end

    running = true

    task.spawn(function()
        while valid() do
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
        writeState(value)

        if value then
            local queued = queueResume()

            if queued then
                notify("Auto Farm Credz ativado.")
            else
                notify("Ativado. queue_on_teleport não disponível.", 5)
            end

            start()
        else
            notify("Auto Farm Credz desativado.")
        end
    end
)

if enabled then
    task.defer(start)
end

Window:Notify({
    Title = "DS HUB v1.0",
    Description = "🎟️ Auto Farm Credz pronto.",
    Time = 3,
})

env.DSHUB_AUTOFARM_LOADED = true

return Window
