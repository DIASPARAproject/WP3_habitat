# launch in powershell


$pathccmsource = "D:\eda\countries"
$pathccmout = "D:\eda\countries"

$namefile = "ne_10m_admin_0_countries"
cd $pathccmsource
curl -o "$namefile.zip" "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/ne_10m_admin_0_countries/exports/shp?lang=fr&timezone=Europe%2FBerlin"
Expand-Archive "$namefile.zip" -DestinationPath "$pathccmout"
