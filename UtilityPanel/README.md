# UtilityPanel

UtilityPanel is a package designed to streamline executing actions in your development workflow.  These actions
are useful for debugging, moderation or testing core features.

## Features
* Easily define UtilityPanel trees
* UI auto-rendered
* UI makes editing action paramesters easy

## Dependencies
* NetworkService
* Fusion

## Example

Here's an example snippet of code and what is rendered:
```lua
UtilityPanelService:CreatePanel("Main", Enum.KeyCode.Equals, function(panel)
	panel:AddCategory("PlayerData", function(category)
		category:AddAction("Print PlayerData", {
			Variables = {
				{Name = "Player", Type = "Player"}
			},

			Runner = function(player, variables)
				print(PlayerDataService:GetPlayerProfile(variables.Player):GetMutableData())
			end
		})

		category:AddAction("Print PlayerCacheValue", {
			Variables = {
				{Name = "Key", Type = "string"}
			},

			Runner = function(player, variables)
				print(string.format("%s: %s", variables.Key, PlayerDataService:GetCacheValue(player, variables.Key)))
			end
		})
	end)
end)
```

![Example](./.img/UtilityPanel.png)