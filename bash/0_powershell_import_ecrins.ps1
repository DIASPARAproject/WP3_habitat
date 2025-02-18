# launch in powershell

# Basin EcrFEC
# River EcrRiv
# Lake 35959544

[String[]]$files = "EcrFEC","EcrRiv"
[String[]]$levels = "fec","rivers"
[String[]]$ecrins = "Basins","Rivers"
$pathccmsource = "D:\eda\ecrins"

for ($i = 0; $i -lt $files.Length; $i++) {
    $file = $files[$i]
    $level = $levels[$i]
    $schemaName = $ecrins[$i]

    Write-Output "Downloading ECRINS "$schemaName""

    $schema = "ECRINS" + "$schemaName"

    cd $pathccmsource

    curl -o "$file.sqlite" "https://sdi.eea.europa.eu/datashare/s/oxF3qK5ZYi8Ae7E/download?path=/eea_v_3035_250_k_ecrins-${level}_p_1990-2006_v01_r00&files=${file}.sqlite"


    psql --dbname="postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara" -c "DROP SCHEMA IF EXISTS $schema CASCADE; CREATE SCHEMA $schema;"
}
