local tick = { _version = "0.1.1" }
tick.__index = tick


local iscallable = function(x)
  if type(x) == "function" then return true end
  local mt = getmetatable(x)
  return mt and mt.__call ~= nil
end

local noop = function()
end


local event = {}
event.__index = event

function event.new(parent, fn, delay, recur, err)
  err = err or 0
  return setmetatable({
    parent  = parent,
    delay   = delay,
    timer   = delay + err,
    fn      = fn,
    recur   = recur,
  }, event)
end


function event:after(fn, delay)

  if self.recur then
    error("cannot chain a recurring event")
  end
  
  local oldfn = self.fn
  local e = event.new(self.parent, fn, delay, false)
  self.fn = function()
    oldfn()
    e.timer = e.timer + self.parent.err
    self.parent:add(e)
  end
  return e
end


function event:stop()
  tick.remove(self.parent, self)
end



function tick.group()
  return setmetatable({ err = 0 }, tick)
end


function tick:add(e)
  self[e] = true
  table.insert(self, e)
  return e
end


function tick:remove(e)
  if type(e) == "number" then
  
    local idx = e
    e = self[idx]
    self[e] = nil
    self[idx] = self[#self]
    table.remove(self)
    return e
  end
  self[e] = false
  for i, v in ipairs(self) do
    if v == e then
      return self:remove(i)
    end
  end
end


function tick:update(dt)
  for i = #self, 1, -1 do
    local e = self[i]
    e.timer = e.timer - dt
    while e.timer <= 0 do
      if e.recur then
        e.timer = e.timer + e.delay
      else
        self:remove(i) 
      end
      self.err = e.timer
      e.fn()
      if not e.recur then
        break
      end
    end
  end
  self.err = 0
end


function tick:event(fn, delay, recur)
  delay = tonumber(delay)
 
  if not iscallable(fn) then
    error("expected `fn` to be callable")
  end
  if type(delay) ~= "number" then
    error("expected `delay` to be a number")
  end
  if delay < 0 then
    error("expected `delay` of zero or greater")
  end
 
  local d = delay + self.err
  if d < 0 then
    local err = self.err
    self.err = d
    fn()
    self.err = err
    return self:add(event.new(self, noop, delay, recur, self.err))
  end
 
  return self:add(event.new(self, fn, delay, recur, self.err))
end


function tick:delay(fn, delay)
  return self:event(fn, delay, false)
end


function tick:recur(fn, delay)
  return self:event(fn, delay, true)
end


local group = tick.group()

local bound = {
  update  = function(...) return tick.update(group, ...) end,
  delay   = function(...) return tick.delay (group, ...) end,
  recur   = function(...) return tick.recur (group, ...) end,
  remove  = function(...) return tick.remove(group, ...) end,
}
setmetatable(bound, tick)

return bound
