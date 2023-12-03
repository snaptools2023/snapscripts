<#
.SYNOPSIS
	Lists cards to ugrade that are either common or have enough boosters to get to infinite.

.DESCRIPTION
	Powershell script to identify which cards to upgrade for cheap (common) or all the way to infinite (to get another split)

.OUTPUTS
	List of cards that are common or can be upgraded to infinite for a split.

.NOTES
	Version: 1.0 - snaptools2023 - 2023-11-03 - Initial script

	* The data files seem to only refrsh after starting a new game or restarting the app.	So, to get afresh list, you need to do one of those things.
	* todo:	output to file based on parameter?

.EXAMPLE
		List-CardsToUpgrade2.ps1
#>

$maxCardsToDisplay = 145

# boosters and credits required per card rank upgrade
$boosterLevels = @(
	@{
		FromRank         = "Common"
		ToRank           = "Uncommon"
		BoostersRequired = 5
		CreditsRequired  = 25
	},
	@{
		FromRank         = "Uncommon"
		ToRank           = "Rare"
		BoostersRequired = 10
		CreditsRequired  = 100
	},
	@{
		FromRank         = "Rare"
		ToRank           = "Epic"
		BoostersRequired = 20
		CreditsRequired  = 200
	},
	@{
		FromRank         = "Epic"
		ToRank           = "Legendary"
		BoostersRequired = 30
		CreditsRequired  = 300
	},
	@{
		FromRank         = "Legendary"
		ToRank           = "UltraLegendary"
		BoostersRequired = 40
		CreditsRequired  = 400
	},
	@{
		FromRank         = "UltraLegendary"
		ToRank           = "Infinity"
		BoostersRequired = 50
		CreditsRequired  = 500
	}, 
	@{
		FromRank         = "Infinity"
		ToRank           = ""
		BoostersRequired = 999999 # Really high number
		CreditsRequired  = 999999 # Really high number
	}
)

# snap data root path.	This is my path on windows 10 using environment variables for the username.
$snapDataPath = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$shopStatePath = Join-Path $snapDataPath "ShopState.json"
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"

# get credits from shop state file
$shopStateJson = Get-Content $shopStatePath | ConvertFrom-Json
$availableCredits = $shopStateJson.ServerState.Account.Credits

# get boosters from collection state file
$collectionStateJson = Get-Content $collectionStatePath | ConvertFrom-Json 
$cards = $collectionStateJson.ServerState.Cards
$cardDefStats = $collectionStateJson.ServerState.CardDefStats.Stats

# final output hashtable
$results = @()

# loop through each card and identify if we have enough boosters and credits
foreach ($card in $cards) {
	$boosterLevel = $boosterLevels | Where-Object { $_.FromRank -eq $card.RarityDefId }

	# verify that the card actually has a boosters value befor using it - otherwise, assume 0
	if (Get-Member -inputobject $cardDefStats.PSObject.Properties[$card.CardDefId].Value -name "Boosters" -Membertype Properties) {
		$availableBoosters = $cardDefStats.PSObject.Properties[$card.CardDefId].Value.Boosters
	}
	else {
		$availableBoosters = 0
	}

	# todo:  verify we have enough credits

	# if we have enough boosters for this card and enough credits, add it to the list
	if ($boosterLevel.FromRank -eq $boosterLevels[0].FromRank -and $availableCredits -ge $boosterLevels[0].CreditsRequired) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; BoostersRequired = $boosterLevel.BoostersRequired; FromRank = $boosterLevel.FromRank; ToRank = $boosterLevel.ToRank; CreditsRequired = $boosterLevel.CreditsRequired }
	} elseif ($boosterLevel.FromRank -eq $boosterLevels[1].FromRank -and $availableBoosters -ge 145 -and $availableCredits -ge $boosterLevels[1].CreditsRequired) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; BoostersRequired = $boosterLevel.BoostersRequired; FromRank = $boosterLevel.FromRank; ToRank = $boosterLevel.ToRank; CreditsRequired = $boosterLevel.CreditsRequired }
	} elseif ($boosterLevel.FromRank -eq $boosterLevels[2].FromRank -and $availableBoosters -ge 140 -and $availableCredits -ge $boosterLevels[2].CreditsRequired) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; BoostersRequired = $boosterLevel.BoostersRequired; FromRank = $boosterLevel.FromRank; ToRank = $boosterLevel.ToRank; CreditsRequired = $boosterLevel.CreditsRequired }
	} elseif ($boosterLevel.FromRank -eq $boosterLevels[3].FromRank -and $availableBoosters -ge 120 -and $availableCredits -ge $boosterLevels[3].CreditsRequired) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; BoostersRequired = $boosterLevel.BoostersRequired; FromRank = $boosterLevel.FromRank; ToRank = $boosterLevel.ToRank; CreditsRequired = $boosterLevel.CreditsRequired }
	} elseif ($boosterLevel.FromRank -eq $boosterLevels[4].FromRank -and $availableBoosters -ge 90 -and $availableCredits -ge $boosterLevels[4].CreditsRequired) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; BoostersRequired = $boosterLevel.BoostersRequired; FromRank = $boosterLevel.FromRank; ToRank = $boosterLevel.ToRank; CreditsRequired = $boosterLevel.CreditsRequired }
	} elseif ($boosterLevel.FromRank -eq $boosterLevels[5].FromRank -and $availableBoosters -ge 50 -and $availableCredits -ge $boosterLevels[5].CreditsRequired) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; BoostersRequired = $boosterLevel.BoostersRequired; FromRank = $boosterLevel.FromRank; ToRank = $boosterLevel.ToRank; CreditsRequired = $boosterLevel.CreditsRequired }
	}
}

# sort the final list by credits required which will put the cheapest cards at the top.
$results = @($results | Sort-Object -Property CreditsRequired, CardDefId)

# limit to the top 15 cards
$counter = 0;
foreach ($result in $results) {
	if ($counter -gt $maxCardsToDisplay) {
		continue
	}

	# todo:  this should show what it takes to get to infinite
	Write-Host "$($result.CardDefId) requires $($result.BoostersRequired) boosters to upgrade from $($result.FromRank) to $($result.ToRank) for $($result.CreditsRequired) credits"
	$counter++
}
