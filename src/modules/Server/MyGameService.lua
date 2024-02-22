--[=[
	@class MyGameService
]=]

local require = require(script.Parent.loader).load(script)

local MyGameService = {}
MyGameService.ServiceName = "MyGameService"

function MyGameService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))
	
	-- Internal
	self._serviceBag:GetService(require("MyGameBinders"))
	self._serviceBag:GetService(require("MyGameTranslator"))
end

return MyGameService