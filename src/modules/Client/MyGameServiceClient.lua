--[=[
	@class MyGameServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local MyGameServiceClient = {}
MyGameServiceClient.ServiceName = "MyGameServiceClient"

function MyGameServiceClient:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrServiceClient"))

	-- Internal
	self._serviceBag:GetService(require("MyGameBindersClient"))
	self._serviceBag:GetService(require("MyGameTranslator"))
end

return MyGameServiceClient
