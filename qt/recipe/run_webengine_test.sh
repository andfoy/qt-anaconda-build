#!/bin/bash

set -e

ls
cd test/webengine
ln -s ${GXX} g++
export PATH=$PREFIX/bin/xc-avoidance:${PWD}:${PATH}
# Only test that this builds
qmake qtwebengine.pro
make
