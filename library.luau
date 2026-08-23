local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local http_service = game:GetService("HttpService")
local coregui = game:GetService("CoreGui")
local run_service = game:GetService("RunService")

local player = players.LocalPlayer

if getgenv().library then
    getgenv().library:unload()
end

local library = {
    flags = {},
    config_flags = {},
    instances = {},
    connections = {},
    current_tab = nil,
    directory = "Femboy-Ware",
    themes = {
        preset = {
            background = Color3.fromRGB(30, 30, 30),
            sidebar = Color3.fromRGB(25, 25, 25),
            accent = Color3.fromRGB(255, 105, 180),
            text = Color3.fromRGB(220, 220, 220),
            placeholder = Color3.fromRGB(140, 140, 140),
            stroke = Color3.fromRGB(50, 50, 50),
            element_background = Color3.fromRGB(40, 40, 40),
            dropdown = Color3.fromRGB(35, 35, 35),
            highlight = Color3.fromRGB(40, 40, 40)
        }
    },
    tab_order = 0
}

function library:create(class, props)
    local inst = Instance.new(class)
    for prop, val in next, props do
        inst[prop] = val
    end
    table.insert(self.instances, inst)
    return inst
end

function library:connection(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self.connections, conn)
    return conn
end

function library:unload()
    for _, conn in next, self.connections do if conn.Connected then conn:Disconnect() end end
    for _, inst in next, self.instances do if inst and inst.Parent then inst:Destroy() end end
    if self.gui then self.gui:Destroy() end
    getgenv().library = nil
end

function library:get_icon(icon)
    if not icon then return "rbxasset://textures/ui/GuiImagePlaceholder.png" end
    
    -- allow direct rbxasset or http links
    if string.sub(icon, 1, 4) == "http" or string.sub(icon, 1, 7) == "rbxasset" then
        return icon
    end

    if not isfolder(self.directory) then makefolder(self.directory) end
    local icon_folder = self.directory .. "/icons"
    if not isfolder(icon_folder) then makefolder(icon_folder) end

    local file_name = icon
    -- strip .png if user accidentally included it
    if string.sub(file_name, -4):lower() == ".png" then
        file_name = string.sub(file_name, 1, -5)
    end
    file_name = file_name .. ".png"

    local path = icon_folder .. "/" .. file_name
    if isfile(path) then
        return getcustomasset(path)
    end

    -- fallback to github
    local url = "https://raw.githubusercontent.com/codexvsberserkerxylo/femboy-ware/main/assets/icons/" .. file_name
    local success, data = pcall(function() return game:HttpGet(url) end)

    if success and data and #data > 100 then
        writefile(path, data)
        return getcustomasset(path)
    end

    warn("the prebuilt icon named '"..icon.."' could not be found. please look at the github to see all icons")
    
    -- fallback to question.png
    local q_path = icon_folder .. "/question.png"
    if isfile(q_path) then
        return getcustomasset(q_path)
    end
    
    local q_url = "https://raw.githubusercontent.com/codexvsberserkerxylo/femboy-ware/main/assets/icons/question.png"
    local q_success, q_data = pcall(function() return game:HttpGet(q_url) end)
    if q_success and q_data and #q_data > 100 then
        writefile(q_path, q_data)
        return getcustomasset(q_path)
    end

    return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

function library:loading_screen(props)
    local cfg = {
        text = props.text or "loading...",
        duration = props.duration or 2,
        icon = props.icon or "logo"
    }

    local loader_gui = self:create("ScreenGui", {
        Name = "femboy_loader",
        Parent = gethui() and gethui() or coregui,
        IgnoreGuiInset = true,
        DisplayOrder = 9999
    })

    local screen = self:create("Frame", {
        Name = "loader",
        Parent = loader_gui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0
    })

    local logo = self:create("ImageLabel", {
        Name = "logo",
        Parent = screen,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -20),
        Size = UDim2.new(0, 80, 0, 80),
        Image = self:get_icon(cfg.icon)
    })

    local text_label = self:create("TextLabel", {
        Name = "text",
        Parent = screen,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 40),
        Size = UDim2.new(0, 200, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = cfg.text,
        TextColor3 = self.themes.preset.text,
        TextSize = 14
    })

    local spin_conn
    spin_conn = run_service.RenderStepped:Connect(function()
        local speed = math.abs(math.sin(tick() * 2)) * 8 + 1
        logo.Rotation = logo.Rotation + speed
    end)

    task.delay(cfg.duration, function()
        spin_conn:Disconnect()
        tween_service:Create(screen, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
        tween_service:Create(logo, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
        tween_service:Create(text_label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        task.delay(0.5, function() loader_gui:Destroy() end)
    end)
end

function library:window(props)
    local cfg = {
        title = props.title or "femboy-ware",
        subtitle = props.subtitle or "",
        size = props.size or UDim2.new(0, 650, 0, 450),
        icon = props.icon or "logo"
    }

    self.gui = self:create("ScreenGui", {
        Name = "femboy_ware",
        Parent = gethui() and gethui() or coregui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    local main_frame = self:create("Frame", {
        Name = "main",
        Parent = self.gui,
        Size = cfg.size,
        Position = UDim2.new(0.5, -cfg.size.X.Offset/2, 0.5, -cfg.size.Y.Offset/2),
        BackgroundColor3 = self.themes.preset.background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    self:create("UICorner", { Parent = main_frame, CornerRadius = UDim.new(0, 6) })
    self:create("UIStroke", { Parent = main_frame, Color = self.themes.preset.stroke, Thickness = 1 })

    local topbar = self:create("Frame", {
        Name = "topbar",
        Parent = main_frame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.themes.preset.sidebar,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = topbar, CornerRadius = UDim.new(0, 6) })

    local window_icon = self:create("ImageLabel", {
        Name = "icon",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(0, 24, 0, 24),
        Image = self:get_icon(cfg.icon)
    })

    local title_label = self:create("TextLabel", {
        Name = "title",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -200, 1, 0),
        Font = Enum.Font.GothamBold,
        RichText = true,
        Text = string.format('<font size="14">%s</font><font size="12" color="#8c8c8c">%s</font>', cfg.title, cfg.subtitle),
        TextColor3 = self.themes.preset.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local content = self:create("Frame", {
        Name = "content",
        Parent = main_frame,
        Position = UDim2.new(0, 8, 0, 48),
        Size = UDim2.new(1, -16, 1, -56),
        BackgroundTransparency = 1
    })

    local sidebar = self:create("Frame", {
        Name = "sidebar",
        Parent = content,
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = self.themes.preset.sidebar,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    self:create("UICorner", { Parent = sidebar, CornerRadius = UDim.new(0, 4) })

    local tab_list = self:create("ScrollingFrame", {
        Name = "tab_list",
        Parent = sidebar,
        Size = UDim2.new(1, 0, 1, -50),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    self:create("UIListLayout", { Parent = tab_list, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    self:create("UIPadding", { Parent = tab_list, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })

    local player_frame = self:create("Frame", {
        Name = "player_info",
        Parent = sidebar,
        Position = UDim2.new(0, 6, 1, -44),
        Size = UDim2.new(1, -12, 0, 32),
        BackgroundTransparency = 1
    })

    local avatar_img = self:create("ImageLabel", {
        Name = "avatar",
        Parent = player_frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"
    })
    self:create("UICorner", { Parent = avatar_img, CornerRadius = UDim.new(1, 0) })

    local pname_label = self:create("TextLabel", {
        Name = "pname",
        Parent = player_frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = player.DisplayName,
        TextColor3 = self.themes.preset.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local tab_content = self:create("Frame", {
        Name = "tab_content",
        Parent = content,
        Position = UDim2.new(0, 148, 0, 0),
        Size = UDim2.new(1, -148, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })

    local close_btn = self:create("ImageButton", {
        Name = "close",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -34, 0, 8),
        Size = UDim2.new(0, 24, 0, 24),
        Image = self:get_icon("x")
    })

    local minimize_btn = self:create("ImageButton", {
        Name = "minimize",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -68, 0, 9),
        Size = UDim2.new(0, 21, 0, 21),
        Image = self:get_icon("minimize")
    })

    local settings_btn = self:create("ImageButton", {
        Name = "settings",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -101, 0, 9),
        Size = UDim2.new(0, 21, 0, 21),
        Image = self:get_icon("settings")
    })

    local panel_btn = self:create("ImageButton", {
        Name = "panel",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -134, 0, 9),
        Size = UDim2.new(0, 21, 0, 21),
        Image = self:get_icon("panel-close")
    })

    local dragging, drag_start, start_pos
    self:connection(topbar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            drag_start = input.Position
            start_pos = main_frame.Position
        end
    end)
    self:connection(topbar.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    self:connection(uis.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - drag_start
                main_frame.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
            end
        end
    end)

    self:connection(close_btn.MouseButton1Click, function() self:unload() end)

    local minimized = false
    self:connection(minimize_btn.MouseButton1Click, function()
        minimized = not minimized
        local target_size = minimized and UDim2.new(cfg.size.X.Scale, cfg.size.X.Offset, 0, 40) or cfg.size
        minimize_btn.Image = minimized and self:get_icon("maximize") or self:get_icon("minimize")
        content.Visible = not minimized
        tween_service:Create(main_frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), { Size = target_size }):Play()
    end)

    local panel_collapsed = false
    self:connection(panel_btn.MouseButton1Click, function()
        panel_collapsed = not panel_collapsed
        local target_w = panel_collapsed and 50 or 140
        local target_x = panel_collapsed and 58 or 148
        local target_icon = panel_collapsed and "panel-open" or "panel-close"
        
        tween_service:Create(sidebar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), { Size = UDim2.new(0, target_w, 1, 0) }):Play()
        tween_service:Create(tab_content, TweenInfo.new(0.3, Enum.EasingStyle.Quart), { Position = UDim2.new(0, target_x, 0, 0), Size = UDim2.new(1, -target_x, 1, 0) }):Play()
        panel_btn.Image = self:get_icon(target_icon)
        
        for _, tab in next, self.tabs do
            if tab.text_label then tab.text_label.Visible = not panel_collapsed end
        end
        pname_label.Visible = not panel_collapsed
        
        if panel_collapsed then
            tween_service:Create(avatar_img, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -16, 0, 0) }):Play()
        else
            tween_service:Create(avatar_img, TweenInfo.new(0.3), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        end
    end)

    self.tabs = {}

    -- auto create home tab
    local home_tab = self:tab({ name = "home", icon = "house", hidden_order = -1 })
    local home_section = home_tab:section({ name = "info" })
    home_section:add_info_row("welcome", "hello " .. player.DisplayName)
    home_section:add_info_row("script", "femboy-ware v1.0")
    home_section:add_info_row("status", "undetected")
    home_tab:select()

    cfg.settings_tab = self:tab({ name = "settings", icon = "settings", hidden = true })
    cfg.settings_tab.frame.Visible = false
    cfg.settings_tab.button.Visible = false

    self:connection(settings_btn.MouseButton1Click, function() cfg.settings_tab:select() end)

    local config_section = cfg.settings_tab:section({ name = "configs" })
    local config_name_input = config_section:textbox({ placeholder = "config name", clear_on_focus = true })

    config_section:button({ 
        name = "save config", 
        callback = function()
            local name = config_name_input.instance.Text
            if name == "" then return end
            local config_data = {}
            for flag, val in next, self.flags do config_data[flag] = val end
            local path = self.directory .. "/configs/" .. name .. ".json"
            writefile(path, http_service:JSONEncode(config_data))
            self:notification({ text = "saved config: " .. name })
            config_section:refresh_configs()
        end 
    })

    config_section:button({ 
        name = "load config", 
        callback = function()
            local name = config_name_input.instance.Text
            if name == "" then return end
            local path = self.directory .. "/configs/" .. name .. ".json"
            if isfile(path) then
                local data = http_service:JSONDecode(readfile(path))
                for flag, val in next, data do
                    if self.config_flags[flag] then self.config_flags[flag](val) end
                end
                self:notification({ text = "loaded config: " .. name })
            else
                self:notification({ text = "config not found!" })
            end
        end 
    })

    function config_section:refresh_configs()
        if not isfolder(self.directory .. "/configs") then makefolder(self.directory .. "/configs") end
        local files = listfiles(self.directory .. "/configs")
        local names = {}
        for _, file in next, files do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
        if config_section.config_dd then config_section.config_dd:refresh(names) end
    end

    config_section.config_dd = config_section:dropdown({ 
        name = "saved configs", 
        options = {}, 
        callback = function(val) config_name_input.instance.Text = val end
    })
    config_section:refresh_configs()

    return setmetatable(cfg, { __index = self })
end

function library:tab(props)
    local cfg = {
        name = props.name or "tab",
        icon = props.icon or "down",
        hidden = props.hidden or false
    }

    local order = props.hidden_order or self.tab_order
    if not props.hidden_order then
        self.tab_order += 1
        order = self.tab_order
    end

    local button = self:create("TextButton", {
        Name = cfg.name,
        Parent = self.gui.main.content.sidebar.tab_list,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.themes.preset.highlight,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order
    })
    self:create("UICorner", { Parent = button, CornerRadius = UDim.new(0, 4) })

    local accent_bar = self:create("Frame", {
        Name = "accent",
        Parent = button,
        Size = UDim2.new(0, 2, 0, 16),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = self.themes.preset.accent,
        BorderSizePixel = 0,
        Visible = false
    })
    self:create("UICorner", { Parent = accent_bar, CornerRadius = UDim.new(1, 0) })

    local icon_label = self:create("ImageLabel", {
        Name = "icon",
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = self:get_icon(cfg.icon)
    })

    local text_label = self:create("TextLabel", {
        Name = "text",
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Font = Enum.Font.Gotham,
        Text = cfg.name,
        TextColor3 = self.themes.preset.placeholder,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local frame = self:create("ScrollingFrame", {
        Name = cfg.name .. "_page",
        Parent = self.gui.main.content.tab_content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.themes.preset.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Position = UDim2.new(0, 0, 0, 0)
    })
    self:create("UIListLayout", { Parent = frame, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    self:create("UIPadding", { Parent = frame, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    cfg.button = button
    cfg.frame = frame
    cfg.text_label = text_label
    cfg.order = order

    table.insert(self.tabs, cfg)

    function cfg:select()
        if library.current_tab == cfg then return end
        
        local old_tab = library.current_tab
        local direction = 1
        if old_tab and old_tab.order then
            if old_tab.order < cfg.order then direction = 1 else direction = -1 end
        end

        if old_tab then
            old_tab.button.BackgroundTransparency = 1
            old_tab.button.accent.Visible = false
            old_tab.button.text.TextColor3 = library.themes.preset.placeholder
            
            old_tab.frame.Position = UDim2.new(0, 0, 0, 0)
            tween_service:Create(old_tab.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(-direction, 0, 0, 0) }):Play()
            task.delay(0.3, function()
                old_tab.frame.Visible = false
                old_tab.frame.Position = UDim2.new(0, 0, 0, 0)
            end)
        end

        library.current_tab = cfg
        button.BackgroundTransparency = 0
        accent_bar.Visible = true
        text_label.TextColor3 = library.themes.preset.text
        
        frame.Visible = true
        frame.Position = UDim2.new(direction, 0, 0, 0)
        tween_service:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end

    self:connection(button.MouseButton1Click, function() cfg:select() end)

    return setmetatable(cfg, { __index = self })
end

function library:section(props)
    local cfg = {
        name = props.name or "section",
        icon = props.icon or nil,
        expanded = true
    }

    local section_frame = self:create("Frame", {
        Name = cfg.name,
        Parent = self.current_tab.frame,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.themes.preset.element_background,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = section_frame, CornerRadius = UDim.new(0, 4) })

    local header = self:create("TextButton", {
        Name = "header",
        Parent = section_frame,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    })

    local dropdown_icon = self:create("ImageLabel", {
        Name = "dropdown",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0, 8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = self:get_icon("down")
    })

    local text_x = 12
    if cfg.icon then
        local s_icon = self:create("ImageLabel", {
            Name = "s_icon",
            Parent = header,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(0, 16, 0, 16),
            Image = self:get_icon(cfg.icon)
        })
        text_x = 32
    end

    local title = self:create("TextLabel", {
        Name = "title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, text_x, 0, 0),
        Size = UDim2.new(1, -text_x - 24, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = cfg.name,
        TextColor3 = self.themes.preset.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local elements_holder = self:create("Frame", {
        Name = "elements",
        Parent = section_frame,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })
    self:create("UIListLayout", { Parent = elements_holder, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    self:create("UIPadding", { Parent = elements_holder, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    cfg.holder = elements_holder

    self:connection(header.MouseButton1Click, function()
        cfg.expanded = not cfg.expanded
        local target_size = cfg.expanded and elements_holder.AbsoluteSize.Y or 0
        local target_rot = cfg.expanded and 0 or 180
        
        tween_service:Create(elements_holder, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, target_size) }):Play()
        tween_service:Create(dropdown_icon, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = target_rot }):Play()

        if cfg.expanded then
            task.delay(0.3, function() elements_holder.AutomaticSize = Enum.AutomaticSize.Y end)
        else
            elements_holder.AutomaticSize = Enum.AutomaticSize.None
        end
    end)

    function cfg:add_info_row(name, val)
        local row = self:create("Frame", {
            Name = name,
            Parent = self.holder,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1
        }) -- fixed syntax here
        self:create("TextLabel", {
            Name = "name",
            Parent = row,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = self.themes.preset.placeholder,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        self:create("TextLabel", {
            Name = "val",
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = val,
            TextColor3 = self.themes.preset.text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right
        })
    end

    return setmetatable(cfg, { __index = self })
end

function library:toggle(props)
    local cfg = {
        name = props.name or "toggle",
        default = props.default or false,
        flag = props.flag or props.name,
        callback = props.callback or function() end
    }

    local toggle_frame = self:create("TextButton", {
        Name = cfg.name,
        Parent = self.holder,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    })
    self:create("TextLabel", {
        Name = "name",
        Parent = toggle_frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.Gotham,
        Text = cfg.name,
        TextColor3 = self.themes.preset.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local switch_bg = self:create("Frame", {
        Name = "switch",
        Parent = toggle_frame,
        Position = UDim2.new(1, -28, 0, 8),
        Size = UDim2.new(0, 24, 0, 16),
        BackgroundColor3 = self.themes.preset.dropdown,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = switch_bg, CornerRadius = UDim.new(1, 0) })

    local switch_dot = self:create("Frame", {
        Name = "dot",
        Parent = switch_bg,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = self.themes.preset.text,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = switch_dot, CornerRadius = UDim.new(1, 0) })

    function cfg.set(val)
        cfg.value = val
        self.flags[cfg.flag] = val
        local color = val and self.themes.preset.accent or self.themes.preset.dropdown
        local pos = val and UDim2.new(1, -14, 0, 2) or UDim2.new(0, 2, 0, 2)
        tween_service:Create(switch_bg, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
        tween_service:Create(switch_dot, TweenInfo.new(0.2), { Position = pos }):Play()
        cfg.callback(val)
    end

    self:connection(toggle_frame.MouseButton1Click, function() cfg.set(not cfg.value) end)
    cfg.set(cfg.default)
    self.config_flags[cfg.flag] = cfg.set
    return cfg
end

function library:button(props)
    local cfg = {
        name = props.name or "button",
        callback = props.callback or function() end
    }

    local btn = self:create("TextButton", {
        Name = cfg.name,
        Parent = self.holder,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.themes.preset.dropdown,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

    self:create("TextLabel", {
        Name = "name",
        Parent = btn,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = cfg.name,
        TextColor3 = self.themes.preset.text,
        TextSize = 13
    })

    self:connection(btn.MouseButton1Click, function()
        tween_service:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.themes.preset.accent }):Play()
        task.delay(0.1, function()
            tween_service:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = self.themes.preset.dropdown }):Play()
        end)
        cfg.callback()
    end)
    return cfg
end

function library:keybind(props)
    local cfg = {
        name = props.name or "keybind",
        default = props.default or Enum.KeyCode.Unknown,
        flag = props.flag or props.name,
        callback = props.callback or function() end,
        binding = false
    }

    local bind_frame = self:create("TextButton", {
        Name = cfg.name,
        Parent = self.holder,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    })
    self:create("TextLabel", {
        Name = "name",
        Parent = bind_frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.Gotham,
        Text = cfg.name,
        TextColor3 = self.themes.preset.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local bind_btn = self:create("TextButton", {
        Name = "bind",
        Parent = bind_frame,
        Position = UDim2.new(1, -48, 0, 6),
        Size = UDim2.new(0, 40, 0, 20),
        BackgroundColor3 = self.themes.preset.dropdown,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    self:create("UICorner", { Parent = bind_btn, CornerRadius = UDim.new(0, 4) })

    local bind_text = self:create("TextLabel", {
        Name = "text",
        Parent = bind_btn,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "...",
        TextColor3 = self.themes.preset.placeholder,
        TextSize = 12
    })

    function cfg.set(key)
        cfg.key = key
        self.flags[cfg.flag] = key
        bind_text.Text = key.Name
        cfg.callback(key)
    end

    self:connection(bind_btn.MouseButton1Click, function()
        bind_text.Text = "..."
        cfg.binding = true
        local conn
        conn = uis.InputBegan:Connect(function(input)
            if cfg.binding then
                if input.UserInputType == Enum.UserInputType.Keyboard then cfg.set(input.KeyCode) end
                cfg.binding = false
                conn:Disconnect()
            end
        end)
    end)

    cfg.set(cfg.default)
    self.config_flags[cfg.flag] = cfg.set
    return cfg
end

function library:dropdown(props)
    local cfg = {
        name = props.name or "dropdown",
        options = props.options or {},
        default = props.default or (props.options and props.options[1] or nil),
        flag = props.flag or props.name,
        callback = props.callback or function() end,
        open = false
    }

    local dd_frame = self:create("Frame", { Name = cfg.name, Parent = self.holder, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 })
    self:create("TextLabel", {
        Name = "name",
        Parent = dd_frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = cfg.name,
        TextColor3 = self.themes.preset.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local dd_btn = self:create("TextButton", {
        Name = "select",
        Parent = dd_frame,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = self.themes.preset.dropdown,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    self:create("UICorner", { Parent = dd_btn, CornerRadius = UDim.new(0, 4) })

    local dd_text = self:create("TextLabel", {
        Name = "val",
        Parent = dd_btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "...",
        TextColor3 = self.themes.preset.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local dd_icon = self:create("ImageLabel", {
        Name = "icon",
        Parent = dd_btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0, 4),
        Size = UDim2.new(0, 16, 0, 16),
        Image = self:get_icon("down")
    })

    local dd_list = self:create("Frame", {
        Name = "list",
        Parent = dd_frame,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = self.themes.preset.dropdown,
        BorderSizePixel = 0,
        Visible = false
    })
    self:create("UICorner", { Parent = dd_list, CornerRadius = UDim.new(0, 4) })
    self:create("UIListLayout", { Parent = dd_list, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
    self:create("UIPadding", { Parent = dd_list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })

    local function set_height()
        local count = 0
        for _ in next, cfg.options do count += 1 end
        dd_list.Size = UDim2.new(1, 0, 0, math.clamp(count * 24 + 8, 0, 120))
    end

    function cfg.set(val)
        cfg.value = val
        self.flags[cfg.flag] = val
        dd_text.Text = val
        cfg.callback(val)
    end

    function cfg:refresh(opts)
        cfg.options = opts
        for _, child in next, dd_list:GetChildren() do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, opt in next, opts do
            local opt_btn = self:create("TextButton", {
                Name = opt,
                Parent = dd_list,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false
            })
            self:create("TextLabel", {
                Name = "val",
                Parent = opt_btn,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 0),
                Size = UDim2.new(1, -8, 1, 0),
                Font = Enum.Font.Gotham,
                Text = opt,
                TextColor3 = self.themes.preset.text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            self:connection(opt_btn.MouseButton1Click, function()
                cfg.set(opt)
                cfg.open = false
                tween_service:Create(dd_icon, TweenInfo.new(0.2), { Rotation = 0 }):Play()
                dd_list.Visible = false
            end)
        end
        set_height()
    end

    self:connection(dd_btn.MouseButton1Click, function()
        cfg.open = not cfg.open
        tween_service:Create(dd_icon, TweenInfo.new(0.2), { Rotation = cfg.open and 180 or 0 }):Play()
        dd_list.Visible = cfg.open
    end)

    cfg:refresh(cfg.options)
    if cfg.default then cfg.set(cfg.default) end
    self.config_flags[cfg.flag] = cfg.set
    return cfg
end

function library:textbox(props)
    local cfg = {
        placeholder = props.placeholder or "enter text...",
        default = props.default or "",
        flag = props.flag or props.name,
        callback = props.callback or function() end,
        clear_on_focus = props.clear_on_focus or false
    }

    local tb_frame = self:create("TextBox", {
        Name = "textbox",
        Parent = self.holder,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = self.themes.preset.dropdown,
        Text = "",
        PlaceholderText = cfg.placeholder,
        PlaceholderColor3 = self.themes.preset.placeholder,
        Font = Enum.Font.Gotham,
        TextColor3 = self.themes.preset.text,
        TextSize = 12,
        ClearTextOnFocus = cfg.clear_on_focus,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = tb_frame, CornerRadius = UDim.new(0, 4) })
    self:create("UIPadding", { Parent = tb_frame, PaddingLeft = UDim.new(0, 8) })

    cfg.instance = tb_frame

    self:connection(tb_frame.FocusLost, function()
        self.flags[cfg.flag] = tb_frame.Text
        cfg.callback(tb_frame.Text)
    end)

    if cfg.default ~= "" then
        tb_frame.Text = cfg.default
        self.flags[cfg.flag] = cfg.default
    end

    self.config_flags[cfg.flag] = function(val)
        tb_frame.Text = val
        self.flags[cfg.flag] = val
        cfg.callback(val)
    end
    return cfg
end

function library:slider(props)
    local cfg = {
        name = props.name or "slider",
        min = props.min or 0,
        max = props.max or 100,
        default = props.default or 50,
        flag = props.flag or props.name,
        callback = props.callback or function() end,
        dragging = false
    }

    local s_frame = self:create("Frame", { Name = cfg.name, Parent = self.holder, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
    self:create("TextLabel", {
        Name = "name",
        Parent = s_frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = cfg.name,
        TextColor3 = self.themes.preset.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local val_label = self:create("TextLabel", {
        Name = "val",
        Parent = s_frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 30, 0, 16),
        Font = Enum.Font.Gotham,
        Text = tostring(cfg.default),
        TextColor3 = self.themes.preset.placeholder,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    })

    local track = self:create("TextButton", {
        Name = "track",
        Parent = s_frame,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundColor3 = self.themes.preset.dropdown,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = track, CornerRadius = UDim.new(1, 0) })

    local fill = self:create("Frame", {
        Name = "fill",
        Parent = track,
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundColor3 = self.themes.preset.accent,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

    function cfg.set(val)
        val = math.clamp(val, cfg.min, cfg.max)
        cfg.value = val
        self.flags[cfg.flag] = val
        val_label.Text = tostring(val)
        local percent = (val - cfg.min) / (cfg.max - cfg.min)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        cfg.callback(val)
    end

    self:connection(track.MouseButton1Down, function()
        cfg.dragging = true
        local percent = math.clamp((uis:GetMouseLocation().X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        cfg.set(cfg.min + (cfg.max - cfg.min) * percent)
    end)
    self:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then cfg.dragging = false end
    end)
    self:connection(uis.InputChanged, function(input)
        if cfg.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((uis:GetMouseLocation().X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            cfg.set(cfg.min + (cfg.max - cfg.min) * percent)
        end
    end)

    cfg.set(cfg.default)
    self.config_flags[cfg.flag] = cfg.set
    return cfg
end

function library:notification(props)
    local cfg = {
        text = props.text or "notification",
        duration = props.duration or 3
    }

    local notif = self:create("Frame", {
        Name = "notif",
        Parent = self.gui,
        Position = UDim2.new(1, -300, 1, -50),
        Size = UDim2.new(0, 200, 0, 40),
        BackgroundColor3 = self.themes.preset.element_background,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = notif, CornerRadius = UDim.new(0, 4) })
    
    self:create("TextLabel", {
        Name = "text",
        Parent = notif,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Font = Enum.Font.Gotham,
        Text = cfg.text,
        TextColor3 = self.themes.preset.text,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    tween_service:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -210, 1, -50)
    }):Play()

    task.delay(cfg.duration, function()
        tween_service:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 0, 1, -50)
        }):Play()
        task.delay(0.5, function() notif:Destroy() end)
    end)
end

getgenv().library = library
return library
