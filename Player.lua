local love = require("love")
local Bullet = require("Bullet")

function Player()
    local img = love.graphics.newImage("assets/Player.png")
    local w, h = img:getDimensions()
    
    return {
        radius = (w + h) / 4 * 0.8, -- Approximate radius
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        origin_x = w / 2,
        origin_y = h / 2,
        
        move = function (self, mouse_x, mouse_y)
            self.x = mouse_x
            self.y = mouse_y
        end,

        shoot = function (self)
            -- Shoot upwards
            local b_speed = 600
            local angle = -math.pi / 2
            return Bullet(self.x, self.y - self.radius, angle, b_speed, "player")
        end,

        draw = function (self)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(img, self.x, self.y, 0, 1, 1, self.origin_x, self.origin_y)
        end
    }
end

return Player
