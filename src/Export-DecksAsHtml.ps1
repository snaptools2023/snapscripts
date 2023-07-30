<#
.SYNOPSIS
	Export marvel snap decks as simple html file.

.DESCRIPTION
	Export marvel snap decks as simple html file.

.OUTPUTS
	Export html file - see OutputFilename parameter below.

.NOTES
	Version: 1.0
	Author: snaptools2023
	Creation Date: 2023-07-28
	Purpose/Change: Initial script

	* The data files seem to only refrsh after starting a new game or restarting the app.	So, to get afresh list, you need to do one of those things.

.PARAMETER DeckName
	The name of the deck to export.	If no deck name is given, all decks are exported.

.PARAMETER OutputFilename
	The name of file to write the export to.

.EXAMPLE
	Export-DecksAsHtml.ps1 

	Execute with default values - this will export all decks to a file in the current directory with a timestamp in the name.
.EXAMPLE
	# execute specifying the deck name and the output filename - this will export only the deck named Patriot to a file in the current directory called PatriotDeck.html
	Export-DecksAsHtml.ps1 -DeckName Patriot -OutputFileName PatriotDeck.html

	Execute specifying the deck name and the output filename - this will export only the deck named Patriot to a file in the current directory called PatriotDeck.html
.EXAMPLE
	Export-DecksAsHtml.ps1 -OutputFileName AllDecks.html

	Execute specifying the output filename - this will export all decks to a file in the current directory called AllDecks.html
.EXAMPLE
	Export-DecksAsHtml.ps1 -DeckName Patriot -OutputFileName c:\PatriotDeck.html

	Execute specifying the deck name and the output filename - this will export only the deck named Patriot to a file in c:\ PatriotDeck.html
#>

param ([string] $DeckName, [string] $OutputFilename)

if ('' -eq $OutputFilename) {
	$timestamp = (get-date).ToString("yyyyMMddHHmmss")
	$OutputFilename = "alldecks-$timestamp.html"
}

if ('' -eq $DeckName) {
	$Deckname = '*' # yes, this will conflict with decks named '*'.  "dont have that deck name"
}

# snap data root path.  This is my path on windows 10 using environment variables for the username.
$snapDataPath = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"
$collectionStateJson = Get-Content $collectionStatePath | ConvertFrom-Json 

# get all decks
$decks = $collectionStateJson.ServerState.Decks

# final output hashtable
$results = @()

# start html
Add-Content $OutputFilename -Value "<!doctype html><html lang=en><head><meta charset=utf-8><title>Deck Export</title><style>html { max-width: 70ch; padding: 3em 1em; margin: auto; line-height: 1.75; font-size: 1.25em; h1,h2,h3,h4,h5,h6 { margin: 3em 0 1em; } p,ul,ol { margin-bottom: 2em; color: #1d1d1d; font-family: sans-serif; }</style></head><body>"

# loop through each card and identify if we have enough boosters and credits
foreach ($deck in $decks) {
	# if we are exporting all decks, or just this specific deck
	if (('*' -eq $DeckName) -or ($deck.Name -eq $DeckName)) {
		Add-Content $OutputFilename -Value "<h2>Deck:  $($deck.Name)</h2><p><ul>" # start the p and ul

		$deckToSerialize = @{
			# "Name" = $deck.Name
			"Cards" = @()
		}

		foreach ($card in $deck.Cards) {
			Add-Content $OutputFilename -Value "<li>$($card.CardDefId)</li>"

			# add to array to serialize
			$deckToSerialize.Cards += @{ "CardDefId" = $card.CardDefId }
		}

		Add-Content $OutputFilename -Value "</ul>" # end the ul

		$deckToSerializeJson = $deckToSerialize | ConvertTo-Json -Compress

		$deckToSerializeBytes = [System.Text.Encoding]::Unicode.GetBytes($deckToSerializeJson)
		$deckToSerializeBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($deckToSerializeJson))

		# write deck code
		Add-Content $OutputFilename -Value $deckToSerializeBase64
		Add-Content $OutputFilename -Value "</p>" # end the p
		Add-Content $OutputFilename -Value ""
	}

	Add-Content $OutputFilename -Value "</body></html>"
}
