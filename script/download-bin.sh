
mkdir -p /opt/software
cd /opt/software

## erigon

wget https://github.com/erigontech/erigon/releases/download/v3.0.17/erigon_v3.0.17_linux_amd64.tar.gz
tar zxvf erigon_v3.0.17_linux_amd64.tar.gz
cp erigon_v3.0.17_linux_amd64/erigon /usr/local/bin/
which erigon
# /usr/local/bin/erigon 

erigon --version
# erigon version 3.0.17-7d3cab29


## beacon-chain

wget https://github.com/OffchainLabs/prysm/releases/download/v6.0.4/beacon-chain-v6.0.4-linux-amd64
cp beacon-chain-v6.0.4-linux-amd64 /usr/local/bin/beacon-chain
chmod +x /usr/local/bin/beacon-chain

which beacon-chain
# /usr/local/bin/beacon-chain

beacon-chain --version
# beacon-chain version Prysm/v6.0.4/91b44360fcd74bad41f38b79bb3b05094408a2d0. Built at: 2025-06-05 16:21:20+00:00

## beacon-chain
wget https://github.com/OffchainLabs/prysm/releases/download/v6.0.4/validator-v6.0.4-linux-amd64
cp validator-v6.0.4-linux-amd64 /usr/local/bin/validator
chmod +x /usr/local/bin/validator

which validator
# /usr/local/bin/validato

validator --version
# validator version Prysm/v6.0.4/91b44360fcd74bad41f38b79bb3b05094408a2d0. Built at: 2025-06-05 16:21:20+00:00