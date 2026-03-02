local love = require("love")
local Bullet = require("Bullet")

local EnemyType = {}
EnemyType.__index = EnemyType

local ENEMY_TYPES = {
    SCOUT = {
        name = "Scout",
        hp = 1,
        speed = 120,
        radius = 15,
        color = {0.8, 0.3, 0.3},
        score = 10,
        behavior = "chase",
        shoots = false,
        desc = "Fast but fragile"
    },
    SOLDIER = {
        name = "Soldier",
        hp = 3,
        speed = 80,
        radius = 20,
        color = {0.3, 0.8, 0.3},
        score = 25,
        behavior = "chase",
        shoots = true,
        shoot_interval = 2.5,
        shoot_speed = 200,
        desc = "Basic enemy that shoots"
    },
    TANK = {
        name = "Tank",
        hp = 10,
        speed = 40,
        radius = 35,
        color = {0.4, 0.4, 0.8},
        score = 50,
        behavior = "chase",
        shoots = true,
        shoot_interval = 3.5,
        shoot_speed = 150,
        desc = "Slow but tough"
    },
    RUSHER = {
        name = "Rusher",
        hp = 1,
        speed = 200,
        radius = 12,
        color = {1, 0.5, 0},
        score = 15,
        behavior = "rush",
        shoots = false,
        desc = "Very fast, charges at you"
    },
    SWARMER = {
        name = "Swarmer",
        hp = 1,
        speed = 60,
        radius = 10,
        color = {0.8, 0.8, 0.2},
        score = 8,
        behavior = "swarm",
        shoots = false,
        desc = "Weak but appears in groups"
    },
    SNIPER = {
        name = "Sniper",
        hp = 2,
        speed = 30,
        radius = 18,
        color = {0.8, 0.2, 0.8},
        score = 40,
        behavior = "maintain_distance",
        shoots = true,
        shoot_interval = 4,
        shoot_speed = 400,
        desc = "Stays back, shoots fast bullets"
    },
    BOMBER = {
        name = "Bomber",
        hp = 2,
        speed = 50,
        radius = 25,
        color = {1, 0.2, 0.2},
        score = 35,
        behavior = "explode",
        shoots = false,
        explodes = true,
        explode_radius = 80,
        desc = "Explodes when close"
    },
    SPLITTER = {
        name = "Splitter",
        hp = 4,
        speed = 45,
        radius = 28,
        color = {0.3, 0.8, 0.8},
        score = 60,
        behavior = "chase",
        shoots = false,
        splits = true,
        split_count = 3,
        desc = "Splits into smaller enemies"
    },
    WEAVER = {
        name = "Weaver",
        hp = 2,
        speed = 70,
        radius = 16,
        color = {0.9, 0.4, 0.9},
        score = 30,
        behavior = "weave",
        shoots = false,
        desc = "Moves in a zigzag pattern"
    },
    TELEPORTER = {
        name = "Teleporter",
        hp = 3,
        speed = 40,
        radius = 20,
        color = {0.5, 0, 1},
        score = 45,
        behavior = "teleport",
        shoots = true,
        shoot_interval = 3,
        shoot_speed = 250,
        desc = "Teleports around the arena"
    },
    BOSS = {
        name = "Overlord",
        hp = 50,
        speed = 30,
        radius = 60,
        color = {1, 0, 0},
        score = 500,
        behavior = "boss",
        shoots = true,
        shoot_interval = 1.5,
        shoot_speed = 180,
        desc = "The ultimate threat"
    },
    PHANTOM = {
        name = "Phantom",
        hp = 2,
        speed = 90,
        radius = 14,
        color = {0.6, 0.2, 0.8},
        score = 35,
        behavior = "phase",
        shoots = false,
        desc = "Phases in and out of existence"
    },
    GUARDIAN = {
        name = "Guardian",
        hp = 15,
        speed = 35,
        radius = 40,
        color = {0.2, 0.5, 0.7},
        score = 70,
        behavior = "intercept",
        shoots = true,
        shoot_interval = 2,
        shoot_speed = 180,
        desc = "Protects other enemies"
    },
    HORNET = {
        name = "Hornet",
        hp = 1,
        speed = 150,
        radius = 10,
        color = {1, 0.8, 0},
        score = 20,
        behavior = "orbit",
        shoots = false,
        desc = "Orbits around before striking"
    },
    SENTINEL = {
        name = "Sentinel",
        hp = 8,
        speed = 25,
        radius = 30,
        color = {0.3, 0.3, 0.5},
        score = 55,
        behavior = "station",
        shoots = true,
        shoot_interval = 1.8,
        shoot_speed = 220,
        desc = "Stationary turret enemy"
    },
    VORTEX = {
        name = "Vortex",
        hp = 4,
        speed = 55,
        radius = 22,
        color = {0.4, 0, 0.6},
        score = 45,
        behavior = "pull",
        shoots = true,
        shoot_interval = 3,
        shoot_speed = 120,
        pull_strength = 80,
        desc = "Pulls enemies toward it"
    },
    NINJA = {
        name = "Ninja",
        hp = 2,
        speed = 140,
        radius = 13,
        color = {0.1, 0.1, 0.15},
        score = 40,
        behavior = "dash",
        shoots = false,
        dash_interval = 2,
        desc = "Dashes unpredictably"
    },
    MOTH = {
        name = "Moth",
        hp = 3,
        speed = 45,
        radius = 18,
        color = {0.9, 0.6, 0.2},
        score = 30,
        behavior = "zigzag",
        shoots = true,
        shoot_interval = 2.5,
        shoot_speed = 160,
        desc = "Erratic flight pattern"
    }
}

local enemy_img = love.graphics.newImage("assets/Enemy.png")
local w, h = enemy_img:getDimensions()

function EnemyType.new(type_name, level)
    local etype = ENEMY_TYPES[type_name] or ENEMY_TYPES.SCOUT
    
    local function get_spawn_position(radius)
        local dice = math.random(1, 4)
        local _x, _y
        if dice == 1 then
            _x = math.random(0, love.graphics.getWidth())
            _y = -(radius) * 4
        elseif dice == 2 then
            _x = -(radius) * 4
            _y = math.random(0, love.graphics.getHeight())
        elseif dice == 3 then
            _x = math.random(0, love.graphics.getWidth())
            _y = love.graphics.getHeight() + (radius * 4)
        else
            _x = love.graphics.getWidth() + (radius * 4)
            _y = math.random(0, love.graphics.getHeight())
        end
        return _x, _y
    end
    
    local _x, _y = get_spawn_position(etype.radius * 2)
    
    local base_hp = etype.hp
    local hp_multiplier = 1 + (level - 1) * 0.3
    local speed_multiplier = 1 + (level - 1) * 0.08
    
    local shoot_timer = 0
    local teleport_timer = 0
    local weave_timer = 0
    local split_done = false
    local health = base_hp * hp_multiplier
    local max_health = health
    
    local function get_next_enemy_type(level)
        if level < 2 then
            return {"SCOUT"}
        elseif level < 4 then
            return {"SCOUT", "SOLDIER", "RUSHER"}
        elseif level < 6 then
            return {"SCOUT", "SOLDIER", "RUSHER", "SWARMER", "TANK"}
        elseif level < 8 then
            return {"SOLDIER", "RUSHER", "SWARMER", "TANK", "SNIPER", "BOMBER"}
        else
            return {"SOLDIER", "TANK", "SNIPER", "BOMBER", "SPLITTER", "WEAVER", "TELEPORTER"}
        end
    end
    
    return setmetatable({
        type = etype,
        level = level,
        x = _x,
        y = _y,
        radius = etype.radius,
        hp = health,
        max_hp = max_health,
        speed = etype.speed * speed_multiplier,
        shoot_timer = shoot_timer,
        teleport_timer = teleport_timer,
        weave_timer = weave_timer,
        split_done = split_done,
        vx = 0,
        vy = 0,
        angle = 0,
        rotation = 0,
        dead = false,
        alpha = 1,
        phase_timer = 0,
        orbit_timer = 0,
        dash_timer = 0,
        dash_duration = 0,
        is_dashing = false,
        dash_target_x = 0,
        dash_target_y = 0,
        zigzag_timer = 0,
        
        poison_timer = 0,
        burn_timer = 0,
        freeze_timer = 0,
        
        isTouched = function(self, target_x, target_y, target_radius)
            local dx = self.x - target_x
            local dy = self.y - target_y
            return math.sqrt(dx * dx + dy * dy) <= (self.radius + target_radius)
        end,
        
        applyStatus = function(self, status_type, duration)
            if status_type == "poison" then
                self.poison_timer = duration
            elseif status_type == "burn" then
                self.burn_timer = duration
            elseif status_type == "freeze" then
                self.freeze_timer = duration
            end
        end,
        
        updateStatusEffects = function(self, dt)
            local damage = 0
            if self.poison_timer > 0 then
                self.poison_timer = self.poison_timer - dt
                damage = damage + 0.5 * dt
            end
            if self.burn_timer > 0 then
                self.burn_timer = self.burn_timer - dt
                damage = damage + 0.8 * dt
            end
            if self.freeze_timer > 0 then
                self.freeze_timer = self.freeze_timer - dt
                self.speed = self.type.speed * 0.3
            else
                self.speed = self.type.speed * (1 + (self.level - 1) * 0.08)
            end
            if damage > 0 then
                self.hp = self.hp - damage
                if self.hp <= 0 then
                    self.dead = true
                end
            end
        end,
        
        takeDamage = function(self, damage)
            self.hp = self.hp - damage
            if self.hp <= 0 then
                self.dead = true
            end
            return self.dead
        end,
        
        move = function(self, player_x, player_y, dt, player)
            local behavior = self.type.behavior
            local target_x = player_x
            local target_y = player_y
            
            if behavior == "chase" then
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                self.vx = math.cos(angle) * self.speed
                self.vy = math.sin(angle) * self.speed
                
            elseif behavior == "rush" then
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                self.speed = 250
                self.vx = math.cos(angle) * self.speed
                self.vy = math.sin(angle) * self.speed
                
            elseif behavior == "swarm" then
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                local noise = math.sin(weave_timer * 5) * 30
                self.vx = math.cos(angle) * self.speed + math.cos(angle + math.pi/2) * noise
                self.vy = math.sin(angle) * self.speed + math.sin(angle + math.pi/2) * noise
                weave_timer = weave_timer + dt
                
            elseif behavior == "maintain_distance" then
                local dx = target_x - self.x
                local dy = target_y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local ideal_dist = 300
                
                if dist > ideal_dist + 50 then
                    local angle = math.atan2(dy, dx)
                    self.vx = math.cos(angle) * self.speed
                    self.vy = math.sin(angle) * self.speed
                elseif dist < ideal_dist - 50 then
                    local angle = math.atan2(dy, dx)
                    self.vx = -math.cos(angle) * self.speed
                    self.vy = -math.sin(angle) * self.speed
                else
                    self.vx = 0
                    self.vy = 0
                end
                
            elseif behavior == "explode" then
                local dx = target_x - self.x
                local dy = target_y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist < self.type.explode_radius then
                    self.dead = true
                    return "explode", self.x, self.y, self.type.explode_radius
                else
                    local angle = math.atan2(dy, dx)
                    self.vx = math.cos(angle) * self.speed
                    self.vy = math.sin(angle) * self.speed
                end
                
            elseif behavior == "weave" then
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                local weave_amplitude = 50
                local weave_freq = 4
                weave_timer = weave_timer + dt
                local perp_angle = angle + math.pi / 2
                self.vx = math.cos(angle) * self.speed + math.cos(perp_angle) * math.sin(weave_timer * weave_freq) * weave_amplitude
                self.vy = math.sin(angle) * self.speed + math.sin(perp_angle) * math.sin(weave_timer * weave_freq) * weave_amplitude
                
            elseif behavior == "teleport" then
                teleport_timer = teleport_timer + dt
                if teleport_timer > 3 then
                    teleport_timer = 0
                    self.x = player_x + (math.random() - 0.5) * 400
                    self.y = player_y + (math.random() - 0.5) * 400
                    self.x = math.max(50, math.min(love.graphics.getWidth() - 50, self.x))
                    self.y = math.max(50, math.min(love.graphics.getHeight() - 50, self.y))
                end
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                self.vx = math.cos(angle) * self.speed
                self.vy = math.sin(angle) * self.speed
                
            elseif behavior == "boss" then
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                self.vx = math.cos(angle) * self.speed
                self.vy = math.sin(angle) * self.speed
            
            elseif behavior == "phase" then
                self.phase_timer = (self.phase_timer or 0) + dt
                local alpha = 0.5 + math.sin(self.phase_timer * 3) * 0.3
                self.alpha = alpha
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                self.vx = math.cos(angle) * self.speed * alpha
                self.vy = math.sin(angle) * self.speed * alpha
            
            elseif behavior == "intercept" then
                local closest_bullet = nil
                local closest_dist = 500
                if player and player.bullets then
                    for _, b in ipairs(player.bullets or {}) do
                        local d = math.sqrt((self.x - b.x)^2 + (self.y - b.y)^2)
                        if d < closest_dist then
                            closest_dist = d
                            closest_bullet = b
                        end
                    end
                end
                if closest_bullet then
                    local angle = math.atan2(closest_bullet.y - self.y, closest_bullet.x - self.x)
                    self.vx = math.cos(angle) * self.speed * 1.2
                    self.vy = math.sin(angle) * self.speed * 1.2
                else
                    local angle = math.atan2(target_y - self.y, target_x - self.x)
                    self.vx = math.cos(angle) * self.speed * 0.5
                    self.vy = math.sin(angle) * self.speed * 0.5
                end
            
            elseif behavior == "orbit" then
                self.orbit_timer = (self.orbit_timer or 0) + dt
                local orbit_radius = 150
                local orbit_speed = 2
                local target_angle = math.atan2(target_y - self.y, target_x - self.x)
                local orbit_offset = math.sin(self.orbit_timer * orbit_speed) * 1.5
                local final_angle = target_angle + orbit_offset
                local desired_x = target_x + math.cos(final_angle) * orbit_radius
                local desired_y = target_y + math.sin(final_angle) * orbit_radius
                local angle = math.atan2(desired_y - self.y, desired_x - self.x)
                self.vx = math.cos(angle) * self.speed
                self.vy = math.sin(angle) * self.speed
            
            elseif behavior == "station" then
                self.vx = 0
                self.vy = 0
            
            elseif behavior == "pull" then
                local dist = math.sqrt((target_x - self.x)^2 + (target_y - self.y)^2)
                if dist > 100 then
                    local angle = math.atan2(target_y - self.y, target_x - self.x)
                    self.vx = math.cos(angle) * self.speed
                    self.vy = math.sin(angle) * self.speed
                else
                    self.vx = self.vx * 0.95
                    self.vy = self.vy * 0.95
                end
            
            elseif behavior == "dash" then
                self.dash_timer = (self.dash_timer or 0) + dt
                if self.dash_timer > (self.type.dash_interval or 2) then
                    self.dash_timer = 0
                    self.is_dashing = true
                    self.dash_duration = 0.3
                    self.dash_target_x = target_x + (math.random() - 0.5) * 200
                    self.dash_target_y = target_y + (math.random() - 0.5) * 200
                end
                if self.is_dashing then
                    self.dash_duration = (self.dash_duration or 0) - dt
                    local angle = math.atan2(self.dash_target_y - self.y, self.dash_target_x - self.x)
                    self.vx = math.cos(angle) * self.speed * 3
                    self.vy = math.sin(angle) * self.speed * 3
                    if self.dash_duration <= 0 then
                        self.is_dashing = false
                    end
                else
                    local angle = math.atan2(target_y - self.y, target_x - self.x)
                    local noise = math.sin(self.dash_timer * 8) * 30
                    self.vx = math.cos(angle) * self.speed * 0.7 + math.cos(angle + math.pi/2) * noise
                    self.vy = math.sin(angle) * self.speed * 0.7 + math.sin(angle + math.pi/2) * noise
                end
            
            elseif behavior == "zigzag" then
                self.zigzag_timer = (self.zigzag_timer or 0) + dt
                local angle = math.atan2(target_y - self.y, target_x - self.x)
                local zigzag_amp = 60
                local zigzag_freq = 5
                local perp_angle = angle + math.pi / 2
                self.vx = math.cos(angle) * self.speed + math.cos(perp_angle) * math.sin(self.zigzag_timer * zigzag_freq) * zigzag_amp
                self.vy = math.sin(angle) * self.speed + math.sin(perp_angle) * math.sin(self.zigzag_timer * zigzag_freq) * zigzag_amp
            end
            
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
            
            self.rotation = self.rotation + dt * 2
            
            return nil
        end,
        
        updateShooting = function(self, dt, player_x, player_y)
            if not self.type.shoots then return nil end
            
            self.shoot_timer = self.shoot_timer + dt
            if self.shoot_timer >= self.type.shoot_interval then
                self.shoot_timer = 0
                
                local angle = math.atan2(player_y - self.y, player_x - self.x)
                
                if self.type.behavior == "boss" then
                    for i = -2, 2 do
                        local spread = i * 0.3
                        table.insert(bullets, Bullet(self.x, self.y, angle + spread, self.type.shoot_speed, "enemy", true))
                    end
                else
                    return Bullet(self.x, self.y, angle, self.type.shoot_speed, "enemy", true)
                end
            end
            return nil
        end,
        
        trySplit = function(self, all_enemies)
            if self.type.splits and not self.split_done and self.hp <= self.max_hp * 0.5 then
                self.split_done = true
                local types = get_next_enemy_type(self.level)
                for i = 1, self.type.split_count do
                    local new_type = types[math.random(#types)]
                    local new_enemy = EnemyType.new(new_type, self.level)
                    new_enemy.x = self.x + (math.random() - 0.5) * 30
                    new_enemy.y = self.y + (math.random() - 0.5) * 30
                    new_enemy.hp = new_enemy.hp * 0.5
                    new_enemy.max_hp = new_enemy.max_hp * 0.5
                    table.insert(all_enemies, new_enemy)
                end
            end
        end,
        
        getScore = function(self)
            return self.type.score * (1 + (self.level - 1) * 0.2)
        end,
        
        draw = function(self)
            local c = self.type.color
            local time = love.timer.getTime()
            
            for layer = 1, 3 do
                local glow_alpha = (4 - layer) * 0.12
                love.graphics.setColor(c[1], c[2], c[3], glow_alpha)
                love.graphics.circle("fill", self.x, self.y, self.radius + layer * 8)
            end
            
            love.graphics.setColor(c[1], c[2], c[3])
            
            love.graphics.push()
            love.graphics.translate(self.x, self.y)
            love.graphics.rotate(self.rotation)
            
            local scale = self.radius / (w/2)
            if scale < 0.5 then scale = 0.5 end
            
            love.graphics.draw(enemy_img, 0, 0, 0, scale, scale, w/2, h/2)
            
            love.graphics.pop()
            
            love.graphics.setColor(c[1] * 0.8, c[2] * 0.8, c[3] * 0.8, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", self.x, self.y, self.radius + 2)
            
            if self.hp < self.max_hp then
                local bar_width = self.radius * 2
                local bar_height = 5
                local bar_y = self.y - self.radius - 14
                
                love.graphics.setColor(0.2, 0.2, 0.25)
                love.graphics.rectangle("fill", self.x - bar_width/2, bar_y, bar_width, bar_height)
                
                love.graphics.setColor(0.3, 0.9, 0.4)
                love.graphics.rectangle("fill", self.x - bar_width/2, bar_y, bar_width * (self.hp / self.max_hp), bar_height)
                
                love.graphics.setColor(0.5, 1, 0.6, 0.8)
                love.graphics.rectangle("line", self.x - bar_width/2, bar_y, bar_width, bar_height)
            end
            
            local time = love.timer.getTime()
            
            if self.poison_timer > 0 then
                local pulse = math.sin(time * 10) * 0.3 + 0.5
                love.graphics.setColor(0.3, 0.9, 0.3, pulse)
                for i = 1, 5 do
                    local angle = time * 3 + i * 1.2
                    local dist = self.radius + 5 + math.sin(time * 5 + i) * 3
                    local px = self.x + math.cos(angle) * dist
                    local py = self.y + math.sin(angle) * dist
                    love.graphics.circle("fill", px, py, 3)
                end
            end
            
            if self.burn_timer > 0 then
                local pulse = math.sin(time * 15) * 0.3 + 0.6
                love.graphics.setColor(1, 0.4 + pulse * 0.3, 0, pulse)
                for i = 1, 4 do
                    local flame_y = self.y - self.radius - 5 - (i * 4) - math.sin(time * 10 + i * 0.5) * 3
                    love.graphics.circle("fill", self.x + (i - 2.5) * 6, flame_y, 3 + i * 0.5)
                end
            end
            
            if self.freeze_timer > 0 then
                local pulse = math.sin(time * 8) * 0.2 + 0.6
                love.graphics.setColor(0.5, 0.8, 1, pulse)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", self.x, self.y, self.radius + 8)
                love.graphics.circle("line", self.x, self.y, self.radius + 14)
                
                love.graphics.setColor(0.7, 0.9, 1, pulse * 0.8)
                for i = 0, 3 do
                    local angle = i * math.pi / 2 + time * 0.5
                    local sx = self.x + math.cos(angle) * (self.radius + 10)
                    local sy = self.y + math.sin(angle) * (self.radius + 10)
                    love.graphics.line(self.x, self.y, sx, sy)
                end
            end
            
            love.graphics.setColor(1, 1, 1)
        end
    }, EnemyType)
end

function EnemyType.getRandomType(level)
    local types = {}
    if level < 2 then
        types = {"SCOUT", "SWARMER"}
    elseif level < 3 then
        types = {"SCOUT", "SCOUT", "SOLDIER", "SWARMER"}
    elseif level < 4 then
        types = {"SCOUT", "SOLDIER", "RUSHER", "SWARMER", "WEAVER"}
    elseif level < 5 then
        types = {"SCOUT", "SOLDIER", "RUSHER", "SWARMER", "TANK", "BOMBER"}
    elseif level < 6 then
        types = {"SOLDIER", "RUSHER", "SWARMER", "TANK", "BOMBER", "PHANTOM", "NINJA"}
    elseif level < 7 then
        types = {"SOLDIER", "RUSHER", "SWARMER", "TANK", "BOMBER", "SNIPER", "PHANTOM", "HORNET"}
    elseif level < 8 then
        types = {"SOLDIER", "TANK", "BOMBER", "SNIPER", "WEAVER", "TELEPORTER", "PHANTOM", "GUARDIAN", "NINJA"}
    elseif level < 10 then
        types = {"TANK", "BOMBER", "SNIPER", "SPLITTER", "WEAVER", "TELEPORTER", "GUARDIAN", "VORTEX", "MOTH"}
    else
        types = {"TANK", "BOMBER", "SNIPER", "SPLITTER", "WEAVER", "TELEPORTER", "GUARDIAN", "VORTEX", "NINJA", "MOTH", "PHANTOM", "HORNET", "SENTINEL"}
    end
    
    return types[math.random(#types)]
end

function EnemyType.spawnBoss(level)
    local boss = EnemyType.new("BOSS", level)
    boss.x = love.graphics.getWidth() / 2
    boss.y = -100
    return boss
end

return EnemyType
