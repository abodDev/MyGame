--[[
	@class MyGameTranslator
]]

local require = require(script.Parent.loader).load(script)

return require("JSONTranslator").new("MyGameTranslator", "en", {
	gameName = "MyGame";
})