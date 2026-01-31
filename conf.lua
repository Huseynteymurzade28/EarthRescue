local love = require("love")

function love.conf(t)
    t.window.title = "OrbRescue - Retro Space"
    t.window.width = 1200
    t.window.height = 800
    t.window.resizable = false
    t.window.vsync = 1
    t.console = false

    t.modules.joystick = false
    t.modules.physics = false
end
