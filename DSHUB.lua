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

-- Quando o toggle continua ativo após Replay/transição de servidor,
-- o novo servidor ganha alguns segundos para terminar de carregar.
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
-- Player freeze: movement is disabled while automation runs.
-- Teleports still move the character by CFrame/PivotTo.
-- ----------------------------------------------------------
local frozenCharacter = nil
local frozenHumanoid = nil
local frozenRoot = nil
local frozenValues = nil
local frozenControls = nil
local teleporting = false

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
        -- Keep controls disabled, but do not anchor during a teleport.
        if not teleporting then
            root.Anchored = true
        end

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
    if not current() then
        return false
    end

    if typeof(destination) ~= "CFrame" then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    local oldAnchored = root.Anchored
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera and camera.CFrame
    local cameraSubject = camera and camera.CameraSubject
    local cameraType = camera and camera.CameraType

    teleporting = true

    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = cameraCFrame
    end

    local ok = pcall(function()
        -- IMPORTANT: an anchored root can leave the server at the old position.
        root.Anchored = false

        if humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            RunService.Heartbeat:Wait()
        end

        character:PivotTo(destination)
        root.CFrame = destination

        -- Keep the exact CFrame for multiple frames so the replicated
        -- character state settles at the destination.
        for _ = 1, 8 do
            if not current() then
                break
            end

            root.CFrame = destination
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
        end
    end)

    if camera and camera.Parent then
        camera.CameraSubject = cameraSubject
        camera.CameraType = cameraType
        camera.CFrame = cameraCFrame
    end

    teleporting = false

    if not ok then
        root.Anchored = oldAnchored
        return false
    end

    if enabled and root.Parent then
        root.Anchored = true
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    else
        root.Anchored = oldAnchored
    end

    return true
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
    if not finalDoor then
        return nil
    end

    -- Exact hierarchy shown in the screenshots:
    -- FinalDoor > Command > CommandButton > Prompt > ProximityPrompt
    local command = finalDoor:FindFirstChild("Command")
    local commandButton = command and command:FindFirstChild("CommandButton")
    local promptFolder = commandButton and commandButton:FindFirstChild("Prompt")

    if promptFolder then
        if promptFolder:IsA("ProximityPrompt") then
            return promptFolder
        end

        local prompt = promptFolder:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            return prompt
        end

        for _, object in ipairs(promptFolder:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                return object
            end
        end
    end

    -- Strict fallback only inside FinalDoor.
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

local function waitForExactFinalPrompt(timeout)
    local deadline = os.clock() + (timeout or 12)

    while current() and os.clock() < deadline do
        local prompt = getExactFinalPrompt()

        if prompt and prompt.Parent then
            return prompt
        end

        task.wait(0.20)
    end

    return nil
end

local function getPromptActivationCFrame(prompt)
    if not prompt or not prompt.Parent then
        return nil
    end

    local holder = prompt.Parent
    local cf

    if holder:IsA("Attachment") then
        cf = holder.WorldCFrame
    elseif holder:IsA("BasePart") then
        cf = holder.CFrame
    else
        local model = prompt:FindFirstAncestorOfClass("Model")
        if model then
            local ok, pivot = pcall(model.GetPivot, model)
            if ok and pivot then
                cf = pivot
            end
        end
    end

    if not cf then
        return nil
    end

    -- Fica 2 studs na frente do prompt, dentro da distância normal de interação.
    local position = cf.Position - cf.LookVector * 2
    return CFrame.lookAt(
        position,
        cf.Position,
        Vector3.yAxis
    )
end

local getTimerLabel
local parseTimerText

local function fireFinalDoorPrompt()
    local prompt
    local deadline = os.clock() + 15

    while current() and os.clock() < deadline do
        prompt = getExactFinalPrompt()

        if prompt and prompt.Parent then
            break
        end

        task.wait(0.20)
    end

    if not prompt or not prompt.Parent then
        return false
    end

    for attempt = 1, 3 do
        if not current() then
            return false
        end

        prompt = getExactFinalPrompt()
        if not prompt or not prompt.Parent then
            task.wait(0.25)
            continue
        end

        local label = getTimerLabel()
        local before = label and parseTimerText(label.Text) or nil

        -- Do not teleport to DoorR here. The prompt must be activated
        -- while the server still has the player at Command.
        if type(fireproximityprompt) == "function" then
            pcall(function()
                fireproximityprompt(prompt)
            end)
        end

        -- Same native fallback as the original RUNAWAYS script.
        pcall(function()
            local duration = prompt.HoldDuration

            prompt.HoldDuration = 0
            prompt:InputHoldBegin()
            task.wait(0.10)
            prompt:InputHoldEnd()
            prompt.HoldDuration = duration
        end)

        local expires = os.clock() + 6

        while current() and os.clock() < expires do
            if not prompt.Parent then
                return true
            end

            local currentLabel = getTimerLabel()
            local after = currentLabel and parseTimerText(currentLabel.Text) or nil

            -- Confirm the actual game state rather than trusting pcall().
            if not prompt.Enabled then
                return true
            end

            if after and before and after < before then
                return true
            end

            if after and after < 120 then
                return true
            end

            task.wait(0.20)
        end

        task.wait(attempt)
    end

    return false
end

getTimerLabel = function()
    local finalDoor = getFinalDoor()
    if not finalDoor then
        return nil
    end

    -- Exact hierarchy from the Explorer:
    -- FinalDoor > Timer > SurfaceGui > Timer > Time
    local timerModel = finalDoor:FindFirstChild("Timer")
    local surfaceGui = timerModel and timerModel:FindFirstChild("SurfaceGui")
    local timerFrame = surfaceGui and surfaceGui:FindFirstChild("Timer")
    local timeLabel = timerFrame and timerFrame:FindFirstChild("Time")

    if timeLabel
        and (timeLabel:IsA("TextLabel")
            or timeLabel:IsA("TextButton")
            or timeLabel:IsA("TextBox"))
    then
        return timeLabel
    end

    -- Same path, but tolerate dynamically recreated intermediate folders.
    if timerModel then
        for _, object in ipairs(timerModel:GetDescendants()) do
            if object.Name == "Time"
                and (object:IsA("TextLabel")
                    or object:IsA("TextButton")
                    or object:IsA("TextBox"))
            then
                return object
            end
        end
    end

    -- Last-resort fallback inside FinalDoor only.
    for _, object in ipairs(finalDoor:GetDescendants()) do
        if object.Name == "Time"
            and (object:IsA("TextLabel")
                or object:IsA("TextButton")
                or object:IsA("TextBox"))
        then
            return object
        end
    end

    return nil
end

parseTimerText = function(text)
    text = tostring(text or "")

    -- Time is a RichText TextLabel. Strip all markup before parsing.
    text = text:gsub("<[^>]->", "")
    text = text
        :gsub("\194\160", " ") -- UTF-8 non-breaking space
        :gsub("\226\128\175", " ") -- UTF-8 narrow no-break space
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")

    -- Accept:
    -- 00m 02s
    -- 0m 02s
    -- 00m02s
    -- 00M 02S
    local minutes, seconds = text:match("(%d+)%s*[mM]%s*(%d+)%s*[sS]")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end

    -- mm:ss
    minutes, seconds = text:match("(%d+)%s*:%s*(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end

    -- Just seconds
    local onlySeconds = text:match("(%d+)%s*[sS]")
    if onlySeconds then
        return tonumber(onlySeconds)
    end

    -- Plain number
    local number = text:match("(%d+)")
    if number then
        return tonumber(number)
    end

    return nil
end

local function waitForTimerZero(timeout)
    local deadline = os.clock() + (timeout or 180)
    local label = nil
    local textConnection = nil
    local ancestryConnection = nil
    local triggered = false
    local countdownSeen = false
    local previousRemaining = nil
    local attachedLabel = nil

    local function disconnect()
        if textConnection then
            textConnection:Disconnect()
            textConnection = nil
        end

        if ancestryConnection then
            ancestryConnection:Disconnect()
            ancestryConnection = nil
        end
    end

    local function checkText(value)
        local remaining = parseTimerText(value)

        if remaining ~= nil then
            countdownSeen = true

            -- The moment the real countdown reaches 2 seconds or less,
            -- trigger the lateral-teleport sequence. Do not wait for the
            -- text to disappear at zero.
            if remaining <= 2 then
                triggered = true
                return
            end

            previousRemaining = remaining
        end
    end

    local function attach(currentLabel)
        if not currentLabel or currentLabel == attachedLabel then
            return
        end

        if textConnection then
            textConnection:Disconnect()
            textConnection = nil
        end

        if ancestryConnection then
            ancestryConnection:Disconnect()
            ancestryConnection = nil
        end

        attachedLabel = currentLabel

        -- Immediate check.
        checkText(currentLabel.Text)

        textConnection = currentLabel:GetPropertyChangedSignal("Text"):Connect(function()
            if triggered then
                return
            end

            checkText(currentLabel.Text)
        end)

        ancestryConnection = currentLabel.AncestryChanged:Connect(function(_, parent)
            if not parent then
                attachedLabel = nil

                if textConnection then
                    textConnection:Disconnect()
                    textConnection = nil
                end

                if ancestryConnection then
                    ancestryConnection:Disconnect()
                    ancestryConnection = nil
                end
            end
        end)
    end

    while current() and os.clock() < deadline and not triggered do
        label = getTimerLabel()

        if label and label.Parent then
            attach(label)

            -- Backup polling in case the game mutates the Text in a way that
            -- doesn't emit the expected property signal.
            checkText(label.Text)
        else
            attachedLabel = nil

            if textConnection then
                textConnection:Disconnect()
                textConnection = nil
            end

            if ancestryConnection then
                ancestryConnection:Disconnect()
                ancestryConnection = nil
            end
        end

        task.wait(0.01)
    end

    disconnect()

    return triggered
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

        -- Recalcula a DoorR antes de cada lado, caso a porta tenha sido
        -- recriada/movida ao abrir a fronteira.
        local success = false

        for _ = 1, 3 do
            if not current() then
                return false
            end

            if teleportFromDoorR(direction, 0.50) then
                success = true
                break
            end

            task.wait(0.10)
        end

        if not success then
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
-- Door opening completion
-- ----------------------------------------------------------
local function waitForOpeningAnimationToFinish(timeout)
    local finalDoor = getFinalDoor()
    if not finalDoor then
        return false
    end

    local deadline = os.clock() + (timeout or 15)
    local lastSignature = nil
    local stableSince = nil

    while current() and os.clock() < deadline do
        local playing = false

        for _, object in ipairs(finalDoor:GetDescendants()) do
            if object:IsA("Animator") then
                local ok, tracks = pcall(function()
                    return object:GetPlayingAnimationTracks()
                end)

                if ok then
                    for _, track in ipairs(tracks) do
                        if track.IsPlaying then
                            playing = true
                            break
                        end
                    end
                end
            end

            if playing then
                break
            end
        end

        local left = finalDoor:FindFirstChild("DoorL")
        local right = finalDoor:FindFirstChild("DoorR")
        local leftDoor = left and left:FindFirstChild("Door", true)
        local rightDoor = right and right:FindFirstChild("Door", true)

        local signature = tostring(leftDoor and leftDoor.CFrame or "")
            .. "|"
            .. tostring(rightDoor and rightDoor.CFrame or "")

        if not playing and signature ~= "|" then
            if signature == lastSignature then
                stableSince = stableSince or os.clock()

                if os.clock() - stableSince >= 0.45 then
                    return true
                end
            else
                stableSince = nil
            end
        else
            stableSince = nil
        end

        lastSignature = signature
        task.wait(0.10)
    end

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

    -- Depois de "play", espera exatamente 2 segundos antes de criar a sala.
    if not waitSeconds(2) then
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

    -- 1) Chega ao Command/final usando a cadeia antiga e os 3 teleportes.
    local ok = teleports:ToEnd()
    if not ok then
        task.wait(1)
        return true
    end

    -- Dá tempo para a posição do Command chegar ao servidor.
    if not waitSeconds(0.75) then
        return true
    end

    removeHelicopters()

    -- 2) O prompt é ativado ENQUANTO o player ainda está no Command.
    writeSetting(PHASE_KEY, "ActivatingFinalDoor")

    if not fireFinalDoorPrompt() then
        task.wait(1)
        return true
    end

    -- 3) Só depois da ativação espera a animação de abertura terminar
    -- e acrescenta mais 2 segundos.
    writeSetting(PHASE_KEY, "WaitingDoorOpening")

    if not waitForOpeningAnimationToFinish(15) then
        return true
    end

    if not waitSeconds(2) then
        return true
    end

    -- 4) Agora sim vai para DoorR, com a posição sendo replicada ao servidor.
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

    if not waitSeconds(0.35) then
        return true
    end

    -- 5) Não usa um timer interno de 2 minutos.
    -- O cronômetro oficial é FinalDoor > Timer > SurfaceGui > Timer > Time. O processo lateral começa exatamente em 00m 02s.
    writeSetting(PHASE_KEY, "WaitingTime")

    if not waitForTimerZero(180) then
        return true
    end

    if not current() then
        return true
    end

    -- 6) Quando o Time chegar a 00m 02s, mesmo que o Text tenha RichText ou mude imediatamente depois:
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

    -- 7) Só depois do último retorno ao DoorR espera o EndScreen.
    writeSetting(PHASE_KEY, "WaitingEndScreen")

    if not waitForEndScreen() then
        return true
    end

    -- 8) EndScreen encontrado: Replay uma única vez e não executa
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
