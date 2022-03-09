local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Table = SuperStack:GetModule("Table")

return Table.readonly({
	DataStoreKey = "SuperStack_UserData",

	RetryDelay = 5,
	MaxRetries = 5,

	NilDataDeferTime = 60,

	AutosaveFrequency = 5 * 60,

	DataSchema = {
		-- Referral codes
		HasBeenReferred = "",
		TotalReferrals = 0,

		-- Promo codes
		PromoCodeRedemptions = {},
		
		-- General
		TotalVisits = 0,
		SchemaVersion = 1,
	},

	DataReplicationIgnoreList = {
		"SchemaVersion",
		"PromoCodeRedemptions",
		"PendingReferrals"
	}
})