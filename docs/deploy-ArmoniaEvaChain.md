## 创建Nodekey
具体内容阅读[create_nodekey.txt]
按部署的节点数量生成，nodekey的作用是保证erigon的enode地址的唯一和不变，enode是节点的唯一标识符，用于在P2P网络中进行通信和身份验证。每个节点的enode地址由nodekey生成，格式为enode://<public_key>@<ip_address>:<port>，其中public_key是nodekey的公钥，ip_address是节点的IP地址，port是节点的端口号。

## 创建peerID
具体内容阅读[create_peerID.txt]
peerID是共识层prysm的唯一标识符，用于在P2P网络中进行通信和身份验证。也是按部署的节点数量生成，生成peerID与节点匹配，不能重复使用
'''
note:保证peerID不变要将network-keys拷贝到/eva-testnet/prysm/beacon-data/下，即使要清理数据，也不要删除network-keys
'''

## 创建验证和地址
阅读wallet-import.txt和gensis.txt,并且了解deposit的安装和使用，生成的地址数量需要添加到network-configs/mnemonics.yaml的count，使用的助记词添加到mnemonic字段
需要按索引使用deposit生成对应的秘钥，例如validater_keys,由于我们是直接写入到创世信息里，所以deposit_data.......这个文件暂时不用,按需要的节点数量将keystore文件拷贝到类似keys-one目录下，使用validator转成wallets-one
'''
note:有链需要验证者在线数量要满足大于总数的2/3，创世节点生成的区块才能验证通过，后续节点才能同步，所以给创世节点分配的秘钥数量要大于总数的2/3
'''

## 生成创世信息
创世文件在network-configs下，genesis.json和config.yaml,除了链ID修改，其他参数可根据需求改动
阅读genesis.txt，使用eth-genesis-state-generator生成genesis.ssz

## 启动创世节点
'''
cd aec-testnet/
./aec_testnet_init.sh
./start_erigon1.sh
./start_beacon1.sh
./start_validator1.sh
'''
start_erigon1.sh脚本里的--staticpeers和--trustedpeers里面的enode需要根据你生成的来提供
start_beacon1.sh脚本里--peer参数也需要根据peerid-batch里的提供
目前已配置了三个节点的参数，修改对应的ip后，可直接启动
创世节点启动后需要等待一段时间后开始出块，出块后读取finalized，返回非0值在往下执行

## 启动其他节点
'''
cd aec-testnet/
./aec_testnet_init.sh
./start_erigon2.sh
./start_beacon2.sh
./start_validator2.sh
'''
start_erigon0.sh和start_erigon2.sh都是其他节点的启动脚本，主要是--staticpeers和--trustedpeers得值，要配置已知的节点地址
erigon启动后等到打印[p2p] GoodPeers     eth68=2在往下执行，否则从头开始
