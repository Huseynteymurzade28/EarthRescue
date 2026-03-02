local love = require("love")

function Button(text, func, func_param, width, height)
    return {
        width = width or 240,
        height = height or 65,
        func = func or function ()
            print("This button has no function assigned.")
        end,
        func_param = func_param,
        text = text or "Button",
        button_x = 0,
        button_y = 0,
        hover_sound_played = false,
        anim_scale = 1,
        target_scale = 1,
        glow_pulse = 0,

        is_hovered = function(self, mx, my)
            return mx >= self.button_x and mx <= self.button_x + self.width and
                   my >= self.button_y and my <= self.button_y + self.height
        end,

        on_mouse_pressed = function(self, mx, my, button)
            if self:is_hovered(mx, my) and button == 1 then
                if self.func then
                    if self.func_param then
                        self.func(self.func_param)
                    else
                        self.func()
                    end
                end
                return true
            end
            return false
        end,

        draw = function(self, x, y)
            self.button_x = x or self.button_x
            self.button_y = y or self.button_y
            
            local mx, my = love.mouse.getPosition()
            local hovered = self:is_hovered(mx, my)
            local time = love.timer.getTime()
            
            self.target_scale = hovered and 1.08 or 1.0
            self.anim_scale = self.anim_scale + (self.target_scale - self.anim_scale) * 0.25
            self.glow_pulse = self.glow_pulse + 0.08
            
            local w = self.width * self.anim_scale
            local h = self.height * self.anim_scale
            local bx = self.button_x - (w - self.width) / 2
            local by = self.button_y - (h - self.height) / 2
            
            local pulse = math.sin(self.glow_pulse) * 0.15 + 0.85
            
            local base_r, base_g, base_b = 0.05, 0.08, 0.12
            local accent_r, accent_g, accent_b = 0.0, 0.9, 1.0
            local glow_intensity = 0.15
            
            if hovered then
                base_r, base_g, base_b = 0.08, 0.05, 0.18
                accent_r, accent_g, accent_b = 0.4, 0.7, 1.0
                glow_intensity = 0.4
            end
            
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", bx + 6, by + 6, w, h)
            
            for i = 1, 6 do
                local alpha = (7 - i) * 0.035 * glow_intensity * pulse
                love.graphics.setColor(accent_r, accent_g, accent_b, alpha)
                love.graphics.rectangle("fill", bx - i*3, by - i*3, w + i*6, h + i*6)
            end
            
            love.graphics.setColor(base_r, base_g, base_b, 0.95)
            love.graphics.rectangle("fill", bx, by, w, h)
            
            local gradient_steps = 10
            for gi = 0, gradient_steps - 1 do
                local gy = by + (gi / gradient_steps) * h * 0.4
                local gh = h * 0.4 / gradient_steps + 1
                local alpha = (gi / gradient_steps) * 0.3
                love.graphics.setColor(accent_r * 0.5, accent_g * 0.5, accent_b * 0.5, alpha)
                love.graphics.rectangle("fill", bx, gy, w, gh)
            end
            
            local border_alpha = hovered and 1 or 0.6
            love.graphics.setColor(accent_r, accent_g, accent_b, border_alpha * pulse)
            love.graphics.setLineWidth(hovered and 4 or 2)
            love.graphics.rectangle("line", bx, by, w, h)
            
            local corner_len = 18
            love.graphics.setLineWidth(hovered and 5 or 3)
            
            love.graphics.setColor(accent_r, accent_g, accent_b, border_alpha * pulse)
            love.graphics.line(bx, by + corner_len, bx, by)
            love.graphics.line(bx, by, bx + corner_len, by)
            
            love.graphics.line(bx + w - corner_len, by, bx + w, by)
            love.graphics.line(bx + w, by, bx + w, by + corner_len)
            
            love.graphics.line(bx, by + h - corner_len, bx, by + h)
            love.graphics.line(bx, by + h, bx + corner_len, by + h)
            
            love.graphics.line(bx + w - corner_len, by + h, bx + w, by + h)
            love.graphics.line(bx + w, by + h - corner_len, bx + w, by + h)
            
            if hovered then
                love.graphics.setColor(accent_r, accent_g, accent_b, 0.15 * pulse)
                love.graphics.rectangle("fill", bx + 5, by + 5, w - 10, h - 10)
            end
            
            love.graphics.setColor(1, 1, 1)
            local font = love.graphics.newFont(20)
            love.graphics.setFont(font)
            local textW = font:getWidth(self.text)
            local textH = font:getHeight()
            
            if hovered then
                love.graphics.setColor(accent_r, accent_g, accent_b)
            end
            
            love.graphics.print(self.text, bx + w/2 - textW/2, by + h/2 - textH/2)
            
            love.graphics.setLineWidth(1)
        end
    }
end

return Button
