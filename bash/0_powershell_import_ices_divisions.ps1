# launch in powershell

# ICES_areas
# ICES_ecoregions

[String[]]$files = "areas","ecoregions"
md "D:\eda\ices"
$pathccmsource = "D:\eda\ices"
#$pathccmout = "D:\eda\ices\ICES"
foreach ($file in $files){
Write-Output $file
$namefile = "ICES_$file"
$schema = "ICES_$file"
cd $pathccmsource
curl -o "$namefile.zip" https://gis.ices.dk/shapefiles/$namefile.zip
$destination = Join-Path -Path $pathccmsource -ChildPath $namefile
if (-not (Test-Path -Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}
Expand-Archive "$namefile.zip" -DestinationPath "$destination"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "DROP SCHEMA IF EXISTS $schema CASCADE; CREATE SCHEMA $schema;"
}

