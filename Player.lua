local love = require("love")
local Bullet = require("Bullet")

function Player(modifiers)
    modifiers = modifiers or {}
    
    local img = love.graphics.newImage("assets/Player.png")
    local w, h = img:getDimensions()
    
    local speed_mod = modifiers.speed or 1
    local damage_mod = modifiers.damage or 1
    local fire_rate_mod = modifiers.fire_rate or 1
    local crit_chance = modifiers.crit_chance or 0
    local pierce_mod = modifiers.pierce or 0
    local regen = modifiers.regen or 0
    
    return {
        radius = (w + h) / 4 * 0.8,
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        origin_x = w / 2,
        origin_y = h / 2,
        
        hp = (modifiers.starting_hp or 0) + 3,
        max_hp = (modifiers.starting_hp or 0) + 3,
        invulnerable = 0,
        
        shoot_cooldown = 0,
        base_cooldown = 0.2 / fire_rate_mod,
        
        powerups = {
            -- Offense
            triple_shot = 0,
            rapid_fire = 0,
            piercing = 0,
            spread = 0,
            homing = 0,
            critical = 0,
            double_tap = 0,
            multi_shot = 0,
            dragon_breath = 0,
            sniper = 0,
            shotgun = 0,
            laser = 0,
            plasma = 0,
            fireball = 0,
            thunder = 0,
            void_shot = 0,
            spirit_arrow = 0,
            blade_storm = 0,
            
            -- Defense
            shield = 0,
            armor = 0,
            ghost_mode = 0,
            god_mode = 0,
            dodge = 0,
            reflect = 0,
            
            -- Utility
            speed_boost = 0,
            time_slow = 0,
            lifesteal = 0,
            vampirism = 0,
            regen = 0,
            magnet = 0,
            fortune = 0,
            
            -- Special
            chain_lightning = 0,
            explosion = 0,
            energy_orb = 0,
            plasma_storm = 0,
            black_hole = 0,
            meteor_rain = 0,
            ice_nova = 0,
            poison_cloud = 0,
            thunderstorm = 0,
            army_of_shadows = 0,
            gravity_pulse = 0,
            life_drain = 0,
            phase_shift = 0,
            quantum_strike = 0,
            cosmic_ray = 0,
            sunburst = 0,
            frost_arrow = 0,
            flame_wave = 0,
            void_tentacle = 0,
            spirit_bomb = 0,
            infinity_edge = 0,
            echo_strike = 0,
            shadow_clone = 0,
            blood_mist = 0,
            
            -- Ultimate
            apocalypse = 0,
            infinite_power = 0,
            neo = 0,
            berserk = 0,
            phoenix = 0
        },
        
        energy_orbs = {},
        plasma_storms = {},
        black_holes = {},
        
        kill_count = 0,
        
        damage_multiplier = damage_mod,
        crit_chance = crit_chance,
        pierce_count = pierce_mod,
        
        keys = {w = false, a = false, s = false, d = false},
        mouse_down = false,
        
        updateKeys = function(self, key, pressed)
            local k = key:lower()
            if k == "w" or k == "up" then self.keys.w = pressed end
            if k == "a" or k == "left" then self.keys.a = pressed end
            if k == "s" or k == "down" then self.keys.s = pressed end
            if k == "d" or k == "right" then self.keys.d = pressed end
        end,
        
        move = function(self, dt)
            local dx, dy = 0, 0
            
            if self.keys.w then dy = dy - 1 end
            if self.keys.s then dy = dy + 1 end
            if self.keys.a then dx = dx - 1 end
            if self.keys.d then dx = dx + 1 end
            
            if dx ~= 0 or dy ~= 0 then
                local len = math.sqrt(dx * dx + dy * dy)
                dx = dx / len
                dy = dy / len
                
                local speed = 400 * speed_mod * (1 + (self.powerups.speed_boost or 0) * 0.15)
                self.x = self.x + dx * speed * dt
                self.y = self.y + dy * speed * dt
            end
            
            self.x = math.max(self.radius, math.min(love.graphics.getWidth() - self.radius, self.x))
            self.y = math.max(self.radius, math.min(love.graphics.getHeight() - self.radius, self.y))
            
            if self.invulnerable > 0 then
                self.invulnerable = self.invulnerable - dt
            end
            
            self.shoot_cooldown = self.shoot_cooldown - dt
            
            for i = #self.energy_orbs, 1, -1 do
                local orb = self.energy_orbs[i]
                orb.angle = orb.angle + orb.speed * dt
                orb.timer = orb.timer - dt
                if orb.timer <= 0 then
                    table.remove(self.energy_orbs, i)
                end
            end
        end,
        
        takeDamage = function(self, amount)
            if self.invulnerable > 0 then return false end
            
            if self.powerups.shield > 0 then
                self.powerups.shield = self.powerups.shield - 1
                self.invulnerable = 1
                return false
            end
            
            self.hp = self.hp - amount
            self.invulnerable = 1.5
            
            return self.hp <= 0
        end,
        
        heal = function(self, amount)
            self.hp = math.min(self.max_hp, self.hp + amount)
        end,
        
        shoot = function(self, mouse_x, mouse_y, enemies, bullets_ref)
            if self.shoot_cooldown > 0 then return end
            
            local cooldown_reduction = 0
            if self.powerups.rapid_fire > 0 then
                cooldown_reduction = self.powerups.rapid_fire * 0.15
            end
            self.shoot_cooldown = self.base_cooldown * (1 - cooldown_reduction)
            
            local angle = math.atan2(mouse_y - self.y, mouse_x - self.x)
            local base_speed = 700
            
            local function create_bullet(shoot_angle, is_homing, custom_speed)
                local is_crit = math.random() < (self.crit_chance + self.powerups.critical * 0.15)
                local damage_mult = is_crit and 3 or 1
                local b = Bullet(self.x, self.y, shoot_angle, custom_speed or base_speed, "player")
                b.damage = 1 * self.damage_multiplier * damage_mult
                b.is_crit = is_crit
                b.pierce_count = self.pierce_count + self.powerups.piercing
                b.homing = is_homing or (self.powerups.homing > 0)
                b.homing_strength = self.powerups.homing * 0.5
                return b
            end
            
            local bullets_created = {}
            
            local spread_count = 1 + self.powerups.spread * 2 + self.powerups.multi_shot * 7
            local triple_count = self.powerups.triple_shot
            local double_chance = self.powerups.double_tap * 0.15
            
            if spread_count > 1 then
                local start_angle = angle - (spread_count - 1) * 0.08
                for i = 1, spread_count do
                    table.insert(bullets_created, create_bullet(start_angle + (i-1) * 0.08, false))
                    if math.random() < double_chance then
                        table.insert(bullets_created, create_bullet(start_angle + (i-1) * 0.08, false))
                    end
                end
            elseif triple_count > 0 then
                local count = 2 + triple_count * 2
                local start_angle = angle - (count - 1) * 0.12
                for i = 1, count do
                    table.insert(bullets_created, create_bullet(start_angle + (i-1) * 0.12, false))
                    if math.random() < double_chance then
                        table.insert(bullets_created, create_bullet(start_angle + (i-1) * 0.12, false))
                    end
                end
            else
                table.insert(bullets_created, create_bullet(angle, self.powerups.homing > 0))
                if math.random() < double_chance then
                    table.insert(bullets_created, create_bullet(angle, self.powerups.homing > 0))
                end
            end
            
            return bullets_created
        end,
        
        addPowerup = function(self, power_data)
            local apply_funcs = {
                -- Offense stacks
                ["TRIPLE SHOT"] = function() self.powerups.triple_shot = self.powerups.triple_shot + 1 end,
                ["RAPID FIRE"] = function() self.powerups.rapid_fire = self.powerups.rapid_fire + 1 end,
                ["QUICK SLIDES"] = function() self.powerups.speed_boost = self.powerups.speed_boost + 1 end,
                ["SHARP ARROWS"] = function() self.damage_multiplier = self.damage_multiplier * 1.1 end,
                ["LIGHT FOOT"] = function() self.powerups.dodge = (self.powerups.dodge or 0) + 5 end,
                ["STEADY HAND"] = function() end,
                ["FOCUSED MIND"] = function() self.powerups.critical = self.powerups.critical + 1 end,
                ["SWIFT STRIKE"] = function() self.powerups.rapid_fire = self.powerups.rapid_fire + 1 end,
                ["PIERCING SHOT"] = function() self.powerups.piercing = self.powerups.piercing + 1 end,
                ["DOUBLE TAP"] = function() self.powerups.double_tap = self.powerups.double_tap + 1 end,
                ["SPREAD CANNON"] = function() self.powerups.spread = self.powerups.spread + 1 end,
                ["HOMING BOLTS"] = function() self.powerups.homing = self.powerups.homing + 1 end,
                ["CRITICAL STRIKE"] = function() self.powerups.critical = self.powerups.critical + 2 end,
                ["TIME DILATION"] = function() self.powerups.time_slow = self.powerups.time_slow + 1 end,
                ["SNIPER ELITE"] = function() self.powerups.sniper = self.powerups.sniper + 1 end,
                ["SHOTGUN BLAST"] = function() self.powerups.shotgun = self.powerups.shotgun + 1 end,
                ["PLASMA CHARGE"] = function() self.powerups.plasma = self.powerups.plasma + 1 end,
                ["GHOST WALK"] = function() self.powerups.ghost_mode = self.powerups.ghost_mode + 1 end,
                ["THUNDER STRIKE"] = function() self.powerups.thunder = self.powerups.thunder + 1 end,
                ["VOID SHOT"] = function() self.powerups.void_shot = self.powerups.void_shot + 1 end,
                ["SPIRIT ARROW"] = function() self.powerups.spirit_arrow = self.powerups.spirit_arrow + 1 end,
                ["ARMOR PIERCING"] = function() self.powerups.armor = self.powerups.armor + 1 end,
                ["MULTI FIRE"] = function() self.powerups.multi_shot = self.powerups.multi_shot + 1 end,
                ["DRAGON BREATH"] = function() self.powerups.dragon_breath = self.powerups.dragon_breath + 1 end,
                ["PLASMA STORM"] = function()
                    self.powerups.plasma_storm = self.powerups.plasma_storm + 1
                    table.insert(self.plasma_storms, {x = self.x, y = self.y, radius = 40 + self.powerups.plasma_storm * 10, timer = 12, damage = 1.5 + self.powerups.plasma_storm * 0.5})
                end,
                ["GRAVITY WELL"] = function() self.powerups.gravity_pulse = (self.powerups.gravity_pulse or 0) + 1 end,
                ["ARMY OF ONE"] = function() self.powerups.army_of_shadows = (self.powerups.army_of_shadows or 0) + 1 end,
                ["ICE NOVA"] = function() self.powerups.ice_nova = (self.powerups.ice_nova or 0) + 1 end,
                ["POISON CLOUD"] = function() self.powerups.poison_cloud = (self.powerups.poison_cloud or 0) + 1 end,
                ["QUANTUM STRIKE"] = function() self.powerups.quantum_strike = (self.powerups.quantum_strike or 0) + 1 end,
                ["COSMIC RAY"] = function() self.powerups.cosmic_ray = (self.powerups.cosmic_ray or 0) + 1 end,
                ["ECHO STRIKE"] = function() self.powerups.echo_strike = (self.powerups.echo_strike or 0) + 1 end,
                
                -- Defense stacks
                ["BASIC SHIELD"] = function() self.powerups.shield = self.powerups.shield + 1 end,
                ["SHIELD"] = function() self.powerups.shield = self.powerups.shield + 1 end,
                ["MEDIUM ARMOR"] = function() self.powerups.armor = (self.powerups.armor or 0) + 15 end,
                ["PHASE SHIFT"] = function() self.powerups.ghost_mode = self.powerups.ghost_mode + 1 end,
                ["DEFLECTION"] = function() self.powerups.reflect = (self.powerups.reflect or 0) + 1 end,
                ["GHOST MODE"] = function() self.powerups.ghost_mode = self.powerups.ghost_mode + 1 end,
                ["GOD MODE"] = function()
                    self.powerups.god_mode = self.powerups.god_mode + 1
                    self.invulnerable = 5
                end,
                
                -- Utility stacks
                ["ENERGY SALVE"] = function() self:heal(1) end,
                ["REGENERATION"] = function() self.powerups.regen = (self.powerups.regen or 0) + 1 end,
                ["VAMPIRIC TOUCH"] = function() self.powerups.lifesteal = (self.powerups.lifesteal or 0) + 1 end,
                ["VAMPIRE"] = function() self.powerups.vampirism = (self.powerups.vampirism or 0) + 1 end,
                ["LUCK BOOST"] = function() self.powerups.fortune = (self.powerups.fortune or 0) + 1 end,
                ["GOLDEN TOUCH"] = function() end,
                ["MYSTIC ORB"] = function()
                    self.powerups.energy_orb = self.powerups.energy_orb + 1
                    table.insert(self.energy_orbs, {
                        angle = 0,
                        speed = 2 + self.powerups.energy_orb * 0.3,
                        radius = 60 + self.powerups.energy_orb * 12,
                        timer = 15,
                        damage = 0.4 + self.powerups.energy_orb * 0.15
                    })
                end,
                ["ENERGY ORB"] = function()
                    self.powerups.energy_orb = self.powerups.energy_orb + 1
                    table.insert(self.energy_orbs, {
                        angle = 0,
                        speed = 2 + self.powerups.energy_orb * 0.3,
                        radius = 60 + self.powerups.energy_orb * 12,
                        timer = 15,
                        damage = 0.4 + self.powerups.energy_orb * 0.15
                    })
                end,
                
                -- Special stacks
                ["CHAIN LIGHTNING"] = function() self.powerups.chain_lightning = self.powerups.chain_lightning + 1 end,
                ["EXPLOSIVE ROUND"] = function() self.powerups.explosion = self.powerups.explosion + 1 end,
                ["EXPLOSION"] = function() self.powerups.explosion = self.powerups.explosion + 1 end,
                ["POISON TIP"] = function() self.powerups.poison_cloud = (self.powerups.poison_cloud or 0) + 1 end,
                ["ICE SHARD"] = function() self.powerups.ice_nova = (self.powerups.ice_nova or 0) + 1 end,
                ["FLAME TONGUE"] = function() self.powerups.dragon_breath = (self.powerups.dragon_breath or 0) + 1 end,
                ["BURNING ARROW"] = function() self.powerups.dragon_breath = (self.powerups.dragon_breath or 0) + 1 end,
                ["WEAK FREEZE"] = function() end,
                ["SHOCK WAVE"] = function() self.powerups.thunder = (self.powerups.thunder or 0) + 1 end,
                
                -- Epic/Mythic/Legendary
                ["BLACK HOLE"] = function()
                    self.powerups.black_hole = self.powerups.black_hole + 1
                    table.insert(self.black_holes, {x = self.x, y = self.y, radius = 25 + self.powerups.black_hole * 8, timer = 6, pull_strength = 80 + self.powerups.black_hole * 20})
                end,
                ["METEOR RAIN"] = function() self.powerups.meteor_rain = self.powerups.meteor_rain + 1 end,
                ["SUNBURST"] = function() self.powerups.sunburst = (self.powerups.sunburst or 0) + 1 end,
                ["VOID TENTACLES"] = function() end,
                ["PHANTOM ARMY"] = function() self.powerups.shadow_clone = (self.powerups.shadow_clone or 0) + 1 end,
                ["BLOOD RITUAL"] = function() self.powerups.lifesteal = (self.powerups.lifesteal or 0) + 2 end,
                ["THUNDER LORD"] = function() self.powerups.thunderstorm = (self.powerups.thunderstorm or 0) + 1 end,
                ["PHOENIX RISE"] = function() self.max_hp = self.max_hp + 2; self.hp = self.hp + 2 end,
                ["APOCALYPSE"] = function() self.powerups.apocalypse = (self.powerups.apocalypse or 0) + 1 end,
                ["NEO MODE"] = function()
                    self.powerups.neo = (self.powerups.neo or 0) + 1
                    self.damage_multiplier = self.damage_multiplier * 1.5
                    self.base_cooldown = self.base_cooldown * 0.8
                end,
                ["INFINITY EDGE"] = function() self.powerups.infinity_edge = (self.powerups.infinity_edge or 0) + 1 end,
                ["BERSERKER"] = function() self.powerups.berserk = (self.powerups.berserk or 0) + 1 end,
                ["OMEGA STRIKE"] = function() end,
                ["GOD HAND"] = function()
                    self.powerups.neo = (self.powerups.neo or 0) + 1
                    self.invulnerable = 10
                end,
                ["TRANSCENDENCE"] = function()
                    self.damage_multiplier = self.damage_multiplier * 2
                    self.max_hp = self.max_hp + 5
                    self.hp = self.max_hp
                end,
                ["INFINITE POWER"] = function()
                    self.powerups.infinite_power = self.powerups.infinite_power + 1
                    self.damage_multiplier = self.damage_multiplier * 1.5
                    self.base_cooldown = self.base_cooldown * 0.7
                end,
                
                -- Legacy
                ["HOMING MISSILES"] = function() self.powerups.homing = self.powerups.homing + 1 end,
                ["CRITICAL HIT"] = function() self.powerups.critical = self.powerups.critical + 1 end,
                ["TIME SLOW"] = function() self.powerups.time_slow = self.powerups.time_slow + 1 end,
            }
            
            if apply_funcs[power_data.name] then
                apply_funcs[power_data.name]()
            end
        end,
        
        removePowerup = function(self, power_name)
            if self.powerups[power_name] then
                self.powerups[power_name] = 0
            end
        end,
        
        onEnemyKill = function(self, enemies)
            self.kill_count = self.kill_count + 1
            
            local lifesteal_amount = (self.powerups.vampirism or 0) + (self.powerups.lifesteal or 0)
            if lifesteal_amount > 0 then
                if self.kill_count % math.max(1, 12 - lifesteal_amount) == 0 then
                    self:heal(1)
                end
            end
        end,
        
        getTimeSlowFactor = function(self)
            if self.powerups.time_slow > 0 then
                return 1 - (self.powerups.time_slow * 0.15)
            end
            return 1
        end,
        
        draw = function(self, mouse_x, mouse_y)
            local flash = self.invulnerable > 0 and (math.floor(self.invulnerable * 20) % 2 == 0)
            
            if not flash then
                love.graphics.setColor(1, 1, 1)
                local angle = 0
                if mouse_x and mouse_y then
                    angle = math.atan2(mouse_y - self.y, mouse_x - self.x) + math.pi / 2
                end
                love.graphics.draw(img, self.x, self.y, angle, 1, 1, self.origin_x, self.origin_y)
            end
            
            local time = love.timer.getTime()
            
            if self.powerups.shield > 0 then
                local shield_alpha = 0.3 + math.sin(time * 3) * 0.15
                love.graphics.setColor(0.3, 0.6, 1, shield_alpha)
                love.graphics.circle("fill", self.x, self.y, self.radius + 15 + self.powerups.shield * 3)
                love.graphics.setColor(0.5, 0.8, 1, 0.8)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", self.x, self.y, self.radius + 15 + self.powerups.shield * 3)
            end
            
            if self.powerups.ghost_mode > 0 and self.invulnerable > 0 then
                love.graphics.setColor(0.6, 0.8, 1, 0.3)
                for i = 1, 3 do
                    local ghost_x = self.x + math.sin(time * 5 + i) * 20
                    local ghost_y = self.y + math.cos(time * 4 + i) * 15
                    love.graphics.circle("fill", ghost_x, ghost_y, self.radius * 0.8)
                end
            end
            
            for _, orb in ipairs(self.energy_orbs) do
                local orb_time = time + orb.angle
                local ox = self.x + math.cos(orb_time) * orb.radius
                local oy = self.y + math.sin(orb_time) * orb.radius
                
                for layer = 1, 3 do
                    local alpha = (4 - layer) * 0.15
                    love.graphics.setColor(0.3, 0.6, 1, alpha)
                    love.graphics.circle("fill", ox, oy, 10 + layer * 4)
                end
                
                love.graphics.setColor(0.5, 0.9, 1, 0.9)
                love.graphics.circle("fill", ox, oy, 8)
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.circle("fill", ox, oy, 4)
            end
            
            for _, storm in ipairs(self.plasma_storms or {}) do
                local storm_alpha = (storm.timer / 10) * 0.3
                love.graphics.setColor(0.8, 0.2, 1, storm_alpha)
                love.graphics.circle("fill", storm.x, storm.y, storm.radius)
                love.graphics.setColor(1, 0.5, 1, storm_alpha * 0.5)
                love.graphics.circle("line", storm.x, storm.y, storm.radius * 0.7)
            end
            
            for _, bh in ipairs(self.black_holes or {}) do
                local bh_alpha = (bh.timer / 5) * 0.4
                love.graphics.setColor(0.2, 0, 0.3, bh_alpha)
                love.graphics.circle("fill", bh.x, bh.y, bh.radius)
                love.graphics.setColor(0.5, 0, 0.8, bh_alpha * 0.8)
                love.graphics.circle("line", bh.x, bh.y, bh.radius * 0.6)
                love.graphics.setColor(1, 1, 1, bh_alpha)
                love.graphics.circle("fill", bh.x, bh.y, 5)
            end
            
            if self.powerups.dragon_breath > 0 and self.mouse_down then
                local angle_to_mouse = math.atan2(love.mouse.getY() - self.y, love.mouse.getX() - self.x)
                for i = 1, 5 do
                    local flame_angle = angle_to_mouse + (i - 3) * 0.15
                    local dist = 30 + i * 8
                    local fx = self.x + math.cos(flame_angle) * dist
                    local fy = self.y + math.sin(flame_angle) * dist
                    local flame_size = 8 + math.random(-2, 2)
                    love.graphics.setColor(1, 0.5 + math.random() * 0.3, 0, 0.7)
                    love.graphics.circle("fill", fx, fy, flame_size)
                end
            end
            
            if self.powerups.god_mode > 0 then
                local god_glow = math.sin(time * 8) * 0.3 + 0.7
                love.graphics.setColor(1, 0.9, 0.3, god_glow * 0.3)
                love.graphics.circle("fill", self.x, self.y, self.radius + 30)
                love.graphics.setColor(1, 0.9, 0.5, god_glow)
                love.graphics.setLineWidth(3)
                love.graphics.circle("line", self.x, self.y, self.radius + 20)
            end
            
            love.graphics.setColor(1, 1, 1)
        end,
        
        drawHUD = function(self)
            local font = love.graphics.getFont()
            
            for i = 1, self.max_hp do
                local hx = 20 + (i - 1) * 35
                local hy = love.graphics.getHeight() - 40
                
                if i <= self.hp then
                    love.graphics.setColor(0.2, 0.9, 0.4)
                    love.graphics.rectangle("fill", hx, hy, 28, 20)
                else
                    love.graphics.setColor(0.3, 0.3, 0.3)
                    love.graphics.rectangle("fill", hx, hy, 28, 20)
                end
                
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.rectangle("line", hx, hy, 28, 20)
            end
            
            local active_powers = {}
            local power_names = {
                triple_shot = {name = "Triple", color = {0.7, 0.7, 0.7}},
                rapid_fire = {name = "Rapid", color = {0.7, 0.7, 0.7}},
                piercing = {name = "Pierce", color = {0.3, 0.8, 0.4}},
                spread = {name = "Spread", color = {0.3, 0.6, 1}},
                homing = {name = "Homing", color = {0.3, 0.6, 1}},
                shield = {name = "Shield", color = {0.3, 0.6, 1}},
                chain_lightning = {name = "Chain", color = {0.7, 0.4, 0.9}},
                explosion = {name = "Explode", color = {0.3, 0.8, 0.4}},
                critical = {name = "Crit", color = {0.3, 0.6, 1}},
                energy_orb = {name = "Orb", color = {0.7, 0.4, 0.9}},
                time_slow = {name = "Slow", color = {0.3, 0.6, 1}},
                vampirism = {name = "Vampire", color = {0.7, 0.4, 0.9}},
                double_tap = {name = "Double", color = {0.3, 0.8, 0.4}},
                speed_boost = {name = "Speed", color = {0.7, 0.7, 0.7}},
                dragon_breath = {name = "Fire", color = {1, 0.4, 0.1}},
                plasma_storm = {name = "Plasma", color = {0.7, 0.4, 0.9}},
                multi_shot = {name = "Multi", color = {0.7, 0.4, 0.9}},
                ghost_mode = {name = "Ghost", color = {0.5, 0.8, 1}},
                black_hole = {name = "Void", color = {0.4, 0.1, 0.5}},
                god_mode = {name = "GOD", color = {1, 0.85, 0.2}},
                meteor_rain = {name = "Meteor", color = {0.4, 0.1, 0.5}},
                infinite_power = {name = "INF", color = {1, 0.85, 0.2}},
                armor = {name = "Armor", color = {0.3, 0.6, 1}},
                lifesteal = {name = "Leech", color = {0.7, 0.4, 0.9}},
                poison_cloud = {name = "Poison", color = {0.3, 0.8, 0.3}},
                ice_nova = {name = "Ice", color = {0.5, 0.8, 1}},
                thunder = {name = "Thunder", color = {1, 0.9, 0.3}},
                quantum_strike = {name = "Quantum", color = {0.7, 0.4, 0.9}},
                sunburst = {name = "Sun", color = {1, 0.6, 0.1}},
                apocalypse = {name = "APOCALYPSE", color = {1, 0.1, 0.1}},
                neo = {name = "NEO", color = {0.1, 1, 0.9}},
                phoenix = {name = "Phoenix", color = {1, 0.5, 0.1}},
                berserk = {name = "Berserk", color = {1, 0.2, 0.2}},
            }
            
            for name, level in pairs(self.powerups) do
                if level > 0 and power_names[name] then
                    table.insert(active_powers, {
                        name = power_names[name].name, 
                        level = level, 
                        id = name,
                        color = power_names[name].color
                    })
                end
            end
            
            local max_slots = 5
            local slot_size = 50
            local slot_spacing = 8
            local hotbar_width = max_slots * slot_size + (max_slots - 1) * slot_spacing
            local hotbar_x = love.graphics.getWidth() / 2 - hotbar_width / 2
            local hotbar_y = love.graphics.getHeight() - 90
            
            love.graphics.setColor(0.05, 0.05, 0.12, 0.9)
            love.graphics.rectangle("fill", hotbar_x - 10, hotbar_y - 10, hotbar_width + 20, slot_size + 35)
            love.graphics.setColor(0.15, 0.25, 0.4, 0.6)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", hotbar_x - 10, hotbar_y - 10, hotbar_width + 20, slot_size + 35)
            
            love.graphics.setFont(love.graphics.newFont(12))
            love.graphics.setColor(0.5, 0.6, 0.8)
            love.graphics.printf("SKILLS", hotbar_x, hotbar_y - 25, hotbar_width, "center")
            
            local time = love.timer.getTime()
            
            for i = 1, max_slots do
                local sx = hotbar_x + (i - 1) * (slot_size + slot_spacing)
                local sy = hotbar_y
                
                local power = active_powers[i]
                
                if power then
                    local pulse = math.sin(time * 3 + i) * 0.15 + 0.85
                    
                    for layer = 1, 3 do
                        local alpha = (4 - layer) * 0.08 * pulse
                        love.graphics.setColor(power.color[1], power.color[2], power.color[3], alpha)
                        love.graphics.rectangle("fill", sx - layer*2, sy - layer*2, slot_size + layer*4, slot_size + layer*4)
                    end
                    
                    love.graphics.setColor(power.color[1] * 0.2, power.color[2] * 0.2, power.color[3] * 0.2, 0.9)
                    love.graphics.rectangle("fill", sx, sy, slot_size, slot_size)
                    
                    love.graphics.setColor(power.color[1], power.color[2], power.color[3], 0.8)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", sx, sy, slot_size, slot_size)
                    
                    love.graphics.setFont(love.graphics.newFont(14))
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(power.name, sx + slot_size/2 - love.graphics.getFont():getWidth(power.name)/2, sy + 8)
                    
                    love.graphics.setFont(love.graphics.newFont(11))
                    love.graphics.setColor(0.8, 0.8, 0.9)
                    love.graphics.print("x" .. power.level, sx + slot_size/2 - love.graphics.getFont():getWidth("x" .. power.level)/2, sy + 28)
                    
                else
                    love.graphics.setColor(0.1, 0.1, 0.15, 0.7)
                    love.graphics.rectangle("fill", sx, sy, slot_size, slot_size)
                    
                    love.graphics.setColor(0.2, 0.25, 0.3, 0.5)
                    love.graphics.setLineWidth(1)
                    love.graphics.rectangle("line", sx, sy, slot_size, slot_size)
                end
            end
            
            if #active_powers > max_slots then
                love.graphics.setFont(love.graphics.newFont(10))
                love.graphics.setColor(1, 0.8, 0.3)
                love.graphics.print("+" .. (#active_powers - max_slots) .. " more", hotbar_x + hotbar_width + 15, hotbar_y + 18)
            end
            
            local tracker_x = love.graphics.getWidth() - 230
            local tracker_y = 80
            local tracker_height = math.max(#active_powers * 16 + 20, 60)
            
            love.graphics.setColor(0.2, 0.3, 0.5, 0.6)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", tracker_x - 5, tracker_y - 5, 215, tracker_height + 5)
                
                love.graphics.setFont(love.graphics.newFont(11))
                for i, p in ipairs(active_powers) do
                    local py = tracker_y + i * 16
                    
                    local rarity_color = {0.7, 0.7, 0.7}
                    if p.level >= 5 then rarity_color = {1, 0.85, 0.2}
                    elseif p.level >= 3 then rarity_color = {0.7, 0.4, 1}
                    elseif p.level >= 2 then rarity_color = {0.3, 0.6, 1} end
                    
                    love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3])
                    love.graphics.print(p.name .. " x" .. p.level, tracker_x, py)
                end
            
            love.graphics.setColor(1, 1, 1)
        end
    }
end

return Player
