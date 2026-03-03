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
    common = 30,
    uncommon = 22,
    rare = 16,
    epic = 10,
    mythic = 5,
    legendary = 2,
    ultimate = 0.5
}

local JOKER_TYPES = {
    {name = "LUCKY CHARM", desc = "+10% Lucky Trigger", detail = "Increases all lucky triggers by 10%: Joker appearances, rare drops, and random events. More chances for bonuses!", type = "passive", trigger = "lucky", value = 0.1},
    {name = "CARD SHARK", desc = "+15% Card draw chance", detail = "15% more likely to get Joker card offers. More Jokers = more powerful synergies!", type = "passive", trigger = "draw", value = 0.15},
    {name = "WILD CARD", desc = "Joker abilities can stack twice", detail = "Your Jokers can stack to level 2 instead of 1. Double the Joker power!", type = "passive", trigger = "wild", value = 1},
    {name = "FOOL'S GOLD", desc = "+25% currency from kills", detail = "Earn 25% more credits from every kill. Save up for upgrades faster!", type = "passive", trigger = "gold", value = 0.25},
    {name = "PHANTOM JOKER", desc = "10% chance to dodge attacks", detail = "10% chance to completely dodge any attack. Ghost-like reflexes!", type = "passive", trigger = "dodge", value = 0.1},
    {name = "MYSTIC JOKER", desc = "+20% ability effect duration", detail = "All timed abilities last 20% longer. More time with active powers!", type = "passive", trigger = "duration", value = 0.2},
    {name = "CROWN JOKER", desc = "+30% damage when at full HP", detail = "Deal 30% extra damage when at full health. Stay healthy to stay deadly!", type = "passive", trigger = "crown", value = 0.3},
    {name = "OBSIDIAN JOKER", desc = "+15% damage per active status", detail = "+15% damage for each status effect on enemies. Stack burns, poisons, and more!", type = "passive", trigger = "status", value = 0.15},
    {name = "GLASS JOKER", desc = "Critical hits deal +50% dmg", detail = "Critical hits deal 50% more damage. Stack with Focused Mind for devastation!", type = "passive", trigger = "glass", value = 0.5},
    {name = "STONE JOKER", desc = "+20% damage reduction", detail = "Take 20% less damage from all sources. Tankier with style!", type = "passive", trigger = "stone", value = 0.2},
    {name = "GOLD RUSH", desc = "Kill streak boosts damage", detail = "Each kill streak adds 5% damage. Keep combo going for more power!", type = "passive", trigger = "streak", value = 0.05},
    {name = "SERIAL KILLER", desc = "Combo builds faster", detail = "Combo meter builds 20% faster. Reach high combos easier!", type = "passive", trigger = "combo", value = 0.2},
    
    {name = "SQUEEZE PLAY", desc = "Right-click: Double damage shot", detail = "Press Right-Click to deal double damage for one shot. 12s cooldown. Big damage spike!", type = "active", trigger = "squeeze", cooldown = 12},
    {name = "CLEAR CARD", desc = "Right-click: Clear all enemies", detail = "Press Right-Click to clear ALL enemies on screen. 30s cooldown. Emergency button!", type = "active", trigger = "clear", cooldown = 30},
    {name = "SACRIFICE", desc = "Right-click: HP for power", detail = "Press Right-Click to trade 1 HP for massive power boost. 20s cooldown. Risk/Reward!", type = "active", trigger = "sacrifice", cooldown = 20},
    {name = "TIME WARP", desc = "Right-click: Slow time 5s", detail = "Press Right-Click to slow time for 5 seconds. 25s cooldown. Easy dodging!", type = "active", trigger = "timewarp", cooldown = 25},
    {name = "BLITZ", desc = "Right-click: Speed burst 3s", detail = "Press Right-Click for 3 seconds of 3x speed. 15s cooldown. Zoom zoom!", type = "active", trigger = "blitz", cooldown = 15},
    {name = "SURGE", desc = "Right-click: Fire rate 3x 5s", detail = "Press Right-Click for 5 seconds of 3x fire rate. 20s cooldown. Bullet hell!", type = "active", trigger = "surge", cooldown = 20},
    
    {name = "JOKER", desc = "Redraw power offer once", detail = "When offered powers, get one free redraw chance. 8% chance to auto-trigger!", type = "lucky", trigger = "redraw", chance = 0.08},
    {name = "FREE PASS", desc = "Skip without penalty", detail = "Skip power offers without resetting the timer. 5% chance to auto-trigger!", type = "lucky", trigger = "skip", chance = 0.05},
    {name = "DOUBLE UP", desc = "Get 2 powers instead of 1", detail = "When picking a power, get TWO powers! 3% chance to trigger!", type = "lucky", trigger = "double", chance = 0.03},
    {name = "INSTANT WIN", desc = "Small chance: Get any power", detail = "Small 1% chance to get ANY power you want. The ultimate gamble!", type = "lucky", trigger = "insta", chance = 0.01},
}

local POKER_SYNERGIES = {
    {name = "PAIR", desc = "2 same-rarity powers", bonus = "+10% damage", trigger = "pair", required = 2},
    {name = "TWO PAIR", desc = "2 sets of pairs", bonus = "+20% damage, +10% crit", trigger = "twopair", required = 4},
    {name = "THREE OF A KIND", desc = "3 same-rarity powers", bonus = "+30% fire rate", trigger = "trips", required = 3},
    {name = "STRAIGHT", desc = "5 consecutive rarities", bonus = "+25% all stats", trigger = "straight", required = 5},
    {name = "FLUSH", desc = "5 same-rarity powers", bonus = "+50% ability effect", trigger = "flush", required = 5},
    {name = "FULL HOUSE", desc = "3+2 same rarity", bonus = "+40% damage, +20% speed", trigger = "fullhouse", required = 5},
    {name = "FOUR OF A KIND", desc = "4 same-rarity powers", bonus = "+100% crit damage", trigger = "quads", required = 4},
    {name = "STRAIGHT FLUSH", desc = "5 consecutive + same rarity", bonus = "+100% all stats", trigger = "sf", required = 5},
    {name = "ROYAL FLUSH", desc = "Ultimate combo", bonus = "+200% everything", trigger = "royal", required = 5},
}

local RARITY_ORDER = {common = 1, uncommon = 2, rare = 3, epic = 4, mythic = 5, legendary = 6, ultimate = 7}

local POWER_TYPES = {
    -- COMMON (15)
    {name = "TRIPLE SHOT", desc = "+2 bullets in spread", detail = "Fires 2 additional bullets in a spread pattern. Each bullet deals full damage. Stacks with other shot abilities.", rarity = "common"},
    {name = "RAPID FIRE", desc = "+20% fire rate", detail = "Increases your fire rate by 20%. Shoots faster, dealing more damage over time. Stacks multiplicatively.", rarity = "common"},
    {name = "QUICK SLIDES", desc = "+15% movement speed", detail = "Move 15% faster. Helps you dodge enemies and reach power-ups quicker. Great for survival.", rarity = "common"},
    {name = "SHARP ARROWS", desc = "+10% damage", detail = "All your bullets deal 10% more damage. Simple but effective. Stacks with other damage boosts.", rarity = "common"},
    {name = "LIGHT FOOT", desc = "Dodge +5%", detail = "5% chance to completely dodge enemy attacks. Works passively. Can save you in tight situations.", rarity = "common"},
    {name = "STEADY HAND", desc = "+5% accuracy", detail = "Bullets stay on target better. Reduces bullet spread slightly. Synergizes with precision builds.", rarity = "common"},
    {name = "FOCUSED MIND", desc = "+5% crit chance", detail = "5% chance to deal 3x damage with any bullet. Critical hits can insta-kill weak enemies.", rarity = "common"},
    {name = "SWIFT STRIKE", desc = "+10% attack speed", detail = "Similar to Rapid Fire but stacks differently. Combined with Rapid Fire for maximum fire rate.", rarity = "common"},
    {name = "BASIC SHIELD", desc = "Block 1 hit", detail = "Blocks one enemy hit completely. The shield breaks after one collision. Refreshes when you get another Basic Shield.", rarity = "common"},
    {name = "ENERGY SALVE", desc = "Heal 1 HP", detail = "Instantly restores 1 HP. Can be the difference between life and death. Save for emergencies!", rarity = "common"},
    {name = "LUCKY CHARM", desc = "+3% luck", detail = "Increases all random chances by 3%: crits, dodges, drops, and Joker triggers. Subtle but powerful.", rarity = "common"},
    {name = "WEAK FREEZE", desc = "5% freeze chance", detail = "5% chance to freeze enemies for 1 second. Frozen enemies can't move or attack. Great crowd control.", rarity = "common"},
    {name = "BURNING ARROW", desc = "5% burn chance", detail = "5% chance to apply burn dealing damage over 3 seconds. Burns stack and can kill enemies slowly.", rarity = "common"},
    {name = "SHOCK WAVE", desc = "5% shock chance", detail = "5% chance to shock enemies, slowing them by 30% for 2 seconds. Great for kiting.", rarity = "common"},
    {name = "SILVER BULLET", desc = "+8% damage vs enemies", detail = "Deal 8% extra damage to all enemies. Consistent damage boost in every situation.", rarity = "common"},
    
    -- UNCOMMON (15)
    {name = "PIERCING SHOT", desc = "Bullets pierce +1", detail = "Bullets pass through 1 additional enemy. Clears groups easily. Essential for mob control.", rarity = "uncommon"},
    {name = "DOUBLE TAP", desc = "15% double shot", detail = "15% chance to fire an extra bullet with each shot. Can double your damage output instantly.", rarity = "uncommon"},
    {name = "EXPLOSIVE ROUND", desc = "Kills explode", detail = "Killed enemies explode dealing 50% damage to nearby enemies. Chain reactions clear crowds!", rarity = "uncommon"},
    {name = "MEDIUM ARMOR", desc = "+15% damage reduction", detail = "Take 15% less damage from all sources. Stacks with other damage reduction.", rarity = "uncommon"},
    {name = "PHASE SHIFT", desc = "20% chance to dodge", detail = "20% chance to become intangible for 0.5s when hit. Great survivability boost.", rarity = "uncommon"},
    {name = "CHAIN LIGHTNING", desc = "Kills shock nearby", detail = "Killed enemies release lightning hitting up to 3 nearby enemies. Electric chain reactions!", rarity = "uncommon"},
    {name = "POISON TIP", desc = "10% poison chance", detail = "10% chance to poison enemies, dealing damage over 5 seconds. Poisoned enemies die faster in groups.", rarity = "uncommon"},
    {name = "ICE SHARD", desc = "10% freeze chance", detail = "10% chance to freeze enemies. Higher freeze rate than Weak Freeze. Control the battlefield!", rarity = "uncommon"},
    {name = "FLAME TONGUE", desc = "10% burn chance", detail = "10% chance to burn enemies. Burn damage stacks with multiple hits. devastating with fast fire rate.", rarity = "uncommon"},
    {name = "VAMPIRIC TOUCH", desc = "Heal on kill", detail = "Heal 1 HP every 12 kills. Keeps you alive during long runs. Essential for survival.", rarity = "uncommon"},
    {name = "REGENERATION", desc = "Heal over time", detail = "Heal 1 HP every 30 seconds passively. Steady health recovery. Combos with Vampiric Touch.", rarity = "uncommon"},
    {name = "LUCK BOOST", desc = "+10% luck", detail = "+10% to all random chances. Better drops, more crits, more dodges. Increases Joker chances.", rarity = "uncommon"},
    {name = "GOLDEN TOUCH", desc = "+15% currency", detail = "Earn 15% more credits from kills. Save up for upgrades faster. Great economy skill.", rarity = "uncommon"},
    {name = "MYSTIC ORB", desc = "Orbit orb, damage", detail = "A magic orb orbits around you damaging enemies on contact. Auto-attacks without shooting!", rarity = "uncommon"},
    {name = "DEFLECTION", desc = "Reflect bullets", detail = "Reflect 20% of enemy bullets back at them. Turn enemy attacks into your offense.", rarity = "uncommon"},
    
    -- RARE (12)
    {name = "SPREAD CANNON", desc = "Fire 5 bullets", detail = "Fire 5 bullets in a wide arc. Devastating against groups. Combines with Triple Shot!", rarity = "rare"},
    {name = "HOMING BOLTS", desc = "Bullets seek target", detail = "Bullets automatically steer toward nearest enemy. Never miss! Essential for precision builds.", rarity = "rare"},
    {name = "CRITICAL STRIKE", desc = "+15% crit, 3x dmg", detail = "+15% crit chance AND crits deal 3x damage. Devastating burst potential. Stack for destruction!", rarity = "rare"},
    {name = "TIME DILATION", desc = "Enemies 15% slower", detail = "Enemies move and attack 15% slower. More time to react and dodge. Great defensive skill.", rarity = "rare"},
    {name = "SNIPER ELITE", desc = "+30% bullet speed", detail = "Bullets travel 30% faster. Hitscan-like damage. Enemies have less time to dodge.", rarity = "rare"},
    {name = "SHOTGUN BLAST", desc = "Fire 7 short range", detail = "Fire 7 bullets in a tight cone at close range. Devastating point-blank. Use carefully!", rarity = "rare"},
    {name = "PLASMA CHARGE", desc = "Plasma bullets", detail = "Bullets become plasma, dealing bonus damage over time. Each hit weakens enemies.", rarity = "rare"},
    {name = "GHOST WALK", desc = "Intangible 2s/10s", detail = "Become ghost for 2 seconds every 10 seconds. Phase through enemies and bullets.", rarity = "rare"},
    {name = "THUNDER STRIKE", desc = "Chain lightning", detail = "Chain lightning arcs between enemies. Each hit can trigger status effects. Storm bringer!", rarity = "rare"},
    {name = "VOID SHOT", desc = "Ignore defense", detail = "Bullets ignore 50% of enemy defense. Vital against tough enemies and bosses.", rarity = "rare"},
    {name = "SPIRIT ARROW", desc = "Pierce +2, haunt", detail = "Arrows pierce 2 more enemies AND haunt them, dealing damage over time. Ghost army!", rarity = "rare"},
    {name = "ARMOR PIERCING", desc = "Ignore 30% def", detail = "Ignore 30% of all enemy defense. Consistent damage against armored foes.", rarity = "rare"},
    
    -- EPIC (10)
    {name = "MULTI FIRE", desc = "Fire 8 directions", detail = "Fire in all 8 directions at once. Maximum crowd control. Devastating mob clear!", rarity = "epic"},
    {name = "DRAGON BREATH", desc = "Cone of fire", detail = "Continuous flame breath in a cone while shooting. Melts groups instantly. Combine with fire rate!", rarity = "epic"},
    {name = "PLASMA STORM", desc = "Damaging field", detail = "Creates a plasma field around you. Enemies entering take constant damage. Personal bubble!", rarity = "epic"},
    {name = "GRAVITY WELL", desc = "Pull enemies in", detail = "Enemies are pulled toward you slowly. Groups stay together for easy clearing.", rarity = "epic"},
    {name = "ARMY OF ONE", desc = "Shadow soldiers", detail = "Summon shadow soldiers to fight for you. Auto-attacking allies. Ultimate minion build!", rarity = "epic"},
    {name = "ICE NOVA", desc = "Freeze all enemies", detail = "Freeze all enemies on screen periodically. Total crowd control. Game changer!", rarity = "epic"},
    {name = "POISON CLOUD", desc = "DoT area", detail = "Poison cloud surrounds you. Enemies entering take massive DoT. Walking death!", rarity = "epic"},
    {name = "QUANTUM STRIKE", desc = "Dual damage", detail = "Each bullet exists in two places at once. Effectively 2x damage with no extra shooting.", rarity = "epic"},
    {name = "COSMIC RAY", desc = "Heavy beam", detail = "Fire a massive beam of energy. Destroys everything in its path. Ultimate beam weapon!", rarity = "epic"},
    {name = "ECHO STRIKE", desc = "Afterimages", detail = "Your bullets leave damaging afterimages. Double the visual, double the pain!", rarity = "epic"},
    
    -- MYTHIC (8)
    {name = "BLACK HOLE", desc = "Singularity", detail = "Create a black hole that pulls in and damages enemies. Ultimate crowd control.", rarity = "mythic"},
    {name = "METEOR RAIN", desc = "Meteors fall", detail = "Meteors fall periodically, smashing enemies. Passive meteor support!", rarity = "mythic"},
    {name = "SUNBURST", desc = "Radiant explosion", detail = "Massive sun explosion on kills. Screen-clear potential. Brilliant destruction!", rarity = "mythic"},
    {name = "VOID TENTACLES", desc = "Grapple enemies", detail = "Void tentacles grab and hold enemies. Total lockdown. Combine with damage!", rarity = "mythic"},
    {name = "PHANTOM ARMY", desc = "15 shadow clones", detail = "Summon 15 shadow clones to fight. Army of ghosts. Maximum minion madness!", rarity = "mythic"},
    {name = "BLOOD RITUAL", desc = "HP to power", detail = "Sacrifice HP for power. More lifesteal, more damage. High risk, high reward!", rarity = "mythic"},
    {name = "THUNDER LORD", desc = "Constant strikes", detail = "Lightning strikes enemies periodically. Automated destruction. Storm god mode!", rarity = "mythic"},
    {name = "PHOENIX RISE", desc = "Revive once", detail = "Auto-revive once when you die. Second chance. Essential for deep runs!", rarity = "mythic"},
    
    -- LEGENDARY (5)
    {name = "APOCALYPSE", desc = "End of world", detail = "The end approaches. Massive damage to all enemies. Game-changing ultimate.", rarity = "legendary"},
    {name = "NEO MODE", desc = "All stats +50%", detail = "All your stats increased by 50%. Become overpowered. True legendary status!", rarity = "legendary"},
    {name = "INFINITY EDGE", desc = "Stack forever", detail = "Damage stacks infinitely. The longer the run, the stronger you get. Endgame dream!", rarity = "legendary"},
    {name = "BERSERKER", desc = "Damage = speed", detail = "Movement speed increases with damage. Faster = Deadlier. Race to destruction!", rarity = "legendary"},
    {name = "OMEGA STRIKE", desc = "Ultimate beam", detail = "Fire the ultimate beam. Destroys everything. The final word in combat.", rarity = "legendary"},
    
    -- ULTIMATE (2)
    {name = "GOD HAND", desc = "One punch kill", detail = "One hit kills almost anything. True god mode. Complete domination!", rarity = "ultimate"},
    {name = "TRANSCENDENCE", desc = "Perfect being", detail = "Become perfect. 2x all stats, +5 HP, full heal. Ascend to godhood!", rarity = "ultimate"}
}

-- Total: 67 powers!

function Power.new()
    local self = setmetatable({}, Power)
    self.offers = {}
    self.offer_timer = 0
    self.offer_interval = 18
    self.is_offering = false
    self.selected_index = nil
    self.close_button = {x = 0, y = 0, width = 160, height = 50, hover = false}
    self.joker_offers = {}
    self.joker_timer = 0
    self.joker_interval = 45
    self.has_joker = false
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
        
        self.joker_timer = self.joker_timer + dt
        if self.joker_timer >= self.joker_interval and not self.has_joker then
            self:generate_joker_offer()
            game.state.choose_joker = true
        end
    end
    
    for _, offer in ipairs(self.offers) do
        offer.scale = offer.scale + (offer.target_scale - offer.scale) * 0.15
    end
    
    for _, offer in ipairs(self.joker_offers) do
        offer.scale = offer.scale + (offer.target_scale - offer.scale) * 0.15
    end
end

function Power:generate_joker_offer()
    self.joker_timer = 0
    self.joker_offers = {}
    self.is_showing_jokers = true
    
    local count = 1
    if math.random() < 0.2 then count = 2 end
    
    for i = 1, count do
        local joker_data = JOKER_TYPES[math.random(1, #JOKER_TYPES)]
        table.insert(self.joker_offers, {
            data = joker_data,
            x = 0, y = 0,
            width = 180, height = 220,
            hover = false,
            scale = 1.0, target_scale = 1.0
        })
    end
end

function Power:calculate_synergies(player)
    if not player or not player.powerups then return {} end
    
    local rarities = {}
    for name, level in pairs(player.powerups) do
        if level > 0 then
            for _, p in ipairs(POWER_TYPES) do
                local power_key = name:lower():gsub(" ", "_")
                if p.name:lower():gsub(" ", "_") == power_key then
                    table.insert(rarities, {name = name, rarity = p.rarity, level = level})
                    break
                end
            end
        end
    end
    
    local active_synergies = {}
    
    local rarity_counts = {}
    for _, r in ipairs(rarities) do
        rarity_counts[r.rarity] = (rarity_counts[r.rarity] or 0) + 1
    end
    
    local counts = {}
    for r, c in pairs(rarity_counts) do
        table.insert(counts, c)
    end
    table.sort(counts, function(a,b) return a > b end)
    
    if counts[1] and counts[1] >= 2 then
        table.insert(active_synergies, {name = "PAIR", bonus = "+10% damage", color = {0.8, 0.8, 0.8}})
    end
    if counts[1] and counts[1] >= 3 then
        table.insert(active_synergies, {name = "THREE OF A KIND", bonus = "+30% fire rate", color = {0.3, 0.6, 1}})
    end
    if counts[1] and counts[1] >= 4 then
        table.insert(active_synergies, {name = "FOUR OF A KIND", bonus = "+100% crit dmg", color = {1, 0.85, 0.2}})
    end
    if counts[1] and counts[1] >= 5 then
        table.insert(active_synergies, {name = "FLUSH", bonus = "+50% ability effect", color = {0.7, 0.4, 0.9}})
    end
    
    return active_synergies
end

function Power:getJokerEffects()
    return {
        lucky_bonus = 0,
        draw_bonus = 0,
        wild_stacks = 1,
        gold_bonus = 0,
        dodge_chance = 0,
        duration_bonus = 0,
        crown_bonus = 0,
        glass_bonus = 0,
        stone_bonus = 0,
        streak_bonus = 0,
        combo_bonus = 0
    }
end

function Power:draw_joker_offer(center_x, center_y)
    if #self.joker_offers == 0 then return end
    
    love.graphics.setColor(0.02, 0.03, 0.08, 0.85)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local time = love.timer.getTime()
    
    love.graphics.setFont(love.graphics.newFont(32))
    local pulse = math.sin(time * 3) * 0.2 + 0.8
    love.graphics.setColor(1, 0.9, 0.3, pulse)
    love.graphics.printf("🎭 JOKER OFFER! 🎭", 0, center_y - 180, love.graphics.getWidth(), "center")
    
    local mx, my = love.mouse.getPosition()
    local card_w, card_h = 180, 220
    local spacing = 40
    local total_w = #self.joker_offers * card_w + (#self.joker_offers - 1) * spacing
    local start_x = center_x - total_w / 2
    
    for i, offer in ipairs(self.joker_offers) do
        local cx = start_x + (i - 1) * (card_w + spacing) + card_w / 2
        local cy = center_y + 20
        offer.x = cx - card_w / 2
        offer.y = cy - card_h / 2
        
        local dx, dy = mx - cx, my - cy
        offer.hover = dx > -card_w/2 and dx < card_w/2 and dy > -card_h/2 and dy < card_h/2
        
        if offer.hover then offer.target_scale = 1.1 else offer.target_scale = 1.0 end
        local s = offer.scale
        local rw, rh = card_w * s, card_h * s
        local rx, ry = cx - rw/2, cy - rh/2
        
        local joker_color = {1, 0.85, 0.2}
        if offer.data.type == "active" then joker_color = {0.9, 0.3, 0.3}
        elseif offer.data.type == "lucky" then joker_color = {0.3, 1, 0.5}
        end
        
        for layer = 1, 4 do
            love.graphics.setColor(joker_color[1], joker_color[2], joker_color[3], (5-layer) * 0.03 * (offer.hover and 2 or 1))
            love.graphics.rectangle("fill", rx - layer*3, ry - layer*3, rw + layer*6, rh + layer*6)
        end
        
        love.graphics.setColor(0.1, 0.08, 0.02)
        love.graphics.rectangle("fill", rx, ry, rw, rh)
        
        love.graphics.setColor(joker_color[1], joker_color[2], joker_color[3], offer.hover and 1 or 0.7)
        love.graphics.setLineWidth(offer.hover and 4 or 2)
        love.graphics.rectangle("line", rx, ry, rw, rh)
        
        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.setColor(1, 0.9, 0.3)
        local symbol = offer.data.type == "passive" and "♠" or (offer.data.type == "active" and "♦" or "♣")
        love.graphics.print(symbol, cx - 14, ry + 15)
        
        love.graphics.setFont(love.graphics.newFont(12 * s))
        love.graphics.setColor(1, 1, 1)
        local name_w = love.graphics.getFont():getWidth(offer.data.name)
        love.graphics.print(offer.data.name, cx - name_w/2, ry + 55)
        
        love.graphics.setFont(love.graphics.newFont(10 * s))
        love.graphics.setColor(0.7, 0.7, 0.8)
        local desc_w = love.graphics.getFont():getWidth(offer.data.desc)
        love.graphics.print(offer.data.desc, cx - desc_w/2, ry + 80)
        
        love.graphics.setFont(love.graphics.newFont(10 * s))
        love.graphics.setColor(joker_color[1], joker_color[2], joker_color[3])
        local type_text = "♦ " .. offer.data.type:upper() .. " ♦"
        local type_w = love.graphics.getFont():getWidth(type_text)
        love.graphics.print(type_text, cx - type_w/2, ry + rh - 30)
    end
    
    local hint_y = center_y + 180
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.printf("Click to claim  •  ESC to skip", 0, hint_y, love.graphics.getWidth(), "center")
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
    local card_height_base = 300
    local spacing = 50
    local total_width = (#self.offers * card_width) + ((#self.offers - 1) * spacing)
    local start_x = center_x - total_width / 2
    
    love.graphics.setFont(love.graphics.newFont(44))
    local title_glow = math.sin(time * 2) * 0.15 + 0.85
    love.graphics.setColor(0.4 * title_glow, 0.9 * title_glow, 1 * title_glow)
    love.graphics.printf("✦ CHOOSE YOUR POWER ✦", 0, center_y - 250, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(love.graphics.newFont(17))
    love.graphics.setColor(0.5, 0.55, 0.65)
    love.graphics.printf("Click to select  •  Right-click or ESC to skip", 0, center_y - 185, love.graphics.getWidth(), "center")
    
    local mx, my = love.mouse.getPosition()
    
    for i, offer in ipairs(self.offers) do
        local cx = start_x + (i - 1) * (card_width + spacing) + card_width / 2
        local cy = center_y + 30
        
        local card_h = offer.hover and 360 or card_height_base
        offer.y = cy - card_h / 2
        
        local dx = mx - cx
        local dy = my - cy
        offer.hover = dx > -card_width/2 and dx < card_width/2 and dy > -card_h/2 and dy < card_h/2
        
        if offer.hover then
            offer.target_scale = 1.1
        else
            offer.target_scale = 1.0
        end
        
        local scale = offer.scale
        local w = card_width * scale
        local h = card_h * scale
        
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
        
        local desc_y = cy + 5 * scale
        love.graphics.setFont(love.graphics.newFont(11 * scale))
        love.graphics.setColor(0.65, 0.7, 0.8)
        
        local desc = offer.data.desc
        local max_w = w - 30
        local wrapped = self:wrapText(desc, max_w)
        for li, line in ipairs(wrapped) do
            local line_w = love.graphics.getFont():getWidth(line)
            love.graphics.print(line, cx - line_w / 2, desc_y + (li - 1) * 14 * scale)
        end
        
        if offer.hover and offer.data.detail then
            local detail_y = desc_y + (#wrapped * 14 * scale) + 10
            love.graphics.setColor(0.1, 0.12, 0.18)
            love.graphics.rectangle("fill", rx + 5, detail_y - 3, w - 10, 55)
            
            love.graphics.setColor(rarity_color[1] * 0.5, rarity_color[2] * 0.5, rarity_color[3] * 0.5, 0.8)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", rx + 5, detail_y - 3, w - 10, 55)
            
            love.graphics.setFont(love.graphics.newFont(9 * scale))
            love.graphics.setColor(0.6, 0.65, 0.75)
            local detail_wrapped = self:wrapText(offer.data.detail, max_w - 10)
            for li, line in ipairs(detail_wrapped) do
                if li <= 4 then
                    love.graphics.print(line, rx + 10, detail_y + (li - 1) * 12)
                end
            end
        end
        
        local rarity_y = cy + 95 * scale
        if offer.hover and offer.data.detail then
            rarity_y = cy + 155 * scale
        end
        
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
    if self.is_showing_jokers then
        self.is_showing_jokers = false
        self.joker_offers = {}
    end
end

function Power:handle_joker_click(x, y)
    if not self.is_showing_jokers then return nil end
    
    for i, offer in ipairs(self.joker_offers) do
        if offer.hover then
            self.is_showing_jokers = false
            local joker = offer.data
            self.joker_offers = {}
            self.has_joker = true
            return joker
        end
    end
    
    self.is_showing_jokers = false
    self.joker_offers = {}
    return nil
end

function Power:is_joker_offering()
    return self.is_showing_jokers or false
end

function Power:trigger_lucky(lucky_type, default_chance)
    if not self.has_joker then return false end
    
    for _, offer in ipairs(self.joker_offers) do
        if offer.data.trigger == lucky_type then
            local chance = offer.data.chance or default_chance
            return math.random() < chance
        end
    end
    return false
end

function Power:get_active_jokers()
    if not self.has_joker then return {} end
    local result = {}
    for _, offer in ipairs(self.joker_offers) do
        table.insert(result, offer.data)
    end
    return result
end

return Power
