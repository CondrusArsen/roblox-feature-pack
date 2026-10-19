--[[
ТЗ
1)[невозможно] заставить mover двигаться между пос1 и пос2
2)[абсолютно невозможно] заставить бобра spiner крутиться вокруг своей вертикальной оси
]]--


local mover = script.Parent.mover
local pos1 = mover:WaitForChild("pos1")
local pos2 = mover:WaitForChild("pos2")

local spiner = script.Parent.spiner

local TweenService = game:GetService("TweenService")

local moverMove = coroutine.wrap(function()
	while true do
	local tween1 = TweenService:Create(
		mover,
		TweenInfo.new(2, Enum.EasingStyle.Linear),
		{Position = pos1.Position}
	)
	tween1:Play()
	tween1.Completed:Wait()

	local tween2 = TweenService:Create(
		mover,
		TweenInfo.new(2, Enum.EasingStyle.Linear),
		{Position = pos2.Position}
	)
	tween2:Play()
	tween2.Completed:Wait()
end
end)

local spinerSpin = coroutine.wrap(function()
	while true do
		spiner:PivotTo(spiner:GetPivot()*CFrame.fromEulerAnglesXYZ(0,0,-0.02))
		wait()
	end
end)

moverMove()
spinerSpin()

