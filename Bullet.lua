local love = require("love")

function Bullet(x, y, angle, speed, owner, is_enemy)
    local _vx = math.cos(angle) * speed
    local _vy = math.sin(angle) * speed
    
    return {
        x = x,
        y = y,
        vx = _vx,
        vy = _vy,
        radius = 3,
        owner = owner, -- "player" or "enemy"
        dead = false,
        is_enemy = is_enemy or false,

        update = function(self, dt)
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
            
            -- Bounds check
            if self.x < 0 or self.x > love.graphics.getWidth() or
               self.y < 0 or self.y > love.graphics.getHeight() then
                self.dead = true
            end
        end,

        draw = function(self)
            if self.is_enemy then
                love.graphics.setColor(1, 0, 0)
            else
                love.graphics.setColor(0, 1, 1) -- Cyan for player
            end
            love.graphics.circle("fill", self.x, self.y, self.radius)
        end
    }
end

return Bullet
