# launch in powershell

# Basin 20082137
# River 20087321
# Lake 35959544

[String[]]$files = "20082137","20087321","35959544"
[String[]]$atlas = "Basin","River","Lake"
$pathccmsource = "D:\eda\hydroatlas"
$pathccmout = "D:\eda\"

for ($i = 0; $i -lt $files.Length; $i++) {
    $file = $files[$i]
    $atlasName = $atlas[$i]

    Write-Output "Downloading "$atlasName""ATLAS""

    $namefile = "$atlasName" + "ATLAS_Data_v10.gdb"
    $schema = "$atlasName" + "ATLAS"

    cd $pathccmsource

    curl -o "$namefile.zip" "https://figshare.com/ndownloader/files/$file"

    Expand-Archive "$namefile.zip" -DestinationPath "$pathccmout"

    psql --dbname="postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara" -c "DROP SCHEMA IF EXISTS $schema CASCADE; CREATE SCHEMA $schema;"
}
