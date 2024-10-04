# launch in powershell

# 2000 north sea
# 2001 irland
# 2002 italy + adriatic
# 2003 france
# 2004 iberian peninsula
# -[2005 danube]
# -[2006 north black sea]
# 2007 Baltique north, Azov
# 2008 Norvege suede
# 2009 greece + turquiye + albania
# 2010 Canaries
# -[2011 Black sea]
# -[2012 Oural]
# 2013 Volga [Keep only North]
# 2015 Azores
# 2016 Shetlands Faeroes
# 2017 tigris Euphrate [keep only mediterranean]
# 2018 Iceland

[String[]]$windows = "2000","2001","2002","2003","2004","2007","2008","2009","2010","2013","2015","2016","2017","2018"
$pathccmsource = "D:\eda\ccm21"
$pathccmout = "D:\eda\"
foreach ($window in $windows){
Write-Output $window
$namefile = "CCM21_WGS84_window$window"
$schema="w$window"
cd $pathccmsource
curl -o "$namefile.zip" https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/DROUGHTOBS/Hydrology_datasets/CCM2/$namefile
Expand-Archive "$namefile.zip" -DestinationPath "$pathccmout"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "DROP SCHEMA IF EXISTS $schema CASCADE; CREATE SCHEMA $schema;"
}


# Overview riverbasins only available 3035

$pathccmsource = "D:\eda\ccm21"
$pathccmout = "D:\eda\"
$path = "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/DROUGHTOBS/Hydrology_datasets/CCM2/CCM21_LAEA_RiverBasins.zip"
$namefile = "CCM21_LAEA_RiverBasins"
$schema="ccm21"
cd $pathccmsource
curl -o "$namefile.zip" $path
Expand-Archive "$namefile.zip" -DestinationPath "$pathccmout"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "DROP SCHEMA IF EXISTS $schema CASCADE; CREATE SCHEMA $schema;"


# Lakes