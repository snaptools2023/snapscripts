#
#
# The data files seem to only refrsh after starting a new game or restarting the app.  So, to get afresh list, you need to do one of those things.
#
# todo:  take the output file as a parameter
#

$timestamp = (get-date).ToString("yyyyMMddTHHmmss")
$outputFile = "alldecks-$timestamp.txt"

# snap data root path.  This is my path on windows 10 using environment variables for the username.
$snapDataPath = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"
$collectionStateJson = Get-Content $collectionStatePath | ConvertFrom-Json 

# get all decks
$decks = $collectionStateJson.ServerState.Decks

# final output hashtable
$results = @()

# loop through each card and identify if we have enough boosters and credits
foreach ($deck in $decks) {
	Add-Content $outputFile -Value "Deck:  $($deck.Name)" # $([Environment]::NewLine)

	$deckToSerialize = @{
		# "Name" = $deck.Name
		"Cards" = @()
	}

	foreach ($card in $deck.Cards) {
		Add-Content $outputFile -Value "- $($card.CardDefId)"

		# add to array to serialize

		$deckToSerialize.Cards += @{ "CardDefId" = $card.CardDefId }
	}

	$deckToSerializeJson = $deckToSerialize | ConvertTo-Json -Compress

	$deckToSerializeBytes = [System.Text.Encoding]::Unicode.GetBytes($deckToSerializeJson)
	$deckToSerializeBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($deckToSerializeJson))
	
	# write deck code
	Add-Content $outputFile -Value $deckToSerializeBase64
	Add-Content $outputFile -Value ""
	Add-Content $outputFile -Value ""
}
