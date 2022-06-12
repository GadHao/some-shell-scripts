function Get-LocalLizationSQL {
    $allFiles = Get-ChildItem -Recurse -File -Filter '*.cs' | Where-Object { ($_.FullName -notlike '*\obj\*') -and ($_.FullName -notlike '*\bin\*') };

    foreach ($file in $allFiles) {
        $result = ""
        Select-String -Pattern 'localizer\["(.+)"\]' -AllMatches -Path $file.FullName |
        ForEach-Object {
            if ($_.Matches.Groups[1].Value) {
                $result += $_.Matches.Groups[1].Value
            }
        }
    }
    
    $result
}