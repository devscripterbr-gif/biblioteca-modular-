-- DS HUB v1.0 | Hub.lua
-- Biblioteca de interface. Não contém lógica de jogo.

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    player = Players.PlayerAdded:Wait()
end

local function getParent()
    local ok, hui = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
    end)

    if ok and hui then
        return hui
    end

    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)

    if okCore and core then
        return core
    end

    return player:WaitForChild("PlayerGui")
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
end

function Library.Init(options)
    options = options or {}

    local parent = getParent()

    local old = parent:FindFirstChild("DSHUB_V1_0")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DSHUB_V1_0"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999

    local okParent = pcall(function()
        gui.Parent = parent
    end)

    if not okParent or not gui.Parent then
        error("DS HUB: não foi possível criar a ScreenGui.")
    end

    local main = Instance.new("Frame")
    main.Name = "Window"
    main.Size = UDim2.fromOffset(430, 230)
    main.Position = UDim2.new(0.5, -215, 0.5, -115)
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BorderSizePixel = 0
    main.Visible = true
    main.Parent = gui
    corner(main, 10)

    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(0, 255, 100)
    outline.Thickness = 1
    outline.Parent = main

    local bar = Instance.new("Frame")
    bar.Name = "TopBar"
    bar.Size = UDim2.new(1, 0, 0, 40)
    bar.BackgroundColor3 = Color3.fromRGB(7, 7, 7)
    bar.BorderSizePixel = 0
    bar.Parent = main
    corner(bar, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -105, 1, 0)
    title.Position = UDim2.fromOffset(12, 0)
    title.BackgroundTransparency = 1
    title.Text = tostring(options.Name or "DS Hub")
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bar

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.fromOffset(45, 40)
    ver.Position = UDim2.fromOffset(85, 0)
    ver.BackgroundTransparency = 1
    ver.Text = tostring(options.Version or "v1.0")
    ver.TextColor3 = Color3.fromRGB(170, 255, 195)
    ver.Font = Enum.Font.GothamBold
    ver.TextSize = 11
    ver.TextXAlignment = Enum.TextXAlignment.Left
    ver.Parent = bar

    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.fromOffset(30, 30)
    minimize.Position = UDim2.new(1, -68, 0.5, -15)
    minimize.BackgroundTransparency = 1
    minimize.Text = "—"
    minimize.TextColor3 = Color3.fromRGB(180, 180, 180)
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 15
    minimize.Parent = bar

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(30, 30)
    close.Position = UDim2.new(1, -35, 0.5, -15)
    close.BackgroundTransparency = 1
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(180, 180, 180)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 11
    close.Parent = bar

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 135, 1, -48)
    sidebar.Position = UDim2.fromOffset(6, 46)
    sidebar.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    corner(sidebar, 8)

    local sideList = Instance.new("UIListLayout")
    sideList.Padding = UDim.new(0, 5)
    sideList.Parent = sidebar

    local sidePad = Instance.new("UIPadding")
    sidePad.PaddingTop = UDim.new(0, 7)
    sidePad.PaddingLeft = UDim.new(0, 5)
    sidePad.PaddingRight = UDim.new(0, 5)
    sidePad.Parent = sidebar

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -147, 1, -48)
    pages.Position = UDim2.fromOffset(147, 46)
    pages.BackgroundTransparency = 1
    pages.Parent = main

    local window = {
        ScreenGui = gui,
        Main = main,
        Tabs = {},
        Options = {},
        Toggles = {},
        Unloaded = false,
    }

    function window:Notify(info)
        info = info or {}

        local toast = Instance.new("Frame")
        toast.Size = UDim2.fromOffset(275, 58)
        toast.Position = UDim2.new(1, -8, 0, 8)
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        toast.BorderSizePixel = 0
        toast.ZIndex = 500
        toast.Parent = gui
        corner(toast, 8)

        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(0, 255, 100)
        s.Thickness = 1
        s.Parent = toast

        local a = Instance.new("TextLabel")
        a.Size = UDim2.new(1, -14, 0, 18)
        a.Position = UDim2.fromOffset(7, 4)
        a.BackgroundTransparency = 1
        a.Text = tostring(info.Title or "DS HUB")
        a.TextColor3 = Color3.fromRGB(0, 255, 100)
        a.Font = Enum.Font.GothamBold
        a.TextSize = 10
        a.TextXAlignment = Enum.TextXAlignment.Left
        a.ZIndex = 501
        a.Parent = toast

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -14, 0, 28)
        b.Position = UDim2.fromOffset(7, 24)
        b.BackgroundTransparency = 1
        b.Text = tostring(info.Description or "")
        b.TextColor3 = Color3.fromRGB(240, 240, 240)
        b.Font = Enum.Font.Gotham
        b.TextSize = 9
        b.TextWrapped = true
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.ZIndex = 501
        b.Parent = toast

        task.delay(tonumber(info.Time) or 3, function()
            if toast.Parent then
                toast:Destroy()
            end
        end)
    end

    function window:CreateTab(tabName, icon)
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 34)
        tabButton.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        tabButton.BackgroundTransparency = (#self.Tabs == 0) and 0.7 or 1
        tabButton.BorderSizePixel = 0
        tabButton.Text = tostring(icon or "•") .. "  " .. tostring(tabName)
        tabButton.TextColor3 = (#self.Tabs == 0)
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(145, 155, 145)
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextSize = 10
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.Parent = sidebar
        corner(tabButton, 7)

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = (#self.Tabs == 0)
        page.Parent = pages

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 7)
        list.Parent = page

        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
        end)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 5)
        pad.PaddingLeft = UDim.new(0, 3)
        pad.PaddingRight = UDim.new(0, 5)
        pad.Parent = page

        local tab = {
            Page = page,
            Button = tabButton,
        }

        function tab:CreateToggle(id, defaultValue, callback)
            local option = {
                Value = defaultValue == true,
                Default = defaultValue == true,
            }

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 48)
            card.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            card.BorderSizePixel = 0
            card.Parent = page
            corner(card, 8)

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(20, 45, 25)
            stroke.Thickness = 1
            stroke.Parent = card

            local text = Instance.new("TextLabel")
            text.Size = UDim2.new(1, -72, 1, 0)
            text.Position = UDim2.fromOffset(11, 0)
            text.BackgroundTransparency = 1
            text.Text = tostring(id)
            text.TextColor3 = Color3.fromRGB(245, 245, 245)
            text.Font = Enum.Font.GothamMedium
            text.TextSize = 10
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.Parent = card

            local switch = Instance.new("Frame")
            switch.Size = UDim2.fromOffset(40, 22)
            switch.Position = UDim2.new(1, -52, 0.5, -11)
            switch.BackgroundColor3 = option.Value
                and Color3.fromRGB(0, 255, 100)
                or Color3.fromRGB(25, 25, 25)
            switch.BorderSizePixel = 0
            switch.Parent = card
            corner(switch, 11)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position = option.Value
                and UDim2.new(1, -19, 0.5, -8)
                or UDim2.fromOffset(3, 3)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch
            corner(knob, 8)

            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.Parent = card

            function option:SetValue(value)
                self.Value = value == true

                switch.BackgroundColor3 = self.Value
                    and Color3.fromRGB(0, 255, 100)
                    or Color3.fromRGB(25, 25, 25)

                knob.Position = self.Value
                    and UDim2.new(1, -19, 0.5, -8)
                    or UDim2.fromOffset(3, 3)

                if callback then
                    task.spawn(callback, self.Value)
                end
            end

            hit.MouseButton1Click:Connect(function()
                option:SetValue(not option.Value)
            end)

            window.Options[id] = option
            window.Toggles[id] = option

            return option
        end

        table.insert(self.Tabs, tab)

        tabButton.MouseButton1Click:Connect(function()
            for _, item in ipairs(self.Tabs) do
                item.Page.Visible = false
                item.Button.BackgroundTransparency = 1
                item.Button.TextColor3 = Color3.fromRGB(145, 155, 145)
            end

            page.Visible = true
            tabButton.BackgroundTransparency = 0.7
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)

        return tab
    end

    local dragging = false
    local dragStart
    local startPosition

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    local minimized = false

    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        sidebar.Visible = not minimized
        pages.Visible = not minimized
        main.Size = minimized
            and UDim2.fromOffset(430, 40)
            or UDim2.fromOffset(430, 230)
        minimize.Text = minimized and "+" or "—"
    end)

    close.MouseButton1Click:Connect(function()
        window:Unload()
    end)

    function window:Unload()
        if self.Unloaded then
            return
        end

        self.Unloaded = true

        if gui.Parent then
            gui:Destroy()
        end
    end

    return window
end

return Library
