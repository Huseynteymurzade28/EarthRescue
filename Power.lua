local love = require("love")

local Power = {}
Power.__index = Power

local RARITY_COLORS = {
    common = {0.6, 0.7, 0.75},
    uncommon = {0.3, 0.8, 0.4},
    rare = {0.3, 0.6, 1.0},
    epic = {0.7, 0.4, 0.9},
    mythic = {1.0, 0.55, 0.0},
    legendary = {1.0, 0.85, 0.2},
    ultimate = {0.2, 1.0, 0.9}
}

local RARITY_WEIGHTS = {
    common = 35,
    uncommon = 25,
    rare = 18,
    epic = 12,
    mythic = 6,
    legendary = 3,
    ultimate = 1
}

local POWER_TYPES = {
    -- COMMON (15)
    {name = "TRIPLE SHOT", desc = "+2 bullets in spread", rarity = "common"},
    {name = "RAPID FIRE", desc = "+20% fire rate", rarity = "common"},
    {name = "QUICK SLIDES", desc = "+15% movement speed", rarity = "common"},
    {name = "SHARP ARROWS", desc = "+10% damage", rarity = "common"},
    {name = "LIGHT FOOT", desc = "Dodge +5%", rarity = "common"},
    {name = "STEADY HAND", desc = "+5% accuracy", rarity = "common"},
    {name = "FOCUSED MIND", desc = "+5% crit chance", rarity = "common"},
    {name = "SWIFT STRIKE", desc = "+10% attack speed", rarity = "common"},
    {name = "BASIC SHIELD", desc = "Block 1 hit", rarity = "common"},
    {name = "ENERGY SALVE", desc = "Heal 1 HP", rarity = "common"},
    {name = "LUCKY CHARM", desc = "+3% luck", rarity = "common"},
    {name = "WEAK FREEZE", desc = "5% freeze chance", rarity = "common"},
    {name = "BURNING ARROW", desc = "5% burn chance", rarity = "common"},
    {name = "SHOCK WAVE", desc = "5% shock chance", rarity = "common"},
    {name = "SILVER BULLET", desc = "+8% damage vs enemies", rarity = "common"},
    
    -- UNCOMMON (15)
    {name = "PIERCING SHOT", desc = "Bullets pierce +1", rarity = "uncommon"},
    {name = "DOUBLE TAP", desc = "15% double shot", rarity = "uncommon"},
    {name = "EXPLOSIVE ROUND", desc = "Kills explode", rarity = "uncommon"},
    {name = "MEDIUM ARMOR", desc = "+15% damage reduction", rarity = "uncommon"},
    {name = "PHASE SHIFT", desc = "20% chance to dodge", rarity = "uncommon"},
    {name = "CHAIN LIGHTNING", desc = "Kills shock nearby", rarity = "uncommon"},
    {name = "POISON TIP", desc = "10% poison chance", rarity = "uncommon"},
    {name = "ICE SHARD", desc = "10% freeze chance", rarity = "uncommon"},
    {name = "FLAME TONGUE", desc = "10% burn chance", rarity = "uncommon"},
    {name = "VAMPIRIC TOUCH", desc = "Heal on kill", rarity = "uncommon"},
    {name = "REGENERATION", desc = "Heal over time", rarity = "uncommon"},
    {name = "LUCK BOOST", desc = "+10% luck", rarity = "uncommon"},
    {name = "GOLDEN TOUCH", desc = "+15% currency", rarity = "uncommon"},
    {name = "MYSTIC ORB", desc = "Orbit orb, damage", rarity = "uncommon"},
    {name = "DEFLECTION", desc = "Reflect bullets", rarity = "uncommon"},
    
    -- RARE (12)
    {name = "SPREAD CANNON", desc = "Fire 5 bullets", rarity = "rare"},
    {name = "HOMING BOLTS", desc = "Bullets seek target", rarity = "rare"},
    {name = "CRITICAL STRIKE", desc = "+15% crit, 3x dmg", rarity = "rare"},
    {name = "TIME DILATION", desc = "Enemies 15% slower", rarity = "rare"},
    {name = "SNIPER ELITE", desc = "+30% bullet speed", rarity = "rare"},
    {name = "SHOTGUN BLAST", desc = "Fire 7 short range", rarity = "rare"},
    {name = "PLASMA CHARGE", desc = "Plasma bullets", rarity = "rare"},
    {name = "GHOST WALK", desc = "Intangible 2s/10s", rarity = "rare"},
    {name = "THUNDER STRIKE", desc = "Chain lightning", rarity = "rare"},
    {name = "VOID SHOT", desc = "Ignore defense", rarity = "rare"},
    {name = "SPIRIT ARROW", desc = "Pierce +2, haunt", rarity = "rare"},
    {name = "ARMOR PIERCING", desc = "Ignore 30% def", rarity = "rare"},
    
    -- EPIC (10)
    {name = "MULTI FIRE", desc = "Fire 8 directions", rarity = "epic"},
    {name = "DRAGON BREATH", desc = "Cone of fire", rarity = "epic"},
    {name = "PLASMA STORM", desc = "Damaging field", rarity = "epic"},
    {name = "GRAVITY WELL", desc = "Pull enemies in", rarity = "epic"},
    {name = "ARMY OF ONE", desc = "Shadow soldiers", rarity = "epic"},
    {name = "ICE NOVA", desc = "Freeze all enemies", rarity = "epic"},
    {name = "POISON CLOUD", desc = "DoT area", rarity = "epic"},
    {name = "QUANTUM STRIKE", desc = "Dual damage", rarity = "epic"},
    {name = "COSMIC RAY", desc = "Heavy beam", rarity = "epic"},
    {name = "ECHO STRIKE", desc = "Afterimages", rarity = "epic"},
    
    -- MYTHIC (8)
    {name = "BLACK HOLE", desc = "Singularity", rarity = "mythic"},
    {name = "METEOR RAIN", desc = "Meteors fall", rarity = "mythic"},
    {name = "SUNBURST", desc = "Radiant explosion", rarity = "mythic"},
    {name = "VOID TENTACLES", desc = "Grapple enemies", rarity = "mythic"},
    {name = "PHANTOM ARMY", desc = "15 shadow clones", rarity = "mythic"},
    {name = "BLOOD RITUAL", desc = "HP to power", rarity = "mythic"},
    {name = "THUNDER LORD", desc = "Constant strikes", rarity = "mythic"},
    {name = "PHOENIX RISE", desc = "Revive once", rarity = "mythic"},
    
    -- LEGENDARY (5)
    {name = "APOCALYPSE", desc = "End of world", rarity = "legendary"},
    {name = "NEO MODE", desc = "All stats +50%", rarity = "legendary"},
    {name = "INFINITY EDGE", desc = "Stack forever", rarity = "legendary"},
    {name = "BERSERKER", desc = "Damage = speed", rarity = "legendary"},
    {name = "OMEGA STRIKE", desc = "Ultimate beam", rarity = "legendary"},
    
    -- ULTIMATE (2)
    {name = "GOD HAND", desc = "One punch kill", rarity = "ultimate"},
    {name = "TRANSCENDENCE", desc = "Perfect being", rarity = "ultimate"}
}

-- Total: 67 powers!

function Power.new()
    local self = setmetatable({}, Power)
    self.offers = {}
    self.offer_timer = 0
    self.offer_interval = 10
    self.is_offering = false
    self.selected_index = nil
    self.close_button = {x = 0, y = 0, width = 160, height = 50, hover = false}
    return self
end

function Power:generate_offers(player_level)
    self.offers = {}
    self.offer_timer = 0
    self.is_offering = true
    self.selected_index = nil
    
    local offers_count = 3
    local used_powers = {}
    
    for i = 1, offers_count do
        local power_data = self:weighted_random_power(player_level, used_powers)
        table.insert(used_powers, power_data.name)
        
        local offer = {
            data = power_data,
            x = 0,
            y = 0,
            width = 220,
            height = 300,
            hover = false,
            scale = 1.0,
            target_scale = 1.0
        }
        table.insert(self.offers, offer)
    end
end

function Power:weighted_random_power(player_level, used_powers)
    local total_weight = 0
    for _, p in ipairs(POWER_TYPES) do
        local weight = RARITY_WEIGHTS[p.rarity] or 5
        if player_level < 2 and p.rarity == "epic" then weight = 0 end
        if player_level < 3 and p.rarity == "mythic" then weight = 0 end
        if player_level < 5 and p.rarity == "legendary" then weight = 0 end
        if player_level < 8 and p.rarity == "ultimate" then weight = 0 end
        total_weight = total_weight + weight
    end
    
    local roll = math.random() * total_weight
    local running = 0
    
    for _, p in ipairs(POWER_TYPES) do
        local is_used = false
        for _, used in ipairs(used_powers or {}) do
            if used == p.name then is_used = true break end
        end
        if not is_used then
            local weight = RARITY_WEIGHTS[p.rarity] or 5
            if player_level < 2 and p.rarity == "epic" then weight = 0 end
            if player_level < 3 and p.rarity == "mythic" then weight = 0 end
            if player_level < 5 and p.rarity == "legendary" then weight = 0 end
            if player_level < 8 and p.rarity == "ultimate" then weight = 0 end
            
            running = running + weight
            if roll <= running then
                return p
            end
        end
    end
    
    return POWER_TYPES[1]
end

function Power:update(dt, player, game)
    if game.state.running and not game.state.paused and not game.state.choose_power then
        self.offer_timer = self.offer_timer + dt
        if self.offer_timer >= self.offer_interval and not self.is_offering then
            self:generate_offers(game.current_level)
            game.state.choose_power = true
        end
    end
    
    for _, offer in ipairs(self.offers) do
        offer.scale = offer.scale + (offer.target_scale - offer.scale) * 0.15
    end
end

function Power:draw(center_x, center_y)
    if not self.is_offering then return end
    
    love.graphics.setColor(0.02, 0.03, 0.08, 0.92)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local time = love.timer.getTime()
    
    for i = 1, 80 do
        local x = (math.sin(time * 0.3 + i * 0.7) * 0.5 + 0.5) * love.graphics.getWidth()
        local y = (math.cos(time * 0.5 + i * 0.4) * 0.5 + 0.5) * love.graphics.getHeight()
        local size = math.random(1, 4)
        local alpha = math.random(0.05, 0.2)
        local star_color = math.random(1, 3)
        if star_color == 1 then love.graphics.setColor(0.8, 0.9, 1, alpha)
        elseif star_color == 2 then love.graphics.setColor(0.6, 0.8, 1, alpha)
        else love.graphics.setColor(0.5, 0.7, 0.9, alpha) end
        love.graphics.circle("fill", x, y, size)
    end
    
    local card_width = 220
    local card_height = 300
    local spacing = 50
    local total_width = (#self.offers * card_width) + ((#self.offers - 1) * spacing)
    local start_x = center_x - total_width / 2
    
    love.graphics.setFont(love.graphics.newFont(44))
    local title_glow = math.sin(time * 2) * 0.15 + 0.85
    love.graphics.setColor(0.4 * title_glow, 0.9 * title_glow, 1 * title_glow)
    love.graphics.printf("✦ CHOOSE YOUR POWER ✦", 0, center_y - 240, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(love.graphics.newFont(17))
    love.graphics.setColor(0.5, 0.55, 0.65)
    love.graphics.printf("Click to select  •  Right-click or ESC to skip", 0, center_y - 185, love.graphics.getWidth(), "center")
    
    local mx, my = love.mouse.getPosition()
    
    for i, offer in ipairs(self.offers) do
        local cx = start_x + (i - 1) * (card_width + spacing) + card_width / 2
        local cy = center_y + 30
        offer.x = cx - card_width / 2
        offer.y = cy - card_height / 2
        
        local dx = mx - cx
        local dy = my - cy
        offer.hover = dx > -card_width/2 and dx < card_width/2 and dy > -card_height/2 and dy < card_height/2
        
        if offer.hover then
            offer.target_scale = 1.1
        else
            offer.target_scale = 1.0
        end
        
        local scale = offer.scale
        local w = card_width * scale
        local h = card_height * scale
        
        local rx = cx - w / 2
        local ry = cy - h / 2
        
        local rarity_color = RARITY_COLORS[offer.data.rarity] or {0.7, 0.7, 0.7}
        
        for layer = 1, 5 do
            local glow_alpha = (6 - layer) * 0.025 * (offer.hover and 2.5 or 1)
            love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3], glow_alpha)
            love.graphics.rectangle("fill", rx - layer*4, ry - layer*4, w + layer*8, h + layer*8)
        end
        
        local bg_grad = {}
        for gi = 0, 1, 0.1 do
            local alpha = gi * 0.15
            love.graphics.setColor(rarity_color[1] * 0.15, rarity_color[2] * 0.15, rarity_color[3] * 0.2, alpha)
            love.graphics.rectangle("fill", rx, ry + gi * h * 0.4, w, h * 0.4 / 10 + 1)
        end
        
        love.graphics.setColor(0.04, 0.05, 0.1)
        love.graphics.rectangle("fill", rx, ry, w, h)
        
        local border_alpha = offer.hover and 1 or 0.75
        love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3], border_alpha)
        love.graphics.setLineWidth(offer.hover and 5 or 3)
        love.graphics.rectangle("line", rx, ry, w, h)
        
        if offer.hover then
            love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3], 0.18)
            love.graphics.rectangle("fill", rx + 4, ry + 4, w - 8, h - 8)
        end
        
        love.graphics.setLineWidth(1)
        
        local orb_y = cy - 90 * scale
        for layer = 1, 4 do
            local orb_alpha = (5 - layer) * 0.12
            love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3], orb_alpha)
            love.graphics.circle("fill", cx, orb_y, 45 * scale + layer * 10)
        end
        
        love.graphics.setColor(rarity_color[1] * 0.4, rarity_color[2] * 0.4, rarity_color[3] * 0.4)
        love.graphics.circle("fill", cx, orb_y, 38 * scale)
        love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3])
        love.graphics.circle("line", cx, orb_y, 38 * scale)
        
        local icon_symbols = {
            common = "◇",
            uncommon = "◆",
            rare = "★",
            epic = "✦",
            mythic = "✧",
            legendary = "👑",
            ultimate = "🔥"
        }
        
        love.graphics.setFont(love.graphics.newFont(34))
        love.graphics.setColor(1, 1, 1)
        local symbol = icon_symbols[offer.data.rarity] or "◆"
        local symbol_w = love.graphics.getFont():getWidth(symbol)
        love.graphics.print(symbol, cx - symbol_w/2, orb_y - 17)
        
        local name_y = cy - 30 * scale
        love.graphics.setFont(love.graphics.newFont(15 * scale))
        love.graphics.setColor(1, 1, 1)
        local name = offer.data.name
        local name_w = love.graphics.getFont():getWidth(name)
        love.graphics.print(name, cx - name_w / 2, name_y)
        
        local desc_y = cy + 10 * scale
        love.graphics.setFont(love.graphics.newFont(11 * scale))
        love.graphics.setColor(0.65, 0.7, 0.8)
        
        local desc = offer.data.desc
        local max_w = w - 30
        local wrapped = self:wrapText(desc, max_w)
        for li, line in ipairs(wrapped) do
            local line_w = love.graphics.getFont():getWidth(line)
            love.graphics.print(line, cx - line_w / 2, desc_y + (li - 1) * 14 * scale)
        end
        
        local rarity_y = cy + 95 * scale
        
        love.graphics.setColor(rarity_color[1] * 0.15, rarity_color[2] * 0.15, rarity_color[3] * 0.15)
        love.graphics.rectangle("fill", cx - 55, rarity_y - 5, 110, 26)
        
        love.graphics.setFont(love.graphics.newFont(12 * scale))
        local rarity_text = "♦ " .. offer.data.rarity:upper() .. " ♦"
        local rt_w = love.graphics.getFont():getWidth(rarity_text)
        love.graphics.setColor(rarity_color[1], rarity_color[2], rarity_color[3])
        love.graphics.print(rarity_text, cx - rt_w / 2, rarity_y)
    end
    
    local btn_w = 160
    local btn_h = 50
    local btn_x = center_x - btn_w / 2
    local btn_y = center_y + 210
    
    local dx = mx - btn_x - btn_w/2
    local dy = my - btn_y - btn_h/2
    self.close_button.hover = dx > 0 and dx < btn_w and dy > 0 and dy < btn_h
    
    local btn_hover = self.close_button.hover
    local btn_r, btn_g, btn_b = 0.35, 0.1, 0.2
    if btn_hover then
        btn_r, btn_g, btn_b = 0.65, 0.15, 0.25
    end
    
    for layer = 1, 3 do
        local glow_alpha = (4 - layer) * 0.12 * (btn_hover and 1.8 or 1)
        love.graphics.setColor(btn_r + 0.3, btn_g, btn_b, glow_alpha)
        love.graphics.rectangle("fill", btn_x - layer*2, btn_y - layer*2, btn_w + layer*4, btn_h + layer*4)
    end
    
    love.graphics.setColor(btn_r, btn_g, btn_b, 0.9)
    love.graphics.rectangle("fill", btn_x, btn_y, btn_w, btn_h)
    
    love.graphics.setColor(btn_r + 0.35, btn_g + 0.25, btn_b + 0.25, btn_hover and 1 or 0.7)
    love.graphics.setLineWidth(btn_hover and 3 or 2)
    love.graphics.rectangle("line", btn_x, btn_y, btn_w, btn_h)
    
    if btn_hover then
        love.graphics.setColor(1, 0.4, 0.5, 0.15)
        love.graphics.rectangle("fill", btn_x + 4, btn_y + 4, btn_w - 8, btn_h - 8)
    end
    
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 0.65, 0.7)
    local skip_text = "⏭ SKIP"
    love.graphics.print(skip_text, btn_x + btn_w/2 - love.graphics.getFont():getWidth(skip_text)/2, btn_y + 13)
    
    self.close_button.x = btn_x
    self.close_button.y = btn_y
    self.close_button.width = btn_w
    self.close_button.height = btn_h
end

function Power:wrapText(text, max_width)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local lines = {}
    local current_line = ""
    
    for _, word in ipairs(words) do
        local test_line = current_line == "" and word or current_line .. " " .. word
        if love.graphics.getFont():getWidth(test_line) > max_width and current_line ~= "" then
            table.insert(lines, current_line)
            current_line = word
        else
            current_line = test_line
        end
    end
    table.insert(lines, current_line)
    
    return lines
end

function Power:handle_click(x, y)
    if not self.is_offering then return nil end
    
    for i, offer in ipairs(self.offers) do
        if offer.hover then
            self.is_offering = false
            self.offers = {}
            return offer.data
        end
    end
    
    if self.close_button.hover then
        self:skip_offer()
        return nil
    end
    
    return nil
end

function Power:getCloseButton()
    return self.close_button
end

function Power:skip_offer()
    if self.is_offering then
        self.is_offering = false
        self.offers = {}
        self.offer_timer = 0
    end
end

return Power
