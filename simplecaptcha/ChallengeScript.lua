-- ChallengeScript.lua
-- Last Updated 24.05.2025 by @deltadeveloperr

local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local CaptchaEvent = ReplicatedStorage:WaitForChild("CaptchaCheck")

local BackgroundFrame = script.Parent:WaitForChild("BackgroundFrame")
local ChallengeFrame = BackgroundFrame:WaitForChild("ChallengeFrame")
local BoxGroup = ChallengeFrame:WaitForChild("BoxGroup")
local HintBox = ChallengeFrame:WaitForChild("HintBox")

local BoxButtons = {}
for _, object in ipairs(BoxGroup:GetChildren()) do
	if object:IsA("TextButton") then
		table.insert(BoxButtons, object)
	end
end

local coreGuiTypes = {
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.EmotesMenu,
	Enum.CoreGuiType.SelfView,
}
local savedCoreGuiStates = {}
local coreGuiIsManaged = false

local function saveAndDisableCoreGui()
	if coreGuiIsManaged then return end
	for _, cgType in ipairs(coreGuiTypes) do
		local isEnabled
		pcall(function()
			isEnabled = StarterGui:GetCoreGuiEnabled(cgType)
		end)
		savedCoreGuiStates[cgType] = isEnabled
		pcall(function()
			StarterGui:SetCoreGuiEnabled(cgType, false)
		end)
	end
	coreGuiIsManaged = true
end

local function restoreCoreGui()
	if not coreGuiIsManaged then return end
	for _, cgType in ipairs(coreGuiTypes) do
		local wasEnabled = savedCoreGuiStates[cgType]
		if wasEnabled ~= nil then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(cgType, wasEnabled)
			end)
		end
	end
	savedCoreGuiStates = {}
	coreGuiIsManaged = false
end

local function fadeOutAndDestroy(gui)
	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweens = {}

	table.insert(tweens, TweenService:Create(BackgroundFrame, tweenInfo, {BackgroundTransparency = 1}))
	for _, obj in ipairs(gui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(obj, tweenInfo, {TextTransparency = 1, BackgroundTransparency = 1}))
		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			table.insert(tweens, TweenService:Create(obj, tweenInfo, {ImageTransparency = 1, BackgroundTransparency = 1}))
		end
	end
	for _, tween in ipairs(tweens) do
		tween:Play()
	end
	task.wait(tweenInfo.Time)
	gui:Destroy()
end

CaptchaEvent.OnClientEvent:Connect(function(mode, arg1, arg2)
	if mode == "challenge" then
		saveAndDisableCoreGui()
		local correctNumber = arg1
		local boxTexts = arg2

		HintBox.Text = 'Please select the box that contains "' .. correctNumber .. '"'
		for i, button in ipairs(BoxButtons) do
			button.Text = boxTexts[i]
		end

	elseif mode == "success" then
		restoreCoreGui()
		fadeOutAndDestroy(script.Parent)
	end
end)

for _, button in ipairs(BoxButtons) do
	button.MouseButton1Click:Connect(function()
		CaptchaEvent:FireServer("answer", button.Text)
	end)
end
