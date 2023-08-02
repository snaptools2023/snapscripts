<#
.SYNOPSIS
	Export marvel snap decks as a html file - light templating included.

.DESCRIPTION
	Export marvel snap decks as a html file - light templating included.

.OUTPUTS
	Export html file - see OutputFilename parameter below.

.NOTES
	Version: 1.0 - snaptools2023 - 2023-07-28 - Initial script
	Version: 1.1 - snaptools2023 - 2023-08-01 - migrated to external html templates.

	* The data files seem to only refrsh after starting a new game or restarting the app.	So, to get afresh list, you need to do one of those things.

.PARAMETER DeckName
	The name of the deck to export.	If no deck name is given, all decks are exported.

.PARAMETER OutputFilename
	The name of file to write the export to.

.EXAMPLE
	Export-DecksAsHtmlAdvanced.ps1 

	Execute with default values - this will export all decks to a file in the current directory with a timestamp in the name.
.EXAMPLE
	# execute specifying the deck name and the output filename - this will export only the deck named Patriot to a file in the current directory called PatriotDeck.html
	Export-DecksAsHtmlAdvanced.ps1 -DeckName Patriot -OutputFileName PatriotDeck.html

	Execute specifying the deck name and the output filename - this will export only the deck named Patriot to a file in the current directory called PatriotDeck.html
.EXAMPLE
	Export-DecksAsHtmlAdvanced.ps1 -OutputFileName AllDecks.html

	Execute specifying the output filename - this will export all decks to a file in the current directory called AllDecks.html
.EXAMPLE
	Export-DecksAsHtmlAdvanced.ps1 -DeckName Patriot -OutputFileName c:\PatriotDeck.html

	Execute specifying the deck name and the output filename - this will export only the deck named Patriot to a file in c:\ PatriotDeck.html
#>

#
# parameters and validation/defaults
#
param ([string] $DeckName, [string] $OutputFilename)

Set-StrictMode -Version 1

if ('' -eq $OutputFilename) {
	$timestamp = (get-date).ToString("yyyyMMddHHmmss")
	$OutputFilename = "alldecks-$timestamp.html"
}

if ('' -eq $DeckName) {
	$Deckname = '*' # yes, this will conflict with decks named '*'.  "dont have that deck name"
}

#
# functions
#
# https://www.bricelam.net/2012/09/simple-template-engine-for-powershell.html
# Merge-Tokens 'Hello, $target$! My name is $self$.' @{
# 	Target = 'World'
# 	Self = 'Brice'
# }
function Merge-Tokens($template, $tokens) {
    return [regex]::Replace($template, '\$(?<tokenName>\w+)\$', {
            param($match)

            $tokenName = $match.Groups['tokenName'].Value

            return $tokens[$tokenName]
        })
}

function Load-Template($templateName) {
	$path = $MyInvocation.ScriptName
	$path = Split-Path $path -Parent
	$path = Join-Path $path "_Export-DecksAsHtmlAdvanced-Templates\$templateName.html" # todo:  windows only here. fix this later
	$templateContent = Get-Content -Path $path -Raw
	return $templateContent
}

#
# main script
#

# snap data root path.  This is my path on windows 10 using environment variables for the username.
$snapDataPath = Join-Path $env:USERPROFILE '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod'
$collectionStatePath = Join-Path $snapDataPath "CollectionState.json"
$collectionStateJson = Get-Content $collectionStatePath | ConvertFrom-Json 

# get all decks
$decks = $collectionStateJson.ServerState.Decks

# start html
$htmlBody = Merge-Tokens -template (Load-Template -templateName 'header') -tokens @{ 
	title = "Marvel Snap Deck Export $((get-date).ToString("MM-dd-yyyy hh:mm tt"))"
}

# loop through each deck
foreach ($deck in $decks) {
	# if we are exporting all decks, or just this specific deck
	if (('*' -eq $DeckName) -or ($deck.Name -eq $DeckName)) {
		$deckToSerialize = @{
			"Cards" = @()
		}

		$htmlCardTemplate = Load-Template -templateName 'card'
		$htmlCards = ""

		foreach ($card in $deck.Cards) {
			$htmlCards += Merge-Tokens -template $htmlCardTemplate -tokens @{ 
				CardDefId = $card.CardDefId
			}

			# add to array to serialize
			$deckToSerialize.Cards += @{ "CardDefId" = $card.CardDefId }
		}

		$deckToSerializeJson = $deckToSerialize | ConvertTo-Json -Compress
		$deckToSerializeBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($deckToSerializeJson))

		$htmlDeck = Merge-Tokens -template (Load-Template -templateName 'deck') -tokens @{ 
			name = $deck.Name
			cards = $htmlCards
			deckToSerializeBase64 = $deckToSerializeBase64
		}

		$htmlBody += $htmlDeck
	}
}

$output = Merge-Tokens -template (Load-Template -templateName 'base') -tokens @{ 
	title = "Marvel Snap Deck Export"
	htmlBody = $htmlBody 
}

Add-Content $OutputFilename -Value $output

