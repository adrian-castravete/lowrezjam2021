local lg = love.graphics
local common = require("age.common")
local spritesheet = require("age.spritesheet")

local COLORS = {
	{1, 0, 0},
	{0, 0.5, 1},
	{0, 1, 0},
	{1, 1, 0},
	{0.5, 0, 1},
	{1, 0.5, 0},
	{0, 0, 0.5},
}
local WAYS = {"left", "up", "right", "down"}
local BUTTON_DELAY = 0.2
local BUTTON_DELAY_FIRST = 0.4

age.component("player", {
	parents = { "sprite" },
	i = 1,
	j = 1,
	x = 4,
	y = 4,
	w = 8,
	h = 8,
	color = {0, 0, 0},
	bs = {},
})

local function updateLoc(e)
	e.x = (e.i - 0.5) * 8
	e.y = (e.j - 0.5) * 8
end

local function moveTo(e, b)
	if b == "left" and e.i > 1 then
		e.i = e.i - 1
	end
	if b == "up" and e.j > 1 then
		e.j = e.j - 1
	end
	if b == "right" and e.i < game.w then
		e.i = e.i + 1
	end
	if b == "down" and e.j < game.h then
		e.j = e.j + 1
	end
	updateLoc(e)
end

age.system("player", function (e, dt)
	for _, k in ipairs(WAYS) do
		local b = e.bs[k]
		if b then
			if b.dt < 0 then
				moveTo(e, k)
				b.dt = BUTTON_DELAY
			end
			b.dt = b.dt - dt
		end
	end
end)

age.receive("player", "pressed", function (e, b)
	e.bs[b] = {
		dt = BUTTON_DELAY_FIRST,
	}
	moveTo(e, b)
end)

age.receive("player", "released", function (e, b)
	e.bs[b] = nil
end)

age.component("piece", {
	parents = {"sprite"},
	i = 1,
	j = 1,
	w = 6,
	h = 6,
	init = function (e)
		updateLoc(e)
		if not e.c then
			e.c = math.floor(math.random() * 7 + 1)
		end
		e.color = COLORS[e.c]
	end
})

age.receive("piece", "player-move-piece", function (e)

end)
