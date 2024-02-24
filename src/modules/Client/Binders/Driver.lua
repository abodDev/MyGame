local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local Spring = require("Spring")
local CharacterUtils = require("CharacterUtils")

local positionSpring = Spring.new(Vector3.new())
local anglesSpring = Spring.new(Vector3.new())

local dampingValue = Instance.new("NumberValue")
dampingValue.Name = "dampingValue"
dampingValue.Parent = Workspace
dampingValue.Value = 1

local speedValue = Instance.new("NumberValue")
speedValue.Name = "speedValue"
speedValue.Parent = Workspace
speedValue.Value = 20

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
		self:_cameraFollowCar()
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

function Driver:_cameraFollowCar()
	anglesSpring.s = speedValue.Value
	positionSpring.s = speedValue.Value

	anglesSpring.d = dampingValue.Value
	positionSpring.d = dampingValue.Value

	local function getPositionAndAnglesFromCFrame(cf)
		return cf.Position, Vector3.new(cf:ToEulerAnglesXYZ())
	end

	local function getCFrameFromPositionAndAngles(pos, ang)
		return CFrame.new(pos) * CFrame.Angles(ang.X, ang.Y, ang.Z)
	end

	local function _getClosestAngle(new: number, old: number)
		while math.abs(new - old) > math.pi do
			if new > old then
				new -= math.pi * 2
			else
				new += math.pi * 2
			end
		end

		return new
	end

	local function getClosestAngles(new: Vector3, old: Vector3)
		return Vector3.new(
			_getClosestAngle(new.X, old.X),
			_getClosestAngle(new.Y, old.Y),
			_getClosestAngle(new.Z, old.Z)
		)
	end

	local cameraCFrameGoal = self._obj.SeatPart.CFrame * CFrame.new(0, 6, 20)

	local cameraPosGoal, rawcameraOriGoal = getPositionAndAnglesFromCFrame(cameraCFrameGoal)

	local perviousCameraOriGoal = anglesSpring.t
	local cameraOriGoal = getClosestAngles(rawcameraOriGoal, perviousCameraOriGoal)

	anglesSpring.t = cameraOriGoal
	positionSpring.t = cameraPosGoal

	local cameraOri = anglesSpring.p
	local cameraPos = positionSpring.p

	local finalCameraCFrame = getCFrameFromPositionAndAngles(cameraPos, cameraOri)

	Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	Workspace.CurrentCamera.CFrame = finalCameraCFrame
end

return Driver
