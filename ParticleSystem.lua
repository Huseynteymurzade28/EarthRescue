local love = require("love")

local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem.new()
    local self = setmetatable({}, ParticleSystem)
    self.particles = {}
    self.screen_shake = {x = 0, y = 0, intensity = 0, duration = 0}
    return self
end

function ParticleSystem:emit(x, y, config)
    local count = config.count or 10
    local color = config.color or {1, 1, 0}
    local speed = config.speed or 100
    local life = config.life or 0.5
    local size = config.size or 3
    local gravity = config.gravity or 0
    local decay = config.decay or 1
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local vel = math.random() * speed
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * vel,
            vy = math.sin(angle) * vel,
            life = life * (0.5 + math.random() * 0.5),
            max_life = life,
            size = size * (0.5 + math.random() * 0.5),
            color = {color[1], color[2], color[3]},
            gravity = gravity,
            decay = decay
        })
    end
end

function ParticleSystem:explosion(x, y, size, color)
    local count = size * 3
    self:emit(x, y, {
        count = count,
        color = color or {1, 0.5, 0},
        speed = size * 40,
        life = 0.6,
        size = size * 0.8,
        decay = 0.8
    })
end

function ParticleSystem:trail(x, y, color, size)
    self:emit(x, y, {
        count = 2,
        color = color or {0, 1, 1},
        speed = 20,
        life = 0.3,
        size = size or 2,
        decay = 1.5
    })
end

function ParticleSystem:hit(x, y, color)
    self:emit(x, y, {
        count = 8,
        color = color or {1, 1, 1},
        speed = 150,
        life = 0.3,
        size = 4
    })
end

function ParticleSystem:powerup(x, y, color)
    for i = 1, 20 do
        local angle = (i / 20) * math.pi * 2
        local dist = 30
        table.insert(self.particles, {
            x = x + math.cos(angle) * dist,
            y = y + math.sin(angle) * dist,
            vx = -math.cos(angle) * 50,
            vy = -math.sin(angle) * 50,
            life = 0.8,
            max_life = 0.8,
            size = 5,
            color = color or {1, 0.8, 0},
            gravity = 0,
            decay = 0.5
        })
    end
end

function ParticleSystem:flash(r, g, b, intensity, duration)
    self.screen_flash = {
        r = r or 1,
        g = g or 1,
        b = b or 1,
        intensity = intensity or 0.5,
        duration = duration or 0.1,
        timer = 0
    }
end

function ParticleSystem:shake(intensity, duration)
    self.screen_shake.intensity = intensity
    self.screen_shake.duration = duration
end

function ParticleSystem:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + p.gravity * dt
        p.life = p.life - dt * p.decay
        
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    
    if self.screen_shake.duration > 0 then
        self.screen_shake.duration = self.screen_shake.duration - dt
        self.screen_shake.x = (math.random() - 0.5) * self.screen_shake.intensity * 2
        self.screen_shake.y = (math.random() - 0.5) * self.screen_shake.intensity * 2
        self.screen_shake.intensity = self.screen_shake.intensity * 0.9
    else
        self.screen_shake.x = 0
        self.screen_shake.y = 0
    end
    
    if self.screen_flash then
        self.screen_flash.timer = self.screen_flash.timer + dt
        if self.screen_flash.timer >= self.screen_flash.duration then
            self.screen_flash = nil
        end
    end
end

function ParticleSystem:draw()
    love.graphics.push()
    love.graphics.translate(self.screen_shake.x, self.screen_shake.y)
    
    for _, p in ipairs(self.particles) do
        local alpha = p.life / p.max_life
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
    
    love.graphics.pop()
    
    if self.screen_flash then
        local alpha = (1 - self.screen_flash.timer / self.screen_flash.duration) * self.screen_flash.intensity
        love.graphics.setColor(self.screen_flash.r, self.screen_flash.g, self.screen_flash.b, alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function ParticleSystem:getShakeOffset()
    return self.screen_shake.x, self.screen_shake.y
end

return ParticleSystem
