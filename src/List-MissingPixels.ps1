<#
.SYNOPSIS
	Lists all pixel variant cards that are NOT in the player's collection.

.DESCRIPTION
	Reads the comprehensive list of pixel card variant keys from .data/all_pixels.txt
	(which contains every Pixel variant known on snap.fan), then checks the player's
	CollectionState to find which of those pixel variants are missing from the collection.

.OUTPUTS
	Table of missing pixel variants sorted alphabetically, with summary counts.

.NOTES
	Version: 1.0 - snaptools2023 - 2026-05-28 - Initial script

	* The data files seem to only refresh after starting a new game or restarting the app.
	  So, to get a fresh list, you need to do one of those things.

	* all_pixels.txt contains every known Pixel ArtVariantDefId (e.g. Abomination_01).
	  To refresh this list, visit the snap.fan Pixel variants pages:
	    https://snap.fan/cards/variants/Pixel/
	    https://snap.fan/cards/variants/Pixel/?page=2
	    https://snap.fan/cards/variants/Pixel/?page=3
	    https://snap.fan/cards/variants/Pixel/?page=4
	    https://snap.fan/cards/variants/Pixel/?page=5

.EXAMPLE
	List-MissingPixels.ps1
#>

# ---------------------------------------------------------------------------
# Data paths
# ---------------------------------------------------------------------------
$pixelsFilePath      = Join-Path $PSScriptRoot '..\.data\all_pixels.txt'
$snapDataPath        = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"

# read all pixel variant keys from file, ignoring blank lines
$pixelVariantKeys = Get-Content $pixelsFilePath | Where-Object { $_.Trim() -ne '' }

# load collection state
$collectionStateJson = Get-Content $collectionStatePath | ConvertFrom-Json
$cards = $collectionStateJson.ServerState.Cards

# build a set of owned ArtVariantDefIds (across all cards the player owns)
$ownedVariantDefIds = [System.Collections.Generic.HashSet[string]]::new()
foreach ($card in $cards) {
	if ($card.PSObject.Properties['ArtVariantDefId'] -and $card.ArtVariantDefId) {
		[void]$ownedVariantDefIds.Add($card.ArtVariantDefId)
	}
}

# also build lookup: ArtVariantDefId -> CardDefId for cards that ARE owned
# (so for missing pixels, we know which card they belong to even if we don't own them)
$artVariantLookup = @{}
foreach ($card in $cards) {
	if ($card.PSObject.Properties['ArtVariantDefId'] -and $card.ArtVariantDefId) {
		$artVariantLookup[$card.ArtVariantDefId] = $card.CardDefId
	}
}

# determine missing pixels: keys in all_pixels.txt but NOT in ownedVariantDefIds
$missingPixels = @()

foreach ($pixelKey in $pixelVariantKeys) {
	if (-not $ownedVariantDefIds.Contains($pixelKey)) {
		# Try to figure out the CardDefId for this pixel variant
		# Pixel variants follow the pattern: CardDefId_01
		# Extract the base card name from the variant key
		$cardName = $pixelKey -replace '_\d+$', ''

		$missingPixels += [PSCustomObject] @{
			ArtVariantDefId = $pixelKey
			CardName        = $cardName
		}
	}
}

# sort alphabetically
$missingPixels = @($missingPixels | Sort-Object -Property ArtVariantDefId)

# output results
$ownedCount = $pixelVariantKeys.Count - $missingPixels.Count
$totalCount = $pixelVariantKeys.Count
$pctOwned   = if ($totalCount -gt 0) { ($ownedCount / $totalCount) * 100 } else { 0 }

Write-Host ""
Write-Host "================================================================"
Write-Host "  Missing Pixel Variants"
Write-Host "================================================================"
Write-Host "  Total pixel variants on snap.fan : $totalCount"
Write-Host "  Owned pixel variants              : $ownedCount"
Write-Host "  MISSING pixel variants            : $($missingPixels.Count)"
Write-Host "  % owned                           : $('{0:N1}' -f $pctOwned)%"
Write-Host "================================================================"
Write-Host ""

if ($missingPixels.Count -gt 0) {
	Write-Host "Missing pixel variants ($($missingPixels.Count)):"
	Write-Host ""
	$missingPixels | Format-Table -AutoSize -Property ArtVariantDefId
}
else {
	Write-Host "All $totalCount pixel variants are in your collection!"
}
