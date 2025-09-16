#!/usr/bin/env bash
set -euo pipefail

# === 可调参数（也支持用环境变量覆盖） ===
COUNT="${COUNT:-5}"                                   # 需要生成的节点数量
OUTDIR="${OUTDIR:-../config/peerid-batch}"                    # 输出目录
CONFIG="${CONFIG:-../network/config.yaml}"     # 链配置
GENESIS="${GENESIS:-../network/genesis.ssz}"   # 创世 state
HOST_IP="${HOST_IP:-127.0.0.1}"                       # 仅用于临时启动（对 PeerID 无影响）

# 端口基值（避免冲突即可；仅用于临时启动）
BASE_HTTP="${BASE_HTTP:-3500}"
BASE_TCP="${BASE_TCP:-13000}"
BASE_UDP="${BASE_UDP:-12000}"
BASE_QUIC="${BASE_QUIC:-13000}"

# 是否打包 datadir（1=打包为 tgz；0=保留原目录）
PACK="${PACK:-0}"

command -v curl >/dev/null || { echo "need: curl"; exit 1; }
command -v jq   >/dev/null || { echo "need: jq";   exit 1; }

mkdir -p "$OUTDIR"
CSV="$OUTDIR/peerids.csv"
: > "$CSV"
echo "index,peer_id,datadir,enr,http_port,p2p_tcp,p2p_udp,p2p_quic" >> "$CSV"

for i in $(seq 1 "$COUNT"); do
  DATADIR="$OUTDIR/node$i"
  mkdir -p "$DATADIR"

  HTTP_PORT=$((BASE_HTTP + i - 1))
  TCP_PORT=$((BASE_TCP + i - 1))
  UDP_PORT=$((BASE_UDP + i - 1))
  QUIC_PORT=$((BASE_QUIC + i - 1))

  LOG="$DATADIR/start.log"
  echo "[*] generating node$i (http:$HTTP_PORT tcp:$TCP_PORT udp:$UDP_PORT quic:$QUIC_PORT)..."

  beacon-chain \
    --accept-terms-of-use=true \
    --datadir="$DATADIR" \
    --p2p-static-id=true \
    --p2p-host-ip="$HOST_IP" \
    --p2p-tcp-port="$TCP_PORT" \
    --p2p-udp-port="$UDP_PORT" \
    --p2p-quic-port="$QUIC_PORT" \
    --min-sync-peers=0 \
    --http-host=127.0.0.1 --http-port="$HTTP_PORT" \
    --disable-monitoring=true \
    --verbosity=error \
    --chain-config-file="$CONFIG" \
    --genesis-state="$GENESIS" \
    >"$LOG" 2>&1 &

  PID=$!

  # 等 HTTP 就绪
  ready=0
  for t in $(seq 1 100); do
    if curl -fsS "http://127.0.0.1:$HTTP_PORT/eth/v1/node/identity" >/dev/null 2>&1; then
      ready=1; break
    fi
    sleep 0.1
  done
  if [[ $ready -ne 1 ]]; then
    echo "[-] node$i http not ready; see $LOG" >&2
    kill "$PID" >/dev/null 2>&1 || true
    wait "$PID" 2>/dev/null || true
    exit 1
  fi

  ID_JSON=$(curl -fsS "http://127.0.0.1:$HTTP_PORT/eth/v1/node/identity")
  PEER_ID=$(echo "$ID_JSON" | jq -r '.data.peer_id')
  ENR=$(echo "$ID_JSON" | jq -r '.data.enr')

  echo "$i,$PEER_ID,$DATADIR,$ENR,$HTTP_PORT,$TCP_PORT,$UDP_PORT,$QUIC_PORT" >> "$CSV"
  echo "    -> $PEER_ID"

  # 关进程
  kill "$PID" >/dev/null 2>&1 || true
  wait "$PID" 2>/dev/null || true

  # 可选：把 datadir 打包，方便分发
  if [[ "$PACK" == "1" ]]; then
    tar -C "$DATADIR" -czf "$OUTDIR/node$i.tgz" .
    echo "    packed: $OUTDIR/node$i.tgz"
  fi
done

echo
echo "Done. PeerIDs written to: $CSV"
echo "每个节点的私钥在各自 datadir 下的 network-keys/ 中（部署时拷过去即可）"
