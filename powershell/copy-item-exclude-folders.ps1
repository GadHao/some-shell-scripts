function Copy-Folder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$FromPath,

        [Parameter(Mandatory)]
        [String]$ToPath
    )

    if (!(Test-Path $FromPath)) {
        Write-Error 'The FromPath is not exist'
        exit 1
    }
}