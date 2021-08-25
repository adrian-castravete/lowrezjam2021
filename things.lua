local lg = love.graphics
local common = require("age.common")
local spritesheet = require("age.spritesheet")

local colors = {
	{1, 0, 0},
	{0, 0.5, 1},
	{0, 1, 0},
	{1, 1, 0},
	{0.5, 0, 1},
	{1, 0.5, 0},
	{0, 0, 0.5},
}
local oposites = {
	left = "right",
	up = "down",
	right = "left",
	down = "up",
}
local buttonDelay = 0.2
local buttonDelayFirst = 0.4
local animSpeed = 8

local matchScores = {}
local pattern = {}
local pState = "name"
local transforms = ""
local function createPat(w, h)
	local outPat = {}
	for j=1, h do
		outPat[j] = {}
		for i=1, w do
			outPat[j][i] = 0
		end
	end
	return outPat
end
local function copyPat(inPat)
	local outPat = {}
	for _, ln in ipairs(inPat) do
		local outLine = {}
		for _, c in ipairs(ln) do
			outLine[#outLine+1] = c
		end
		outPat[#outPat+1] = outLine
	end
	outPat.name = inPat.name
	outPat.score = inPat.score
	return outPat
end
local function transformPat(inPat, tr)
	local outPat = nil
	
	if tr == "r" then
		outPat = createPat(#inPat, #inPat[1])
		outPat.name = inPat.name
		outPat.score = inPat.score
	else
		outPat = copyPat(inPat)
	end
	
	for j, line in ipairs(inPat) do
		for i, c in ipairs(line) do
			if tr == "h" then
				outPat[j][#line + 1 - i] = c
			elseif tr == "v" then
				outPat[#inPat + 1 - j][i] = c
			elseif tr == "r" then
				outPat[i][#inPat + 1 - j] = c
			end
		end
	end
	
	return outPat
end
local function endPatternSet()
	matchScores[#matchScores + 1] = pattern
	for l=1, bit.lshift(1, #transforms) - 1 do
		local cp = copyPat(pattern)
		for i=1, #transforms do
			local tloc = bit.lshift(1, i-1)
			if bit.band(l, tloc) > 0 then
				cp = transformPat(cp, transforms:sub(i, i))
			end
		end
		matchScores[#matchScores + 1] = cp
	end
	
	pattern = {}
	pState = "name"
	transforms = ""
end
local mapPat = {
	["."] = 0,
	["+"] = 1,
	["="] = 2,
}
local function matchesLine(line)
	local sLine = line:gsub("^%s+|%s+$", "")
	 
	if pState == "name" and sLine ~= "" then
		pattern.name = sLine
		pState = "score"
	elseif pState == "score" then
		pattern.score = tonumber(sLine)
		pState = "transforms"
	elseif pState == "transforms" then
		transforms = sLine
		pState = "pattern"
	elseif pState == "pattern" then
		if sLine == "." then
			endPatternSet()
		else
			local pLine = {}
			for i=1, #sLine do
				pLine[#pLine+1] = mapPat[sLine:sub(i, i)]
			end
			pattern[#pattern+1] = pLine
		end
	end
end
for line in love.filesystem.lines("patterns.txt") do
	matchesLine(line)
end
--[[
local contents = ""
for i, p in ipairs(matchScores) do
	contents = contents .. string.format("%d. %s\n", i, p.name)
	for _, l in ipairs(p) do
		local lc = l[1]
		for ic=2, #l do
			lc = lc .. " " .. l[ic]
		end
		contents = contents .. lc .. "\n"
	end
	contents = contents .. "\n"
end
contents = contents .. transforms .. "\n"
love.filesystem.write("patterns.out", contents)
--]]

local function lerp(a, b, r)
	return a + (b - a) * r
end

local function updateLoc(e)
	e.x = (e.i - 0.5) * 8
	e.y = (e.j - 0.5) * 8
end

local function dirDelta(d)
	local x, y = 0, 0
	if d == "left" then x = -1 end
	if d == "up" then y = -1 end
	if d == "right" then x = 1 end
	if d == "down" then y = 1 end
	return x, y
end

local function moveTo(e, b)
	local dx, dy = dirDelta(b)
	e.i = e.i + dx
	e.j = e.j + dy
	updateLoc(e)
end

local function moveToAndAnimate(e, dir)
	if e.locked then return end
	local v = 8 / animSpeed
	local dx, dy = dirDelta(dir)
	local nx, ny = e.i + dx, e.j + dy
	if nx < 1 or ny < 1 or nx > game.w or ny > game.h then
		return
	end
	e.locked = true
	dx, dy = dx * v, dy * v
	age.tween(animSpeed, function (v)
		e.x = e.x + dx
		e.y = e.y + dy
	end, function ()
		moveTo(e, dir)
		e.locked = false
	end)
end

local function pieceAnimateMove(e, dir, cbFunc)
	if e.locked then return end
	e.locked = true
	local sx, sy = e.x, e.y
	local dx, dy = dirDelta(dir)
	local a = 0
	if dir == "left" then
		a = 0
	end
	if dir == "up" then
		a = math.pi / 2
	end
	if dir == "right" then
		a = math.pi
	end
	if dir == "down" then
		a = 3 * math.pi / 2
	end
	age.tween(animSpeed, function (v)
		local fa = a + v / animSpeed * math.pi
		e.x = sx + (dx + math.cos(fa)) * 4
		e.y = sy + (dy + math.sin(fa)) * 4
	end,
	function ()
		moveTo(e, dir)
		if cbFunc then
			cbFunc(e)
		end
		e.locked = false
	end)
end

local function otherPiece(x, y, dir)
	local dx, dy = dirDelta(dir)
	local ox, oy = x + dx, y + dy
	if ox < 1 or oy < 1 or ox > game.w or oy > game.h then
		return nil
	end
	return ox, oy, oposites[dir]
end

age.thing("player", {
	data = {
		i = math.floor(game.w / 2) + 1,
		j = math.floor(game.h / 2) + 1,
		x = 0,
		y = 0,
		w = 8,
		h = 8,
		color = {0, 0, 0},
		bs = {},
		locked = true,
	},
	parents = { "sprite" },
	init = function (e)
		updateLoc(e)
	end,
	system = function (e, dt)
		if not e.locked and not e.bs.hold then
			for k, _ in pairs(oposites) do
				local b = e.bs[k]
				if b then
					if b.dt < 0 then
						moveToAndAnimate(e, k)
						b.dt = buttonDelay
					end
					b.dt = b.dt - dt
				end
			end
		end
	end,
	messages = {
		pressed = function (e, b)
			if e.locked then return end

			e.bs[b] = {
				dt = buttonDelayFirst,
			}
			if e.bs.hold then
				age.message("game", "playerMovePiece", e.i, e.j, b)
			else
				moveToAndAnimate(e, b)
			end
		end,

		released = function (e, b)
			e.bs[b] = nil
		end,

		lock = function (e)
			e.locked = true
		end,

		unlock = function (e)
			e.locked = false
		end,
	},
})

age.thing("game", {
	data = {
		__checkMatchesIncorrect = function (e, x, y)
			local out, xm, ym, xM, yM = {}, x, y, x, y
			local m, i = e.map, 1
			local a, ai, c = {}, {}, m[y][x]
			if c == 0 then return a, ai end
			local function walk(x, y, dx, dy)
				if x < 1 or y < 1 or x > game.w or y > game.h then return end
				if m[y][x] ~= c then return end
				local k = x..","..y
				if not ai[k] then
					local ni = #a + 1
					a[ni] = {x, y}
					ai[k] = ni
				end
				walk(x+dx, y+dy, dx, dy)
			end
			walk(x, y, -1, 0)
			walk(x, y, 0, -1)
			walk(x, y, 1, 0)
			walk(x, y, 0, 1)
			a.x = x
			a.y = y
			a.indices = ai
			return a
		end,
		checkPattern = function(e, pattern, x, y)
			local target, pieces, ipieces = nil, {}, {}
			for j=1, #pattern do
				for i=1, #pattern[j] do
					local cx, cy = x+i-1, y+j-1
					if pattern[j][i] > 0 then
						local current = e.map[cy][cx]
						if current < 1 then
							return false
						end
						if not target then
							target = current
						elseif current ~= target then
							return false
						end
						pieces[#pieces+1] = {cx, cy}
						ipieces[cx..","..cy] = #pieces
					end
					if pattern[j][i] > 1 then
						pieces.x = cx
						pieces.y = cy
					end
				end
			end
			pieces.indices = ipieces
			return true, pieces
		end,
		checkAllMatches = function (e)
			age.message("player", "lock")
			local collected = true
			while collected do
				collected = false
				for k=#matchScores, 1, -1 do
					local pattern = matchScores[k]
					for j=1, game.h + 1 - #pattern do
						for i=1, game.w + 1 - #pattern[1] do
							local ok, pieces = e:checkPattern(matchScores[k], i, j)
							if ok then
								collected = true
								e:collect(pieces)
								break
							end
						end
					end
				end
			end
			age.message("player", "unlock")
		end,
		collect = function (e, pieces)
			for _, p in ipairs(pieces) do
				e.map[p[2]][p[1]] = -1
			end
			age.message("piece", "collect", pieces)
		end,
	},
	init = function (e)
		local m = {}
		for j=1, game.h do
			m[j] = {}
			for i=1, game.w do
				local c = math.random(1, #colors)
				m[j][i] = c
				age.entity("piece", {
					i = i, 
					j = j,
					c = c,
				})
			end
		end
		e.map = m
	end,
	system = function (e, dt)
		if not e.firstCheckDone then
			e.firstCheckDone = true
			e:checkAllMatches()
		end
		local m = e.map
		local n = {}
		for j, ln in ipairs(m) do
			n[j] = {}
			for i, c in ipairs(ln) do
				n[j][i] = c
				if c == 0 then
					if j == 1 then
						n[j][i] = -1
						age.entity("piece", {
							i = i, 
							j = j,
							c = math.random(1, #colors),
							idrop = true,
						})
					elseif m[j-1][i] > 0 then
						n[j][i] = -1
						n[j-1][i] = -1
						age.message("piece", "drop", i, j - 1)
					end
				end
			end
		end
		e.map = n
	end,
	messages = {
		checkMatches = function (e)
			e:checkAllMatches()
		end,
		
		playerMovePiece = function (e, x, y, dir)
			if x < 2 and dir == "left"
			or y < 2 and dir == "up"
			or x > game.w - 1 and dir == "right"
			or y > game.h - 1 and dir == "down" then
				age.message("piece", "bumpPiece", x, y, dir)
			else
				
			end
		end,
		
		pieceDestroyed = function (e, x, y)
			e.map[y][x] = 0
		end,
		
		pieceDropped = function (e, x, y, c)
			e.map[y][x] = c
			if y > 1 then
				e.map[y-1][x] = 0
			end
		end,
	},
})

age.thing("piece", {
	data = {
		i = 1,
		j = 1,
		w = 6,
		h = 6,
		idrop = false,
		color = nil,
	},
	parents = {"sprite"},
	init = function (e)
		e.x = (e.i - 1) * 8 + 4
		e.y = (e.j - 1) * 8 + 4
		if e.c then
			e.color = colors[e.c] 
		end
		if e.idrop then
			local sy = e.y - 8
			local oy = e.y
			local asp = animSpeed * 2
			age.tween(asp, function (v)
				local r = v / asp
				e.y = lerp(sy, oy, r)
			end, function ()
				e.y = oy
				age.message("game", "pieceDropped", e.i, e.j, e.c)
			end)
		end
	end,
	messages = {
		collect = function (e, pieces)
			local k = e.i .. "," .. e.j
			if pieces.indices[k] then
				local sx, sy = e.x, e.y
				local ox, oy = (pieces.x - 0.5) * 8, (pieces.y - 0.5) * 8
				local asp = animSpeed * 4
				local rs = math.random() - 0.5
				age.tween(asp, function (v)
					local r = v / asp
					e.x = lerp(sx, ox, r)
					e.y = lerp(sy, oy, r)
					e.s = 1 - r
					e.r = r * 12 * rs
				end, function ()
					age.message("game", "pieceDestroyed", e.i, e.j, e.c)
					e.destroy = true
				end)
			end
		end,
		drop = function (e, x, y)
			if e.i ~= x or e.j ~= y then return end
			local asp = animSpeed * 2
			local sy = e.y
			local oy = e.y + 8
			age.tween(asp, function (v)
				local r = v / asp
				e.y = lerp(sy, oy, r)
			end, function ()
				e.j = e.j + 1
				e.y = oy
				age.message("game", "pieceDropped", e.i, e.j, e.c)
			end)
		end,
	},
})