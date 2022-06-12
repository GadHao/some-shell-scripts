function Get-LocalLizationText {
    $allFiles = Get-ChildItem -Recurse -File -Filter '*.cs' | Where-Object { ($_.FullName -notlike '*\obj\*') -and ($_.FullName -notlike '*\bin\*') };

    foreach ($file in $allFiles) {
        $result = @()
        Select-String -Pattern 'localizer\["(.+)"\]' -AllMatches -Path $file.FullName |
        ForEach-Object {
            if ($_.Matches.Groups[1].Value) {
                $result += $_.Matches.Groups[1].Value
            }
        }

        $result = $result | Sort-Object | Get-Unique
    }
    
    $result -join "`r`n" | Set-Clipboard
}

function Get-LocalLizationSQL {
    $translatedText = Get-Clipboard
    $translatedItems = $translatedText -split "`r`n"
    $result = ''
    foreach ($item in $translatedItems) {
        $value = $item.Replace("'", "''")
        $result += "INSERT OR IGNORE INTO LocalizationRecords(Key, ResourceKey, Text, LocalizationCulture, UpdatedTimestamp) VALUES('', '', '$value', 'en-US', '$((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss.fffffff"))');`r`n"
    }
    
    $result | Set-Clipboard
}