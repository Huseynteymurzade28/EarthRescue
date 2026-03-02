local love = require("love")
local EnemyType = require("EnemyType")
local Player = require("Player")
local Button = require("Button")
local Bullet = require("Bullet")
local Power = require("Power")
local ParticleSystem = require("ParticleSystem")
local UpgradeManager = require("UpgradeManager")

math.randomseed(os.time())

local game = {
    difficulty = 1,
    state = {
        menu = true,
        settings = false,
        paused = false,
        running = false,
        gameover = false,
        choose_power = false,
        upgrades = false
    },
    points = 0,
    combo = 0,
    combo_timer = 0,
    combo_multiplier = 1,
    levels = {30, 60, 100, 150, 210, 280, 360, 450, 550, 660},
    current_level = 1,
    session_currency = 0,
    wave_timer = 0,
    wave_number = 1,
    enemies_per_wave = 5
}

local fonts = {
    small = {font = love.graphics.newFont(14), size = 14},
    medium = {font = love.graphics.newFont(18), size = 18},
    large = {font = love.graphics.newFont(28), size = 28},
    gigantic = {font = love.graphics.newFont(50), size = 50},
}

local player = nil
local player_modifiers = {}

local power_system = Power.new()
local particles = ParticleSystem.new()
local upgrade_manager = UpgradeManager.new()

local buttons = {
    menu_state = {},
    game_over = {},
    upgrades = {}
}

local enemies = {}
local bullets = {}
local enemy_bullets = {}

local asteroid_timer = 0
local asteroid_spawn_rate = 2
local enemy_spawn_timer = 0
local enemy_spawn_rate = 2

local stars = {}
local nebula_clouds = {}
local particles_bg = {}

local function createStars()
    stars = {}
    nebula_clouds = {}
    particles_bg = {}
    
    for i = 1, 300 do
        table.insert(stars, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            size = math.random(0.5, 3),
            speed = math.random(5, 30),
            brightness = math.random(0.3, 1),
            twinkle = math.random(0, math.pi * 2),
            color_type = math.random(1, 4)
        })
    end
    
    for i = 1, 12 do
        table.insert(nebula_clouds, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            radius = math.random(200, 500),
            color = {math.random(0.05, 0.15), math.random(0.02, 0.1), math.random(0.15, 0.3)},
            alpha = math.random(0.02, 0.05),
            speed = math.random(3, 15),
            rotation = math.random(0, math.pi * 2),
            rot_speed = (math.random() - 0.5) * 0.1
        })
    end
    
    for i = 1, 50 do
        table.insert(particles_bg, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            vx = (math.random() - 0.5) * 10,
            vy = (math.random() - 0.5) * 10,
            size = math.random(1, 3),
            life = math.random(3, 8),
            max_life = math.random(3, 8),
            color_type = math.random(1, 3)
        })
    end
end

local function drawBackground(time)
    love.graphics.setColor(0.01, 0.01, 0.03)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    for _, cloud in ipairs(nebula_clouds) do
        cloud.rotation = cloud.rotation + cloud.rot_speed * 0.01
        local cy = (cloud.y + cloud.speed * time * 0.5) % (love.graphics.getHeight() + cloud.radius * 2) - cloud.radius
        
        love.graphics.setColor(cloud.color[1], cloud.color[2], cloud.color[3], cloud.alpha)
        love.graphics.push()
        love.graphics.translate(cloud.x, cy)
        love.graphics.rotate(cloud.rotation)
        love.graphics.circle("fill", 0, 0, cloud.radius)
        love.graphics.circle("fill", cloud.radius * 0.6, cloud.radius * 0.3, cloud.radius * 0.6)
        love.graphics.circle("fill", -cloud.radius * 0.4, -cloud.radius * 0.2, cloud.radius * 0.5)
        love.graphics.pop()
    end
    
    for _, star in ipairs(stars) do
        local sy = (star.y + star.speed * time) % love.graphics.getHeight()
        local twinkle = math.sin(time * 2 + star.twinkle) * 0.4 + 0.6
        
        local r, g, b = 0.8, 0.9, 1
        if star.color_type == 2 then r, g, b = 1, 0.9, 0.7
        elseif star.color_type == 3 then r, g, b = 0.7, 0.8, 1
        elseif star.color_type == 4 then r, g, b = 1, 0.7, 0.8 end
        
        love.graphics.setColor(r, g, b, star.brightness * twinkle)
        love.graphics.circle("fill", star.x, sy, star.size)
        
        if star.size > 2 then
            love.graphics.setColor(r, g, b, star.brightness * twinkle * 0.3)
            love.graphics.circle("fill", star.x, sy, star.size * 2)
        end
    end
    
    for _, p in ipairs(particles_bg) do
        p.x = p.x + p.vx * 0.01
        p.y = p.y + p.vy * 0.01
        p.life = p.life - 0.016
        
        if p.life <= 0 or p.x < 0 or p.x > love.graphics.getWidth() or p.y < 0 or p.y > love.graphics.getHeight() then
            p.x = math.random(0, love.graphics.getWidth())
            p.y = math.random(0, love.graphics.getHeight())
            p.life = p.max_life
        end
        
        local alpha = (p.life / p.max_life) * 0.5
        local r, g, b = 0.3, 0.5, 1
        if p.color_type == 2 then r, g, b = 1, 0.5, 0.3
        elseif p.color_type == 3 then r, g, b = 0.3, 1, 0.5 end
        
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

local function changeGameState(state)
    for k, v in pairs(game.state) do
        game.state[k] = (k == state)
    end
end

local function getPlayerModifiers()
    return {
        speed = upgrade_manager:getModifier("speed_up"),
        damage = upgrade_manager:getModifier("damage_up"),
        fire_rate = upgrade_manager:getModifier("fire_rate"),
        starting_hp = upgrade_manager:getModifier("starting_hp"),
        crit_chance = upgrade_manager:getModifier("crit_chance"),
        pierce = upgrade_manager:getModifier("pierce_up"),
        regen = upgrade_manager:getModifier("regen")
    }
end

local function startNewGame()
    changeGameState("running")
    
    player_modifiers = getPlayerModifiers()
    player = Player(player_modifiers)
    
    game.points = 0
    game.combo = 0
    game.combo_timer = 0
    game.combo_multiplier = 1
    game.difficulty = 1
    game.current_level = 1
    game.session_currency = 0
    game.wave_timer = 0
    game.wave_number = 1
    game.enemies_per_wave = 3
    
    enemies = {}
    bullets = {}
    enemy_bullets = {}
    enemy_spawn_timer = 0
    enemy_spawn_rate = 3
    
    local starting_types = EnemyType.getRandomType(1)
    local starting_enemy = EnemyType.new(starting_types, 1)
    table.insert(enemies, starting_enemy)
    
    player.hp = player.max_hp
    
    power_system = Power.new()
    particles = ParticleSystem.new()
end

local function goMenu()
    changeGameState("menu")
end

local function goUpgrades()
    changeGameState("upgrades")
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if game.state.menu then
            for _, btn in pairs(buttons.menu_state) do
                btn:on_mouse_pressed(x, y, button)
            end
        elseif game.state.gameover then
            for _, btn in pairs(buttons.game_over) do
                btn:on_mouse_pressed(x, y, button)
            end
        elseif game.state.upgrades then
            local upgrades_list = upgrade_manager:getEligibleUpgrades()
            
            local mx, my = love.mouse.getPosition()
            local start_x = cx - 300
            local start_y = cy - 40
            local cols = 2
            local btn_w, btn_h = 280, 55
            local spacing = 15
            
            for i, u in ipairs(upgrades_list) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local bx = start_x + col * (btn_w + spacing)
                local by = start_y + row * (btn_h + spacing)
                
                local hovered = mx >= bx and mx <= bx + btn_w and my >= by and my <= by + btn_h
                
                if hovered and button == 1 then
                    if upgrade_manager:canAfford(u.id) then
                        upgrade_manager:purchase(u.id)
                    end
                end
            end
            
            local back_btn_x = cx - 130
            local back_btn_y = love.graphics.getHeight() - 80
            local back_hovered = mx >= back_btn_x and mx <= back_btn_x + 260 and my >= back_btn_y and my <= back_btn_y + 65
            if back_hovered and button == 1 then
                goMenu()
            end
        elseif game.state.choose_power then
            local cx = love.graphics.getWidth() / 2
            local cy = love.graphics.getHeight() / 2
            local selected = power_system:handle_click(x, y)
            if selected then
                player:addPowerup(selected)
                particles:powerup(player.x, player.y, {1, 0.8, 0})
                particles:flash(1, 0.9, 0.3, 0.3, 0.2)
                game.state.choose_power = false
            else
                local close_btn = power_system:getCloseButton()
                if close_btn and close_btn.hover then
                    power_system:skip_offer()
                    game.state.choose_power = false
                end
            end
        elseif game.state.running then
            player.mouse_down = true
        end
    elseif button == 2 then
        if game.state.running then
            local mx, my = x, y
            local max_slots = 5
            local slot_size = 50
            local slot_spacing = 8
            local hotbar_width = max_slots * slot_size + (max_slots - 1) * slot_spacing
            local hotbar_x = love.graphics.getWidth() / 2 - hotbar_width / 2
            local hotbar_y = love.graphics.getHeight() - 90
            
            for i = 1, max_slots do
                local sx = hotbar_x + (i - 1) * (slot_size + slot_spacing)
                local sy = hotbar_y
                if mx >= sx and mx <= sx + slot_size and my >= sy and my <= sy + slot_size then
                    local active_powers = {}
                    local power_names = {
                        triple_shot = true, rapid_fire = true, piercing = true, spread = true, homing = true,
                        shield = true, chain_lightning = true, explosion = true, critical = true, energy_orb = true,
                        time_slow = true, vampirism = true, double_tap = true, speed_boost = true, dragon_breath = true,
                        plasma_storm = true, multi_shot = true, ghost_mode = true, black_hole = true, god_mode = true,
                        meteor_rain = true, infinite_power = true, armor = true, lifesteal = true, poison_cloud = true,
                        ice_nova = true, thunder = true, quantum_strike = true, sunburst = true, apocalypse = true,
                        neo = true, phoenix = true, berserk = true
                    }
                    for name, level in pairs(player.powerups) do
                        if level > 0 and power_names[name] then
                            table.insert(active_powers, {id = name, level = level})
                        end
                    end
                    if active_powers[i] then
                        player:removePowerup(active_powers[i].id)
                        particles:explosion(mx, my, 30, {1, 0.3, 0.3})
                    end
                    break
                end
            end
        end
        if game.state.choose_power then
            power_system:skip_offer()
            game.state.choose_power = false
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and game.state.running then
        player.mouse_down = false
    end
end

function love.keypressed(key)
    if game.state.running then
        player:updateKeys(key, true)
    end
    if key == "escape" then
        if game.state.choose_power then
            power_system:skip_offer()
            game.state.choose_power = false
        elseif game.state.running then
            game.state.paused = not game.state.paused
        end
    end
    if key == "f11" or key == "f" then
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    end
end

function love.keyreleased(key)
    if game.state.running then
        player:updateKeys(key, false)
    end
end

function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    createStars()
    
    local bw, bh = 260, 65
    
    buttons.menu_state.play = Button("PLAY", startNewGame, nil, bw, bh)
    buttons.menu_state.upgrades = Button("UPGRADES", goUpgrades, nil, bw, bh)
    buttons.menu_state.exit = Button("QUIT", love.event.quit, nil, bw, bh)
    
    buttons.game_over.replay = Button("TRY AGAIN", startNewGame, nil, bw, bh)
    buttons.game_over.menu = Button("MENU", goMenu, nil, bw, bh)
    buttons.game_over.exit = Button("QUIT", love.event.quit, nil, bw, bh)
    
    local upgrades_list = upgrade_manager:getEligibleUpgrades()
    for _, u in ipairs(upgrades_list) do
        buttons.upgrades[u.id] = Button(u.data.name .. " Lv." .. (u.level + 1), function() end, nil, 280, 50)
    end
    buttons.upgrades.back = Button("BACK", goMenu, nil, bw, bh)
end

function love.update(dt)
    local mouse_x, mouse_y = love.mouse.getPosition()
    
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed * dt
        if star.y > love.graphics.getHeight() then
            star.y = -5
            star.x = math.random(0, love.graphics.getWidth())
        end
    end
    
    particles:update(dt)
    
    power_system:update(dt, player, game)
    
    if game.state.choose_power then
        return
    end
    
    if not game.state.running then return end
    
    local time_slow = player:getTimeSlowFactor()
    local effective_dt = dt * time_slow
    
    player:move(dt)
    
    if player.mouse_down then
        local bullet_list = player:shoot(mouse_x, mouse_y, enemies, bullets)
        if bullet_list then
            for _, b in ipairs(bullet_list) do
                table.insert(bullets, b)
            end
        end
    end
    
    for _, orb in ipairs(player.energy_orbs) do
        local ox = player.x + math.cos(orb.angle) * orb.radius
        local oy = player.y + math.sin(orb.angle) * orb.radius
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            local dist = math.sqrt((ox - e.x)^2 + (oy - e.y)^2)
            if dist < e.radius + 10 then
                if e:takeDamage(orb.damage * dt * 10) then
                    local score = e:getScore()
                    game.points = game.points + score * game.combo_multiplier
                    player:onEnemyKill(enemies)
                    particles:explosion(e.x, e.y, e.radius, {0.5, 0.8, 1})
                    table.remove(enemies, i)
                end
            end
        end
    end
    
    game.wave_timer = game.wave_timer + dt
    
    enemy_spawn_timer = enemy_spawn_timer + dt
    local spawn_threshold = math.max(0.8, 3 - game.current_level * 0.2)
    local max_enemies = 3 + game.current_level + math.floor(game.wave_number / 3)
    if enemy_spawn_timer > spawn_threshold and #enemies < max_enemies then
        enemy_spawn_timer = 0
        local etype = EnemyType.getRandomType(game.current_level)
        table.insert(enemies, EnemyType.new(etype, game.current_level))
    end
    
    if game.wave_timer > 45 then
        game.wave_timer = 0
        game.wave_number = game.wave_number + 1
        
        if game.wave_number % 5 == 0 and game.wave_number > 5 then
            local boss = EnemyType.spawnBoss(game.current_level)
            table.insert(enemies, boss)
            particles:flash(1, 0, 0, 0.4, 0.5)
            particles:shake(10, 1)
        end
    end
    
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        
        if b.homing and #enemies > 0 then
            local closest = enemies[1]
            local closest_dist = math.huge
            for _, e in ipairs(enemies) do
                local d = math.sqrt((b.x - e.x)^2 + (b.y - e.y)^2)
                if d < closest_dist then
                    closest_dist = d
                    closest = e
                end
            end
            if closest then
                local target_angle = math.atan2(closest.y - b.y, closest.x - b.x)
                local current_angle = math.atan2(b.vy, b.vx)
                local diff = target_angle - current_angle
                while diff > math.pi do diff = diff - 2 * math.pi end
                while diff < -math.pi do diff = diff + 2 * math.pi end
                local new_angle = current_angle + diff * (b.homing_strength or 0.5)
                local speed = math.sqrt(b.vx^2 + b.vy^2)
                b.vx = math.cos(new_angle) * speed
                b.vy = math.sin(new_angle) * speed
            end
        end
        
        b:update(effective_dt)
        
        if b.dead then
            table.remove(bullets, i)
        end
    end
    
    for i = #enemy_bullets, 1, -1 do
        local b = enemy_bullets[i]
        b:update(effective_dt)
        
        if not b.dead then
            local dist = math.sqrt((b.x - player.x)^2 + (b.y - player.y)^2)
            if dist < player.radius + b.radius then
                if player:takeDamage(1) then
                    particles:explosion(player.x, player.y, 30, {1, 0.3, 0.3})
                    particles:shake(15, 0.5)
                    changeGameState("gameover")
                    upgrade_manager:recordRun(game.points, game.current_level, game.session_currency)
                end
                b.dead = true
            end
        end
        
        if b.dead then
            table.remove(enemy_bullets, i)
        end
    end
    
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        
        e:move(player.x, player.y, effective_dt, player)
        
        e:updateStatusEffects(effective_dt)
        
        if e:isTouched(player.x, player.y, player.radius) then
            if player:takeDamage(1) then
                particles:explosion(player.x, player.y, 30, {1, 0.3, 0.3})
                particles:shake(15, 0.5)
                changeGameState("gameover")
                upgrade_manager:recordRun(game.points, game.current_level, game.session_currency)
            end
        end
        
        local b = e:updateShooting(effective_dt, player.x, player.y)
        if b then
            table.insert(enemy_bullets, b)
        end
        
        e:trySplit(enemies)
    end
    
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        local hit_something = false
        
        for j = #enemies, 1, -1 do
            local e = enemies[j]
            if e:isTouched(b.x, b.y, b.radius) then
                local is_crit = b.is_crit and " CRITICAL!" or ""
                local killed = e:takeDamage(b.damage)
                
                particles:hit(b.x, b.y, b.is_crit and {1, 1, 0} or {1, 1, 1})
                
                if player.powerups.poison_cloud > 0 and math.random() < 0.3 then
                    e:applyStatus("poison", 3)
                end
                if player.powerups.dragon_breath > 0 and math.random() < 0.3 then
                    e:applyStatus("burn", 2)
                end
                if player.powerups.ice_nova > 0 and math.random() < 0.25 then
                    e:applyStatus("freeze", 2)
                end
                
                if killed then
                    local score = e:getScore()
                    game.combo = game.combo + 1
                    game.combo_timer = 3
                    game.combo_multiplier = 1 + math.min(game.combo * 0.1, 5)
                    
                    game.points = game.points + score * game.combo_multiplier
                    game.session_currency = game.session_currency + math.floor(score / 10)
                    
                    player:onEnemyKill(enemies)
                    
                    if player.powerups.explosion > 0 then
                        particles:explosion(e.x, e.y, e.radius * 1.5, {1, 0.5, 0})
                        for _, nearby in ipairs(enemies) do
                            local d = math.sqrt((e.x - nearby.x)^2 + (e.y - nearby.y)^2)
                            if d < e.radius * 3 and nearby ~= e then
                                if nearby:takeDamage(b.damage * 0.5) then
                                    local s = nearby:getScore()
                                    game.points = game.points + s * game.combo_multiplier
                                    game.session_currency = game.session_currency + math.floor(s / 10)
                                    particles:explosion(nearby.x, nearby.y, nearby.radius, {1, 0.5, 0})
                                    table.remove(enemies, j)
                                end
                            end
                        end
                    end
                    
                    if player.powerups.chain_lightning > 0 then
                        for _, nearby in ipairs(enemies) do
                            local d = math.sqrt((e.x - nearby.x)^2 + (e.y - nearby.y)^2)
                            if d < 100 and nearby ~= e then
                                if nearby:takeDamage(b.damage * 0.3 * player.powerups.chain_lightning) then
                                    local s = nearby:getScore()
                                    game.points = game.points + s * game.combo_multiplier
                                    particles:hit(nearby.x, nearby.y, {0.5, 0.5, 1})
                                    table.remove(enemies, j)
                                    break
                                end
                            end
                        end
                    end
                    
                    table.remove(enemies, j)
                end
                
                b.pierce_count = (b.pierce_count or 0) - 1
                if b.pierce_count < 0 then
                    b.dead = true
                end
                
                hit_something = true
                break
            end
        end
        
        if not hit_something and b.dead == false then
            if b.x < 0 or b.x > love.graphics.getWidth() or
               b.y < 0 or b.y > love.graphics.getHeight() then
                b.dead = true
            end
        end
    end
    
    game.combo_timer = game.combo_timer - dt
    if game.combo_timer <= 0 then
        game.combo = 0
        game.combo_multiplier = 1
    end
    
    for i = 1, #game.levels do
        if math.floor(game.points) >= game.levels[i] and game.current_level == i then
            game.current_level = i + 1
            game.difficulty = game.difficulty + 1
            
            asteroid_spawn_rate = math.max(0.5, 2 - (game.difficulty * 0.15))
            enemy_spawn_rate = math.max(0.8, 2.5 - (game.difficulty * 0.2))
            
            particles:flash(0.2, 0.8, 0.2, 0.3, 0.3)
            particles:shake(5, 0.3)
        end
    end
    
    game.points = game.points + dt * (1 + game.combo * 0.5)
end

function love.draw()
    love.graphics.setBackgroundColor(0.02, 0.02, 0.05)
    
    local time = love.timer.getTime()
    drawBackground(time)
    
    local mouse_x, mouse_y = love.mouse.getPosition()
    local shake_x, shake_y = 0, 0
    if particles then
        shake_x, shake_y = particles:getShakeOffset()
    end
    
    love.graphics.push()
    love.graphics.translate(shake_x, shake_y)
    
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    
    if game.state.running or game.state.choose_power then
        for i = #bullets, 1, -1 do
            bullets[i]:draw()
        end
        for i = #enemy_bullets, 1, -1 do
            enemy_bullets[i]:draw()
        end
        for i = 1, #enemies do
            enemies[i]:draw()
        end
        
        if player then
            player:draw(mouse_x, mouse_y)
        end
        
        particles:draw()
        
        if game.state.running then
            DrawCrosshair(mouse_x, mouse_y)
        end
        
        love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
        love.graphics.rectangle("fill", 10, 10, 200, 110)
        love.graphics.setColor(0, 0.9, 0.9, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, 10, 200, 110)
        
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.printf("SCORE", 20, 18, 180, "left")
        
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(0.2, 1, 0.4)
        love.graphics.printf(math.floor(game.points), 20, 35, 180, "left")
        
        love.graphics.setFont(love.graphics.newFont(12))
        if game.combo > 1 then
            local combo_alpha = 0.5 + math.sin(love.timer.getTime() * 8) * 0.3
            love.graphics.setColor(1, 0.7 * combo_alpha + 0.3, 0.3 * combo_alpha)
            love.graphics.printf("COMBO x" .. string.format("%.1f", game.combo_multiplier) .. " (" .. game.combo .. " hits)", 20, 65, 180, "left")
        end
        
        love.graphics.setColor(0.3, 0.6, 1)
        love.graphics.printf("WAVE " .. game.wave_number, 20, 85, 90, "left")
        
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf("LVL " .. game.current_level, 110, 85, 90, "left")
        
        love.graphics.setColor(1, 0.6, 0.2)
        love.graphics.printf("+" .. game.session_currency, 20, 102, 180, "left")
        
        if player then
            player:drawHUD()
        end
        
        local time_to_power = 10 - power_system.offer_timer
        if time_to_power > 0 and not game.state.choose_power then
            local bar_width = 150
            local bar_x = love.graphics.getWidth() - bar_width - 20
            local progress = time_to_power / 10
            
            love.graphics.setColor(0.1, 0.1, 0.15, 0.7)
            love.graphics.rectangle("fill", bar_x - 10, 15, bar_width + 20, 35)
            
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.rectangle("fill", bar_x, 25, bar_width, 15)
            
            local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
            love.graphics.setColor(0.8 * pulse, 0.6 * pulse, 0.2 * pulse, 1)
            love.graphics.rectangle("fill", bar_x, 25, bar_width * progress, 15)
            
            love.graphics.setColor(0.6, 0.6, 0.7)
            love.graphics.setFont(love.graphics.newFont(11))
            love.graphics.printf("POWER", bar_x, 43, bar_width, "center")
        end
        
        if game.state.choose_power then
            power_system:draw(cx, cy)
            DrawCursor(love.mouse.getPosition())
        end
    end
    
    love.graphics.pop()
    
    if game.state.menu then
        love.graphics.setBackgroundColor(0.01, 0.01, 0.03)
        drawBackground(time)
        
        love.graphics.setColor(0.03, 0.02, 0.08, 0.85)
        love.graphics.rectangle("fill", cx - 320, cy - 220, 640, 460)
        
        love.graphics.setColor(0.15, 0.2, 0.35, 0.5)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", cx - 320, cy - 220, 640, 460)
        
        love.graphics.setColor(0.0, 0.8, 0.9, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx - 315, cy - 215, 630, 450)
        
        love.graphics.setFont(fonts.gigantic.font)
        
        local pulse = math.sin(time * 2) * 0.1 + 0.9
        local glow_r, glow_g, glow_b = 0.1, 0.5 + pulse * 0.3, 1.0
        
        for i = 1, 4 do
            love.graphics.setColor(glow_r, glow_g, glow_b, 0.1 / i)
            love.graphics.printf("EARTH RESCUE", i*2, cy - 165 + i*2, love.graphics.getWidth(), "center")
        end
        
        love.graphics.setColor(0.0, 0.9 * pulse, 1.0 * pulse)
        love.graphics.printf("EARTH RESCUE", 0, cy - 165, love.graphics.getWidth(), "center")
        
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 0.4, 0.7, pulse)
        love.graphics.printf("✦ ROGUE SURVIVOR ✦", 0, cy - 95, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(0.5, 0.6, 0.8, 0.8)
        love.graphics.setFont(fonts.small.font)
        love.graphics.printf("WASD - Move    •    Mouse - Aim    •    Click - Shoot    •    ESC - Pause", 0, cy - 50, love.graphics.getWidth(), "center")
        love.graphics.printf("F11 - Fullscreen    •    Right Click - Skip Power", 0, cy - 32, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(0.08, 0.1, 0.15, 0.9)
        love.graphics.rectangle("fill", cx - 220, cy + 20, 440, 80)
        love.graphics.setColor(0.2, 0.3, 0.5, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx - 220, cy + 20, 440, 80)
        
        local stats = upgrade_manager:getStats()
        
        love.graphics.setFont(love.graphics.newFont(14))
        
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.printf("★ BEST", cx - 190, cy + 30, 100, "left")
        love.graphics.setColor(1, 1, 0.9)
        love.graphics.printf(string.format("%.0f", stats.best_score), cx - 90, cy + 30, 100, "left")
        
        love.graphics.setColor(0.3, 1, 0.5)
        love.graphics.printf("♦ CREDITS", cx + 10, cy + 30, 100, "left")
        love.graphics.setColor(0.7, 1, 0.8)
        love.graphics.printf("" .. stats.currency, cx + 100, cy + 30, 100, "left")
        
        love.graphics.setColor(0.6, 0.7, 1)
        love.graphics.printf("⟳ RUNS", cx - 190, cy + 55, 100, "left")
        love.graphics.setColor(0.8, 0.9, 1)
        love.graphics.printf("" .. stats.total_runs, cx - 90, cy + 55, 100, "left")
        
        love.graphics.setColor(0.5, 0.8, 1)
        love.graphics.printf("★ LEVEL", cx + 10, cy + 55, 100, "left")
        love.graphics.setColor(0.7, 0.9, 1)
        love.graphics.printf("" .. stats.highest_level, cx + 100, cy + 55, 100, "left")
        
        love.graphics.setFont(fonts.large.font)
        local spacing = 75
        local start_y = cy + 120
        
        buttons.menu_state.play:draw(cx - buttons.menu_state.play.width / 2, start_y - spacing)
        buttons.menu_state.upgrades:draw(cx - buttons.menu_state.upgrades.width / 2, start_y)
        buttons.menu_state.exit:draw(cx - buttons.menu_state.exit.width / 2, start_y + spacing)
        
        DrawCursor(love.mouse.getPosition())
        
    elseif game.state.gameover then
        love.graphics.setBackgroundColor(0.08, 0.02, 0.02)
        drawBackground(time)
        
        love.graphics.setColor(0.1, 0.02, 0.02, 0.8)
        love.graphics.rectangle("fill", cx - 250, cy - 150, 500, 350)
        love.graphics.setColor(0.5, 0.1, 0.1, 0.4)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cx - 250, cy - 150, 500, 350)
        
        love.graphics.setFont(fonts.gigantic.font)
        
        local shake = math.sin(love.timer.getTime() * 15) * 2
        love.graphics.setColor(1, 0.1, 0.1, 0.4)
        love.graphics.printf("GAME OVER", shake + 3, cy - 160 + 3, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("GAME OVER", 0, cy - 160, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(0.12, 0.08, 0.08)
        love.graphics.rectangle("fill", cx - 220, cy - 60, 440, 120)
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx - 220, cy - 60, 440, 120)
        
        love.graphics.setFont(fonts.large.font)
        love.graphics.setColor(0.2, 1, 0.4)
        love.graphics.printf("FINAL SCORE", cx - 100, cy - 50, 200, "center")
        love.graphics.setColor(1, 0.95, 0.3)
        love.graphics.printf(math.floor(game.points), cx - 100, cy - 20, 200, "center")
        
        love.graphics.setFont(fonts.medium.font)
        love.graphics.setColor(1, 0.7, 0.3)
        love.graphics.printf("+" .. game.session_currency .. " CREDITS", cx + 20, cy - 35, 200, "center")
        
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf("WAVE " .. game.wave_number .. "  |  LEVEL " .. game.current_level, 0, cy + 80, love.graphics.getWidth(), "center")
        
        love.graphics.setFont(fonts.large.font)
        local spacing = 70
        local start_y = cy + 130
        
        buttons.game_over.replay:draw(cx - buttons.game_over.replay.width / 2, start_y)
        buttons.game_over.menu:draw(cx - buttons.game_over.menu.width / 2, start_y + spacing)
        buttons.game_over.exit:draw(cx - buttons.game_over.exit.width / 2, start_y + spacing * 2)
        
        DrawCursor(love.mouse.getPosition())
        
    elseif game.state.upgrades then
        love.graphics.setFont(fonts.gigantic.font)
        love.graphics.setColor(0.8, 0.6, 1)
        love.graphics.printf("UPGRADES", 0, cy - 200, love.graphics.getWidth(), "center")
        
        local stats = upgrade_manager:getStats()
        love.graphics.setFont(fonts.large.font)
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.printf("Currency: " .. stats.currency, 0, cy - 140, love.graphics.getWidth(), "center")
        
        love.graphics.setFont(fonts.medium.font)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Best Score: " .. math.floor(stats.best_score) .. " | Runs: " .. stats.total_runs, 0, cy - 100, love.graphics.getWidth(), "center")
        
        local upgrades_list = upgrade_manager:getEligibleUpgrades()
        local start_x = cx - 300
        local start_y = cy - 40
        local cols = 2
        local btn_w, btn_h = 280, 55
        local spacing = 15
        
        for i, u in ipairs(upgrades_list) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local bx = start_x + col * (btn_w + spacing)
            local by = start_y + row * (btn_h + spacing)
            
            if not buttons.upgrades[u.id] then
                buttons.upgrades[u.id] = Button(u.data.name .. " Lv." .. (u.level + 1), function() end, nil, btn_w, btn_h)
            end
            
            local btn = buttons.upgrades[u.id]
            
            local mx, my = love.mouse.getPosition()
            local hovered = mx >= bx and mx <= bx + btn.width and my >= by and my <= by + btn.height
            
            local r, g, b = 0.3, 0.3, 0.35
            if hovered then
                if u.can_afford then
                    r, g, b = 0.2, 0.7, 0.3
                else
                    r, g, b = 0.7, 0.2, 0.2
                end
            end
            
            love.graphics.setColor(r, g, b, 0.3)
            love.graphics.rectangle("fill", bx, by, btn.width, btn.height)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", bx, by, btn.width, btn.height)
            
            love.graphics.setFont(fonts.small.font)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(u.data.name, bx + 10, by + 5)
            
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(u.data.desc, bx + 10, by + 22)
            
            love.graphics.setColor(u.can_afford and 0.3 or 0.8, u.can_afford and 0.9 or 0.3, 0.3)
            love.graphics.print("Cost: " .. u.cost, bx + 10, by + 38)
        end
        
        buttons.upgrades.back:draw(cx - buttons.upgrades.back.width / 2, love.graphics.getHeight() - 100)
        
        DrawCursor(love.mouse.getPosition())
    end
    
    love.graphics.setFont(fonts.small.font)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, love.graphics.getHeight() - 25)
end

function DrawCursor(x, y)
    local time = love.timer.getTime()
    local pulse = math.sin(time * 8) * 0.2 + 0.8
    
    for layer = 1, 3 do
        local alpha = (4 - layer) * 0.1 * pulse
        love.graphics.setColor(0, 0.9 * pulse, 0.9 * pulse, alpha)
        love.graphics.setLineWidth(4 - layer + 1)
        love.graphics.line(x - 12, y, x - 5, y)
        love.graphics.line(x + 5, y, x + 12, y)
        love.graphics.line(x, y - 12, x, y - 5)
        love.graphics.line(x, y + 5, x, y + 12)
    end
    
    love.graphics.setColor(0, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(x - 10, y, x - 4, y)
    love.graphics.line(x + 4, y, x + 10, y)
    love.graphics.line(x, y - 10, x, y - 4)
    love.graphics.line(x, y + 4, x, y + 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", x, y, 2)
    
    love.graphics.setLineWidth(1)
end

function DrawCrosshair(x, y)
    local time = love.timer.getTime()
    local pulse = math.sin(time * 10) * 0.3 + 0.7
    
    for layer = 1, 3 do
        local size = 20 + layer * 5
        local alpha = (4 - layer) * 0.15 * pulse
        love.graphics.setColor(0, 1 * pulse, 1 * pulse, alpha)
        love.graphics.setLineWidth(4 - layer + 1)
        love.graphics.line(x - size, y, x - size + 5, y)
        love.graphics.line(x + size - 5, y, x + size, y)
        love.graphics.line(x, y - size, x, y - size + 5)
        love.graphics.line(x, y + size - 5, x, y + size)
    end
    
    love.graphics.setColor(0, 1, 1, pulse)
    love.graphics.setLineWidth(2)
    love.graphics.line(x - 18, y, x - 6, y)
    love.graphics.line(x + 6, y, x + 18, y)
    love.graphics.line(x, y - 18, x, y - 6)
    love.graphics.line(x, y + 6, x, y + 18)
    
    love.graphics.setColor(1, 0.3, 0.3, 0.8 * pulse)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", x, y, 8, 8)
    love.graphics.circle("line", x, y, 12, 12)
    
    love.graphics.setColor(1, 1, 1, pulse)
    love.graphics.circle("fill", x, y, 2)
    
    love.graphics.setLineWidth(1)
end
