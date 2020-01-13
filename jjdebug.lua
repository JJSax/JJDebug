-- version 0.5.0

jjdebug = {
	__gc = function(self)
		print("destroying self: " .. self.name)
	end
}
jjdebug.__index = jjdebug
jjdebug.defaultFont = love.graphics.newFont(14)

local function totalInTable(tab)
	local tot = 0
	for k, v in pairs(tab) do
		tot = tot + 1
	end
	return tot
end

local function checkTable(tab, var)
	for k,v in pairs(tab) do
		if var == v then return true end
	end
	return false
end

function jjdebug:newDebug(x, y, width, height)
	return setmetatable(
	{
		x = x, 
		y = y, 
		width = width or nil,
		height = height or nil,
		contents = {},
		bottomBuffer = 5,
		topBuffer = 5,
		leftBuffer = 5,
		rightBuffer = 5,
		visible = true,
		bgColor = {0,0,0,0.8},
		textColor = {1,1,1,1},
		font = jjdebug.defaultFont,
		horizontalAlignment = nil,
		verticalAlignment = nil,
		scissorResults = true
	}, jjdebug)
end

function jjdebug:setVisible(bool)
	if bool == "not" then
		self.visible = not self.visible
		return
	end
	self.visible = bool
end

function jjdebug:setTextColor(r, g, b, a)
	if type(r) == "table" then
		assert(#r >= 3 and #r <= 4, "Passed color array incorrect.  expected format {r,g,b[, a]}")
		local r,g,b,a = unpack(r)
	end
	self.textColor = {r,g,b,a}
end

function jjdebug:setBackgroundColor(r, g, b, a)
	if type(r) == "table" then
		assert(#r >= 3 and #r <= 4, "Passed color array incorrect.  expected format {r,g,b[, a]}")
		local r,g,b,a = unpack(r)
	end
	self.bgColor = {r,g,b,a}
end

function jjdebug:setPosition(x, y)
	self.x, self.y = x, y
end

function jjdebug:setDimensions(width, height)
	self.width, self.height = width, height
end

function jjdebug:setAlignment(horizontal, vertical)
	-- horizontal options "left" "right"
	-- vertical options "top" "bottom"
	local vh = {"left", "right", nil, false}
	local vv = {"top", "bottom", nil, false}
	assert(checkTable(vh, horizontal), "Invalid argument passed for paremeter 1.")
	assert(checkTable(vv, vertical) , "Invalid argument passed for paremeter 2.")
	if horizontal == nil then horizontal = false end
	if vertical == nil then vertical = false end
	self.horizontalAlignment, self.verticalAlignment = horizontal, vertical
end

function jjdebug:addTracker(varname, value)
	self.contents[varname] = {
		timerreset = 4,
		displayTimer = 4,
		fadeTimer = 1,
		value = value,
		displayVarname = true,
		ticker = true
	}
end

function jjdebug:setTrackerTimer(varname, value)
	self:addTracker(varname, nil)
	self.contents[varname].displayTimer = value
end

function jjdebug:setTicker(varname, bool)
	self:addTracker(varname, nil)
	self.contents[varname].ticker = bool
end

function jjdebug:setTrackerFadeTimer(varname, value)
	self:addTracker(varname, nil)
	self.contents[varname].fadeTimer = value
end

function jjdebug:displayVarName(varname, bool)
	self:addTracker(varname, nil)
	self.contents[varname].displayVarname = bool
end

function jjdebug:setValue(varname, value, suppress)
	self:addTracker(varname, nil)
	-- suppress prevents timer from resetting, default false
	self.contents[varname].value = value
	if not suppress then
		self.contents[varname].displayTimer = self.contents[varname].timerreset
	end
end

function jjdebug:setResetTimer(varname, time)
	self:addTracker(varname, nil)
	self.contents[varname].timerreset = time
end

function jjdebug:removeTracker(varname)
	self:addTracker(varname, nil)
	self.contents[varname] = nil
end

-------------------------
-- get variable functions
-------------------------

function jjdebug:getVisible()
	return self.visible
end

function jjdebug:getTextColor()
	return self.textColor
end

function jjdebug:getBackgroundColor()
	return self.bgColor
end

function jjdebug:getPosition()
	return self.x, self.y
end

function jjdebug:getDimensions()
	return self.width, self.height
end

function jjdebug:getValue(varname)
	return self.contents[varname].value
end

function jjdebug:trackerExists(tracker)
	return self.contents[tracker] and true or false
end

--------------------------
-- update / draw function 
--------------------------

function jjdebug:update(dt)
	for k,v in pairs(self.contents) do
		if v.ticker then
			v.displayTimer = v.displayTimer - dt
			if v.displayTimer < 0 then
				self:removeTracker(k)
			end
		end
	end
end

function jjdebug:draw()
	if not self.visible then return false end -- don't draw if not supposed to

	local lw, lh = 0, 0
	for k, v in pairs(self.contents) do
		local w = self.font:getWidth(tostring(v.value)) + self.leftBuffer + self.rightBuffer
		if v.displayVarname then
			w = w + self.font:getWidth(": "..tostring(k))
		end
		if w > lw then lw = w end
	end
	lh = totalInTable(self.contents) * self.font:getHeight(" ") + self.topBuffer + self.bottomBuffer

	love.graphics.setColor(self.bgColor)
	-- set x, y position
	local x,y
	if self.horizontalAlignment == "right" then
		x = love.graphics.getWidth() - (self.width and self.width or lw)
	elseif self.horizontalAlignment == "left" then
		x = 0
	else x = self.x
	end
	-- local x = (self.horizontalAlignment == "right" and self.width) and love.graphics.getWidth() - self.width or self.x
	if self.verticalAlignment == "top" then
		y = 0
	elseif self.verticalAlignment == "bottom" then
		y = love.graphics.getHeight() - (self.height and self.height or lh)
	else
		y = self.y
	end


	love.graphics.rectangle("fill", x, y, self.width or lw, self.height or lh)
	local lfont = love.graphics.getFont()
	love.graphics.setFont(self.font)
	local r,g,b,a = unpack(self.textColor)
	local i = 0
	for k,v in pairs(self.contents) do
		love.graphics.setColor(r,g,b,a * ( v.displayTimer > v.fadeTimer and 1 or v.displayTimer / v.fadeTimer ))
		if v.displayVarname then
			love.graphics.print(k..": "..tostring(v.value), x + self.leftBuffer, y + i * self.font:getHeight(" ") + self.topBuffer)
		else
			love.graphics.print(v.value, x + self.leftBuffer, y + i * self.font:getHeight(" ") + self.topBuffer)
		end
		i = i + 1
	end


	love.graphics.setFont(lfont)
end

-- function jjdebug:destroy()
-- 	self.__gc()
-- end

return jjdebug
