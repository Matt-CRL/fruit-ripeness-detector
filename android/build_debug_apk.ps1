$env:JAVA_HOME = 'D:\Android\Studio\jbr'
$config = Get-Content -Raw ..\config\dev.json | ConvertFrom-Json
$dartDefines = (($config.PSObject.Properties | ForEach-Object {
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($_.Name)=$($_.Value)"))
}) -join ',')

.\gradlew.bat assembleDebug --no-daemon "-Pdart-defines=$dartDefines"
