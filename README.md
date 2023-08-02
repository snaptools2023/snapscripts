# snapscripts
Misc scripts for marvel snap.

* [List-CardsToUpgrade.ps1](#list-cardstoupgradeps1)
* [Export-DecksForSharing.ps1](#export-decksforsharingps1)
* [Export-DecksAsHtml.ps1](#export-decksashtmlps1)
* [Export-DecksAsHtmlAdvanced.ps1](#export-decksashtmladvancedps1)

## Todo/coming soon - screenshots of html output

## List-CardsToUpgrade.ps1

### What this script does.

Powershell script to identify which cards to upgrade to get the most out of your credits and boosters.

The logic for identifying which cards to update is to find the lowest credit cost cards that you actually have boosters for.  Some people say that you should upgrade the cards that you have the most boosters for but I find credits being the bigger limiter.  

This script enumerates your cards and lists them in order of least credits required to upgrade.  You could tweak the script to go by booster count or even add a parameter to make it pick at runtime.

The card levels are:

* Uncommon: 25 Credits and 5 Boosters – Gain 1 Collection Level
* Rare: 100 Credits and 10 Boosters – Gain 2 Collection Levels
* Epic: 200 Credits and 20 Boosters – Gain 4 Collection Levels
* Legendary: 300 Credits and 30 Boosters – Gain 6 Collection Levels
* Ultra: 400 Credits and 40 Boosters – Gain 8 Collection Levels
* Infinity 500 Credits and 50 Boosters – Gain 10 Collection Levels

You can see that upgrading to `Uncommon` costs 25 credits per collection level gained.  Upgrading to `Rare` costs 50 credits per collection level.  Upgrading to `Infinity` costs 10 credits per collection level.

### How does it work?

This script looks at only your local files.  It does not send or receive data from any server.

The two files it looks at are:

* '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod\ShopState.json'
* '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod\CollectionState.json'

ShopState is parsed to see how many credits you have in your account.

CollectionState.json is parsed to identify your cards, which levels they are at, and how many boosters they have.

Using these values, a list of cheapest cards to upgrade is produced.

### Example

```
PS > .\List-CardsToUpgrade.ps1
Giganto requires 5 boosters to upgrade from Common to Uncommon for 25 credits
Polaris requires 5 boosters to upgrade from Common to Uncommon for 25 credits
Hood requires 10 boosters to upgrade from Uncommon to Rare for 100 credits
Shuri requires 20 boosters to upgrade from Rare to Epic for 200 credits
CaptainMarvel requires 20 boosters to upgrade from Rare to Epic for 200 credits
Sentinel requires 20 boosters to upgrade from Rare to Epic for 200 credits
Deathlok requires 20 boosters to upgrade from Rare to Epic for 200 credits
Nakia requires 20 boosters to upgrade from Rare to Epic for 200 credits
ProfessorX requires 20 boosters to upgrade from Rare to Epic for 200 credits
... omitted for brevity
Cosmo requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
JessicaJones requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
RocketRaccoon requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
MistyKnight requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
Armor requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
HitMonkey requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
Hobgoblin requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
TheCollector requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
AmericaChavez requires 50 boosters to upgrade from UltraLegendary to Infinity for 500 credits
```

## Export-DecksForSharing.ps1

### What this script does.

Powershell script to export your decks to a text file, including names and the serialized string for importing into snap.  This is a basic "backup" script or a way to share all your decks.

### How does it work?

This script looks at only your local files.  It does not send or receive data from any server.

The file it looks at is:

* '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod\CollectionState.json'

CollectionState.json is parsed to identify your decks and cards.

Using these values, it creates a json representation of the deck and seriailzes it to a string that you can paste into Snap.

### Example

```
PS > .\Export-DecksForSharing.ps1

<in the file alldecks-20230728T223334.txt> (files are timestamped)
Deck:  Destroy
- BuckyBarnes
- Carnage
- Deadpool
- Death
- Deathlok
- Killmonger
- Knull
- Nova
- Sabretooth
- Yondu
eyJDYXJkcyI6W3siQ2FyZERlZklkIjoiQnVja3lCYXJuZXMifSx7IkNhcmREZWZJZCI6IkNhcm5hZ2UifSx7IkNhcmREZWZJZCI6IkRlYWRwb29sIn0seyJDYXJkRGVmSWQiOiJEZWF0aCJ9LHsiQ2FyZERlZklkIjoiRGVhdGhsb2sifSx7IkNhcmREZWZJZCI6IktpbGxtb25nZXIifSx7IkNhcmREZWZJZCI6IktudWxsIn0seyJDYXJkRGVmSWQiOiJOb3ZhIn0seyJDYXJkRGVmSWQiOiJTYWJyZXRvb3RoIn0seyJDYXJkRGVmSWQiOiJWZW5vbSJ9LHsiQ2FyZERlZklkIjoiV29sdmVyaW5lIn0seyJDYXJkRGVmSWQiOiJZb25kdSJ9XX0=


Deck:  HEJaneJaw
- AmericaChavez
- DrDoom
- Dracula
- HighEvolutionary
- Hulk
- Infinaut
- JaneFoster
- Jubilee
- Lockjaw
- Odin
- Thor
- Wasp
eyJDYXJkcyI6W3siQ2FyZERlZklkIjoiQW1lcmljYUNoYXZleiJ9LHsiQ2FyZERlZklkIjoiRHJEb29tIn0seyJDYXJkRGVmSWQiOiJEcmFjdWxhIn0seyJDYXJkRGVmSWQiOiJIaWdoRXZvbHV0aW9uYXJ5In0seyJDYXJkRGVmSWQiOiJIdWxrIn0seyJDYXJkRGVmSWQiOiJJbmZpbmF1dCJ9LHsiQ2FyZERlZklkIjoiSmFuZUZvc3RlciJ9LHsiQ2FyZERlZklkIjoiSnViaWxlZSJ9LHsiQ2FyZERlZklkIjoiTG9ja2phdyJ9LHsiQ2FyZERlZklkIjoiT2RpbiJ9LHsiQ2FyZERlZklkIjoiVGhvciJ9LHsiQ2FyZERlZklkIjoiV2FzcCJ9XX0=

...the rest of your decks here ...

```

## Export-DecksAsHtml.ps1

### What this script does.

Powershell script to export your decks to an html file, including names and the serialized string for importing into snap.  This is a basic "backup" script or a way to share all your decks and view them as a web page.

### How does it work?

This script looks at only your local files.  It does not send or receive data from any server.

The file it looks at is:

* '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod\CollectionState.json'

CollectionState.json is parsed to identify your decks and cards.

Using these values, it creates a json representation of the deck and seriailzes it to a string that you can paste into Snap.

### Example

```
PS > .\Export-DecksAsHtml.ps1
```

## Export-DecksAsHtmlAdvanced.ps1

### What this script does.

Powershell script to export your decks to an html file, including names and the serialized string for importing into snap.  This is a basic "backup" script or a way to share all your decks and view them as a web page.  This template includes a copy button and formatted html.

### How does it work?

This script looks at only your local files.  It does not send or receive data from any server.

The file it looks at is:

* '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod\CollectionState.json'

CollectionState.json is parsed to identify your decks and cards.

Using these values, it creates a json representation of the deck and seriailzes it to a string that you can paste into Snap.

### Example

```
PS > .\Export-DecksAsHtmlAdvanced.ps1
```

## Limitations

The ShopState.json and possibly CollectionState.json files are only updated after you play a game in Marvel Snap.  So, you will upgrade your cards and rerunning the script will not refresh the data.  Play a game first, then it will update.  I just go through the list until I run out of credits, but I'm not the best min/max player out there.

## Why Powershell

I build this on a windows machine and wanted to have the lowest barier to entry.  There is no magic here and the script is tiny.  This could easily be node, python or any other language.  Also, I am not the best Powersheller out there so this script might not be up to your standards.

## Warning

I use these scripts.  You are welcome to use them at your own risk.  Validate all output before you trust it.

