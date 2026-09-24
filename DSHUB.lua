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

        root.Anchored = true
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
        Anchored = root.Anchored,
    }

    humanoid.WalkSpeed = 0
    humanoid.AutoRotate = false

    pcall(function()
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end)

    root.Anchored = true
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    frozenControls = getPlayerControls()
    if frozenControls then
        pcall(function()
            -- Desliga apenas os controles de movimento; a câmera continua livre.
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
                r.Anchored = frozenValues.Anchored
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
        root.Anchored = true
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

local function getFlowModule(forceRefresh)
    if forceRefresh then
        flowCache = nil
    end

    if flowCache
        and type(flowCache) == "table"
        and flowCache.NPCs
        and type(flowCache.NPCs.Damage) == "function"
    then
        return flowCache
    end

    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")
        or ReplicatedStorage:WaitForChild("FlowClient", 10)

    if not flowModule then
        return nil
    end

    local ok, flow = pcall(require, flowModule)
    if ok and type(flow) == "table" then
        flowCache = flow
        return flow
    end

    flowCache = nil
    return nil
end

local function getNPCHumanoids(folder)
    if not folder then
        return {}
    end

    local ok, result = pcall(function()
        if type(folder.QueryDescendants) == "function" then
            return folder:QueryDescendants("Humanoid")
        end
        return nil
    end)

    if ok and type(result) == "table" then
        return result
    end

    local humanoids = {}
    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("Humanoid") then
            humanoids[#humanoids + 1] = object
        end
    end
    return humanoids
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
    if not folder then
        return 0
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return 0
    end

    local flow = getFlowModule()
    if not flow or not flow.NPCs or type(flow.NPCs.Damage) ~= "function" then
        flow = getFlowModule(true)
    end

    if not flow or not flow.NPCs or type(flow.NPCs.Damage) ~= "function" then
        return 0
    end

    local humanoids = getNPCHumanoids(folder)
    local count = 0

    for _, humanoid in ipairs(humanoids) do
        if humanoid
            and humanoid.Parent
            and humanoid.Health > 0
        then
            local npc = humanoid:FindFirstAncestorWhichIsA("Model")
            local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

            if npcRoot
                and (npcRoot.Position - root.Position).Magnitude <= radius
            then
                -- Repete o mesmo método do RUNAWAYS original para garantir
                -- que NPCs recém-carregados também recebam o dano final.
                for _ = 1, 3 do
                    if humanoid.Health <= 0 or not humanoid.Parent then
                        break
                    end

                    local dealt = pcall(
                        flow.NPCs.Damage,
                        humanoid,
                        humanoid.Health + 1
                    )

                    if dealt then
                        count += 1
                    end

                    task.wait(0.05)
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

local function getFinalDoor()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
    local customsBuilding = customs and customs:FindFirstChild("CustomsBuilding")
    local finalDoor = customsBuilding and customsBuilding:FindFirstChild("FinalDoor")
    return finalDoor
end

local function getExactFinalPrompt()
    local finalDoor = getFinalDoor()
    local command = finalDoor and finalDoor:FindFirstChild("Command")
    local commandButton = command and command:FindFirstChild("CommandButton")
    local holder = commandButton and commandButton:FindFirstChild("Prompt")

    if holder then
        if holder:IsA("ProximityPrompt") then
            return holder
        end

        local prompt = holder:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            return prompt
        end

        local descendants = holder:GetDescendants()
        for _, object in ipairs(descendants) do
            if object:IsA("ProximityPrompt") then
                return object
            end
        end
    end

    -- Fallback restricted to FinalDoor, so unrelated prompts are never fired.
    if finalDoor then
        for _, object in ipairs(finalDoor:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                return object
            end
        end
    end
end

local function getDoorRCFrame()
    local finalDoor = getFinalDoor()
    local doorR = finalDoor and finalDoor:FindFirstChild("DoorR", true)

    if not doorR then
        return nil
    end

    if doorR:IsA("BasePart") then
        return doorR.CFrame
    end

    if doorR:IsA("Model") then
        local ok, pivot = pcall(doorR.GetPivot, doorR)
        if ok and pivot then
            return pivot
        end
    end

    return nil
end

local function fireFinalDoorPrompt()
    local prompt = getExactFinalPrompt()

    if not prompt or not prompt.Parent then
        return false
    end

    if type(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)
        if ok then
            return true
        end
    end

    -- Fallback for executors that do not expose fireproximityprompt.
    local ok = pcall(function()
        local oldDuration = prompt.HoldDuration
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
        prompt.HoldDuration = oldDuration
    end)

    return ok
end

local function getTimerLabel()
    local finalDoor = getFinalDoor()
    if not finalDoor then
        return nil
    end

    -- Exact path shown in the Explorer screenshots:
    -- FinalDoor > Command > Screen > SurfaceGui > Frame > Timer > Time
    local command = finalDoor:FindFirstChild("Command")
    local screen = command and command:FindFirstChild("Screen")
    local surfaceGui = screen and screen:FindFirstChild("SurfaceGui")
    local frame = surfaceGui and surfaceGui:FindFirstChild("Frame")
    local timer = frame and frame:FindFirstChild("Timer")
    local timeLabel = timer and timer:FindFirstChild("Time")

    if timeLabel
        and (timeLabel:IsA("TextLabel")
            or timeLabel:IsA("TextButton")
            or timeLabel:IsA("TextBox"))
    then
        return timeLabel
    end

    -- Fallback: only search the same FinalDoor for an object named Time.
    for _, object in ipairs(finalDoor:GetDescendants()) do
        if object.Name == "Time"
            and (object:IsA("TextLabel")
                or object:IsA("TextButton")
                or object:IsA("TextBox"))
        then
            return object
        end
    end
end

local function parseTimerText(text)
    text = tostring(text or "")

    -- Screenshot format: "2m 00s".
    local minutes, seconds = text:match("(%d+)%s*[mM]%s*(%d+)%s*[sS]")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end

    -- Accept common variants too, without replacing the Time label logic.
    minutes, seconds = text:match("(%d+)%s*:%s*(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end

    local onlySeconds = text:match("^(%d+)%s*[sS]$")
    if onlySeconds then
        return tonumber(onlySeconds)
    end

    local number = text:match("^(%d+)$")
    if number then
        return tonumber(number)
    end

    return nil
end

local function waitForTimerZero(timeout)
    local deadline = os.clock() + (timeout or 180)

    while current() and os.clock() < deadline do
        local label = getTimerLabel()

        if label then
            local remaining = parseTimerText(label.Text)
            if remaining ~= nil and remaining <= 0 then
                return true
            end
        end

        task.wait(0.1)
    end

    return false
end

local function teleportFromDoorR(directionVector, seconds)
    local base = getDoorRCFrame()
    if not base then
        return false
    end

    -- Direction is relative to DoorR's own orientation.
    local offset = base.RightVector * directionVector.X
        + base.UpVector * directionVector.Y
        + base.LookVector * directionVector.Z

    if offset.Magnitude <= 0.001 then
        return false
    end

    local sidePosition = base.Position + offset.Unit * 10

    -- Preserve exactly the DoorR rotation while moving 10 studs.
    local sideDestination = CFrame.new(sidePosition) * base.Rotation

    if not teleportCFrame(sideDestination) then
        return false
    end

    task.wait(seconds or 0.50)

    -- Always return to the original DoorR point before the next direction.
    return teleportCFrame(base)
end

local function runDoorRSideTeleports()
    local base = getDoorRCFrame()
    if not base then
        return false
    end

    local directions = {
        {X = 0, Y = 0, Z = -1}, -- frente
        {X = 0, Y = 0, Z = 1},  -- trás
        {X = 1, Y = 0, Z = 0},  -- direita
        {X = -1, Y = 0, Z = 0}, -- esquerda
    }

    for _, direction in ipairs(directions) do
        if not current() then
            return false
        end

        if not teleportFromDoorR(direction, 0.50) then
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
-- DoorR / EndScreen process helpers
-- ----------------------------------------------------------

local function teleportCFrame(destination)
    if typeof(destination) ~= "CFrame" then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    pcall(function()
        player:RequestStreamAroundAsync(destination.Position, 12)
    end)

    return teleports:Move(destination)
end

local function waitForEndScreen()
    while current() do
        local endScreen = workspace:FindFirstChild("EndScreen", true)

        if endScreen and endScreen:IsA("Model") then
            return true
        end

        task.wait(0.25)
    end

    return false
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

    -- 1) Carrega o final usando a cadeia antiga e os 3 teleportes de 1s.
    local ok = teleports:ToEnd()
    if not ok then
        task.wait(1)
        return true
    end

    if not waitSeconds(0.5) then
        return true
    end

    removeHelicopters()

    -- 2) Vai para o DoorR, que é o ponto inicial dos quatro teleportes.
    writeSetting(PHASE_KEY, "DoorR")

    local doorRCFrame = getDoorRCFrame()
    if not doorRCFrame then
        task.wait(1)
        return true
    end

    if not teleportCFrame(doorRCFrame) then
        task.wait(1)
        return true
    end

    -- 3) Dispara especificamente o ProximityPrompt de
    -- FinalDoor > Command > CommandButton > Prompt.
    fireFinalDoorPrompt()

    -- 4) Não usa um timer interno de 2 minutos.
    -- O cronômetro oficial é o TextLabel "Time" do mapa.
    writeSetting(PHASE_KEY, "WaitingTime")

    if not waitForTimerZero(180) then
        return true
    end

    if not current() then
        return true
    end

    -- 5) Quando o Time chegar a 0:
    -- frente -> volta DoorR -> trás -> volta -> direita -> volta -> esquerda -> volta.
    -- Cada posição lateral permanece por exatamente 0.50s.
    writeSetting(PHASE_KEY, "DoorRSideTeleports")

    if not runDoorRSideTeleports() then
        task.wait(1)
        return true
    end

    if not current() then
        return true
    end

    -- 6) Só depois do último retorno ao DoorR espera o EndScreen.
    writeSetting(PHASE_KEY, "WaitingEndScreen")

    if not waitForEndScreen() then
        return true
    end

    -- 7) EndScreen encontrado: Replay uma única vez e não executa
    -- nenhuma outra etapa nesta instância.
    writeSetting(PHASE_KEY, "WaitingForServerTransition")
    queueResume()
    fireFlow("GameManager", "Replay")

    while current() do
        task.wait(1)
    end

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
