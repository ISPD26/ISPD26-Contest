#!/bin/bash

source /opt/conda/etc/profile.d/conda.sh
source /opt/conda/etc/profile.d/mamba.sh
mamba activate probC_env

pip uninstall -y torch torchvision torchaudio torchtext torchdata || true
pip install --upgrade --index-url https://download.pytorch.org/whl/cu118 torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2

make clean
make
find ./bin -type f -exec chmod +x {} +


apt update
DEBIAN_FRONTEND=noninteractive apt install -y libpython3.8 libqt5charts5 libqt5core5a libqt5gui5 libqt5widgets5 libtcl8.6 tcl-tclreadline
apt install ./extpkgs/openroad_2.0_amd64-ubuntu-20.04.deb

cd extpkgs/
cd DREAMPlace/
pip install -r requirements.txt
conda install -y conda-forge::bison
mkdir build
cd build 
cmake .. -DCMAKE_INSTALL_PREFIX=$(readlink -f $PWD/../../DREAMPlace_install) -DPython_EXECUTABLE=$(which python3)
make -j$(nproc)
make install
find . -name "*.sh" -type f -exec chmod +x {} +