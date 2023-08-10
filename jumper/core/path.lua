
if (...) then
	
  -- Dependencies
	local _PATH = (...):match('(.+)%.path$')
  local Heuristic = require (_PATH .. '.heuristics')
	
	 -- Local references
  local abs, max = math.abs, math.max
	local t_insert, t_remove = table.insert, table.remove
	
	
  local Path = {}
  Path.__index = Path

  
  function Path:new()
    return setmetatable({_nodes = {}}, Path)
  end

  
  function Path:iter()
    local i,pathLen = 1,#self._nodes
    return function()
      if self._nodes[i] then
        i = i+1
        return self._nodes[i-1],i-1
      end
    end
  end
  
  
	Path.nodes = Path.iter
	
  
  function Path:getLength()
    local len = 0
    for i = 2,#self._nodes do
      len = len + Heuristic.EUCLIDIAN(self._nodes[i], self._nodes[i-1])
    end
    return len
  end
	

	function Path:addNode(node, index)
		index = index or #self._nodes+1
		t_insert(self._nodes, index, node)
		return self
	end
	
	
  
  function Path:fill()
    local i = 2
    local xi,yi,dx,dy
    local N = #self._nodes
    local incrX, incrY
    while true do
      xi,yi = self._nodes[i]._x,self._nodes[i]._y
      dx,dy = xi-self._nodes[i-1]._x,yi-self._nodes[i-1]._y
      if (abs(dx) > 1 or abs(dy) > 1) then
        incrX = dx/max(abs(dx),1)
        incrY = dy/max(abs(dy),1)
        t_insert(self._nodes, i, self._grid:getNodeAt(self._nodes[i-1]._x + incrX, self._nodes[i-1]._y +incrY))
        N = N+1
      else i=i+1
      end
      if i>N then break end
    end
		return self
  end

  
  function Path:filter()
    local i = 2
    local xi,yi,dx,dy, olddx, olddy
    xi,yi = self._nodes[i]._x, self._nodes[i]._y
    dx, dy = xi - self._nodes[i-1]._x, yi-self._nodes[i-1]._y
    while true do
      olddx, olddy = dx, dy
      if self._nodes[i+1] then
        i = i+1
        xi, yi = self._nodes[i]._x, self._nodes[i]._y
        dx, dy = xi - self._nodes[i-1]._x, yi - self._nodes[i-1]._y
        if olddx == dx and olddy == dy then
          t_remove(self._nodes, i-1)
          i = i - 1
        end
      else break end
    end
		return self
  end
	
  
	function Path:clone()
		local p = Path:new()
		for node in self:nodes() do p:addNode(node) end
		return p
	end
	
  
	function Path:isEqualTo(p2)
		local p1 = self:clone():filter()
		local p2 = p2:clone():filter()
		for node, count in p1:nodes() do
			if not p2._nodes[count] then return false end
			local n = p2._nodes[count]
			if n._x~=node._x or n._y~=node._y then return false end
		end	
		return true
	end
	
  
	function Path:reverse()
		local _nodes = {}
		for i = #self._nodes,1,-1 do
			_nodes[#_nodes+1] = self._nodes[i]		
		end
		self._nodes = _nodes
		return self
	end	

  
	function Path:append(p)
		for node in p:nodes() do self:addNode(node)	end
		return self
	end
	
  return setmetatable(Path,
    {__call = function(self,...)
      return Path:new(...)
    end
  })
end