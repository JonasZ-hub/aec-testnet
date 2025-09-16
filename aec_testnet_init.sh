chmod a+x ./script/data_processing.sh
./script/data_processing.sh all --keep-prysm network-keys
erigon init --datadir=$PWD/data/erigon/ $PWD/network/genesis.json
