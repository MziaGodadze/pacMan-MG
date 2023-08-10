
if (...) then

	local assert = assert
	

  local Node = {}
  Node.__index = Node

  function Node:new(x,y)
    return setmetatable({_x = x, _y = y, _clearance = {}}, Node)
  end

  function Node.__lt(A,B) return (A._f < B._f) end


	function Node:getX() return self._x end
	
	function Node:getY() return self._y end
	

	function Node:getPos() return self._x, self._y end
	
	function Node:getClearance(walkable)
		return self._clearance[walkable]
	end
	
  
	function Node:removeClearance(walkable)
		self._clearance[walkable] = nil
		return self
	end
	
	
	function Node:reset()
		self._g, self._h, self._f = nil, nil, nil
		self._opened, self._closed, self._parent = nil, nil, nil
		return self
	end
	
  return setmetatable(Node,
		{__call = function(self,...) 
			return Node:new(...) 
		end}
	)
end