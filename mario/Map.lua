--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]] require 'Util'

Map = Class {}

TILE_BRICK = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- constructor for our map object
function Map:init()

    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.sprites = generateQuads(self.spritesheet, 16, 16)
    self.music = love.audio.newSource('sounds/music.wav', 'static')

    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 70
    self.mapHeight = 28
    self.tiles = {}
    self.pole = {x = self.mapWidth - 1, y = 2, height = self.mapHeight / 2 - 3}

    self.flagAnimation = Animation({
        texture = 'not necessary wtf',
        frames = {13, 14, 15},
        interval = 0.15
    })

    -- applies positive Y influence on anything affected
    self:appliesPositiveYInfluenceOnAnythingAffected()
    -- associate player with map
    self:associatePlayerWithMap()

    -- camera offsets
    self:cameraOffsets()

    -- cache width and height of map in pixels
    self:cacheWidthAndHeightOfMapInPixels()

    self:fillMapWithEmptyTiles()

    -- begin generating the terrain using vertical scan lines
    -- self:beginGeneratingTheTerrainUsingVerticalScanLines()

    self:genaratingPyramidScene()

    -- start the background music
    self.music:setLooping(true)
    self.music:setVolume(0.03)
    self.music:play()
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidabprint(tile.id)
    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT, MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    local poleTiles = {12, 8, 16}

    for key, value in ipairs(poleTiles) do

        if tile.id == value then
            self:fillMapWithEmptyTiles()
            self:beginGeneratingTheTerrainUsingVerticalScanLines()
            self.pole.showFlag = false
            self.player = Player(self)
        end

    end

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do if tile.id == v then return true end end

    return false
end

-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)
    self.flagAnimation:update(dt)
    self:setTileFlag()
    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
                                     math.min(
                                         self.mapWidthPixels - VIRTUAL_WIDTH,
                                         self.player.x)))
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1,
                          math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y) return self.tiles[(y - 1) * self.mapWidth + x] end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id) self.tiles[(y - 1) * self.mapWidth + x] = id end

-- renders our map to the screen, to be called by main's render
function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                                   (x - 1) * self.tileWidth,
                                   (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()
end

function Map:appliesPositiveYInfluenceOnAnythingAffected() self.gravity = 15 end

function Map:associatePlayerWithMap()

    print(self.pole.x ,self.pole.x -5)

    self.player = Player(self)
    self.player.x =  self.tileWidth * (self.pole.x- 20)

end

function Map:cameraOffsets()
    self.camX = 0
    self.camY = -3
end

function Map:cacheWidthAndHeightOfMapInPixels()
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight
end

function Map:fillMapWithEmptyTiles()
    -- first, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do

            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end
end

function Map:genaratingPyramidScene()

  

    for x = 1, self.mapWidth do
        self:createPyramidOfTiles(x)

        self:createsColumnOfTilesGoingToBottomOfMap(x)
    end

    self:setTileFlag()
    self:createPole()

end

function Map:setTileFlag()
    self:setTile(self.pole.x + 1, self.pole.y,
                 self.flagAnimation:getCurrentFrame())
end

function Map:createPyramidOfTiles(x)

    local distanceBetweenFlagAndPyramid = self.pole.x -6
    local translation = distanceBetweenFlagAndPyramid +2
    for y = 4, self.mapWidth do
        if y >= translation +2  -x and x < distanceBetweenFlagAndPyramid then
            self:setTile(x, y, TILE_BRICK)
        end

    end

end

function Map:createPole()

    self:createBasePole()
    self:createStemPole()
    self:createTopPole()

end

function Map:createBasePole()
    local basePoleTile = 16
    self:setTile(self.pole.x, self.pole.height + self.pole.y, TILE_BRICK)
    self:setTile(self.pole.x, self.pole.height + self.pole.y - 1, basePoleTile)

end

function Map:createStemPole()
    local stemPoleTile = 12
    for y = self.pole.y + 1, self.pole.height + self.pole.y - 2 do
        self:setTile(self.pole.x, y, stemPoleTile)
    end
end

function Map:createTopPole()
    local topPoleTile = 8
    self:setTile(self.pole.x, self.pole.y, topPoleTile)
end

function Map:createBaseLevel(x, level)

    if x < level.x then
        print(x, level.y)
        self:setTile(x, level.y, TILE_BRICK)
    end

end

function Map:beginGeneratingTheTerrainUsingVerticalScanLines()

    for x = 1, self.mapWidth do

        -- 2% chance to generate a cloud
        -- 
        self:twoPorcentChanceToGenerateAcloud(x)

        -- 5% chance to generate a mushroom
        if self:fivePorcentChanceToGenerateAMushroom(x) then

            -- next vertical scan line

            -- 10% chance to generate bush, being sure to generate away from edge
        elseif self:teenPorcentChanceToGenerateBush(x) then

            -- 10% chance to not generate anything, creating a gap

        elseif self:teenPorcentChanceToCreatingAGap(x) then

        else
            -- creates column of tiles going to bottom of map
            self:createsColumnOfTilesGoingToBottomOfMap(x)

            -- chance to create a block for Mario to hit
            self:chanceToCreateABlockForMarioToHit(x)
            -- next vertical scan line
        end
        self:createPyramidOfTiles(x)

    end

    self:createPole()
    self:setTileFlag()
end

function Map:twoPorcentChanceToGenerateAcloud(x)
    if x < self.mapWidth - 2 then
        if math.random(5) == 1 then

            -- choose a random vertical spot above where blocks/pipes generate
            local cloudStart = self:chooseARandomVerticalSpot()

            self:setTile(x, cloudStart, CLOUD_LEFT)
            self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
        end
    end
end

function Map:chooseARandomVerticalSpot()
    return math.random(self.mapHeight / 2 - 6)
end

function Map:fivePorcentChanceToGenerateAMushroom(x)
    if math.random(20) == 1 then
        -- left side of pipe
        self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
        self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)

        -- creates column of tiles going to bottom of map
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_BRICK)
        end
        return true
    end

    return false
end

function Map:teenPorcentChanceToGenerateBush(x)
    -- being sure to generate away from edge
    if math.random(10) == 1 and self:beingSureToGenerateAwayFromEdge(x) then
        local bushLevel = self.mapHeight / 2 - 1

        -- place bush component and then column of bricks
        self:setTile(x, bushLevel, BUSH_LEFT)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_BRICK)
        end
        x = x + 1

        self:setTile(x, bushLevel, BUSH_RIGHT)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_BRICK)
        end

        return true

    end

    return false
end

function Map:beingSureToGenerateAwayFromEdge(x)
    return x < self.mapWidth - 3 and true or false
end

function Map:teenPorcentChanceToCreatingAGap(x)

    if math.random(10) == 1 then

        -- increment X so we skip two scanlines, creating a 2-tile gap
        x = x + 1

        return true
    end

    return false

end

function Map:createsColumnOfTilesGoingToBottomOfMap(x)

    for y = self.mapHeight / 2, self.mapHeight do
        self:setTile(x, y, TILE_BRICK)
    end
end

function Map:chanceToCreateABlockForMarioToHit(x)
    if math.random(15) == 1 then
        self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
    end
end
