local love = require("love")

function Button(text, func, func_param, width, height)
    return {
        width = width or 200,
        height = height or 60,
        func = func or function ()
            print("This button has no function assigned.")
        end,
        func_param = func_param,
        text = text or "Button",
        button_x = 0,
        button_y = 0,

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
            end
        end,

        draw = function(self, x, y)
            self.button_x = x or self.button_x
            self.button_y = y or self.button_y
            
            local mx, my = love.mouse.getPosition()
            local hovered = self:is_hovered(mx, my)

            -- Retro Sci-Fi Style
            local r, g, b = 45/255, 225/255, 145/255 -- Default Neon Cyan/Green
            if hovered then
                r, g, b = 108/255, 56/255, 245/255 -- Purple on hover
            end

            -- Background (Transparent with border)
            love.graphics.setColor(r, g, b, 0.2)
            love.graphics.rectangle("fill", self.button_x, self.button_y, self.width, self.height)

            -- Border (Glowing effect simulated by drawing lines)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", self.button_x, self.button_y, self.width, self.height)
            
            -- Corner Accents
            local corner_len = 10
            love.graphics.setLineWidth(4)
            -- Top Left
            love.graphics.line(self.button_x, self.button_y, self.button_x + corner_len, self.button_y)
            love.graphics.line(self.button_x, self.button_y, self.button_x, self.button_y + corner_len)
            -- Bottom Right
            love.graphics.line(self.button_x + self.width, self.button_y + self.height, self.button_x + self.width - corner_len, self.button_y + self.height)
            love.graphics.line(self.button_x + self.width, self.button_y + self.height, self.button_x + self.width, self.button_y + self.height - corner_len)

            -- Text
            love.graphics.setColor(1, 1, 1, 1)
            local font = love.graphics.getFont()
            local textW = font:getWidth(self.text)
            local textH = font:getHeight()
            love.graphics.print(self.text, self.button_x + self.width/2 - textW/2, self.button_y + self.height/2 - textH/2)
            
            love.graphics.setLineWidth(1)
        end
    }
end

return Button
