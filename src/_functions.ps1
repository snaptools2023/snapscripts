
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

function Get-CardsFromInternet() {
	return Get-FileFromCacheOrInternet -type "cards.json" -url "https://static2.marvelsnap.pro/snap/do.php?cmd=getcards" -maximumCacheAgeInDays 5 # download a copy of the cards database from marvelsnappro - todo, add this to readme
}

function Get-CardFromInternet($cardDefId) {
	return Get-FileFromCacheOrInternet -type "$cardDefId.webp" -url "https://static.marvelsnap.pro/cards/$cardDefId.webp" -maximumCacheAgeInDays 30 # download a copy of the cards database from marvelsnappro - todo, add this to readme
}

function Get-FileFromCacheOrInternet($type, $url, $maximumCacheAgeInDays) {
	$path = $MyInvocation.ScriptName
	$path = Split-Path $path -Parent
	$path = Join-Path $path "_cache\$type" # todo:  windows only here. fix this later

	$needToDownload = $false

	# if the file exists
	if ([System.IO.File]::Exists($path)) {
		$lastWrite = (get-item $path).LastWriteTime
		$timespan = new-timespan -days $maximumCacheAgeInDays

		if (((get-date) - $lastWrite) -gt $timespan) {

			# we have a stale copy of the file in cache - delete it and redownload
			Remove-Item $path
			$needToDownload = $true
		} else {
			# we have a good copy of the cards file in the cache - no need to download
		}
	} else { # else download the file
		$needToDownload = $true
	}

	if ($true -eq $needToDownload) {
		Invoke-WebRequest -Uri $url -OutFile $path
	}

	$returnObject = Get-Content -Path $path -Raw | ConvertFrom-Json

	return $returnObject
}
