nohup beacon-chain \
  --chain-id=1658 \
  --network-id=1658 \
  --datadir=$PWD/data/prysm \
  --execution-endpoint=http://127.0.0.1:8551 \
  --checkpoint-sync-url=http://159.138.146.42:3500 \
  --rpc-host=0.0.0.0 \
  --rpc-port=4000 \
  --http-host=0.0.0.0 \
  --http-cors-domain=* \
  --http-port=3500 \
  --p2p-tcp-port=13000 \
  --p2p-udp-port=12000 \
  --p2p-quic-port=13000 \

  --min-sync-peers=0 \
  --p2p-max-peers=50 \
  --verbosity=debug \
  --slots-per-archive-point=32 \
  --suggested-fee-recipient=0x6318BC08F350835f8b2e2A542f04e2aB129Ab5C4 \
  --jwt-secret=$PWD/secret/jwt.hex \
  --disable-monitoring=false \
  --monitoring-host=0.0.0.0 \
  --monitoring-port=8080 \
  --accept-terms-of-use=true \
  --no-discovery=true \
  --pprof \
  --pprofaddr=0.0.0.0 \
  --pprofport=6060 \
  --p2p-static-id=true \
  --chain-config-file=$PWD/network/config.yaml \
  --genesis-state=$PWD/network/genesis.ssz \
  --contract-deployment-block=0 \
  --peer=/ip4/159.138.146.42/tcp/13000/p2p/16Uiu2HAmBR5zeE1NM3xeX6GjehfzTCjyiudP1Mt9E3txdRbLGic1 \
  --peer=/ip4/94.74.101.69/tcp/13000/p2p/16Uiu2HAkwWqnYq4MqTgvWDXNjXy18hvz1CStpnUmNPuzp3Kdhxx6 \
  > $PWD/logs/beacon.log 2>&1 &

# --no-discovery=false \
 # --p2p-no-discovery=true \
