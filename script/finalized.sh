curl -s http://159.138.146.42:3500/eth/v1/beacon/headers/finalized

curl -s http://159.138.146.42:3500/eth/v1/beacon/states/head/finality_checkpoints

curl -s http://94.74.101.69:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}'

curl -s http://159.138.146.42:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}'

curl -s http://159.138.9.39:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}'
