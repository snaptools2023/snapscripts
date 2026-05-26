<#
.SYNOPSIS
	Lists pixel variant cards that have a Gold Foil or Ink infinity split.

.DESCRIPTION
	Reads the list of pixel card variant keys from .data/all_pixels.txt, then checks the player's
	CollectionState to find which of those cards have already received a GoldFoil or Ink split.

.OUTPUTS
	Table sorted by split count descending, then alphabetically.

.NOTES
	Version: 1.0 - snaptools2023 - 2026-03-23 - Initial script (inverse of List-PixelsWithoutSplits.ps1)

	* The data files seem to only refresh after starting a new game or restarting the app.
	  So, to get a fresh list, you need to do one of those things.

	Split surface effects that indicate a card is "done":
	  - GoldFoil  (Gold infinity split)
	  - Ink       (Ink infinity split)

.EXAMPLE
	List-PixelsWithSplits.ps1
#>

# ---------------------------------------------------------------------------
# Data paths
# ---------------------------------------------------------------------------
$pixelsFilePath      = Join-Path $PSScriptRoot '..\.data\all_pixels.txt'
$snapDataPath        = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"
$masteryStatePath    = Join-Path $snapDataPath "CharacterMasteryState.json"

# read all pixel variant keys from file, ignoring blank lines
$pixelVariantKeys = Get-Content $pixelsFilePath | Where-Object { $_.Trim() -ne '' }

# load collection state
$collectionStateJson = Get-Content $collectionStatePath | ConvertFrom-Json
$cards = $collectionStateJson.ServerState.Cards

# load character mastery state — build lookup: CardDefId -> LastClaimedLevel
$masteryStateJson      = Get-Content $masteryStatePath | ConvertFrom-Json
$characterProgressData = $masteryStateJson.ServerState.CharacterMasteryProgress.CharacterProgressData
$masteryLookup = @{}
foreach ($prop in $characterProgressData.PSObject.Properties) {
	$masteryLookup[$prop.Name] = $prop.Value.LastClaimedLevel
}

# build a lookup: ArtVariantDefId -> CardDefId
$artVariantLookup = @{}
foreach ($card in $cards) {
	if ($card.PSObject.Properties['ArtVariantDefId'] -and $card.ArtVariantDefId) {
		$artVariantLookup[$card.ArtVariantDefId] = $card.CardDefId
	}
}

# build lookups keyed by CardDefId:
#   $splitLookup -> list of SurfaceEffectDefIds (one per split entry)
#   $variantSets -> set of unique ArtVariantDefIds (distinct art variants owned)
$splitLookup = @{}
$variantSets = @{}
foreach ($card in $cards) {
	if (-not $splitLookup.ContainsKey($card.CardDefId)) {
		$splitLookup[$card.CardDefId] = [System.Collections.Generic.List[string]]::new()
		$variantSets[$card.CardDefId] = [System.Collections.Generic.HashSet[string]]::new()
	}
	if ($card.PSObject.Properties['ArtVariantDefId'] -and $card.ArtVariantDefId) {
		[void]$variantSets[$card.CardDefId].Add($card.ArtVariantDefId)
	}
	if ($card.PSObject.Properties['SurfaceEffectDefId'] -and $card.SurfaceEffectDefId) {
		$splitLookup[$card.CardDefId].Add($card.SurfaceEffectDefId)
	}
}

# final results list
$results = @()

foreach ($pixelKey in $pixelVariantKeys) {
	# find the base CardDefId for this pixel variant
	$cardDefId = $artVariantLookup[$pixelKey]

	if (-not $cardDefId) {
		# pixel variant not found in collection — skip
		continue
	}

	# check if any split on this card is GoldFoil or Ink
	$goldFoilSplits = 0
	$inkSplits      = 0
	if ($splitLookup.ContainsKey($cardDefId)) {
		foreach ($surfaceEffect in $splitLookup[$cardDefId]) {
			if ($surfaceEffect -ieq 'GoldFoil') { $goldFoilSplits++ }
			if ($surfaceEffect -ieq 'Ink')      { $inkSplits++ }
		}
	}

	if ($goldFoilSplits -gt 0 -or $inkSplits -gt 0) {
		$totalSplits   = $splitLookup[$cardDefId].Count
		$totalVariants = $variantSets[$cardDefId].Count
		$masteryLevel  = if ($masteryLookup.ContainsKey($cardDefId)) { [int]$masteryLookup[$cardDefId] } else { 0 }

		$results += [PSCustomObject] @{
			CardDefId  = $cardDefId
			Splits     = $totalSplits
			Gold       = $goldFoilSplits
			Ink        = $inkSplits
			Mastery    = $masteryLevel
			Variants   = $totalVariants
		}
	}
}

# sort by total splits descending, then alphabetically for ties
$results = @($results | Sort-Object -Property @{Expression = 'Splits'; Descending = $true}, CardDefId)

Write-Host "Pixel cards with a GoldFoil or Ink split ($($results.Count) of $($pixelVariantKeys.Count)):"
Write-Host ""
$results | Format-Table -AutoSize -Property CardDefId, Splits, Gold, Ink, Mastery, Variants
