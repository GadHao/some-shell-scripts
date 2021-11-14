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
        New-Item $ToPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        Get-ChildItem $FromPath -Force | ForEach-Object {
            # avoid the nested pipeline variable
            $item = $_
            $target_path = Join-Path $ToPath $item.Name
            if (($Exclude | ForEach-Object { $item.Name -like $_ }) -notcontains $true) {
                if (Test-Path $target_path) { Remove-Item $target_path -Recurse -Force }
                Copy-Item $item.FullName $target_path
                Copy-Folder -FromPath $item.FullName $target_path $Exclude
            }
        }
    }
}