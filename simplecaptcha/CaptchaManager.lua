-- CaptchaManager.lua
-- Last Updated 24.05.2025 by @deltadeveloperr

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptchaEvent = ReplicatedStorage:WaitForChild("CaptchaCheck")
local DataStoreService = game:GetService("DataStoreService")

-- Options
local OneTimeVerification = false -- Never shows captcha to player again if completed once
local IntelligentPrompt = true   -- Only show captcha if player matches certain rules

-- Settings for custom rules
local MIN_ACCOUNT_AGE = 7000
--

-- DataStoreService for OneTimeVerification (you can delete this line or just add "--" to disable)
local CaptchaStore = DataStoreService:GetDataStore("OneTimeCaptchaVerification")

math.randomseed(tick())

local attempts = {}

local function getRandomNumber()
	return tostring(math.random(1000, 9999))
end

local function sendChallenge(player)
	local correctNumber = getRandomNumber()
	local correctIndex = math.random(1, 3)

	local boxTexts = {}
	for i = 1, 3 do
		if i == correctIndex then
			boxTexts[i] = correctNumber
		else
			local randomNum
			repeat
				randomNum = getRandomNumber()
			until randomNum ~= correctNumber
			boxTexts[i] = randomNum
		end
	end

	if not attempts[player.UserId] then
		attempts[player.UserId] = { correct = correctNumber, tries = 0 }
	else
		attempts[player.UserId].correct = correctNumber
	end

	CaptchaEvent:FireClient(player, "challenge", correctNumber, boxTexts)
end

-- IntelligentPrompt
local function shouldPromptCaptcha(player)
	if not IntelligentPrompt then
		return true
	end

	if player.AccountAge < MIN_ACCOUNT_AGE then
		return true
	end
	
	-- Add more rules as needed, like ping etc...
	return false
end

-- Main
game.Players.PlayerAdded:Connect(function(player)
	if OneTimeVerification then
		local success, verified = pcall(function()
			return CaptchaStore:GetAsync(tostring(player.UserId))
		end)
		if success and verified then
			return
		end
	end

	player.CharacterAdded:Connect(function()
		if shouldPromptCaptcha(player) then
			sendChallenge(player)
			player.PlayerGui:WaitForChild("ChallengeGui").Enabled = true
		else
			player.PlayerGui:WaitForChild("ChallengeGui"):Destroy()
		end
	end)
end)

CaptchaEvent.OnServerEvent:Connect(function(player, action, selectedNumber)
	local data = attempts[player.UserId]
	if not data then return end

	if action == "answer" then
		if selectedNumber == data.correct then
			CaptchaEvent:FireClient(player, "success")
			if OneTimeVerification then
				pcall(function()
					CaptchaStore:SetAsync(tostring(player.UserId), true)
				end)
			end
		else
			data.tries += 1
			if data.tries >= 3 then
				player:Kick("You failed the Captcha 3 times.")
			else
				sendChallenge(player)
			end
		end
	end
end)
