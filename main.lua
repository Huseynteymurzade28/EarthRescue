local love = require("love")
local enemy = require("Enemy")
local Player = require("Player")
local button = require("Button")
local Asteroid = require("Asteroid")
local Bullet = require("Bullet")

math.randomseed(os.time())

local game = {
    difficulty = 1,
    state = {
        menu = true,
        settings = false,
        paused = false,
        running = false,
        gameover = false,
    },
    points = 0,
    levels = {15, 30, 45, 60, 75},
    current_level = 1,
    settings_data = {
        volume = 100
    }
}

local fonts = {
    medium = {
        font = love.graphics.newFont(18),
        size = 18,
    },
    large = {
        font = love.graphics.newFont(25),
        size = 25,
    },
    gigantic = {
        font = love.graphics.newFont(45),
        size = 45,
    },
}

local player = Player() 

local buttons = {
    menu_state = {},
    settings_state = {},
    game_over = {}
}

local enemies = {}
local asteroids = {}
local bullets = {}
local asteroid_timer = 0
local asteroid_spawn_rate = 2 

-- Starfield
local stars = {}
local function createStars()
    stars = {}
    for i = 1, 100 do
        table.insert(stars, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            size = math.random(1, 3),
            speed = math.random(10, 50)
        })
    end
end

local function changeGameState(state)
    game.state.menu = state == "menu"
    game.state.settings = state == "settings"
    game.state.running = state == "running"
    game.state.paused = state == "paused"
    game.state.gameover = state == "gameover"
end

local function startNewGame()
    changeGameState("running")

    game.points = 0
    game.difficulty = 1
    game.current_level = 1
    asteroids = {}
    bullets = {}
    asteroid_timer = 0
    
    enemies = {
        enemy(1)
    }
end

local function goMenu()
    changeGameState("menu")
    game.points = 0
    enemies = {}
    asteroids = {}
    bullets = {}
end

local function goSettings()
    changeGameState("settings")
end

function love.mousepressed(x, y, button)
    if not game.state.running then
        if button == 1 then
            if game.state.menu then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index]:on_mouse_pressed(x, y, button)
                end
            elseif game.state.settings then
                for index in pairs(buttons.settings_state) do
                    buttons.settings_state[index]:on_mouse_pressed(x, y, button)
                end
            elseif game.state.gameover then
                 for index in pairs(buttons.game_over) do
                    buttons.game_over[index]:on_mouse_pressed(x, y, button)
                 end
            end
        end
    else
        -- Game running, handle shooting
        if button == 1 then
            local b = player:shoot()
            table.insert(bullets, b)
        end
    end
end

function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest", "nearest")

    createStars()

    -- Buttons
    local bw, bh = 240, 60
    
    buttons.menu_state.play_game = button("PLAY GAME", startNewGame, nil, bw, bh)
    buttons.menu_state.settings = button("SETTINGS", goSettings, nil, bw, bh)
    buttons.menu_state.exit_game = button("QUIT", love.event.quit, nil, bw, bh)

    buttons.settings_state.back = button("BACK TO MENU", goMenu, nil, bw, bh)

    buttons.game_over.replay_game = button("TRY AGAIN", startNewGame, nil, bw, bh)
    buttons.game_over.menu = button("MAIN MENU", goMenu, nil, bw, bh)
    buttons.game_over.exit_game = button("QUIT", love.event.quit, nil, bw, bh)
end

function love.update(dt)
    local mouse_x, mouse_y = love.mouse.getPosition()
    
    -- Update stars
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed * dt
        if star.y > love.graphics.getHeight() then
            star.y = -5
            star.x = math.random(0, love.graphics.getWidth())
        end
    end

    if game.state.running then
        player:move(mouse_x, mouse_y)

        -- Spawners
        asteroid_timer = asteroid_timer + dt
        if asteroid_timer > asteroid_spawn_rate then
            asteroid_timer = 0
            table.insert(asteroids, Asteroid(game.difficulty))
        end

        -- Update Entities
        for i = #bullets, 1, -1 do
            bullets[i]:update(dt)
            if bullets[i].dead then
                table.remove(bullets, i)
            end
        end

        for i = #enemies, 1, -1 do
            local e = enemies[i]
            
            -- Enemy logic
            e:move(player.x, player.y, dt)
            
            -- Collision Enemeny vs Player
            if e:isTouched(player.x, player.y, player.radius) then
                changeGameState("gameover")
            end
            
            -- Enemy Shooting
            local b = e:updateShooting(dt, player.x, player.y)
            if b then
                table.insert(bullets, b)
            end
        end
        
        for i = #asteroids, 1, -1 do
            local ast = asteroids[i]
            ast:move(dt)
            
            if ast:isTouched(player.x, player.y, player.radius) then
                changeGameState("gameover")
            end
            
            if ast:isOffScreen() then
                table.remove(asteroids, i)
            end
        end

        -- Bullet Collisions
        for i = #bullets, 1, -1 do
            local b = bullets[i]
            local bullet_removed = false
            
            if b.is_enemy then
                -- Check vs Player
                local dist = math.sqrt((b.x - player.x)^2 + (b.y - player.y)^2)
                if dist < (player.radius + b.radius) then
                    changeGameState("gameover")
                    bullet_removed = true
                end
            else
                -- Check vs Enemies
                for j = #enemies, 1, -1 do
                    local e = enemies[j]
                    if e:isTouched(b.x, b.y, b.radius) then
                        table.remove(enemies, j)
                        table.remove(bullets, i)
                        game.points = game.points + 10 -- Bonus points for kill
                        bullet_removed = true
                        break
                    end
                end
                
                -- Check vs Asteroids
                if not bullet_removed then
                    for j = #asteroids, 1, -1 do
                        local ast = asteroids[j]
                        if ast:isTouched(b.x, b.y, b.radius) then
                            -- Split logic
                            if ast.radius > 15 then
                                local pieces = math.random(2, 4)
                                for k=1, pieces do
                                    table.insert(asteroids, Asteroid(game.difficulty, ast.x, ast.y, ast.radius * 0.6))
                                end
                            end
                            table.remove(asteroids, j)
                            table.remove(bullets, i)
                            game.points = game.points + 5
                            bullet_removed = true
                            break
                        end
                    end
                end
            end
            
            -- If bullet hit something, we already removed it in logic above
        end


        -- Level Up Logic
        for i = 1, #game.levels do
            if math.floor(game.points) >= game.levels[i] and game.current_level == i then
                game.current_level = i + 1
                game.difficulty = game.difficulty + 1
                table.insert(enemies, enemy(game.difficulty))
                asteroid_spawn_rate = math.max(0.5, 2 - (game.difficulty * 0.2))
            end
        end
        game.points = game.points + dt
    end
end


function love.draw()
    -- Draw Background
    love.graphics.clear(10/255, 10/255, 16/255) 
    love.graphics.setColor(1, 1, 1, 0.4)
    for _, star in ipairs(stars) do
        love.graphics.circle("fill", star.x, star.y, star.size)
    end
    love.graphics.setColor(1, 1, 1, 1)


    love.graphics.setFont(fonts.medium.font)
    love.graphics.setColor(108/255,56/255,245/255)
    love.graphics.print("FPS: "..love.timer.getFPS(), fonts.medium.font, love.graphics.getWidth() - 100, love.graphics.getHeight() - 35)
    
    local cx, cy = love.graphics.getDimensions()
    cx = cx / 2
    cy = cy / 2

    if game.state.running then
        love.graphics.printf("Score: " .. math.floor(game.points), fonts.large.font, 20, 20, love.graphics.getWidth(), "left")
        love.graphics.printf("Level: " .. game.current_level, fonts.large.font, 20, 50, love.graphics.getWidth(), "left")
        
        for i = 1, #bullets do
            bullets[i]:draw()
        end
        for i = 1, #enemies do
            enemies[i]:draw()
        end
        for i = 1, #asteroids do
            asteroids[i]:draw()
        end
        player:draw()
        
    elseif game.state.menu then
        -- Title
        love.graphics.setFont(fonts.gigantic.font)
        love.graphics.setColor(0, 1, 1)
        
        -- Text Shadow
        love.graphics.setColor(108/255, 56/255, 245/255, 0.5)
        love.graphics.printf("EARTH RESCUE", 4, cy - 200 + 4, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(0, 1, 1)
        love.graphics.printf("EARTH RESCUE", 0, cy - 200, love.graphics.getWidth(), "center")

        -- Buttons Stack
        local spacing = 80
        local start_y = cy - 30 
        
        buttons.menu_state.play_game:draw(cx - buttons.menu_state.play_game.width / 2, start_y - spacing)
        buttons.menu_state.settings:draw(cx - buttons.menu_state.settings.width / 2, start_y)
        buttons.menu_state.exit_game:draw(cx - buttons.menu_state.exit_game.width / 2, start_y + spacing)
        
        DrawCursor(love.mouse.getPosition())

    elseif game.state.settings then
        love.graphics.setFont(fonts.gigantic.font)
        love.graphics.setColor(0, 1, 1)
        love.graphics.printf("SETTINGS", 0, cy - 200, love.graphics.getWidth(), "center")
        
        love.graphics.setFont(fonts.large.font)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Controls\n\nMouse: Move Ship\nLeft Click: Shoot Laser", 0, cy - 80, love.graphics.getWidth(), "center")
        
        buttons.settings_state.back:draw(cx - buttons.settings_state.back.width / 2, cy + 100)
        
        DrawCursor(love.mouse.getPosition())

    elseif game.state.gameover then
        love.graphics.setFont(fonts.gigantic.font)
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("MISSION FAILED", 0, cy - 200, love.graphics.getWidth(), "center")

        local spacing = 80
        local start_y = cy 
        
        buttons.game_over.replay_game:draw(cx - buttons.game_over.replay_game.width / 2, start_y - spacing)
        buttons.game_over.menu:draw(cx - buttons.game_over.menu.width / 2, start_y)
        buttons.game_over.exit_game:draw(cx - buttons.game_over.exit_game.width / 2, start_y + spacing)

        love.graphics.setColor(108/255,56/255,245/255)
        love.graphics.printf("Final Score: " .. math.floor(game.points), fonts.large.font, 0, cy + 180, love.graphics.getWidth(), "center")
        
        DrawCursor(love.mouse.getPosition())
    end
end

function DrawCursor(x, y)
    love.graphics.setColor(0, 1, 1)
    love.graphics.setLineWidth(2)
    -- Crosshair
    love.graphics.line(x - 10, y, x - 4, y) -- Left
    love.graphics.line(x + 4, y, x + 10, y) -- Right
    love.graphics.line(x, y - 10, x, y - 4) -- Top
    love.graphics.line(x, y + 4, x, y + 10) -- Bottom
    
    -- Center dot? No, let's keep it open
    love.graphics.setLineWidth(1)
end
