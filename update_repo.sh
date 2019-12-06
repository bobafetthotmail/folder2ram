#!/bin/sh
cd debian_package
dpkg-buildpackage -tc --no-sign
cd ..
mv folder2ram_* debian_repo
cd debian_repo
dpkg-scanpackages -m . | gzip --fast > Packages.gz
