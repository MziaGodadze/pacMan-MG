
local abs = math.abs
local sqrt = math.sqrt
local sqrt2 = sqrt(2)
local max, min = math.max, math.min

local Heuristics = {}
 
  function Heuristics.MANHATTAN(nodeA, nodeB) 
		local dx = abs(nodeA._x - nodeB._x)
		local dy = abs(nodeA._y - nodeB._y)
		return (dx + dy) 
	end

  function Heuristics.EUCLIDIAN(nodeA, nodeB)
		local dx = nodeA._x - nodeB._x
		local dy = nodeA._y - nodeB._y
		return sqrt(dx*dx+dy*dy) 
	end

  function Heuristics.DIAGONAL(nodeA, nodeB)
		local dx = abs(nodeA._x - nodeB._x)
		local dy = abs(nodeA._y - nodeB._y)	
		return max(dx,dy) 
	end

  function Heuristics.CARDINTCARD(nodeA, nodeB)
		local dx = abs(nodeA._x - nodeB._x)
		local dy = abs(nodeA._y - nodeB._y)	
    return min(dx,dy) * sqrt2 + max(dx,dy) - min(dx,dy)
  end

return Heuristics