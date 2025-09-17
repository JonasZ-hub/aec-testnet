#!/usr/bin/env bash
set -euo pipefail

# 需要停止的进程名（与 `ps` 中的 COMMAND 名精确一致）
PROCS=(erigon beacon-chain validator)

# 优雅退出的等待秒数
GRACE=8

for p in "${PROCS[@]}"; do
  echo ">>> stopping $p ..."
  # 先尝试优雅停止：精确匹配进程名
  if pkill -x "$p" 2>/dev/null; then
    # 等待直到退出或超时
    for i in $(seq 1 "$GRACE"); do
      if pgrep -x "$p" >/dev/null; then
        sleep 1
      else
        break
      fi
    done
    # 若仍在，强制结束
    if pgrep -x "$p" >/dev/null; then
      echo "!!! $p did not exit after ${GRACE}s, sending KILL"
      pkill -x -9 "$p" || true
    fi
    echo ">>> $p stopped."
  else
    echo "=== $p not running."
  fi
done

echo "All done."
