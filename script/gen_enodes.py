#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse
import subprocess
from binascii import hexlify


SECP256K1_N = int("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", 16)

# 选择计算 nodeId 的后端：优先 coincurve，回退 ecdsa
_BACKEND = None
try:
    import coincurve  # type: ignore
    _BACKEND = "coincurve"
except Exception:
    try:
        from ecdsa import SigningKey, SECP256k1  # type: ignore
        _BACKEND = "ecdsa"
    except Exception:
        _BACKEND = None


def ensure_deps():
    if _BACKEND is None:
        print("ERROR: 需要安装 coincurve 或 ecdsa（任选其一）", file=sys.stderr)
        print("       pip install coincurve   或   pip install ecdsa", file=sys.stderr)
        sys.exit(1)
    # 检查 openssl
    try:
        subprocess.run(["openssl", "version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        print("ERROR: 未找到 openssl 命令，请先安装（apt/yum/brew 等）", file=sys.stderr)
        sys.exit(1)


def openssl_rand_hex32() -> str:
    """用 openssl 生成 32 字节随机数（hex，64字符）"""
    r = subprocess.run(["openssl", "rand", "-hex", "32"], check=True, capture_output=True, text=True)
    return r.stdout.strip()


def gen_nodekey_bytes_via_openssl() -> bytes:
    """生成 1 <= k < n 的 nodekey（32字节），确保有效范围"""
    while True:
        h = openssl_rand_hex32()
        if len(h) != 64:
            continue
        try:
            k = int(h, 16)
        except ValueError:
            continue
        if 1 <= k < SECP256K1_N:
            return k.to_bytes(32, "big")


def nodeid_from_nodekey(nodekey: bytes) -> bytes:
    """由 nodekey 推导 nodeId（未压缩公钥去掉 0x04 前缀，长度64字节）"""
    if _BACKEND == "coincurve":
        priv = coincurve.PrivateKey(nodekey)
        uncompressed = priv.public_key.format(compressed=False)  # 65字节：0x04 + X(32) + Y(32)
        return uncompressed[1:]
    # ecdsa 回退
    sk = SigningKey.from_string(nodekey, curve=SECP256k1)
    return sk.verifying_key.to_string()  # 64字节 X||Y


def write_hex(path: str, b: bytes):
    with open(path, "w") as f:
        f.write(hexlify(b).decode())


def parse_csv_list(s: str) -> list[str]:
    return [x.strip() for x in s.split(",") if x.strip()]


def main():
    ap = argparse.ArgumentParser(
        description="用 OpenSSL 生成 nodekey，并用 Python 计算 nodeId；支持为多个 IP 生成 enode"
    )
    ap.add_argument("--ips", default="", help="逗号分隔的 IP 列表，例如: 1.2.3.4,5.6.7.8")
    ap.add_argument("--ips-file", default="", help="纯文本文件，每行一个 IP")
    ap.add_argument("--count", type=int, default=0, help="生成数量（不提供 IP 时必须指定）")
    ap.add_argument("--ports", default="", help="逗号分隔的端口列表，与 IP 一一对应（可选）")
    ap.add_argument("--port-base", type=int, default=30303, help="未显式给端口时（默认 30303）")
    ap.add_argument("--outdir", default="../config/enodes", help="输出目录（默认 ../config/enodes）")
    ap.add_argument("--json", action="store_true", help="额外输出 static-nodes.json")
    ap.add_argument("--csv", action="store_true", help="额外输出 enodes.csv")
    args = ap.parse_args()

    ensure_deps()
    os.makedirs(args.outdir, exist_ok=True)

    ips: list[str] = []
    if args.ips:
        ips.extend(parse_csv_list(args.ips))
    if args.ips_file:
        with open(args.ips_file) as f:
            for line in f:
                line = line.strip()
                if line:
                    ips.append(line)

    if ips:
        n = len(ips)
    else:
        if args.count <= 0:
            print("ERROR: 未提供 IP，请用 --count 指定生成数量；或用 --ips/--ips-file 提供 IP 列表", file=sys.stderr)
            sys.exit(1)
        n = args.count
        # 占位 IP，部署前再替换
        ips = [f"<PUBLIC_IP_{i+1}>" for i in range(n)]

    # 端口
    ports: list[int]
    if args.ports:
        ports = [int(p) for p in parse_csv_list(args.ports)]
        if len(ports) != n:
            print("ERROR: --ports 数量必须与 IP 数量一致", file=sys.stderr)
            sys.exit(1)
    else:
        ports = [args.port_base for i in range(n)]

    enodes = []
    csv_lines = ["index,nodekey_hex,nodeid,enode"]

    print(f"[*] generating {n} nodekeys & enodes...")
    for i in range(n):
        node_dir = os.path.join(args.outdir, f"node{i+1}")
        os.makedirs(node_dir, exist_ok=True)

        # 1) 生成 nodekey（经 openssl + 范围校验）
        nodekey = gen_nodekey_bytes_via_openssl()
        nodekey_hex = hexlify(nodekey).decode()

        # 保存两份
        with open(os.path.join(node_dir, "nodekey"), "wb") as f:
            f.write(nodekey)
        write_hex(os.path.join(node_dir, "nodekey.hex"), nodekey)

        # 2) 计算 nodeId（64字节 hex）
        nodeid_hex = hexlify(nodeid_from_nodekey(nodekey)).decode()

        # 3) 拼 enode
        enode = f"enode://{nodeid_hex}@{ips[i]}:{ports[i]}"
        with open(os.path.join(node_dir, "enode.txt"), "w") as f:
            f.write(enode + "\n")

        enodes.append(enode)
        csv_lines.append(f"{i+1},{nodekey_hex},{nodeid_hex},{enode}")

        print(f"[{i+1}] nodekey={nodekey_hex}")
        print(f"    nodeId={nodeid_hex}")
        print(f"    enode ={enode}")
        print()

    if args.json:
        static_nodes_path = os.path.join(args.outdir, "static-nodes.json")
        with open(static_nodes_path, "w") as f:
            json.dump(enodes, f, indent=2)
        # 也顺便生成 trusted-nodes.json
        trusted_nodes_path = os.path.join(args.outdir, "trusted-nodes.json")
        with open(trusted_nodes_path, "w") as f:
            json.dump(enodes, f, indent=2)
        print(f"static-nodes.json / trusted-nodes.json 写入: {args.outdir}")

    if args.csv:
        csv_path = os.path.join(args.outdir, "enodes.csv")
        with open(csv_path, "w") as f:
            f.write("\n".join(csv_lines) + "\n")
        print(f"CSV 写入: {csv_path}")

    print("完成。每个节点目录包含：nodekey（原始） / nodekey.hex / enode.txt")
    print("部署时：erigon 可用 --nodekey <文件路径>（或 --nodekeyhex <hex>）固定 enode；")
    print("如禁用发现，可把 static-nodes.json 拷到各节点 datadir，互为静态连点。")


if __name__ == "__main__":
    main()
