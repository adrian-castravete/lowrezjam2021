require("things")

local function start()
	age.entity("hero")
	for j=1, 8 do
		for i=1, 8 do
			age.entity("piece", { i=i, j=j })
		end
	end

	return {
		pressed = function (b)
			age.send("hero", "pressed", b)
		end,
		released = function (b)
			age.send("hero", "released", b)
		end,
	}
end

return {
	start = start,
}
