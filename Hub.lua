-- DS HUB v1.0 | Hub.lua
-- UI mínima: janela, abas, toggle e notificações.

local DSHubLibrary = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local THEME = {
    Background = Color3.fromRGB(0, 0, 0),
    TopBar = Color3.fromRGB(5, 5, 5),
    Sidebar = Color3.fromRGB(3, 3, 3),
    Card = Color3.fromRGB(10, 10, 10),
    Border = Color3.fromRGB(18, 38, 22),
    Accent = Color3.fromRGB(0, 255, 100),
    Text = Color3.fromRGB(245, 245, 245),
    SubText = Color3.fromRGB(145, 155, 145),
    Off = Color3.fromRGB(25, 25, 25),
}

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
end

local function getParent()
    if typeof(gethui) == "function" then
        local ok, gui = pcall(gethui)
        if ok and gui then
            return gui
        end
    end

    local ok, core = pcall(function()
        return game:GetService("CoreGui")
    end)

    return ok and core or LocalPlayer:WaitForChild("PlayerGui")
end

function DSHubLibrary.Init(config)
    config = config or {}

    local parent = getParent()
    local old = parent:FindFirstChild("DSHUB_V1_0")

    if old then
        old:Destroy()
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "DSHUB_V1_0"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 430, 0, 225)
    frame.Position = UDim2.new(0.5, -215, 0.5, -112)
    frame.BackgroundColor3 = THEME.Background
    frame.BorderSizePixel = 0
    frame.Parent = screen
    addCorner(frame, 12)

    local border = Instance.new("UIStroke")
    border.Color = THEME.Accent
    border.Thickness = 1
    border.Parent = frame

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 42)
    top.BackgroundColor3 = THEME.TopBar
    top.BorderSizePixel = 0
    top.Parent = frame
    addCorner(top, 11)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -105, 1, 0)
    title.Position = UDim2.new(0, 13, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = tostring(config.Name or "DS Hub")
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = top

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(0, 50, 1, 0)
    ver.Position = UDim2.new(0, 88, 0, 0)
    ver.BackgroundTransparency = 1
    ver.Text = tostring(config.Version or "v1.0")
    ver.TextColor3 = THEME.Accent
    ver.Font = Enum.Font.GothamBold
    ver.TextSize = 13
    ver.Parent = top

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -68, 0.5, -14)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = THEME.SubText
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 15
    minBtn.Parent = top

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = THEME.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = top

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -12, 1, -50)
    body.Position = UDim2.new(0, 6, 0, 46)
    body.BackgroundTransparency = 1
    body.Parent = frame

    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(0, 145, 1, 0)
    tabsFrame.BackgroundColor3 = THEME.Sidebar
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = body
    addCorner(tabsFrame, 10)

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 6)
    tabList.Parent = tabsFrame

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingTop = UDim.new(0, 9)
    tabPad.PaddingLeft = UDim.new(0, 6)
    tabPad.PaddingRight = UDim.new(0, 6)
    tabPad.Parent = tabsFrame

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -153, 1, 0)
    pages.Position = UDim2.new(0, 153, 0, 0)
    pages.BackgroundTransparency = 1
    pages.Parent = body

    local window = {
        Tabs = {},
        Options = {},
        Toggles = {},
        Unloaded = false,
        ScreenGui = screen,
    }

    function window:Notify(info)
        info = info or {}

        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(0, 280, 0, 56)
        toast.Position = UDim2.new(1, -10, 0, 6)
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.BackgroundColor3 = THEME.Card
        toast.BorderSizePixel = 0
        toast.ZIndex = 3000
        toast.Parent = screen
        addCorner(toast, 9)

        local s = Instance.new("UIStroke")
        s.Color = THEME.Accent
        s.Thickness = 1
        s.Parent = toast

        local a = Instance.new("TextLabel")
        a.Size = UDim2.new(1, -16, 0, 17)
        a.Position = UDim2.new(0, 8, 0, 5)
        a.BackgroundTransparency = 1
        a.Text = tostring(info.Title or "DS HUB")
        a.TextColor3 = THEME.Accent
        a.Font = Enum.Font.GothamBold
        a.TextSize = 10
        a.TextXAlignment = Enum.TextXAlignment.Left
        a.ZIndex = 3001
        a.Parent = toast

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -16, 0, 28)
        b.Position = UDim2.new(0, 8, 0, 22)
        b.BackgroundTransparency = 1
        b.Text = tostring(info.Description or "")
        b.TextColor3 = THEME.Text
        b.Font = Enum.Font.Gotham
        b.TextSize = 9
        b.TextWrapped = true
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.ZIndex = 3001
        b.Parent = toast

        task.delay(tonumber(info.Time) or 4, function()
            if toast.Parent then
                toast:Destroy()
            end
        end)

        return toast
    end

    function window:CreateTab(tabName, icon)
        local index = #self.Tabs

        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 34)
        tabButton.BackgroundColor3 = THEME.Card
        tabButton.BackgroundTransparency = index == 0 and 0.75 or 1
        tabButton.BorderSizePixel = 0
        tabButton.Text = tostring(icon or "•") .. "  " .. tostring(tabName)
        tabButton.TextColor3 = index == 0 and THEME.Text or THEME.SubText
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextSize = 10
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.Parent = tabsFrame
        addCorner(tabButton, 8)

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = THEME.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = index == 0
        page.ZIndex = 20
        page.Parent = pages

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingLeft = UDim.new(0, 3)
        pad.PaddingRight = UDim.new(0, 5)
        pad.PaddingBottom = UDim.new(0, 5)
        pad.Parent = page

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 7)
        list.Parent = page

        page.ZIndex = 20
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
        end)

        local tab = {
            Page = page,
            Button = tabButton,
            Options = {},
        }

        function tab:CreateToggle(id, defaultState, callback)
            local option = {
                Value = defaultState == true,
                Default = defaultState == true,
            }

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 46)
            card.BackgroundColor3 = THEME.Card
            card.BorderSizePixel = 0
            card.Parent = page
            addCorner(card, 9)

            local cs = Instance.new("UIStroke")
            cs.Color = THEME.Border
            cs.Thickness = 1
            cs.Parent = card

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, -74, 1, 0)
            textLabel.Position = UDim2.new(0, 11, 0, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = tostring(id)
            textLabel.TextColor3 = THEME.Text
            textLabel.Font = Enum.Font.GothamMedium
            textLabel.TextSize = 10
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = card

            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 40, 0, 22)
            switch.Position = UDim2.new(1, -52, 0.5, -11)
            switch.BackgroundColor3 = option.Value and THEME.Accent or THEME.Off
            switch.BorderSizePixel = 0
            switch.Parent = card
            addCorner(switch, 11)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = option.Value
                and UDim2.new(1, -19, 0.5, -8)
                or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch
            addCorner(knob, 8)

            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.Parent = card

            function option:SetValue(value)
                self.Value = value == true
                switch.BackgroundColor3 = self.Value and THEME.Accent or THEME.Off
                knob.Position = self.Value
                    and UDim2.new(1, -19, 0.5, -8)
                    or UDim2.new(0, 3, 0.5, -8)

                if callback then
                    task.spawn(callback, self.Value)
                end
            end

            hit.MouseButton1Click:Connect(function()
                option:SetValue(not option.Value)
            end)

            window.Options[id] = option
            window.Toggles[id] = option
            tab.Options[id] = option

            return option
        end

        table.insert(self.Tabs, tab)

        tabButton.MouseButton1Click:Connect(function()
            for _, other in ipairs(self.Tabs) do
                other.Page.Visible = false
                other.Button.BackgroundTransparency = 1
                other.Button.TextColor3 = THEME.SubText
            end

            page.Visible = true
            tabButton.BackgroundTransparency = 0.75
            tabButton.TextColor3 = THEME.Text
        end)

        return tab
    end

    local dragging
    local dragStart
    local startPosition

    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart

            frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    local minimized = false

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        body.Visible = not minimized
        frame.Size = minimized
            and UDim2.new(0, 430, 0, 42)
            or UDim2.new(0, 430, 0, 225)
        minBtn.Text = minimized and "+" or "—"
    end)

    closeBtn.MouseButton1Click:Connect(function()
        window:Unload()
    end)

    function window:Unload()
        if self.Unloaded then
            return
        end

        self.Unloaded = true

        if screen.Parent then
            screen:Destroy()
        end
    end

    return window
end

return DSHubLibrary
