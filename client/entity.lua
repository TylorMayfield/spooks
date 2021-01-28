Entity = Object:extend()

function Entity:new(x, y, image_path)
    self.x = x
    self.y = y
    self.image = love.graphics.newImage(image_path)
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
end

function Entity:update(dt)
    -- We'll leave this empty for now.
end

function Entity:draw()
    love.graphics.draw(self.image, self.x, self.y)
end