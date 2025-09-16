# EXTIP=$(curl -s ifconfig.me)
# EXTIP=$(ip addr show ens5 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
# echo $EXTIP

nohup validator --chain-config-file=$PWD/network/config.yaml \
  --accept-terms-of-use=true \
  --verbosity=debug \
  --datadir=$PWD/data/validator \
  --suggested-fee-recipient=0x6318BC08F350835f8b2e2A542f04e2aB129Ab5C4 \
  --beacon-rest-api-provider=http://127.0.0.1:3500 \
  --disable-monitoring=false \
  --monitoring-host=0.0.0.0 \
  --monitoring-port=8080 \
  --beacon-rpc-provider=127.0.0.1:4000 \
  --wallet-dir=$PWD/wallets/wallet1 \
  --wallet-password-file=$PWD/secret/prysm-password.txt \
  > $PWD/logs/validator.log 2>&1 &
