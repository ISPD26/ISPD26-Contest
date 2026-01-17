apt-get -y update
apt-get -y install git build-essential gcc g++ wget make time x11-apps vim nano sxiv python3-pip clangd-20
pip install pyaml

mkdir -p /opt/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /opt/miniconda3/miniconda.sh
bash /opt/miniconda3/miniconda.sh -b -u -p /opt/miniconda3

cd opt
wget  "https://www.klayout.org/downloads/Ubuntu-24/klayout_0.30.4-1_amd64.deb" -O klayout.deb

apt-get -y install ./klayout.deb

wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2025-09-26/oss-cad-suite-linux-x64-20250926.tgz -O oss-cad-suite.tgz
tar -xvzf oss-cad-suite.tgz
rm oss-cad-suite.tgz


# GitHub CLI

(type -p wget >/dev/null || ( apt update &&  apt-get install wget -y)) \
	&&  mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out |  tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&&  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |  tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&&  apt update \
	&&  apt install gh -y

cd /
git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git
cd OpenROAD-flow-scripts
git reset --hard 26b521c49218eb10f4274d782e420cdc824adbc3

cd /
git clone https://github.com/sakundu/OpenROAD.git
cd OpenROAD
git reset --hard  b84a4ac3ae1731dccb0fc991410038f91a50af83
git submodule update --init --recursive
