local love = require("love")
local Bullet = require("Bullet")

local enemy_img = love.graphics.newImage("assets/Enemy.png")
local w, h = enemy_img:getDimensions()

function Enemy(_level)
    local dice = math.random(1, 4)
    local _x, _y = 0, 0
    local _radius = (w + h) / 4 * 0.9
    
    -- Pick spawn location
    if dice == 1 then   
        _x = math.random(0, love.graphics.getWidth())
        _y = -(_radius) * 4
    elseif dice == 2 then
        _x = -(_radius) * 4
        _y = math.random(0, love.graphics.getHeight())
    elseif dice == 3 then
        _x = math.random(0, love.graphics.getWidth())
        _y = love.graphics.getHeight() + (_radius * 4) 
    else
        _x = love.graphics.getWidth() + (_radius * 4)    
        _y = math.random(0, love.graphics.getHeight())
    end

    local shoot_timer = 0
    local shoot_interval = 2.0 -- Seconds between shots

    return {
        level = _level or 1,
        radius = _radius,
        x = _x,
        y = _y,
        origin_x = w / 2,
        origin_y = h / 2,

        isTouched = function (self,player_x,player_y,player_radius)
            return math.sqrt((self.x - player_x) ^ 2 + (self.y - player_y) ^ 2) <= (self.radius + player_radius) 
        end,
        
        move = function (self, player_x, player_y, dt)   
            local speed = 60 * (1 + self.level * 0.1) 
            
            -- Move towards player
            local angle = math.atan2(player_y - self.y, player_x - self.x)
            self.x = self.x + math.cos(angle) * speed * dt
            self.y = self.y + math.sin(angle) * speed * dt
        end,

        updateShooting = function(self, dt, player_x, player_y)
            if self.level >= 3 then
                shoot_timer = shoot_timer + dt
                if shoot_timer >= shoot_interval then
                    shoot_timer = 0
                    -- Aim at player
                    local angle = math.atan2(player_y - self.y, player_x - self.x)
                    local bullet_speed = 200
                    return Bullet(self.x, self.y, angle, bullet_speed, "enemy", true)
                end
            end
            return nil
        end,

        draw = function (self)
            -- Rotate to face player? Or just spin?
            -- Let's just draw upright for now, or maybe slow spin
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(enemy_img, self.x, self.y, 0, 1, 1, self.origin_x, self.origin_y)
        end
    }
end

return Enemy
