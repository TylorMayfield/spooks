HC = require 'HC'

-- array to hold collision messages
local text = {}
local ghosty = love.graphics.newImage("ghosty.png")
positionX = 0
postionY = 0
scale = .5


function love.load()
    -- add a rectangle to the scene
    rect = HC.rectangle(200,400,400,20)

    -- add a circle to the scene
    mouse = HC.circle(0,0,(ghosty:getHeight()/2) * scale)
    -- get the position of the mouse
    

    mouse:moveTo(love.mouse.getPosition())
    


end

function love.update(dt)
    -- move circle to mouse position
    mouse:moveTo(love.mouse.getPosition())
    x, y = love.mouse.getPosition() 
    -- rotate rectangle
    rect:rotate(dt)

    -- check for collisions
    for shape, delta in pairs(HC.collisions(mouse)) do
        text[#text+1] = string.format("Colliding. Separating vector = (%s,%s,%s)", shape,
                                      delta.x, delta.y)
    end

    while #text > 40 do
        table.remove(text, 1)
    end
end

function love.draw()
    -- print messages
    for i = 1,#text do
        love.graphics.setColor(255,255,255, 255 - (i-1) * 6)
        love.graphics.print(text[#text - (i-1)], 10, i * 15)
    end

    -- shapes can be drawn to the screen

    love.graphics.draw(ghosty, x-((ghosty:getHeight()/2) * scale), y-((ghosty:getHeight()/2) * scale), 0, scale, scale)

    love.graphics.setColor(255,255,255)
    rect:draw('fill')
    --mouse:draw('fill')
    
    
end