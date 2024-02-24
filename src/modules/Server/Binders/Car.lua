local CollectionService = game:GetService("CollectionService")

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local CharacterUtils = require("CharacterUtils")

local Car = setmetatable({}, BaseObject)
Car.ClassName = "Car"
Car.__index = Car

function Car.new(obj, serviceBag)
	local self = setmetatable(BaseObject.new(obj), Car)
	self._serviceBag = assert(serviceBag, "No serviceBag")

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "Seat"
	proximityPrompt.AutoLocalize = false
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = self._obj.VehicleSeat
	proximityPrompt.ActionText = "Sit"

	self._maid:GiveTask(proximityPrompt.Triggered:Connect(function(player)
		proximityPrompt.Enabled = false
		self:_sit(CharacterUtils.getPlayerHumanoid(player))
		self._obj.VehicleSeat:SetNetworkOwner(player)
		self._driver = player
	end))

	self._maid:GiveTask(self._obj.VehicleSeat.Changed:Connect(function(property)
		if property == "Occupant" and self._obj.VehicleSeat.Occupant == nil then
			self:_unsited()
			self._obj.VehicleSeat:SetNetworkOwner(nil)
			proximityPrompt.Enabled = true
		end
	end))

	self._maid:GiveTask(function()
		CollectionService:RemoveTag(CharacterUtils.getPlayerHumanoid(self._driver), "Driver")
	end)

	return self
end

function Car:_sit(humanoid)
	self._obj.VehicleSeat:Sit(humanoid)
	CollectionService:AddTag(humanoid, "Driver")
end

function Car:_unsited()
	if self._driver then
		CollectionService:RemoveTag(CharacterUtils.getPlayerHumanoid(self._driver), "Driver")
		local root = CharacterUtils.getPlayerRootPart(self._driver)
		if root then
			root.Position = self._obj.Body.Position + Vector3.new(-10, 0, 0)
		end
	end
end

return Car
