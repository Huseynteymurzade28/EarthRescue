local love = require("love")

local UpgradeManager = {}
UpgradeManager.__index = UpgradeManager

local UPGRADES = {
    {
        id = "starting_hp",
        name = "EXTRA LIFE",
        desc = "Start each run with +1 HP",
        max_level = 3,
        cost = {100, 250, 500},
        category = "survival"
    },
    {
        id = "damage_up",
        name = "DAMAGE UP",
        desc = "+25% bullet damage",
        max_level = 5,
        cost = {80, 150, 250, 400, 600},
        category = "combat"
    },
    {
        id = "fire_rate",
        name = "RAPID LOAD",
        desc = "+15% fire rate",
        max_level = 5,
        cost = {60, 120, 200, 320, 500},
        category = "combat"
    },
    {
        id = "speed_up",
        name = "THRUSTERS",
        desc = "+15% movement speed",
        max_level = 5,
        cost = {50, 100, 180, 300, 480},
        category = "movement"
    },
    {
        id = "pickup_range",
        name = "SCANNER",
        desc = "+30% power pickup range",
        max_level = 3,
        cost = {75, 175, 350},
        category = "utility"
    },
    {
        id = "luck",
        name = "FORTUNE",
        desc = "+10% chance for rare powers",
        max_level = 5,
        cost = {100, 200, 350, 550, 800},
        category = "utility"
    },
    {
        id = "pierce_up",
        name = "ARMOR PIERCING",
        desc = "+1 bullet pierce",
        max_level = 3,
        cost = {150, 300, 600},
        category = "combat"
    },
    {
        id = "start_power",
        name = "BLESSING",
        desc = "Start with a random power",
        max_level = 1,
        cost = {500},
        category = "special"
    },
    {
        id = "regen",
        name = "AUTO REPAIR",
        desc = "Heal 1 HP every 30 seconds",
        max_level = 3,
        cost = {200, 400, 800},
        category = "survival"
    },
    {
        id = "crit_chance",
        name = "PRECISION",
        desc = "+5% critical hit chance",
        max_level = 5,
        cost = {75, 150, 250, 400, 650},
        category = "combat"
    }
}

local CATEGORY_COLORS = {
    survival = {0.2, 0.9, 0.4},
    combat = {0.9, 0.3, 0.3},
    movement = {0.3, 0.6, 0.9},
    utility = {0.9, 0.8, 0.3},
    special = {0.8, 0.4, 1.0}
}

function UpgradeManager.new()
    local self = setmetatable({}, UpgradeManager)
    self.upgrades = {}
    self.currency = 0
    self.total_runs = 0
    self.best_score = 0
    self.highest_level = 1
    
    for _, u in ipairs(UPGRADES) do
        self.upgrades[u.id] = {
            level = 0,
            data = u
        }
    end
    
    self:load()
    
    return self
end

function UpgradeManager:addCurrency(amount)
    self.currency = self.currency + amount
    self:save()
end

function UpgradeManager:getUpgradeLevel(id)
    return self.upgrades[id].level
end

function UpgradeManager:canAfford(id)
    local u = self.upgrades[id]
    if u.level >= u.data.max_level then return false end
    return self.currency >= u.data.cost[u.level + 1]
end

function UpgradeManager:purchase(id)
    local u = self.upgrades[id]
    if not self:canAfford(id) then return false end
    
    self.currency = self.currency - u.data.cost[u.level + 1]
    u.level = u.level + 1
    self:save()
    return true
end

function UpgradeManager:getModifier(id)
    local u = self.upgrades[id]
    local level = u.level
    
    if id == "starting_hp" then
        return level
    elseif id == "damage_up" then
        return 1 + (level * 0.25)
    elseif id == "fire_rate" then
        return 1 + (level * 0.15)
    elseif id == "speed_up" then
        return 1 + (level * 0.15)
    elseif id == "pickup_range" then
        return 1 + (level * 0.3)
    elseif id == "luck" then
        return level * 0.1
    elseif id == "pierce_up" then
        return level
    elseif id == "regen" then
        return level
    elseif id == "crit_chance" then
        return level * 0.05
    end
    
    return 0
end

function UpgradeManager:recordRun(score, level, currency_earned)
    self.total_runs = self.total_runs + 1
    self.currency = self.currency + currency_earned
    if score > self.best_score then
        self.best_score = score
    end
    if level > self.highest_level then
        self.highest_level = level
    end
    self:save()
end

function UpgradeManager:getEligibleUpgrades()
    local eligible = {}
    for id, u in pairs(self.upgrades) do
        if u.level < u.data.max_level then
            table.insert(eligible, {
                id = id,
                data = u.data,
                level = u.level,
                cost = u.data.cost[u.level + 1],
                can_afford = self.currency >= u.data.cost[u.level + 1]
            })
        end
    end
    return eligible
end

function UpgradeManager:save()
    local data = {
        currency = self.currency,
        total_runs = self.total_runs,
        best_score = self.best_score,
        highest_level = self.highest_level,
        upgrades = {}
    }
    for id, u in pairs(self.upgrades) do
        data.upgrades[id] = u.level
    end
    
    local success, err = love.filesystem.write("save_data.lua", "return " .. table.show(data))
    if not success then
        print("Failed to save: " .. tostring(err))
    end
end

function UpgradeManager:load()
    if love.filesystem.exists("save_data.lua") then
        local success, data = pcall(require, "save_data")
        if success and data then
            self.currency = data.currency or 0
            self.total_runs = data.total_runs or 0
            self.best_score = data.best_score or 0
            self.highest_level = data.highest_level or 1
            if data.upgrades then
                for id, level in pairs(data.upgrades) do
                    if self.upgrades[id] then
                        self.upgrades[id].level = level
                    end
                end
            end
        end
    end
end

function UpgradeManager:getStats()
    return {
        currency = self.currency,
        total_runs = self.total_runs,
        best_score = self.best_score,
        highest_level = self.highest_level
    }
end

function table.show(t, indent)
    local parts = {"{"}
    local indent_str = indent and string.rep("  ", indent) or "  "
    for k, v in pairs(t) do
        if type(v) == "table" then
            table.insert(parts, indent_str .. "[" .. tostring(k) .. "] = " .. table.show(v, (indent or 0) + 1))
        elseif type(v) == "string" then
            table.insert(parts, indent_str .. "[" .. tostring(k) .. '] = "' .. v .. '"')
        else
            table.insert(parts, indent_str .. "[" .. tostring(k) .. "] = " .. tostring(v))
        end
    end
    table.insert(parts, "}")
    return table.concat(parts, "\n")
end

return UpgradeManager
