Set-Location $PSScriptRoot

Write-Verbose "Finding out RAD Studio directory"
$BDSVersion = "22.0"
$BDSDirectory = (Get-ItemProperty `
    -Path "registry::HKEY_CURRENT_USER\SOFTWARE\Embarcadero\BDS\$BDSVersion" `
    -Name RootDir).RootDir
Write-Debug "`$BDSDirectory=$BDSDirectory"

Write-Verbose "Checking if RAD Studio path is correct and there is PAClient in it"
$PAClient=Join-Path -Path $BDSDirectory -ChildPath "bin\paclient.exe"
if(-not $(Test-Path $PAClient)){
    throw -join(
        "Cannot continue - there is no PAClient executable at the path `"$PAClient`".`n",
        "Please check if RAD Studio is installed."
    )
}
Write-Verbose "...ok"

# Assign specific vars based on $PAClient
$PAClientFileInfo = Get-Item $PAClient
$PAClientFileName= -join ($PAClientFileInfo.BaseName, $PAClientFileInfo.Extension)

Write-Verbose "Trying file upload"
Invoke-Expression "$PAClient --host=localhost --put=$PAClient,." > $null
if ((-not $?) -or ($LASTEXITCODE -ne 0)) {
    Write-Verbose "`$LASTEXITCODE = $LASTEXITCODE"
    throw "PAServer does not work - cannot upload file"
}
Write-Verbose "...ok"

Write-Verbose "Trying file download"
Invoke-Expression "$PAClient --host=localhost --get=./$PAClientFilename,." > $null
if (-not $(Test-Path ./$PAClientFilename)) {
    throw "PAServer does not seem to work - cannot download file"
}
Write-Verbose "...ok"

try {
    Write-Verbose "Checking if file is intact"
    if (Compare-Object -ReferenceObject $(Get-Content $PAClient) -DifferenceObject $(Get-Content $PAClientFileName)) {
        throw "PAServer does not seem to work - file downloaded differs from file uploaded"
    }
    Write-Verbose "...ok"

}
finally {
    Remove-Item $PAClientFileName
}

Write-Output "PAServer smoke test passed ok"
exit 0 # just for readability, as exitcode is 0 implicitly