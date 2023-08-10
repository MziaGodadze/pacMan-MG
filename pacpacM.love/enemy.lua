Enemy = Object:extend()

function Enemy:new(tile_x, tile_y, tilemap)
    self.tile_x = tile_x
    self.tile_y = tile_y
    self.radius = 16
    self.xcoords = self.tile_x * (self.radius * 2) + 16
    self.ycoords = self.tile_y * (self.radius * 2) + 16
    self.tilemap = tilemap

    -- Load and preprocess the image
    self.originalImage = love.graphics.newImage("gost.png")
    local newWidth = 32
    local newHeight = 32
    self.image = love.graphics.newCanvas(newWidth, newHeight)
    love.graphics.setCanvas(self.image)
    love.graphics.draw(self.originalImage, 0, 0, 0, newWidth / self.originalImage:getWidth(), newHeight / self.originalImage:getHeight())
    love.graphics.setCanvas()

    self.moveCounter = 0
    self.moveInterval = 60  -- Adjust this value for slower movement
end

function Enemy:draw()
    love.graphics.draw(self.image, self.xcoords, self.ycoords, 0, 1, 1, self.radius, self.radius)
end

function Enemy:follow(player_x, player_y)
    self.moveCounter = self.moveCounter + 1
    if self.moveCounter >= self.moveInterval then
        self.moveCounter = 0

        local directions = {
            {x = -1, y = 0}, -- left
            {x = 1, y = 0},  -- right
            {x = 0, y = -1}, -- up
            {x = 0, y = 1}   -- down
        }
        local randomDirection = directions[love.math.random(1, 4)]

        local new_x = self.tile_x + randomDirection.x
        local new_y = self.tile_y + randomDirection.y

        if isEmpty(self.tilemap, new_x, new_y) then
            self.tile_x = new_x
            self.tile_y = new_y
            self.xcoords = self.tile_x * (self.radius * 2) + 16
            self.ycoords = self.tile_y * (self.radius * 2) + 16
        end
    end
end

function Enemy:update(dt)
    self:follow()
end