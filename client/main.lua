package.path = package.path .. ";../../?.lua"
sock = require "sock"
bitser = require "lib.bitser"
Gamestate = require "lib.gamestate"
UI = require "lib.Gspot"

--Globals
local ticksPerSec = 120
local DIV = love._version_major >= 11 and 1/255 or 1
local input = UI:input('Chat', {64, love.graphics.getHeight() - 32, 256, UI.style.unit})
local ChatSubmit = UI:button('Speak', {input.pos.w + UI.style.unit, 0, 64, UI.style.unit}, input) -- attach a button
--GameStates
local GAMESTATE_PREROLL = {}
local GAMESTATE_MENU = {}
local GAMESTATE_GAME = {}
local GAMESTATE_SETTINGS = {}
local GAMESTATE_LOBBY = {}

local ghosty = love.graphics.newImage("assets/ghosty.png")

function love.load()
    Font = love.graphics.newFont("assets/font/ThinkNothing.otf")
    love.graphics.setFont(Font,1256,"normal",96)
    Gamestate.registerEvents()
    Gamestate.switch(GAMESTATE_MENU)
end

function GAMESTATE_GAME:enter(previous)
    -- how often an update is sent out
    client = sock.newClient("localhost", 22122)
    tickRate = 1/ticksPerSec
    tick = 0

    client:setSerialization(bitser.dumps, bitser.loads)
    client:setSchema("playerState", {
        "index",
        "player",
    })

    -- store the client's index
    -- playerNumber is nil otherwise
    client:on("playerNum", function(num)
        PlayerNumber = num
    end)

    -- receive info on where the players are located
    client:on("playerState", function(data)
        local index = data.index
        local player = data.player

        -- only accept updates for the other player
        if PlayerNumber and index ~= PlayerNumber then
            players[index] = player
        end
    end)

    client:on("ballState", function(data)
        ball = data
    end)

    client:on("scores", function(data)
        scores = data
    end)

    client:connect()

    function NewPlayer(x, y)
        return {
            x = x,
            y = y,
            w = 20,
            h = 100,
        }
    end

    function NewBall(x, y)
        return {
            x = x,
            y = y,
            vx = 150,
            vy = 150,
            w = ghosty:getWidth(),
            h = ghosty:getHeight(),
        }
    end

    local marginX = 50

    players = {
        NewPlayer(marginX, love.graphics.getHeight()/2),
        NewPlayer(love.graphics.getWidth() - marginX, love.graphics.getHeight()/2)
    }

    scores = {0, 0}

    ball = NewBall(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
end

function GAMESTATE_GAME:update(dt)
    client:update()

    if client:getState() == "connected" then
        tick = tick + dt

        -- simulate the ball locally, and receive corrections from the server
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
    end

    if tick >= tickRate then
        tick = 0

        if PlayerNumber then
            local mouseY = love.mouse.getY()
            local playerY = mouseY - players[PlayerNumber].h/2

            -- Update our own player position and send it to the server
            players[PlayerNumber].y = playerY
            client:send("mouseY", playerY)
        end
    end
end

function GAMESTATE_GAME:draw()
    for _, player in pairs(players) do
        love.graphics.rectangle('fill', player.x, player.y, player.w, player.h)
    end

    love.graphics.draw(ghosty, ball.x, ball.y,0, 0.1, 0.1)

    love.graphics.print(client:getState(), 35, 35)
    if PlayerNumber then
        love.graphics.print("Player " .. PlayerNumber, 5, 25)
    else
        love.graphics.print("No player number assigned", 5, 25)
    end
    local score = ("%d - %d"):format(scores[1], scores[2])
    love.graphics.print(score, 5, 45)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function GAMESTATE_GAME:keypressed(key, code)
    if key == 'p' then
        return Gamestate.push(GAMESTATE_MENU)
    end

end

function GAMESTATE_MENU:draw()
    local W, H = love.graphics.getWidth(), love.graphics.getHeight()
    -- overlay with pause message
    love.graphics.setColor(0,0,0, 100)
    love.graphics.rectangle('fill', 0,0, W,H)
    love.graphics.setColor(255,255,255)
    love.graphics.printf('NOT Phasmophobia', 0, H/2, W, 'center')
    love.graphics.print("FPS"..tostring(love.timer.getFPS( )), 10, 10)


    UI:draw()

end

function GAMESTATE_MENU:keypressed(key, code)
    
    if key == 'p' then
        return Gamestate.push(GAMESTATE_GAME)
    end
    if UI.focus then
        local char = (code)
        UI:feedback(code)
        if key ~= "return" then
            if ( code >= 33 and code <= 122 ) then
                if ( love.keyboard.isDown( love.key_lshift ) or love.keyboard.isDown( love.key_rshift ) ) then
                    char = string.upper( key )
                end
            end
            UI:textinput(string.char(string.byte((char))))
        end
    end
    if key == 'return'then -- binding enter key to input focus
        input:focus()
        input:done()
    end
end

function GAMESTATE_MENU:update()

    input.keyrepeat = true -- this is the default anyway
	input.done = function(this) -- Gspot calls element:done() when you hit enter while element has focus. override this behaviour with element.done = false
        if(this.value ~= '') then
            UI:feedback(this.value)
            this.value = ''
            this.Gspot:unfocus()
        end
    end
	ChatSubmit.click = function(this)
		this.parent:done()
	end
end

function love.update(dt)
    UI:update(dt)
    Gamestate.update(dt) -- pass dt to currentState:update(dt)
end

function love.draw()

    Gamestate.draw() -- <callback> is `draw'
end

love.mousepressed = function(x, y, button)
	UI:mousepress(x, y, button) -- pretty sure you want to register mouse events
end
love.mousereleased = function(x, y, button)
	UI:mouserelease(x, y, button)
end
love.wheelmoved = function(x, y)
	UI:mousewheel(x, y)
end