require("things")

local function start()
	age.entity("game")
	age.entity("player")
	for j=1, game.h do
		for i=1, game.w do
			age.entity("piece", { i=i, j=j })
		end
	end

	return {
		pressed = function (b)
			age.send("player", "pressed", b)
		end,
		released = function (b)
			age.send("player", "released", b)
		end,
	}
end

return {
	start = start,
}
