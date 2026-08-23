-- load the library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/codexvsberserkerxylo/femboy-ware/refs/heads/main/library.luau"))()

-- show loading screen
library:loading_screen({ text = "loading femboy-ware...", duration = 3 })

-- create window
local window = library:window({ title = "femboy-ware | best ui", size = UDim2.new(0, 650, 0, 450) })

-- create a tab
local combat_tab = window:tab({ name = "combat", icon = "up" })

-- create a section
local aimbot_section = combat_tab:section({ name = "aimbot" })

-- add elements to section
local enabled_toggle = aimbot_section:toggle({
    name = "enabled",
    default = false,
    flag = "aimbot_enabled",
    callback = function(val)
        print("aimbot enabled:", val)
    end
})

local smoothness_slider = aimbot_section:slider({
    name = "smoothness",
    min = 0,
    max = 10,
    default = 5,
    flag = "aimbot_smoothness",
    callback = function(val)
        print("smoothness:", val)
    end
})

local bodypart_dropdown = aimbot_section:dropdown({
    name = "target part",
    options = { "Head", "Torso", "Left Arm", "Right Arm" },
    default = "Head",
    flag = "aimbot_part",
    callback = function(val)
        print("target part:", val)
    end
})

-- keybind for aimbot
aimbot_section:keybind({
    name = "aimbot key",
    default = Enum.KeyCode.E,
    flag = "aimbot_key",
    callback = function(key)
        print("aimbot key set to:", key.Name)
    end
})

-- visual tab
local visual_tab = window:tab({ name = "visuals", icon = "expand" })
local esp_section = visual_tab:section({ name = "esp settings" })

esp_section:toggle({
    name = "box esp",
    default = true,
    flag = "esp_box"
})

esp_section:toggle({
    name = "name esp",
    default = false,
    flag = "esp_name"
})

esp_section:button({
    name = "refresh players",
    callback = function()
        library:notification({ text = "players refreshed!" })
    end
})
