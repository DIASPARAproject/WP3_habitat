# launch in powershell


$pathccmsource = "D:\eda\countries"
$pathccmout = "D:\eda\countries"

$namefile = "country_shapes"
cd $pathccmsource
curl -o "$namefile.zip" "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/country_shapes/exports/shp?lang=fr&timezone=Europe%2FBerlin"
Expand-Archive "$namefile.zip" -DestinationPath "$pathccmout"
