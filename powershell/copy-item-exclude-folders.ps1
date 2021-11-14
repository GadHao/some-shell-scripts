function Copy-Folder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$FromPath,

        [Parameter(Mandatory)]
        [String]$ToPath,

        [string[]] $Exclude
    )

    if (Test-Path $FromPath -PathType Container) {
        Get-ChildItem $FromPath -Force | ForEach-Object { 
            $target_path = Join-Path $ToPath $_.Name
            if ($_.Name -notin $Exclude) {
                Copy-Item $_.FullName $target_path -ErrorAction SilentlyContinue
                Copy-Folder -FromPath $_.FullName $target_path $Exclude
            }
        }
    }
}