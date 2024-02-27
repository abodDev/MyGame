local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local Spring = require("Spring")
local CharacterUtils = require("CharacterUtils")

local positionSpring = Spring.new(Vector3.new())

local Driver = setmetatable({}, BaseObject)
Driver.ClassName = "Car"
Driver.__index = Driver

function Driver.new(humanoid: Humanoid, serviceBag)
	if CharacterUtils.getPlayerFromCharacter(humanoid.Parent) ~= Players.LocalPlayer then
		return
	end

	local self = setmetatable(BaseObject.new(humanoid), Driver)
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._maid:GiveTask(RunService.Heartbeat:Connect(function()
		self:_updateCamera()
	end))

	self._maid:GiveTask(self._obj.SeatPart.Changed:Connect(function(property)
		if property == "SteerFloat" then
			self:_rotate()
		elseif property == "ThrottleFloat" then
			self:_drive()
		end
	end))

	self._maid:GiveTask(function()
		Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
	end)

	return self
end

function Driver:_drive()
	local SeatPart: VehicleSeat = self._obj.SeatPart
	local MaxAngularVelocity = SeatPart.MaxSpeed / (SeatPart.Parent.WheelBR.Size.Y / 2)

	local CylindricalConstraintBL: CylindricalConstraint = SeatPart.Parent.WheelBL.CylindricalConstraint
	local CylindricalConstraintBR: CylindricalConstraint = SeatPart.Parent.WheelBR.CylindricalConstraint

	local torque = math.abs(SeatPart.ThrottleFloat) * SeatPart.Torque
	CylindricalConstraintBL.MotorMaxTorque = torque
	CylindricalConstraintBR.MotorMaxTorque = torque

	local angularVelocity = math.sign(SeatPart.Throttle) * MaxAngularVelocity
	CylindricalConstraintBL.AngularVelocity = angularVelocity
	CylindricalConstraintBR.AngularVelocity = angularVelocity
end

function Driver:_rotate()
	local SeatPart: VehicleSeat = self._obj.SeatPart
	local AttachmentFL = SeatPart.Parent.Body.AttachmentFL
	local AttachmentFR = SeatPart.Parent.Body.AttachmentFR

	local orientation = Vector3.new(0, -SeatPart.SteerFloat * SeatPart.TurnSpeed, 90)
	local tweenInfo = TweenInfo.new(0.2)
	TweenService:Create(AttachmentFL, tweenInfo, { Orientation = orientation }):Play()
	TweenService:Create(AttachmentFR, tweenInfo, { Orientation = orientation }):Play()
end

function Driver:_updateCamera()
	positionSpring.s = 15
	positionSpring.d = 1

	local function getPositionFromCFrame(cf)
		return cf.Position
	end

	local cameraCFrameGoal = self._obj.SeatPart.CFrame * CFrame.new(0, 6, 16)

	local cameraPosGoal = getPositionFromCFrame(cameraCFrameGoal)

	positionSpring.t = cameraPosGoal

	local cameraPos = positionSpring.p

	Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	Workspace.CurrentCamera.CFrame = CFrame.new(cameraPos, self._obj.SeatPart.Position + Vector3.new(0, 6, 0))
end

return Driver
