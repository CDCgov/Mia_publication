#!/usr/bin/bash
ROOT=$(readlink -f $(dirname $0) | rev | cut -d '/' -f 2- | rev)
printf "[Desktop Entry]
Name=MIA
Exec=R -e \"shiny::runApp('${ROOT}/scripts/MIA.R', launch.browser=TRUE)\"
Terminal=false
Type=Application
Icon=${ROOT}/images/ateam1-50scalevan1.1498553615.png" > ~/Desktop/MIA.desktop
