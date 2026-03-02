local love = require("love")

function love.conf(t)
    t.window.title = "Earth Rescue - Rogue Survivor"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.console = false

    t.modules.joystick = false
    t.modules.physics = false
end
