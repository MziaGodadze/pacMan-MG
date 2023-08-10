local _VERSION = ""
local _RELEASEDATE = ""

if (...) then

  -- Dependencies
  local _PATH = (...):gsub('%.pathfinder$','')
	local Utils     = require (_PATH .. '.core.utils')
	local Assert    = require (_PATH .. '.core.assert')
  local Heap      = require (_PATH .. '.core.bheap')
  local Heuristic = require (_PATH .. '.core.heuristics')
  local Grid      = require (_PATH .. '.grid')
  local Path      = require (_PATH .. '.core.path')

  -- Internalization
  local t_insert, t_remove = table.insert, table.remove
	local floor = math.floor
  local pairs = pairs
  local assert = assert
	local type = type
  local setmetatable, getmetatable = setmetatable, getmetatable

  local Finders = {
    ['ASTAR']     = require (_PATH .. '.search.astar'),
    ['DIJKSTRA']  = require (_PATH .. '.search.dijkstra'),
    ['THETASTAR'] = require (_PATH .. '.search.thetastar'),
    ['BFS']       = require (_PATH .. '.search.bfs'),
    ['DFS']       = require (_PATH .. '.search.dfs'),
    ['JPS']       = require (_PATH .. '.search.jps')
  }
  local toClear = {}

	
  local searchModes = {['DIAGONAL'] = true, ['ORTHOGONAL'] = true}

  local Pathfinder = {}
  Pathfinder.__index = Pathfinder

  
  function Pathfinder:new(grid, finderName, walkable)
    local newPathfinder = {}
    setmetatable(newPathfinder, Pathfinder)
	  newPathfinder:setGrid(grid)
    newPathfinder:setFinder(finderName)
    newPathfinder:setWalkable(walkable)
    newPathfinder:setMode('DIAGONAL')
    newPathfinder:setHeuristic('MANHATTAN')
    newPathfinder:setTunnelling(false)
    return newPathfinder
  end


	function Pathfinder:annotateGrid()
		assert(self._walkable, 'Finder must implement a walkable value')
		for x=self._grid._max_x,self._grid._min_x,-1 do
			for y=self._grid._max_y,self._grid._min_y,-1 do
				local node = self._grid:getNodeAt(x,y)
				if self._grid:isWalkableAt(x,y,self._walkable) then
					local nr = self._grid:getNodeAt(node._x+1, node._y)
					local nrd = self._grid:getNodeAt(node._x+1, node._y+1)
					local nd = self._grid:getNodeAt(node._x, node._y+1)
					if nr and nrd and nd then
						local m = nrd._clearance[self._walkable] or 0
						m = (nd._clearance[self._walkable] or 0)<m and (nd._clearance[self._walkable] or 0) or m
						m = (nr._clearance[self._walkable] or 0)<m and (nr._clearance[self._walkable] or 0) or m
						node._clearance[self._walkable] = m+1
					else
						node._clearance[self._walkable] = 1
					end
				else node._clearance[self._walkable] = 0
				end
			end
		end
		self._grid._isAnnotated[self._walkable] = true
		return self
	end

	
	function Pathfinder:clearAnnotations()
		assert(self._walkable, 'Finder must implement a walkable value')
		for node in self._grid:iter() do
			node:removeClearance(self._walkable)
		end
		self._grid._isAnnotated[self._walkable] = false
		return self
	end

  
  function Pathfinder:setGrid(grid)
    assert(Assert.inherits(grid, Grid), 'Wrong argument #1. Expected a \'grid\' object')
    self._grid = grid
    self._grid._eval = self._walkable and type(self._walkable) == 'function'
    return self
  end

  
  function Pathfinder:getGrid()
    return self._grid
  end

  
  function Pathfinder:setWalkable(walkable)
    assert(Assert.matchType(walkable,'stringintfunctionnil'),
      ('Wrong argument #1. Expected \'string\', \'number\' or \'function\', got %s.'):format(type(walkable)))
    self._walkable = walkable
    self._grid._eval = type(self._walkable) == 'function'
    return self
  end

  
  function Pathfinder:getWalkable()
    return self._walkable
  end

  
  function Pathfinder:setFinder(finderName)
		if not finderName then
			if not self._finder then
				finderName = 'ASTAR'
			else return
			end
		end
    assert(Finders[finderName],'Not a valid finder name!')
    self._finder = finderName
    return self
  end

  
  function Pathfinder:getFinder()
    return self._finder
  end


  function Pathfinder:getFinders()
    return Utils.getKeys(Finders)
  end

  
  function Pathfinder:setHeuristic(heuristic)
    assert(Heuristic[heuristic] or (type(heuristic) == 'function'),'Not a valid heuristic!')
    self._heuristic = Heuristic[heuristic] or heuristic
    return self
  end

  function Pathfinder:getHeuristic()
    return self._heuristic
  end

 
  function Pathfinder:getHeuristics()
    return Utils.getKeys(Heuristic)
  end


  function Pathfinder:setMode(mode)
    assert(searchModes[mode],'Invalid mode')
    self._allowDiagonal = (mode == 'DIAGONAL')
    return self
  end

 
  function Pathfinder:getMode()
    return (self._allowDiagonal and 'DIAGONAL' or 'ORTHOGONAL')
  end

  
  function Pathfinder:getModes()
    return Utils.getKeys(searchModes)
  end


  function Pathfinder:setTunnelling(bool)
    assert(Assert.isBool(bool), ('Wrong argument #1. Expected boolean, got %s'):format(type(bool)))
		self._tunnel = bool
		return self
  end

  
  function Pathfinder:getTunnelling()
		return self._tunnel
  end

  function Pathfinder:getPath(startX, startY, endX, endY, clearance)
		self:reset()
    local startNode = self._grid:getNodeAt(startX, startY)
    local endNode = self._grid:getNodeAt(endX, endY)
    assert(startNode, ('Invalid location [%d, %d]'):format(startX, startY))
    assert(endNode and self._grid:isWalkableAt(endX, endY),
      ('Invalid or unreachable location [%d, %d]'):format(endX, endY))
    local _endNode = Finders[self._finder](self, startNode, endNode, clearance, toClear)
    if _endNode then
			return Utils.traceBackPath(self, _endNode, startNode)
    end
    return nil
  end


	function Pathfinder:reset()
    for node in pairs(toClear) do node:reset() end
    toClear = {}
		return self
	end


  -- Returns Pathfinder class
	Pathfinder._VERSION = _VERSION
	Pathfinder._RELEASEDATE = _RELEASEDATE
  return setmetatable(Pathfinder,{
    __call = function(self,...)
      return self:new(...)
    end
  })

end
