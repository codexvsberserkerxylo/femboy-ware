-- services
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local http_service = game:GetService("HttpService")
local coregui = game:GetService("CoreGui")
local run_service = game:GetService("RunService")

local player = players.LocalPlayer

-- library init
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
            dropdown = Color3.fromRGB(35, 35, 35)
        }
    }
}

-- utility functions
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
    for _, conn in next, self.connections do conn:Disconnect() end
    for _, inst in next, self.instances do if inst and inst.Parent then inst:Destroy() end end
    if self.gui then self.gui:Destroy() end
    getgenv().library = nil
end

-- asset manager with question.png fallback
function library:get_icon(name)
    if not isfolder(self.directory) then makefolder(self.directory) end
    local icon_folder = self.directory .. "/icons"
    if not isfolder(icon_folder) then makefolder(icon_folder) end

    local path = icon_folder .. "/" .. name
    if isfile(path) then
        return getcustomasset(path)
    end

    -- fallback to github if not found locally
    local url = "https://raw.githubusercontent.com/codexvsberserkerxylo/femboy-ware/main/assets/icons/" .. name
    local success, data = pcall(function()
        return game:HttpGet(url)
    end)

    -- simple check to ensure we got an image and not a 404 page
    if success and data and #data > 100 then
        writefile(path, data)
        return getcustomasset(path)
    end

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

-- theme manager
function library:apply_theme(instance, theme_name, property)
    if not self.themes.utility then self.themes.utility = {} end
    if not self.themes.utility[theme_name] then self.themes.utility[theme_name] = {} end
    if not self.themes.utility[theme_name][property] then self.themes.utility[theme_name][property] = {} end
    
    table.insert(self.themes.utility[theme_name][property], instance)
    instance[property] = self.themes.preset[theme_name]
end

-- main window
function library:window(props)
    local cfg = {
        title = props.title or "femboy-ware",
        size = props.size or UDim2.new(0, 600, 0, 400)
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
        Size = UDim2.new(1, 0, 0, 40), -- increased height for 24x24 icons
        BackgroundColor3 = self.themes.preset.sidebar,
        BorderSizePixel = 0
    })
    -- added corner to topbar so it doesn't clip
    self:create("UICorner", { Parent = topbar, CornerRadius = UDim.new(0, 6) })

    local title_label = self:create("TextLabel", {
        Name = "title",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -150, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = cfg.title,
        TextColor3 = self.themes.preset.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local content = self:create("Frame", {
        Name = "content",
        Parent = main_frame,
        Position = UDim2.new(0, 8, 0, 48), -- shifted down to account for 40px topbar
        Size = UDim2.new(1, -16, 1, -56),
        BackgroundTransparency = 1
    })

    local sidebar = self:create("Frame", {
        Name = "sidebar",
        Parent = content,
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = self.themes.preset.sidebar,
        BorderSizePixel = 0
    })
    self:create("UICorner", { Parent = sidebar, CornerRadius = UDim.new(0, 4) })

    local sidebar_list = self:create("UIListLayout", {
        Parent = sidebar,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    self:create("UIPadding", { Parent = sidebar, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })

    local tab_content = self:create("Frame", {
        Name = "tab_content",
        Parent = content,
        Position = UDim2.new(0, 148, 0, 0),
        Size = UDim2.new(1, -148, 1, 0),
        BackgroundTransparency = 1
    })

    -- topbar buttons (now 24x24)
    local function make_topbar_button(name, icon, pos_x)
        local btn = self:create("ImageButton", {
            Name = name,
            Parent = topbar,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, pos_x, 0, 8), -- (40-24)/2 = 8
            Size = UDim2.new(0, 24, 0, 24),
            Image = self:get_icon(icon)
        })
        return btn
    end

    local close_btn = make_topbar_button("close", "x.png", -32)
    local minimize_btn = make_topbar_button("minimize", "minimize.png", -64)
    local settings_btn = make_topbar_button("settings", "settings.png", -96)

    -- dragging logic (mobile & pc)
    local dragging, drag_input, drag_start, start_pos
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

    -- topbar logic
    self:connection(close_btn.MouseButton1Click, function()
        self:unload()
    end)

    local minimized = false
    self:connection(minimize_btn.MouseButton1Click, function()
        minimized = not minimized
        -- only shrink y axis
        local target_size = minimized and UDim2.new(cfg.size.X.Scale, cfg.size.X.Offset, 0, 40) or cfg.size
        -- toggle icon
        minimize_btn.Image = minimized and self:get_icon("expand.png") or self:get_icon("minimize.png")
        
        tween_service:Create(main_frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = target_size
        }):Play()
    end)

    -- auto create settings tab
    cfg.settings_tab = self:tab({ name = "settings", icon = "settings.png" })
    cfg.settings_tab.frame.Visible = false
    cfg.settings_tab.frame.Parent = tab_content -- ensure parentage

    self:connection(settings_btn.MouseButton1Click, function()
        if self.current_tab then
            self.current_tab.button.BackgroundTransparency = 1
            self.current_tab.frame.Visible = false
        end
        self.current_tab = cfg.settings_tab
        cfg.settings_tab.button.BackgroundTransparency = 0.5
        cfg.settings_tab.frame.Visible = true
    end)

    -- config system
    cfg.config_section = cfg.settings_tab:section({ name = "configs" })
    
    local config_name_input = cfg.config_section:textbox({ 
        placeholder = "config name", 
        clear_on_focus = true 
    })

    cfg.config_section:button({ 
        name = "save config", 
        callback = function()
            local name = config_name_input.instance.Text
            if name == "" then return end
            
            local config_data = {}
            for flag, val in next, self.flags do
                config_data[flag] = val
            end
            
            local path = self.directory .. "/configs/" .. name .. ".json"
            writefile(path, http_service:JSONEncode(config_data))
            self:notification({ text = "saved config: " .. name })
            cfg.config_section:refresh_configs()
        end 
    })

    cfg.config_section:button({ 
        name = "load config", 
        callback = function()
            local name = config_name_input.instance.Text
            if name == "" then return end
            
            local path = self.directory .. "/configs/" .. name .. ".json"
            if isfile(path) then
                local data = http_service:JSONDecode(readfile(path))
                for flag, val in next, data do
                    if self.config_flags[flag] then
                        self.config_flags[flag](val)
                    end
                end
                self:notification({ text = "loaded config: " .. name })
            else
                self:notification({ text = "config not found!" })
            end
        end 
    })

    function cfg.config_section:refresh_configs()
        if not isfolder(self.directory .. "/configs") then makefolder(self.directory .. "/configs") end
        local files = listfiles(self.directory .. "/configs")
        local names = {}
        for _, file in next, files do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
        if cfg.config_dropdown then
            cfg.config_dropdown:refresh(names)
        end
    end

    cfg.config_dropdown = cfg.config_section:dropdown({ 
        name = "saved configs", 
        options = {}, 
        callback = function(val)
            config_name_input.instance.Text = val
        end
    })
    cfg.config_section:refresh_configs()

    return setmetatable(cfg, { __index = self })
end

-- tab
function library:tab(props)
    local cfg = {
        name = props.name or "tab",
        icon = props.icon or "down.png"
    }

    local button = self:create("TextButton", {
        Name = cfg.name,
        Parent = self.gui.main.content.sidebar,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    })
    self:create("UICorner", { Parent = button, CornerRadius = UDim.new(0, 4) })

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
        Visible = false
    })
    self:create("UIListLayout", { Parent = frame, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    self:create("UIPadding", { Parent = frame, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    cfg.button = button
    cfg.frame = frame

    self:connection(button.MouseButton1Click, function()
        if self.current_tab then
            self.current_tab.button.BackgroundTransparency = 1
            self.current_tab.frame.Visible = false
        end
        self.current_tab = cfg
        button.BackgroundTransparency = 0.5
        frame.Visible = true
    end)

    return setmetatable(cfg, { __index = self })
end

-- section
function library:section(props)
    local cfg = {
        name = props.name or "section",
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
        Image = self:get_icon("down.png")
    })

    local title = self:create("TextLabel", {
        Name = "title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
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
    cfg.elements = {}

    -- smooth dropdown logic
    self:connection(header.MouseButton1Click, function()
        cfg.expanded = not cfg.expanded
        local target_size = cfg.expanded and elements_holder.AbsoluteSize.Y or 0
        local target_rot = cfg.expanded and 0 or 180
        
        tween_service:Create(elements_holder, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, target_size)
        }):Play()
        tween_service:Create(dropdown_icon, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Rotation = target_rot
        }):Play()

        if cfg.expanded then
            task.delay(0.3, function()
                elements_holder.AutomaticSize = Enum.AutomaticSize.Y
            end)
        else
            elements_holder.AutomaticSize = Enum.AutomaticSize.None
        end
    end)

    return setmetatable(cfg, { __index = self })
end

-- toggle
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
        Position = UDim2.new(0, 0, 0, 0),
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

    self:connection(toggle_frame.MouseButton1Click, function()
        cfg.set(not cfg.value)
    end)

    cfg.set(cfg.default)
    self.config_flags[cfg.flag] = cfg.set
    return cfg
end

-- button
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

-- keybind
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
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    cfg.set(input.KeyCode)
                end
                cfg.binding = false
                conn:Disconnect()
            end
        end)
    end)

    cfg.set(cfg.default)
    self.config_flags[cfg.flag] = cfg.set
    return cfg
end

-- dropdown
function library:dropdown(props)
    local cfg = {
        name = props.name or "dropdown",
        options = props.options or {},
        default = props.default or (props.options and props.options[1] or nil),
        flag = props.flag or props.name,
        callback = props.callback or function() end,
        open = false
    }

    local dd_frame = self:create("Frame", {
        Name = cfg.name,
        Parent = self.holder,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1
    })

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
        Image = self:get_icon("down.png")
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

-- textbox
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

-- slider
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

    local s_frame = self:create("Frame", {
        Name = cfg.name,
        Parent = self.holder,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    })

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            cfg.dragging = false
        end
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

-- notification
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

    notif.Position = UDim2.new(1, 0, 1, -50)
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

-- loading screen
function library:loading_screen(props)
    local cfg = {
        text = props.text or "loading...",
        duration = props.duration or 2
    }

    local screen = self:create("Frame", {
        Name = "loader",
        Parent = self.gui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0
    })

    local logo = self:create("ImageLabel", {
        Name = "logo",
        Parent = screen,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -50, 0.5, -50),
        Size = UDim2.new(0, 100, 0, 100),
        Image = self:get_icon("loader.png")
    })

    local text_label = self:create("TextLabel", {
        Name = "text",
        Parent = screen,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -100, 0.5, 60),
        Size = UDim2.new(0, 200, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = cfg.text,
        TextColor3 = self.themes.preset.text,
        TextSize = 14
    })

    -- simple spin animation
    local spin_conn
    spin_conn = run_service.RenderStepped:Connect(function()
        logo.Rotation = logo.Rotation + 2
    end)

    task.delay(cfg.duration, function()
        spin_conn:Disconnect()
        tween_service:Create(screen, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
        tween_service:Create(logo, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
        tween_service:Create(text_label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        task.delay(0.5, function() screen:Destroy() end)
    end)
end

getgenv().library = library
return library
