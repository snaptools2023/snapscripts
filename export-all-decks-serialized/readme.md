# export-all-decks-serialized.ps1

## What this script does.

Powershell script to export all of your decks to a text file, including names and the serialized string for importing into snap.  This is a basic "backup" script.

## How does it work?

This script looks at only your local files.  It does not send or receive data from any server.

The file it looks at is:

* '\AppData\LocalLow\Second Dinner\SNAP\Standalone\States\nvprod\CollectionState.json'

CollectionState.json is parsed to identify your decks and cards.

Using these values, it creates a json representation of the deck and seriailzes it to a string that you can paste into Snap.

## Example

```
PS > cd .\export-all-decks-serialized\
PS > .\export-all-decks-serialized.ps1

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

# Limitations

The CollectionState.json files are only updated after you play a game in Marvel Snap.  So, you will upgrade your cards and rerunning the script will not refresh the data.

# Why Powershell

I build this on a windows machine and wanted to have the lowest barier to entry.  There is no magic here and the script is tiny.  This could easily be node, python or any other language.  Also, I am not the best Powersheller out there so this script might not be up to your standards.

I have not tested this on any other platforms and it works on my machine.

# Warning

I use this script.  You are welcome to use it at your own risk.  Validate the output before you delete your decks.
