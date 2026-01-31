local love = require("love")

function Asteroid(level_multiplier, x, y, radius)
    -- If x, y, radius are provided, it's a split piece. Otherwise, it's a new spawn.
    local _x, _y, _radius
    local vx, vy
    local speed
    
    local w, h = love.graphics.getDimensions()

    if x and y and radius then
        -- Split Spawn
        _x = x
        _y = y
        _radius = radius
        speed = math.random(50, 150) + (level_multiplier * 5)
        local angle = math.random() * math.pi * 2
        vx = math.cos(angle) * speed
        vy = math.sin(angle) * speed
    else
        -- Natural Spawn
        local min_start_radius = 20
        local max_start_radius = 50
        _radius = math.random(min_start_radius, max_start_radius)
        speed = math.random(50, 100) + (level_multiplier * 5)
        
        local side = math.random(1, 4)
        if side == 1 then -- Top
            _x = math.random(0, w)
            _y = -_radius * 2
            vx = math.random(-50, 50)
            vy = math.random(50, 100)
        elseif side == 2 then -- Right
            _x = w + _radius * 2
            _y = math.random(0, h)
            vx = math.random(-100, -50)
            vy = math.random(-50, 50)
        elseif side == 3 then -- Bottom
            _x = math.random(0, w)
            _y = h + _radius * 2
            vx = math.random(-50, 50)
            vy = math.random(-100, -50)
        else -- Left
            _x = -_radius * 2
            _y = math.random(0, h)
            vx = math.random(50, 100)
            vy = math.random(-50, 50)
        end
        
        local length = math.sqrt(vx^2 + vy^2)
        vx = (vx / length) * speed
        vy = (vy / length) * speed
    end
    
    -- Random points for "rocky" look
    local points = {}
    local num_points = math.random(7, 12)
    for i = 1, num_points do
        local angle = (i / num_points) * math.pi * 2
        local r = _radius * math.random(80, 120) / 100
        table.insert(points, r * math.cos(angle))
        table.insert(points, r * math.sin(angle))
    end

    local rot_speed = math.random() - 0.5
    local rotation = 0

    return {
        type = "asteroid",
        x = _x,
        y = _y,
        radius = _radius,
        points = points,
        
        isTouched = function (self, x, y, r)
            return math.sqrt((self.x - x) ^ 2 + (self.y - y) ^ 2) <= (self.radius + r)
        end,

        isOffScreen = function(self)
             local margin = 100
             return self.x < -margin or self.x > love.graphics.getWidth() + margin or
                    self.y < -margin or self.y > love.graphics.getHeight() + margin
        end,

        move = function (self, dt)
            self.x = self.x + vx * dt
            self.y = self.y + vy * dt
            rotation = rotation + rot_speed * dt
        end,

        draw = function (self)
            love.graphics.push()
            love.graphics.translate(self.x, self.y)
            love.graphics.rotate(rotation)
            
            love.graphics.setColor(0.6, 0.6, 0.7) 
            love.graphics.setLineWidth(2)
            love.graphics.polygon("line", self.points)
            love.graphics.setLineWidth(1)
            
            love.graphics.pop()
        end
    }
end

return Asteroid
