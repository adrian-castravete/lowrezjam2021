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
local ANIM_SPEED = 8

local function lerp(a, b, r)
	return a + (b - a) * r
end

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

local function moveToAndAnimate(e, b)
	if e.locked then return end
	e.locked = true
	local v = 8 / ANIM_SPEED
	local dx, dy = 0, 0
	if b == "left" and e.i > 1 then
		dx = -v
	end
	if b == "up" and e.j > 1 then
		dy = -v
	end
	if b == "right" and e.i < game.w then
		dx = v
	end
	if b == "down" and e.j < game.h then
		dy = v
	end
	age.tween(ANIM_SPEED, function (v)
		e.x = e.x + dx
		e.y = e.y + dy
	end, function ()
		moveTo(e, b)
		e.locked = false
	end)
end

function switchAndAnimate(e, b)
	age.send("piece", "player-move-piece", e.i, e.j, b)
end

function pieceAnimateMove(e, dir, cbFunc)
	if e.locked then return end
	e.locked = true
	local sx, sy = e.x, e.y
	age.tween(ANIM_SPEED, function (v)
		local ox, oy, a = 0, 0, 0
		if dir == "left" then
			ox = -4
			a = 0
		end
		if dir == "up" then
			oy = -4
			a = math.pi / 2
		end
		if dir == "right" then
			ox = 4
			a = math.pi
		end
		if dir == "down" then
			oy = 4
			a = 3 * math.pi / 2
		end
		local fa = a + v / ANIM_SPEED * math.pi
		e.x = sx + ox + math.cos(fa) * 4
		e.y = sy + oy + math.sin(fa) * 4
	end,
	function ()
		moveTo(e, dir)
		e.locked = false
		age.send("game", "check-matches", e.i, e.j, dir)
	end)
end

function checkMatches(x, y, sx, sy)
	-- WIP
end



age.component("player", {
	parents = { "sprite" },
	i = math.floor(game.w / 2) + 1,
	j = math.floor(game.h / 2) + 1,
	x = 0,
	y = 0,
	w = 8,
	h = 8,
	color = {0, 0, 0},
	bs = {},
	init = function (e)
		updateLoc(e)
	end,
})

age.system("player", function (e, dt)
	if not e.locked and not e.bs.hold then
		for _, k in ipairs(WAYS) do
			local b = e.bs[k]
			if b then
				if b.dt < 0 then
					moveToAndAnimate(e, k)
					b.dt = BUTTON_DELAY
				end
				b.dt = b.dt - dt
			end
		end
	end
end)

age.receive("player", "pressed", function (e, b)
	if e.locked then return end

	e.bs[b] = {
		dt = BUTTON_DELAY_FIRST,
	}
	if e.bs.hold then
		switchAndAnimate(e, b)
	else
		moveToAndAnimate(e, b)
	end
end)

age.receive("player", "released", function (e, b)
	e.bs[b] = nil
end)

age.receive("player", "lock", function (e)
	e.locked = true
end)

age.receive("player", "unlock", function (e)
	e.locked = false
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

age.receive("piece", "player-move-piece", function (e, x, y, dir)
	if e.i ~= x or e.j ~= y or e.locked then
		return
	end
	if dir == "left" and x > 1 then
		age.send("piece", "player-move-piece-unlocked", x - 1, y, "right")
	end
	if dir == "up" and y > 1 then
		age.send("piece", "player-move-piece-unlocked", x, y - 1, "down")
	end
	if dir == "right" and x < game.w then
		age.send("piece", "player-move-piece-unlocked", x + 1, y, "left")
	end
	if dir == "down" and y < game.h then
		age.send("piece", "player-move-piece-unlocked", x, y + 1, "up")
	end
end)

age.receive("piece", "player-move-piece-unlocked", function (e, x, y, dir)
	if e.i ~= x or e.j ~= y or e.locked then
		return
	end
	pieceAnimateMove(e, dir)
	if dir == "left" then
		age.send("piece", "player-move-piece-acknowledged", x - 1, y, "right")
	end
	if dir == "up" then
		age.send("piece", "player-move-piece-acknowledged", x, y - 1, "down")
	end
	if dir == "right" then
		age.send("piece", "player-move-piece-acknowledged", x + 1, y, "left")
	end
	if dir == "down" then
		age.send("piece", "player-move-piece-acknowledged", x, y + 1, "up")
	end
end)

age.receive("piece", "player-move-piece-acknowledged", function (e, x, y, dir)
	if e.i ~= x or e.j ~= y or e.locked then
		return
	end
	pieceAnimateMove(e, dir, function ()
		age.send("game", "check-matches", x, y, dir)
	end)
end)

age.component("game", {})

--age.system("game", function (e, dt)
--end)

age.receive("game", "check-matches", function (e, x, y, dir)
	age.send("player", "lock")
	local dx, dy = 0, 0
	if dir == "left" then dx = -1 end
	if dir == "up" then dy = -1 end
	if dir == "right" then dx = 1 end
	if dir == "down" then dy = 1 end

	checkMatches(x, y, x + dx, y + dy)
end)
