lg = love.graphics
lg.setDefaultFilter("nearest", "nearest")

age = require("age")
local vp = require("age.viewport")
vp.setup {
	width = 64,
	height = 64,
}

local input = require("age.input")
input.setup {
	keyboard = {
		hold = {"space"},
		left = {"left", "a"},
		up = {"up", "w"},
		right = {"right", "d"},
		down = {"down", "s"},
	},
	touch = {
		controls = {
			{
				kind = "dpad",
				anchor = "ld",
				size = 40,
				gap = 5,
				deadZone = 0.2,
			},
			{
				name = "hold",
				anchor = "rd",
				size = 30,
				gap = 10,
			},
		}
	},
}

math.randomseed(os.time())
math.random()
math.random()
math.random()

game = {
	w = 8,
	h = 8,
}

clearColor = {0.5, 0.5, 0.5}

function love.update(dt)
	lg.setCanvas(vp.canvas)
	lg.setColor(1, 1, 1)
	lg.clear(clearColor)

	age.update(dt)

	lg.setCanvas()
end

function love.resize(w, h)
	vp.resize(w, h)
	input.resize(w, h)
end

function love.draw()
	vp.draw()
	input.draw()
end

love.keypressed = input.keypressed
function love.keyreleased(key)
	if key == "f12" then
		love.event.quit()
		return
	end

	input.keyreleased(key)
end

love.touchpressed = input.touchpressed
love.touchreleased = input.touchreleased
love.touchmoved = input.touchmoved

--[[
local bs = {}
function love.mousepressed(x, y, b)
	bs[b] = true
	input.touchpressed(b, x, y)
end

function love.mousereleased(x, y, b)
	bs[b] = false
	input.touchreleased(b, x, y)
end

function love.mousemoved(x, y, dx, dy)
	for i=1, 3 do
		if bs[i] then
			input.touchmoved(i, x, y, dx, dy)
		end
	end
end
--]]

local worlds = require("worlds")
local world = worlds.start()

input.onButtonPressed(function(btn)
	world.pressed(btn)
end)

input.onButtonReleased(function(btn)
	world.released(btn)
end)
