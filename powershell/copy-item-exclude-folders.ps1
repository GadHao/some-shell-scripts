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
            $item = $_
            $target_path = Join-Path $ToPath $item.Name
            if (($Exclude | ForEach-Object { $item.Name -like $_ }) -notcontains $true) {
                Copy-Item $item.FullName $target_path -ErrorAction SilentlyContinue
                Copy-Folder -FromPath $item.FullName $target_path $Exclude
            }
        }
    }
}