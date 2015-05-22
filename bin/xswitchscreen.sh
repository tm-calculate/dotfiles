#!/bin/bash
eval $(xdotool getmouselocation --shell)

if [[ ${X} -lt 1680 ]]; then
  xdotool mousemove 1900 1000
  echo '*' | osd_cat -p bottom -i 1700 -d 1 -c red -f -misc-fixed-medium-r-normal--60-0-100-100-c-0-koi8-r -s 1
else
  xdotool mousemove 1420 1000
  echo '*' | osd_cat -p bottom -i 1600 -d 1 -c red -f -misc-fixed-medium-r-normal--60-0-100-100-c-0-koi8-r -s 1
fi