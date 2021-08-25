game = {
	w = 8,
	h = 8,
}

require("things")

local function start()
	age.entity("game")
	age.entity("player")

	return {
		pressed = function (b)
			age.message("player", "pressed", b)
		end,
		released = function (b)
			age.message("player", "released", b)
		end,
	}
end

return {
	start = start,
}