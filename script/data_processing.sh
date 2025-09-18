#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${PWD}"
ERIGON_DIR="${BASE_DIR}/data/erigon/"
PRYSM_DIR="${BASE_DIR}/data/beacon/"
VALIDATOR_DIR="${BASE_DIR}/data/validator"

# 1) 确保目录存在
mkdir -p "${ERIGON_DIR}" "${PRYSM_DIR}" "${VALIDATOR_DIR}"

usage() {
  cat <<EOF
用法: $0 [erigon|prysm|all|<目录路径>] [--keep-prysm <文件或目录>]...

无参数：只检查/创建目录后结束。
参数说明：
  erigon            清空 ${ERIGON_DIR}
  prysm             清空 ${PRYSM_DIR}（可用 --keep-prysm 指定保留项）
  all               同时清空上述两个目录（--keep-prysm 作用于 prysm 目录）
  <目录路径>        清空指定目录（不带保留项）

可选项：
  --keep-prysm X    清空 prysm 时保留 X（可多次传入）。X 可为相对 prysm 目录的名称或绝对路径。

示例：
  $0                         # 只初始化目录
  $0 prysm --keep-prysm jwt.hex
  $0 all --keep-prysm jwt.hex
EOF
}

# 清空目录内容（保留目录本身）
clear_dir() {
  local d="$1"
  if [[ -z "${d}" || "${d}" = "/" ]]; then
    echo "危险：拒绝对根目录或空路径执行清空操作。" >&2
    exit 1
  fi
  [[ -d "${d}" ]] || { echo "目录不存在：${d}" >&2; exit 1; }

  find "${d}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  echo "已清空目录：${d}"
}

# 清空目录但保留某些顶层条目（文件或子目录）
clear_dir_with_keep() {
  local d="$1"; shift || true
  if [[ -z "${d}" || "${d}" = "/" ]]; then
    echo "危险：拒绝对根目录或空路径执行清空操作。" >&2
    exit 1
  fi
  [[ -d "${d}" ]] || { echo "目录不存在：${d}" >&2; exit 1; }

  # 构造 find 过滤：! \( -path keep1 -o -path keep2 ... \)
  local -a find_args=( "${d}" -mindepth 1 -maxdepth 1 )
  if [[ $# -gt 0 ]]; then
    find_args+=( '!' '(' )
    local first=1
    for keep in "$@"; do
      # 相对路径转绝对路径
      if [[ "${keep}" != /* ]]; then
        keep="${d%/}/${keep}"
      fi
      if [[ ${first} -eq 0 ]]; then find_args+=( -o ); fi
      find_args+=( -path "${keep}" )
      first=0
    done
    find_args+=( ')' )
  fi

  find "${find_args[@]}" -exec rm -rf -- {} +
  echo "已清空目录（保留：$*）：${d}"
}

# 解析参数
PRYSM_KEEP=()
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    erigon|prysm|all)
      TARGET="$1"; shift ;;
    --keep-prysm)
      [[ $# -ge 2 ]] || { echo "缺少 --keep-prysm 的参数"; usage; exit 1; }
      PRYSM_KEEP+=( "$2" ); shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    /*|./*|../*)
      TARGET="$1"; shift ;;
    *)
      # 未知参数：给出帮助
      echo "未知参数：$1"; usage; exit 1 ;;
  esac
done

# 无参数：只创建目录并退出
if [[ -z "${TARGET}" ]]; then
  echo "目录已检查/创建："
  echo "  - ${ERIGON_DIR}"
  echo "  - ${PRYSM_DIR}"
  echo "未指定清理参数，结束。"
  exit 0
fi

# 执行清理
case "${TARGET}" in
  erigon)
    clear_dir "${ERIGON_DIR}"
    ;;
  prysm)
    if [[ ${#PRYSM_KEEP[@]} -gt 0 ]]; then
      clear_dir_with_keep "${PRYSM_DIR}" "${PRYSM_KEEP[@]}"
    else
      clear_dir "${PRYSM_DIR}"
    fi
    ;;
  all)
    clear_dir "${ERIGON_DIR}"
    if [[ ${#PRYSM_KEEP[@]} -gt 0 ]]; then
      clear_dir_with_keep "${PRYSM_DIR}" "${PRYSM_KEEP[@]}"
    else
      clear_dir "${PRYSM_DIR}"
    fi
    clear_dir "${VALIDATOR_DIR}"
    ;;
  *)
    # 任意路径（不支持 keep 选项，需求里只提 prysm）
    clear_dir "${TARGET}"
    ;;
esac
