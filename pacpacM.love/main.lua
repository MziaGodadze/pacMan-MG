
function isEmpty(x, y)
    return tilemap[y][x] == 0
end
function love.load()
---   requires-----------------
    require("coins")
    tick=require("tick")
    Grid=require("jumper.grid")
    Pathfinder=require("jumper.pathfinder")
    Object=require("classic")
    require("player")
    require("animations")
    animator=require("animator")
    require("tilemap")
-------------------------------
    --Load the image
    im= love.graphics.newImage("tile.png")

     width = im:getWidth()
     height = im:getHeight()
    im_rotation=0
    tilemap=tilemaps.tilemap
    grid = Grid(tilemap) 
    myFinder = Pathfinder(grid, 'BFS', 0) 
     
    player = Player(
       love.graphics.newImage("player.png"),
       animationz.anim_right,
       2,
       2
)
    require("enemy")
    enemy=Enemy(18,10, tilemap.tilemap)
r=spawn_random_coins(tilemap,260)

-----------create a new player---------------------------
assert(player.animation~=nil, "no animation")
--------------------------------------------------------
len=#r
end
function love.draw()
    enemy:draw()
    for i,row in ipairs(tilemap) do
        for j,tile in ipairs(row) do
               if tile ~= 0 then
            
               
                   love.graphics.draw(im, j * width, i * height)
               end    
             for len=1,#r do  
                for l=1,len do
               if i==r[len][l] and j==r[len][l+1] then
                            love.graphics.rectangle('fill', j*width+10, i*height+10, 10,10)
                         end end end
           end
       end
        
        player:draw()
end
function love.update(dt)

   enemy:follow(player.tile_x, player.tile_y)
    
    player:update(dt)
    for i=1,len do
                if r[i]~=nil and player.tile_y==r[i][1] and player.tile_x==r[i][2] then 
                table.remove(r, i)
                i=1
                print("collision") 
               end  
        end
        enemy:update(dt)
 end
function love.keypressed(key)

    local x = player.tile_x
    local y = player.tile_y

    if key == "a" then
        x = x - 1
        player.animation=animationz.anim_left
    elseif key == "d" then
        x = x + 1
        player.animation=animationz.anim_right
    elseif key == "w" then
        y = y - 1
        player.animation=animationz.anim_above
    elseif key == "s" then
        y = y + 1
        player.animation=animationz.anim_bottom
    end

   if isEmpty(x, y) then
        player.tile_x = x
        player.tile_y = y
    end
if key == "space" then
        sfx:play()
    end
end