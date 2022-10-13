#!/bin/zsh -e

occ_all_tiles=()
occ_t1_tiles=()
occ_t6_tiles=()
bg_light_tiles=()
bg_dark_tiles=()
bg_classic_tiles=()

mkdir -p t

if [[ -s t/all_0_0.png ]]; then
    echo "Map tiles present"
else
    z=0
    for x in 0 1; do
        for y in 0; do
            wget --no-clobber -O t/all_${x}_${y}.png "http://api.gbif.org/v2/map/occurrence/density/0/${x}/${y}@4x.png?style=green.point&srs=EPSG%3A4326"
            occ_all_tiles+=t/all_${x}_${y}.png

            wget --no-clobber -O t/occ1_${x}_${y}.png "http://api.gbif.org/v2/map/occurrence/density/0/${x}/${y}@4x.png?style=classic.point&srs=EPSG%3A4326&taxonKey=1"
            occ_t1_tiles+=t/occ1_${x}_${y}.png

            wget --no-clobber -O t/occ6_${x}_${y}.png "http://api.gbif.org/v2/map/occurrence/density/0/${x}/${y}@4x.png?style=purpleYellow.point&srs=EPSG%3A4326&taxonKey=6"
            occ_t6_tiles+=t/occ6_${x}_${y}.png

		    wget --no-clobber -O t/bg_light_${x}_${y}.png "http://tile.gbif.org/4326/omt/${z}/${x}/${y}@4x.png?style=gbif-light"
            bg_light_tiles+=t/bg_light_${x}_${y}.png

		    wget --no-clobber -O t/bg_dark_${x}_${y}.png "http://tile.gbif.org/4326/omt/${z}/${x}/${y}@4x.png?style=gbif-dark"
            bg_dark_tiles+=t/bg_dark_${x}_${y}.png

		    wget --no-clobber -O t/bg_classic_${x}_${y}.png "http://tile.gbif.org/4326/omt/${z}/${x}/${y}@4x.png?style=gbif-classic"
            bg_classic_tiles+=t/bg_classic_${x}_${y}.png
        done
    done
fi

[[ -s occurrences_all.png ]] || montage $occ_all_tiles -geometry +0+0 -tile 2x1 -background none occurrences_all.png
[[ -s occurrences_t1.png ]] || montage $occ_t1_tiles -geometry +0+0 -tile 2x1 -background none occurrences_t1.png
[[ -s occurrences_t6.png ]] || montage $occ_t6_tiles -geometry +0+0 -tile 2x1 -background none occurrences_t6.png
[[ -s basemap_light.png ]] || montage $bg_light_tiles -geometry +0+0 -tile 2x1 -background none basemap_light.png
[[ -s basemap_dark.png ]] || montage $bg_dark_tiles -geometry +0+0 -tile 2x1 -background none basemap_dark.png
[[ -s basemap_classic.png ]] || montage $bg_classic_tiles -geometry +0+0 -tile 2x1 -background none basemap_classic.png

[[ -s big_marble_21600.jpg ]] || wget --no-clobber -O big_marble_21600.jpg 'https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73801/world.topo.bathy.200409.3x21600x10800.jpg'
[[ -s marble.png ]] || convert -strip big_marble_21600.jpg -resize 8192x4096 marble.png
[[ -s big_marble_5400.png ]] || wget --no-clobber -O big_marble_5400.png 'https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73909/world.topo.bathy.200412.3x5400x2700.png'
[[ -s marble_sm.png ]] || convert -strip big_marble_21600.jpg -resize 4096x2048 marble_sm.png

[[ -s gbif_marble_all.png ]] || composite -gravity center occurrences_all.png marble_sm.png gbif_marble_all.png
[[ -s gbif_classic_t1.png ]] || composite -gravity center occurrences_t1.png basemap_classic.png gbif_classic_t1.png
[[ -s gbif_dark_t6.png ]] || composite -gravity center occurrences_t6.png basemap_dark.png gbif_dark_t6.png

# Note an indexed PNG won't work!
# docker build -t docker.gbif.org/gbif-dymax:latest .
# docker push docker.gbif.org/gbif-dymax:latest
for i in gbif_marble_all.png gbif_classic_t1.png gbif_dark_t6.png marble_sm.png; do
    [[ -s dymax_$i ]] || docker run -it --rm -v $PWD:/usr/src/app docker.gbif.org/gbif-dymax $i dymax_$i
done
