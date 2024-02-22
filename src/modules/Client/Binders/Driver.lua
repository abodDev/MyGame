local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local dampingValue = Instance.new("IntValue")
dampingValue.Name = "dampingValue"
dampingValue.Parent = Workspace
dampingValue.Value = 1

local speedValue = Instance.new("IntValue")
speedValue.Name = "speedValue"
speedValue.Parent = Workspace
speedValue.Value = 20


local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local Spring = require("Spring")

local positionSpring = Spring.new(Vector3.new())
local anglesSpring = Spring.new(Vector3.new())

local Car = setmetatable({}, BaseObject)
Car.ClassName = "Car"
Car.__index = Car

function Car.new(humanoid: Humanoid, serviceBag)
    local self = setmetatable(BaseObject.new(humanoid), Car)
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

function Car:_drive()
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

function Car:_rotate()
    local SeatPart: VehicleSeat = self._obj.SeatPart
    local AttachmentFL = SeatPart.Parent.Body.AttachmentFL
    local AttachmentFR = SeatPart.Parent.Body.AttachmentFR

    local orientation = Vector3.new(0, -SeatPart.SteerFloat * SeatPart.TurnSpeed, 90)
    local tweenInfo = TweenInfo.new(0.2)
    TweenService:Create(AttachmentFL, tweenInfo, {Orientation = orientation}):Play()
    TweenService:Create(AttachmentFR, tweenInfo, {Orientation = orientation}):Play()
end

function Car:_cameraFollowCar()
    local function CFrameToPosOri(cf)
        local pos = cf.Position
        local rx, ry, rz = cf:ToOrientation()
        local ori = Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
        return pos , ori
    end

    local function PosOriToCFrame(pos, ori)
        local cf = CFrame.fromEulerAnglesXYZ(math.rad(ori.X), math.rad(ori.Y), math.rad(ori.Z))
        cf = cf + pos
        return cf
    end

    anglesSpring.s = speedValue.Value
    positionSpring.s = speedValue.Value

    anglesSpring.d = dampingValue.Value
    positionSpring.d = dampingValue.Value

    local cameraCFrameGoal = self._obj.SeatPart.CFrame *  CFrame.new(0, 6, 20)

    local cameraPosGoal, cameraOriGoal = CFrameToPosOri(cameraCFrameGoal) 

    anglesSpring.t = cameraOriGoal
    positionSpring.t = cameraPosGoal

    local cameraOri = anglesSpring.p
    local cameraPos = positionSpring.p

    local finalCameraCFrame = PosOriToCFrame(cameraPos, cameraOri)

    Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    Workspace.CurrentCamera.CFrame = finalCameraCFrame
end

return Car