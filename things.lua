local lg = love.graphics
local common = require("age.common")
local spritesheet = require("age.spritesheet")

age.component("hero", {})

age.component("piece", {
	parents = {"sprite"},
	i=1,
	j=1,
})
