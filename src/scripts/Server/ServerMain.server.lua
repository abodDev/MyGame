--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.MyGame:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.MyGame)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("MyGameService"))
serviceBag:Init()
serviceBag:Start()