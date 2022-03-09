-- PromoCodeService
-- MrAsync
-- 01/13/2022

--[=[
	@class PromoCodeService
	@server
	
	Server component of the PromoCodes Package.
]=]


local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService('HttpService')

local PlayerDataService = SuperStack:GetModule("PlayerDataService")
local SchedulerService = SuperStack:GetModule("SchedulerService")
local SettingsService = SuperStack:GetModule("SettingsService")
local NetworkService = SuperStack:GetModule("NetworkService")
local SlackReporter = SuperStack:GetModule("SlackReporter")
local TypeValidator = SuperStack:GetModule("TypeValidator")
local Promise = SuperStack:GetModule("Promise")
local Logger = SuperStack:GetModule("Logger")

local PromoCodeService = {}
PromoCodeService.__index = PromoCodeService

function PromoCodeService.new()
	local self = setmetatable({}, PromoCodeService)

	self._ProcessRedemptionCallback = function(_, player, promoCodeData, promoCode)
		warn("Process redemption callback is not set!")

		return false
	end
	
	self._CodeDatabase = DataStoreService:GetDataStore("PromoCodes")

	self._PrimaryStore = {}
	self._PrimaryShards = {}
	self._NextUpdate = os.time() + (5 * 60)

	self._ReportsInLastMinute = 0
	self._ReportsReset = os.time() + 60
	self._SlackReporter = SlackReporter.new({
		URL = "https://hooks.slack.com/services/..."
	})

	return self
end

--[=[
	Preprocessor for the internal _RedeemCode method.  This method respects debounces and 
	checks if the user previously redeemed the code.  This method will interally call the
	_RedeemCode method.

	@param player: Player
	@param promoCode: string
	@return Promise -> any
]=]
function PromoCodeService:RedeemCode(player: Player, promoCode: string)
	if (not TypeValidator:Validate(player, "Instance") or
		not TypeValidator:Validate(promoCode, "string")) then
			
		return Promise.reject(Logger:errorCode("InvalidArgument"))
	end

	return Promise.new(function(resolve, reject)
		-- Fetch playerRedemptionList
		local playerProfile = PlayerDataService:GetPlayerProfile(player)
		local playerRedemptions = playerProfile:GetData("PromoCodeRedemptions")

		-- Check if user has already redeemed promoCode
		if (table.find(playerRedemptions, promoCode) and (not SettingsService:Get("DevEnv"))) then
			return reject(Logger:errorCode("CodeRedeemed"))
		end

		-- Handle debounce
		if (PlayerDataService:GetCacheValue(player, "RedeemingPromoCode", false)) then
			return reject(Logger:errorCode("GeneralError"))
		end

		-- Set debounce
		PlayerDataService:SetCacheValue(player, "RedeemingPromoCode", true)

		-- Prevent player from quickly trying to redeem the code again
		playerProfile:UpdateData("PromoCodeRedemptions", function(redemptions)
			table.insert(redemptions, promoCode)
	
			return redemptions
		end)

		-- Redeem the code, handle success and error cases, then reset debounce
		self:_RedeemCode(player, promoCode):andThen(function(response)
			return resolve(response)
		end):catch(function(err)

			-- Remove code from redemption list
			playerProfile:UpdateData("PromoCodeRedemptions", function(redemptions)
				table.remove(redemptions, table.find(redemptions, promoCode))

				return redemptions
			end)

			return reject(err)
		end):finally(function()
			
			PlayerDataService:SetCacheValue(player, "RedeemingPromoCode", false)

		end)
	end)
end


--[=[
	Attempts to redeem a code for a player.  Method yields as there are a few
	DataStore requests that may need to be made.

	@param player Player
	@param promoCode string
	@return errorCode {[string]: any} | promoCodeRewardData {[string]: any}
]=]
function PromoCodeService:_RedeemCode(player: Player, promoCode: string)
	promoCode = string.upper(promoCode)

	return Promise.new(function(resolve, reject)
		local _redemptionStartTime = os.time()
	
		-- Check the validity of the code
		if (not self:_IsPromoCodeValid(promoCode)) then
			return reject(Logger:errorCode("InvalidCode"))
		end

		-- Fetch playerRedemptionList
		local playerProfile = PlayerDataService:GetPlayerProfile(player)
	
		-- Fetch PromoCodeData
		local promoCodeData = self:_FetchPromoCodeData(promoCode)
		local promoCodeShard = self:_FetchPromoCodeShard(promoCodeData)
	
		if (not promoCodeData or not promoCodeShard) then
			return reject(Logger:errorCode("InvalidCode"))
		end
	
		-- Check if code is active
		if (not self:_IsPromoCodeActive(promoCodeData)) then
			return reject(Logger:errorCode("CodeExpired"))
		end
	
		if (not self:_PlayerIsAllowedToRedeemCode(player, promoCodeShard)) then
			return reject(Logger:errorCode("CodeDenied"))
		end
	
		-- Handle limited redemptions if applicable
		if (promoCodeShard.HasLimitedRedemptions) then
			if (promoCodeData.RedemptionsRemaining == 0) then
				return reject(Logger:errorCode("CodeMaxxed"))
			elseif (promoCodeData.RedemptionsRemaining > 0) then
				local canContinue = self:_AttemptLimitedPromoCodeRedemption(promoCode)
		
				if (not canContinue) then
					return reject(Logger:errorCode("CodeMaxxed"))
				end
			end
		end
	
		-- Alert game team to reward player
		local rewardData = HttpService:JSONDecode(
			if (promoCodeShard.Reward == "") then "{}" else promoCodeShard.Reward
		)
		
		local success, response = self:_ProcessRedemption(player, promoCode, rewardData)
	
		-- If game team could not reward the player, allow player to redeem again
		if (not success or (response == false)) then
			self:_ReportToSlack(string.format(
				"Unable to execute ProcessRedemption callback!\n%s",
				tostring(response)
			))
	
			return reject(Logger:errorCode("CodeProcessError"))
		end
	
		local _redemptionEndTime = os.time()
		local _redemptionTime = _redemptionEndTime - _redemptionStartTime
	
		if (_redemptionTime > 3) then
			self:_ReportToSlack(string.format(
				"Code redemption pipeline is unhealthy!\nTook %.2f seconds to redeem a code!",
				_redemptionTime
			))
		end
	
		return resolve(rewardData)
	end)
end

--[=[
	Listens to PlayerAdded and PlayerRemoving to fetch and cleanup PlayerRedemptionLists.
	Also creates PromoCodeGateway remote function.

	:::caution
	This method is called automatically and shouldn't be called elsewhere
	:::
]=]
function PromoCodeService:Initialize()
	-- Register PromoCodeGateway and handle execution
	NetworkService:RegisterFunction("PromoCodeGateway", function(player: Player, promoCode: string)
		local success, response = self:RedeemCode(player, promoCode):await()

		if (not success) then
			return {
				Error = response
			}
		else
			return response
		end
	end)

	-- Initially update master shard list
	self:_UpdatePrimaryStore()
end

--[=[
	Begins a loop that dynamically updates the MasterShardList.

	:::caution
	This method is called automatically and shouldn't be called elsewhere
	:::
]=]
function PromoCodeService:Start()

	-- Update code store every 4 minutes
	SchedulerService:AddTask("PromoCodeRefresh", 4 * 60, function()
		self:_UpdatePrimaryStore()
	end)

	-- Subscribe to force update pipeline
	MessagingService:SubscribeAsync("SS_PromoCodeService_UpdatePrimaryStore", function()
		-- Push next update back
		self._NextUpdate += (5 * 60)

		return self:_UpdatePrimaryStore()
	end)

	PlayerDataService.PlayerProfileAdded:Connect(function(playerProfile)
		local player = playerProfile.Player

		-- Set referral data flag to 0
		PlayerDataService:SetCacheValue(player, "RedeemingPromoCode", false)
	end)

end

--[=[
	Clears a users past code redemptions

	@param player Player
	@return nil
]=]
function PromoCodeService:ClearPlayerRedemptions(player: Player): nil
	local playerProfile = PlayerDataService:GetPlayerProfile(player)
	if (not playerProfile) then return end

	playerProfile:UpdateData("PromoCodeRedemptions", function()
		return {}
	end)
end

--[=[
	@private

	Returns true if the user is allowed to redeem the code based on the Allowlist and Denylist

	@param player Player
	@param promoCodeShard {[string]: any}
	@return boolean
]=]
function PromoCodeService:_PlayerIsAllowedToRedeemCode(player: Player, promoCodeShard: {[string]: any}): boolean
	local userId = player.UserId
	local allowed = true

	local filter = HttpService:JSONDecode(if promoCodeShard.Filter == "" then "[]" else promoCodeShard.Filter)

	if (promoCodeShard.FilterType == "Allowlist") then
		allowed = (allowed and (table.find(filter, userId) ~= nil))
	elseif (promoCodeShard.FilterType == "Denylist") then
		allowed = (allowed and (table.find(filter, userId) == nil))
	end

	return allowed
end

--[=[
	@private

	Returns true if a limited redemption code can be redeemed.

	@param promoCode string
	@return boolean
]=]
function PromoCodeService:_AttemptLimitedPromoCodeRedemption(promoCode: string): boolean
	local success, canRedeem = pcall(function()
		local canRedeemPromoCode = true

		self._CodeDatabase:UpdateAsync("PrimaryStore", function(primaryStore)
			local promoCodeData = primaryStore[promoCode]
			local redemptionsRemaining = promoCodeData.RedemptionsRemaining

			-- If redemptions remaining is zero, we can't redeem
			canRedeemPromoCode = (redemptionsRemaining ~= 0)

			-- Will remove one if needed, clamps to zero
			promoCodeData.RedemptionsRemaining = math.clamp(
				redemptionsRemaining - 1,
				0,
				math.huge
			)

			-- Update internal data
			self._PrimaryStore = primaryStore

			return primaryStore
		end)

		return canRedeemPromoCode
	end)

	if (success) then
		return canRedeem
	else

		self:_ReportToSlack(string.format(
			"Possible LimitedPromoCode contention! Could not Update a PromoCodes' RedemptionsRemaining!\n%s",
			tostring(canRedeem)
		))

		return false
	end
end

--[=[
	@private

	Processes a code redemption in a pcall to handle any errors

	@param arguments any
	@return boolean
]=]
function PromoCodeService:_ProcessRedemption(...): boolean
	local arguments = {...}
	
	return pcall(function()
		return self._ProcessRedemptionCallback(table.unpack(arguments))
	end)
end

--[=[
	@private

	Sets the ProcessRedemptionCallback

	@param callback (any) -> Enum.ProductPurchaseDecision
	@return nil
]=]
function PromoCodeService:SetProcessRedemptionCallback(callback: (any) -> Enum.ProductPurchaseDecision): nil
	if (not callback) then return end

	self._ProcessRedemptionCallback = callback
end

--[=[
	@private

	Returns true if the current date is within the bounds of the active timeframe
	of the code.  False otherwise

	@param promoCodeData {[string]: any}
	@return boolean
]=]
function PromoCodeService:_IsPromoCodeActive(promoCodeData: {[string]: any}): boolean
	local now = DateTime.now().UnixTimestamp

	local afterStart = (now >= promoCodeData.ValidAfter)
	local beforeEnd = if (promoCodeData.Expires) then (now < promoCodeData.ExpirationDate) else true
	
	return (afterStart and beforeEnd)
end

--[=[
	@private

	Returns true if PromoCode is valid, false otherwise.

	@param promoCode string
	@return boolean
]=]
function PromoCodeService:_IsPromoCodeValid(promoCode: string): boolean
	return self._PrimaryStore[promoCode] ~= nil
end

--[=[
	@private

	Fetches the promoCodeShard for a specific code.

	@param promoCodeData {[string]: any}
	@return {[string]: any}
]=]
function PromoCodeService:_FetchPromoCodeShard(promoCodeData: {[string]: any}): {[string]: any} | nil
	local shardId = promoCodeData.ShardId

	-- Return if it already exists
	if (self._PrimaryShards[shardId]) then
		return self._PrimaryShards[shardId]
	end

	-- Attempt to query DataStore
	local success, response = pcall(function()
		return self._CodeDatabase:GetAsync(shardId)
	end)
	
	-- Cache and return data
	if (success) then
		self._PrimaryShards[shardId] = response

		return response
	else
		return {}
	end
end

--[=[
	@private

	Returns the promocode shard for a specific code

	@param promoCode string
	@return {[string]: any}
]=]
function PromoCodeService:_FetchPromoCodeData(promoCode: string): {[string]: any} | nil
	return self._PrimaryStore[promoCode]
end

--[=[
	@private

	Sends a message to slack

	@param message string
	@return nil
]=]
function PromoCodeService:_ReportToSlack(message: string)
	if (self._ReportsInLastMinute >= 15) then return end
	if (message == "") then return end

	self._ReportsInLastMinute += 1

	local formattedMessage = string.format(
		"SuperStack: PromoCodeService\nGame: %s\nDate: %s\nMessage: %s",
		string.format("%s (%i)", game.Name, game.GameId),
		DateTime.now():FormatUniversalTime("lll", "en-us"),
		message
	)

	return self._SlackReporter:SendMessage(formattedMessage)
end

--[=[
	@private

	Updates the cached PrimaryStore with a fresh one

	@return {[string]: {[string]: any}}
]=]
function PromoCodeService:_UpdatePrimaryStore(): {string} | nil
	local success, response = pcall(function()
		return self._CodeDatabase:GetAsync("PrimaryStore")
	end)

	-- No need to panic, another update attempt will occur
	if (not success) then
		return self:_ReportToSlack(string.format(
			"Possible DataStore overload!  Unable to UpdatePrimaryStore!\n%s",
			response
		))
	end

	self._PrimaryStore = (response or {})
	self._PrimaryShards = {}
	
	return response
end

local Singleton = PromoCodeService.new()
return Singleton
