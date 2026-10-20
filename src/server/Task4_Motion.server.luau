--!strict
-- Task 4: tweening and rotation.
--   1. `mover` travels between `pos1` and `pos2` (one reversing, endlessly repeating tween).
--   2. `spiner` rotates around the vertical axis through its pivot, driven by Heartbeat delta
--      time so the speed does not depend on frame rate.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local settings = Config.Task4
local folder = workspace:WaitForChild(settings.Folder)

local mover = folder:WaitForChild(settings.Mover) :: BasePart
local pos1 = mover:WaitForChild("pos1") :: BasePart
local pos2 = mover:WaitForChild("pos2") :: BasePart

mover.CFrame = pos1.CFrame
local moveTween = TweenService:Create(
	mover,
	TweenInfo.new(settings.MoveSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
	{ CFrame = pos2.CFrame }
)
moveTween:Play()

local spinner = folder:WaitForChild(settings.Spinner) :: Model
local startPivot = spinner:GetPivot()
local axisOrigin = CFrame.new(startPivot.Position)
local pivotOffset = axisOrigin:Inverse() * startPivot
local angularSpeed = math.rad(settings.SpinDegreesPerSecond)
local angle = 0

RunService.Heartbeat:Connect(function(deltaTime: number)
	angle = (angle + angularSpeed * deltaTime) % (2 * math.pi)
	spinner:PivotTo(axisOrigin * CFrame.Angles(0, angle, 0) * pivotOffset)
end)
