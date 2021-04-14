lg = love.graphics
fkge = require'fkge'

fkge.game {
	width = 256,
	height = 192,
}

fkge.c('2d', {
	x = 0,
	y = 0,
	w = 8,
	h = 8,
})

fkge.c('color', {
	color = {4/7, 4/7, 2/3},
})

fkge.c('draw', "2d, color")

fkge.c('ship', "draw, input, collision", {
	w = 16,
	h = 16,
	pressedLeft = false,
	pressedRight = false,
	pressedFire = false,
	joy = 'center',
	fireDelta = 0,
	onHit = function (e, o)
		print("hit ship")
		e.color = {1, 0, 0}
	end
})

fkge.s('ship', function (e, _, dt)
	if e.pressedLeft or e.joy == 'left' then
		e.x = e.x - 2
	end
	if e.pressedRight or e.joy == 'right' then
		e.x = e.x + 2
	end
	if e.x > 240 then
		e.x = 240
	end
	if e.x < 16 then
		e.x = 16
	end
	if e.pressedFire and e.fireDelta <= 0 and fkge.count('bullet') < 2 then
		fkge.e('bullet').attr {x = e.x, y = e.y}
		e.fireDelta = 0.4
	end
	if e.fireDelta > 0 then
		e.fireDelta = e.fireDelta - dt
	else
		e.fireDelta = 0
	end
end)

fkge.c('collision', "2d", {
	lastTick = 0,
})

fkge.c('alien', "draw, collision", {
	movePixels = 4,
	onCollision = function (e, o)
		if o.name == "bullet" then
			e.destroy = true
		end
	end
})

fkge.s('alien', function (e)
	if e.x > 240 then
		fkge.message('alien-walker', 'turn_left')
	end
	if e.x < 16 then
		fkge.message('alien-walker', 'turn_right')
	end
end)

fkge.c('alien-bullet', 'draw, collision', {
	w = 1,
	h = 6,
	color = {0, 1, 0},
	onCollision = function (e, o)
		if o.name == "bullet" then
			e.destroy = true
			o.destroy = true
		elseif o.name == "ship" then
			e.destroy = true
			o.onHit(o, e)
		elseif o.name == 'barricade' then
			e.destroy = true
		end
	end,
})

fkge.s('alien-bullet', function (e)
	e.y = e.y + 2
	if e.y > 192 then
		e.destroy = true
	end
end)

local function newAlien(name, w, h, c)
	fkge.c(name, "alien", {
		w = w,
		h = h,
		color = c,
	})
	fkge.s(name, function (e, evt)
		local delay = nil
		if evt.move_right then
			delay = evt.move_right[1]
			fkge.anim(e, 'x', e.x + e.movePixels, delay[1] / 5)
		elseif evt.move_left then
			delay = evt.move_left[1]
			fkge.anim(e, 'x', e.x - e.movePixels, delay[1] / 5)
		elseif evt.go_down then
			delay = evt.go_down[1]
			fkge.anim(e, 'y', e.y + e.movePixels, delay[1] / 5)
		end
		if delay and math.random() < math.min(15, delay[2]) / 20 then
			fkge.e('alien-bullet').attr{
				x = e.x,
				y = e.y,
			}
		end
	end)
end

newAlien('alien1', 12, 12, {1, 0, 0})
newAlien('alien2', 14, 14, {1, 5/7, 0})
newAlien('alien3', 14, 14, {2/7, 5/7, 0})
newAlien('alien4', 16, 15, {0, 5/7, 1})
newAlien('alien5', 16, 16, {5/7, 0, 1})

fkge.s('draw', function (e)
	lg.push()
	lg.setColor(e.color)
	lg.rectangle('fill', e.x - e.w/2, e.y - e.h/2, e.w, e.h)
	lg.pop()
end)

fkge.c('alien-walker', {
	walkRow = 5,
	state = "right",
	delay = 1,
	level = 1,
	tick = 0,
})

local function gameReset()
	fkge.each('barricade', function (e)
		e.destroy = true
	end)
	fkge.each('alien', function (e)
		e.destroy = true
	end)
	for i=1, 4 do
		fkge.e('barricade').attr {
			x = 51 * i,
			y = 152,
		}
	end
	for j=1, 5 do
		for i=1, 8 do
			fkge.e('alien'..j).attr {
				x = 24 + i*24,
				y = 16 + j*16,
			}
		end
	end
	fkge.each('ship', function (e)
		e.attr {
			x = 128,
			y = 176,
		}
	end)
	fkge.message('alien-walker', 'turn_right')
end

fkge.s('alien-walker', function (e, evt, dt)
	if evt.turn_right and e.state == "left" then
		e.nextState = "right"
	elseif evt.turn_left and e.state == "right" then
		e.nextState = "left"
	end

	if e.tick > 0 then
		e.tick = e.tick - dt
		return
	end

	local count = fkge.count("alien")
	if count == 0 then
		gameReset()
		e.delay = e.delay / 2
		e.level = e.level + 1
		return
	end
	local countDelay = e.delay * count / 40
	if e.state == "right" then
		fkge.message('alien'..e.walkRow, 'move_right', {countDelay, e.level})
	elseif e.state == "left" then
		fkge.message('alien'..e.walkRow, 'move_left', {countDelay, e.level})
	elseif e.state == "down" then
		fkge.message('alien'..e.walkRow, 'go_down', {countDelay, e.level})
	end
	e.walkRow = e.walkRow - 1
	while fkge.count('alien'..e.walkRow) == 0 and e.walkRow > 0 do
		e.walkRow = e.walkRow - 1
	end
	if e.walkRow < 1 then
		e.walkRow = 5
		e.tick = countDelay
		if e.state == "down" then
			e.state = e.nextState
			e.nextState = nil
		elseif e.nextState then
			e.state = "down"
		end
	else
		e.tick = e.delay / 5
	end
end)

fkge.s('input', function (e, evt)
	for _, k in ipairs(evt.keypressed or {}) do
		if k == 'left' then
			e.pressedLeft = true
		elseif k == 'right' then
			e.pressedRight = true
		elseif k == 'space' then
			e.pressedFire = true
		end
	end
	for _, k in ipairs(evt.keyreleased or {}) do
		if k == 'escape' then
			fkge.stop()
		elseif k == 'left' then
			e.pressedLeft = false
		elseif k == 'right' then
			e.pressedRight = false
		elseif k == 'space' then
			e.pressedFire = false
		--elseif k == 'r' then
		--	gameReset()
		end
	end
	for _, j in ipairs(evt.joystickaxis or {}) do
		if j[2] == 1 then
			if j[3] < -0.5 then
				e.joy = 'left'
			elseif j[3] > 0.5 then
				e.joy = 'right'
			else
				e.joy = 'center'
			end
		end
	end
	for _, j in ipairs(evt.joystickpressed or {}) do
		if j[2] >= 1 and j[2] <= 4 then
			e.pressedFire = true
		end
	end
	for _, j in ipairs(evt.joystickreleased or {}) do
		if j[2] >= 1 and j[2] <= 4 then
			e.pressedFire = false
		end
	end
end)

fkge.c('barricade', "draw, collision", {
	w = 24,
	h = 24,
	color = {5/7, 1, 2/3},
	onCollision = function (e, o)
		if o.names.alien then
			e.destroy = true
		end
	end
})

fkge.s('barricade', function (e, evt)
end)

fkge.c('bullet', "draw, collision", {
	w = 2,
	h = 6,
	color = {1, 1, 1},
	onCollision = function (e, o)
		if o.name ~= 'ship' then
			e.destroy = true
		end
	end,
})

fkge.s('bullet', function (e, evt)
	e.y = e.y - 2
	if e.y < 0 then
		e.destroy = true
	end
end)

fkge.s('collision', function (e, evt, tick)
	e.lastTick = tick
	fkge.each('collision', function (o)
		if e.id ~= o.id and o.lastTick ~= tick then
			local dx, dy = math.abs(e.x - o.x), math.abs(e.y - o.y)
			local dw, dh = (e.w + o.w) / 2, (e.h + o.h) / 2
			if dx <= dw and dy <= dh then
				if e.onCollision and type(e.onCollision) == 'function' then
					e.onCollision(e, o)
				end
				if o.onCollision and type(o.onCollision) == 'function' then
					o.onCollision(o, e)
				end
			end
		end
	end)
end)

fkge.scene('game', function ()
	fkge.wipe()
	fkge.e('ship')
	fkge.e('alien-walker')
	gameReset()
end)

fkge.scene('load', function ()
	fkge.scene'game'
end)

fkge.scene'load'
