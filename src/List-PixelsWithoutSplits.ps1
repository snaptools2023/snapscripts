<#
.SYNOPSIS
	Lists pixel variant cards that do not yet have a Gold Foil or Ink infinity split.

.DESCRIPTION
	Reads the list of pixel card variant keys from .data/all_pixels.txt, then checks the player's
	CollectionState to find which of those cards have not yet received a GoldFoil or Ink split.
	Probability of earning Ink/Gold on the next split is calculated from two independent components:
	  1. Base 10% protected chance (active from the 4th split onward)
	  2. Mastery % — the Rare Finish drop rate for the card's Character Mastery Level
	Combined chance: Base% + (1 - Base%) x Mastery%

.OUTPUTS
	Table sorted by combined Ink/Gold probability, most likely first.

.NOTES
	Version: 1.0 - snaptools2023 - 2026-03-18 - Initial script
	Version: 1.1 - snaptools2023 - 2026-03-18 - Add split count, variant count, and table output
	Version: 1.2 - snaptools2023 - 2026-03-18 - Add Ink/Gold probability based on infinity-splits.md rules
	Version: 1.3 - snaptools2023 - 2026-03-18 - Update probability to flat 10% rule from official source
	Version: 1.4 - snaptools2023 - 2026-03-18 - Add Character Mastery Level and mastery-based finish rate

	* The data files seem to only refresh after starting a new game or restarting the app.
	  So, to get a fresh list, you need to do one of those things.

	Split surface effects that indicate a card is "done":
	  - GoldFoil  (Gold infinity split)
	  - Ink       (Ink infinity split)

.EXAMPLE
	List-PixelsWithoutSplits.ps1
#>

# ---------------------------------------------------------------------------
# Returns the base protected probability (0.0-1.0) of rolling Ink or Gold.
# Rule: flat 10% per split starting from the 4th split (Splits >= 3).
# ---------------------------------------------------------------------------
function Get-BaseInkGoldChance {
	param ([int]$splits)
	if ($splits -lt 3) { return 0.0 }
	return 0.10
}

# ---------------------------------------------------------------------------
# Returns the Rare Finish drop rate for a given Character Mastery Level.
# Uses a step function matching the four bracket columns in infinity-splits.md.
#   Level  1-9  -> 54%
#   Level 10-19 -> 35%
#   Level 20-29 -> 21%
#   Level 30+   -> 16%
# Gold and Ink are available through this pool only when splits >= 3.
# ---------------------------------------------------------------------------
function Get-MasteryFinishRate {
	param ([int]$masteryLevel)
	if     ($masteryLevel -ge 30) { return 0.16 }
	elseif ($masteryLevel -ge 20) { return 0.21 }
	elseif ($masteryLevel -ge 10) { return 0.35 }
	else                          { return 0.54 }
}

# ---------------------------------------------------------------------------
# Combined probability: base fires first; if not, mastery pool is drawn.
#   P = base + (1 - base) * mastery
# Mastery component only applies when Ink/Gold are in the pool (splits >= 3).
# ---------------------------------------------------------------------------
function Get-CombinedInkGoldChance {
	param ([int]$splits, [int]$masteryLevel)
	$base    = Get-BaseInkGoldChance  -splits $splits
	$mastery = if ($splits -ge 3) { Get-MasteryFinishRate -masteryLevel $masteryLevel } else { 0.0 }
	return $base + (1.0 - $base) * $mastery
}

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
	$hasDoneSplit = $false
	if ($splitLookup.ContainsKey($cardDefId)) {
		foreach ($surfaceEffect in $splitLookup[$cardDefId]) {
			if ($surfaceEffect -ieq 'GoldFoil' -or $surfaceEffect -ieq 'Ink') {
				$hasDoneSplit = $true
				break
			}
		}
	}

	if (-not $hasDoneSplit) {
		$totalSplits   = $splitLookup[$cardDefId].Count
		$totalVariants = $variantSets[$cardDefId].Count
		$masteryLevel  = if ($masteryLookup.ContainsKey($cardDefId)) { [int]$masteryLookup[$cardDefId] } else { 0 }

		$baseChance     = Get-BaseInkGoldChance     -splits $totalSplits
		$masteryChance  = if ($totalSplits -ge 3) { Get-MasteryFinishRate -masteryLevel $masteryLevel } else { 0.0 }
		$combinedChance = Get-CombinedInkGoldChance -splits $totalSplits -masteryLevel $masteryLevel

		$results += [PSCustomObject] @{
			CardDefId    = $cardDefId
			Splits       = $totalSplits
			Mastery      = $masteryLevel
			Variants     = $totalVariants
			'Base %'     = '{0:P1}' -f $baseChance
			'Mastery %'  = '{0:P1}' -f $masteryChance
			'Combined %' = '{0:P1}' -f $combinedChance
			_SortKey     = $combinedChance
		}
	}
}

# sort by combined probability descending, then alphabetically for ties
$results = @($results | Sort-Object -Property @{Expression = '_SortKey'; Descending = $true}, CardDefId)

Write-Host "Pixel cards without a GoldFoil or Ink split ($($results.Count) of $($pixelVariantKeys.Count)):"
Write-Host ""
$results | Format-Table -AutoSize -Property CardDefId, Splits, Mastery, Variants, 'Base %', 'Mastery %', 'Combined %'
