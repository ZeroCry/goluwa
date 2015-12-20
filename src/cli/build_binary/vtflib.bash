#!/bin/bash

cd ../../../data/bin
mkdir src
cd src

git clone https://github.com/panzi/VTFLib
cd VTFLib

mkdir build
cd build
cmake ..

mv src/libVTFLib13.so ../../../linux_x64/libVTFlib.so