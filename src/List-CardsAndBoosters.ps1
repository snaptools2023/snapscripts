<#
.SYNOPSIS
	Lists all cards and the number of boosters each has.

.DESCRIPTION
	Powershell script to list all cards with booster count for each.

.OUTPUTS
	Powershell script to list all cards with booster count for each.

.NOTES
	Version: 1.0 - snaptools2023 - 2023-08-28 - Initial script

	* The data files seem to only refrsh after starting a new game or restarting the app.	So, to get afresh list, you need to do one of those things.
	* todo:	output to file based on parameter?
	* todo: order by name or booster count parameter

.PARAMETER CSV
	True to export the values as csv

.EXAMPLE
	List-CardsAndBoosters.ps1

	Exports all cards and their boosters.

.EXAMPLE
	List-CardsAndBoosters.ps1 -CSV $true

	Exports all cards and their boosters in CSV format.

#>

param ([bool] $CSV)

# snap data root path.	This is my path on windows 10 using environment variables for the username.
$snapDataPath = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"

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

	if ($previousCardDefId -ne $card.CardDefId) {
		$results += [PSCustomObject] @{ CardDefId = $card.CardDefId; AvailableBoosters = $availableBoosters }
		$previousCardDefId = $card.CardDefId
	}
}

# sort the final list by credits required which will put the cheapest cards at the top.
$results = @($results | Sort-Object -Property CardDefId)

$previousCardDefId = ""

foreach ($result in $results) {
	if ($previousCardDefId -ne $result.CardDefId) {
		if ($true -eq $CSV) {
			Write-Host "$($result.CardDefId), $($result.AvailableBoosters)"
		} else {
			Write-Host "$($result.CardDefId) has $($result.AvailableBoosters) boosters"
		}
	}

	$previousCardDefId = $result.CardDefId
}
