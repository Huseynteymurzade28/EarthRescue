local love = require("love")

function Bullet(x, y, angle, speed, owner, is_enemy)
    local _vx = math.cos(angle) * speed
    local _vy = math.sin(angle) * speed
    
    return {
        x = x,
        y = y,
        vx = _vx,
        vy = _vy,
        angle = angle,
        radius = is_enemy and 6 or 5,
        owner = owner,
        dead = false,
        is_enemy = is_enemy or false,
        damage = 1,
        is_crit = false,
        pierce_count = 0,
        homing = false,
        homing_strength = 0.5,
        trail = {},

        update = function(self, dt)
            table.insert(self.trail, {x = self.x, y = self.y, life = 0.15})
            if #self.trail > 12 then
                table.remove(self.trail, 1)
            end
            
            for i = #self.trail, 1, -1 do
                self.trail[i].life = self.trail[i].life - dt
                if self.trail[i].life <= 0 then
                    table.remove(self.trail, i)
                end
            end
            
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
            
            if self.x < -50 or self.x > love.graphics.getWidth() + 50 or
               self.y < -50 or self.y > love.graphics.getHeight() + 50 then
                self.dead = true
            end
        end,

        draw = function(self)
            for i, t in ipairs(self.trail) do
                local alpha = (t.life / 0.15) * 0.6
                local size = self.radius * (t.life / 0.15) * 0.8
                if self.is_enemy then
                    love.graphics.setColor(1, 0.2, 0.2, alpha)
                elseif self.is_crit then
                    love.graphics.setColor(1, 0.9, 0.3, alpha)
                else
                    love.graphics.setColor(0.2, 0.9, 1, alpha)
                end
                love.graphics.circle("fill", t.x, t.y, size)
            end
            
            if self.is_enemy then
                love.graphics.setColor(1, 0.1, 0.1)
                love.graphics.circle("fill", self.x, self.y, self.radius)
                
                love.graphics.setColor(1, 0.5, 0.5, 0.8)
                love.graphics.circle("fill", self.x, self.y, self.radius * 0.5)
                
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.circle("fill", self.x, self.y, self.radius * 0.25)
            else
                local main_color = self.is_crit and {1, 0.9, 0.2} or {0.1, 0.8, 1}
                local glow_color = self.is_crit and {1, 0.7, 0} or {0.3, 0.6, 1}
                
                for layer = 1, 3 do
                    local layer_size = self.radius + layer * 3
                    local alpha = (4 - layer) * 0.15
                    love.graphics.setColor(glow_color[1], glow_color[2], glow_color[3], alpha)
                    love.graphics.circle("fill", self.x, self.y, layer_size)
                end
                
                love.graphics.setColor(main_color[1], main_color[2], main_color[3])
                love.graphics.circle("fill", self.x, self.y, self.radius)
                
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.circle("fill", self.x, self.y, self.radius * 0.4)
                
                love.graphics.setColor(main_color[1], main_color[2], main_color[3], 0.6)
                local angle = self.angle
                local tip_x = self.x + math.cos(angle) * self.radius * 1.5
                local tip_y = self.y + math.sin(angle) * self.radius * 1.5
                love.graphics.circle("fill", tip_x, tip_y, self.radius * 0.4)
            end
            
            if not self.is_enemy and self.homing then
                love.graphics.setColor(1, 0.5, 0, 0.5)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", self.x, self.y, self.radius + 5)
                love.graphics.setLineWidth(1)
            end
            
            if self.is_crit and not self.is_enemy then
                love.graphics.setColor(1, 1, 0.5, 0.8)
                love.graphics.setLineWidth(1)
                for i = 0, 3 do
                    local angle = (i / 4) * math.pi * 2 + love.timer.getTime() * 5
                    local dist = self.radius + 8
                    local sx = self.x + math.cos(angle) * dist
                    local sy = self.y + math.sin(angle) * dist
                    love.graphics.circle("fill", sx, sy, 2)
                end
            end
            
            love.graphics.setColor(1, 1, 1)
        end
    }
end

return Bullet
