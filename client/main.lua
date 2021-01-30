package.path = package.path .. ";../../?.lua"
sock = require "sock"
bitser = require "lib.bitser"
Gamestate = require "lib.gamestate"

--Globals
local ticksPerSec = 120


--GameStates
local GAMESTATE_PREROLL = {}
local GAMESTATE_MENU = {}
local GAMESTATE_GAME = {}
local GAMESTATE_SETTINGS = {}
local GAMESTATE_LOBBY = {}


local ghosty = love.graphics.newImage("img/ghosty.png")

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(GAMESTATE_GAME)
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

    love.graphics.print(client:getState(), 5, 5)
    if PlayerNumber then
        love.graphics.print("Player " .. PlayerNumber, 5, 25)
    else
        love.graphics.print("No player number assigned", 5, 25)
    end
    local score = ("%d - %d"):format(scores[1], scores[2])
    love.graphics.print(score, 5, 45)
end
