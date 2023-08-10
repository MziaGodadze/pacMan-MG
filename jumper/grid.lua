if (...) then

	-- Dependencies
  local _PATH = (...):gsub('%.grid$','')

	-- Local references
  local Utils = require (_PATH .. '.core.utils')
  local Assert = require (_PATH .. '.core.assert')
  local Node = require (_PATH .. '.core.node')

	-- Local references
  local pairs = pairs
  local assert = assert
  local next = next
	local setmetatable = setmetatable
  local floor = math.floor
	local coroutine = coroutine

  -- Offsets for straights moves
  local straightOffsets = {
    {x = 1, y = 0} , {x = -1, y =  0}, 
    {x = 0, y = 1} , {x =  0, y = -1}, 
  }

  -- Offsets for diagonal moves
  local diagonalOffsets = {
    {x = -1, y = -1} , {x = 1, y = -1}, 
    {x = -1, y =  1} , {x = 1, y =  1}, 
  }


  local Grid = {}
  Grid.__index = Grid

  -- Specialized grids
  local PreProcessGrid = setmetatable({},Grid)
  local PostProcessGrid = setmetatable({},Grid)
  PreProcessGrid.__index = PreProcessGrid
  PostProcessGrid.__index = PostProcessGrid
  PreProcessGrid.__call = function (self,x,y)
    return self:getNodeAt(x,y)
  end
  PostProcessGrid.__call = function (self,x,y,create)
    if create then return self:getNodeAt(x,y) end
    return self._nodes[y] and self._nodes[y][x]
  end

  function Grid:new(map, cacheNodeAtRuntime)
		if type(map) == 'string' then
			assert(Assert.isStrMap(map), 'Wrong argument #1. Not a valid string map')
			map = Utils.strToMap(map)
		end
    assert(Assert.isMap(map),('Bad argument #1. Not a valid map'))
    assert(Assert.isBool(cacheNodeAtRuntime) or Assert.isNil(cacheNodeAtRuntime),
      ('Bad argument #2. Expected \'boolean\', got %s.'):format(type(cacheNodeAtRuntime)))
    if cacheNodeAtRuntime then
      return PostProcessGrid:new(map,walkable)
    end
    return PreProcessGrid:new(map,walkable)
  end


  function Grid:isWalkableAt(x, y, walkable, clearance)
    local nodeValue = self._map[y] and self._map[y][x]
    if nodeValue then
      if not walkable then return true end
    else
			return false
    end
		local hasEnoughClearance = not clearance and true or false
		if not hasEnoughClearance then
			if not self._isAnnotated[walkable] then return false end
			local node = self:getNodeAt(x,y)
			local nodeClearance = node:getClearance(walkable)
			hasEnoughClearance = (nodeClearance >= clearance)
		end
    if self._eval then
			return walkable(nodeValue) and hasEnoughClearance
		end
    return ((nodeValue == walkable) and hasEnoughClearance)
  end

  function Grid:getWidth()
    return self._width
  end

  function Grid:getHeight()
     return self._height
  end

  function Grid:getMap()
    return self._map
  end

  
  function Grid:getNodes()
    return self._nodes
  end

  
	function Grid:getBounds()
		return self._min_x, self._min_y,self._max_x, self._max_y
	end

  
  function Grid:getNeighbours(node, walkable, allowDiagonal, tunnel, clearance)
		local neighbours = {}
    for i = 1,#straightOffsets do
      local n = self:getNodeAt(
        node._x + straightOffsets[i].x,
        node._y + straightOffsets[i].y
      )
      if n and self:isWalkableAt(n._x, n._y, walkable, clearance) then
        neighbours[#neighbours+1] = n
      end
    end

    if not allowDiagonal then return neighbours end

		tunnel = not not tunnel
    for i = 1,#diagonalOffsets do
      local n = self:getNodeAt(
        node._x + diagonalOffsets[i].x,
        node._y + diagonalOffsets[i].y
      )
      if n and self:isWalkableAt(n._x, n._y, walkable, clearance) then
				if tunnel then
					neighbours[#neighbours+1] = n
				else
					local skipThisNode = false
					local n1 = self:getNodeAt(node._x+diagonalOffsets[i].x, node._y)
					local n2 = self:getNodeAt(node._x, node._y+diagonalOffsets[i].y)
					if ((n1 and n2) and not self:isWalkableAt(n1._x, n1._y, walkable, clearance) and not self:isWalkableAt(n2._x, n2._y, walkable, clearance)) then
						skipThisNode = true
					end
					if not skipThisNode then neighbours[#neighbours+1] = n end
				end
      end
    end

    return neighbours
  end

  
  function Grid:iter(lx,ly,ex,ey)
    local min_x = lx or self._min_x
    local min_y = ly or self._min_y
    local max_x = ex or self._max_x
    local max_y = ey or self._max_y

    local x, y
    y = min_y
    return function()
      x = not x and min_x or x+1
      if x > max_x then
        x = min_x
        y = y+1
      end
      if y > max_y then
        y = nil
      end
      return self._nodes[y] and self._nodes[y][x] or self:getNodeAt(x,y)
    end
  end

	
	function Grid:around(node, radius)
		local x, y = node._x, node._y
		radius = radius or 1
		local _around = Utils.around()
		local _nodes = {}
		repeat
			local state, x, y = coroutine.resume(_around,x,y,radius)
			local nodeAt = state and self:getNodeAt(x, y)
			if nodeAt then _nodes[#_nodes+1] = nodeAt end
		until (not state)
		local _i = 0
		return function()
			_i = _i+1
			return _nodes[_i]
		end
	end

  
  function Grid:each(f,...)
    for node in self:iter() do f(node,...) end
		return self
  end

  function Grid:eachRange(lx,ly,ex,ey,f,...)
    for node in self:iter(lx,ly,ex,ey) do f(node,...) end
		return self
  end

 
  function Grid:imap(f,...)
    for node in self:iter() do
      node = f(node,...)
    end
		return self
  end

  function Grid:imapRange(lx,ly,ex,ey,f,...)
    for node in self:iter(lx,ly,ex,ey) do
      node = f(node,...)
    end
		return self
  end

  function PreProcessGrid:new(map)
    local newGrid = {}
    newGrid._map = map
    newGrid._nodes, newGrid._min_x, newGrid._max_x, newGrid._min_y, newGrid._max_y = Utils.arrayToNodes(newGrid._map)
    newGrid._width = (newGrid._max_x-newGrid._min_x)+1
    newGrid._height = (newGrid._max_y-newGrid._min_y)+1
		newGrid._isAnnotated = {}
    return setmetatable(newGrid,PreProcessGrid)
  end

  -- Inits a postprocessed grid
  function PostProcessGrid:new(map)
    local newGrid = {}
    newGrid._map = map
    newGrid._nodes = {}
    newGrid._min_x, newGrid._max_x, newGrid._min_y, newGrid._max_y = Utils.getArrayBounds(newGrid._map)
    newGrid._width = (newGrid._max_x-newGrid._min_x)+1
    newGrid._height = (newGrid._max_y-newGrid._min_y)+1
		newGrid._isAnnotated = {}		
    return setmetatable(newGrid,PostProcessGrid)
  end


  function PreProcessGrid:getNodeAt(x,y)
    return self._nodes[y] and self._nodes[y][x] or nil
  end

  function PostProcessGrid:getNodeAt(x,y)
    if not x or not y then return end
    if Utils.outOfRange(x,self._min_x,self._max_x) then return end
    if Utils.outOfRange(y,self._min_y,self._max_y) then return end
    if not self._nodes[y] then self._nodes[y] = {} end
    if not self._nodes[y][x] then self._nodes[y][x] = Node:new(x,y) end
    return self._nodes[y][x]
  end

  return setmetatable(Grid,{
    __call = function(self,...)
      return self:new(...)
    end
  })

end
