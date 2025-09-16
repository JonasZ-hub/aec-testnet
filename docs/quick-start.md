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
'''
note:启动创世节点后，要等到curl -s http://159.138.146.42:3500/eth/v1/beacon/headers/finalized返回的slot非0在启动下一个节点
'''
[![finalized](./images/finalized.png)](./images/finalized.png)

## 启动其他节点
'''
cd aec-testnet/
./aec_testnet_init.sh
./start_erigon2.sh
./start_beacon2.sh
./start_validator2.sh
'''
start_erigon0.sh和start_erigon2.sh都是其他节点的启动脚本，主要是--staticpeers和--trustedpeers得值，要配置已知的节点地址

'''
note:在启动erigon后，要查看日志，看到打印有下图，要pkill erigon，重新执行./aec_testnet_init.sh和./start_erigon2.sh
'''
[![no goodpeer](./images/goodpeer.png)](./images/goodpeer.png)
正常出块如图
[![正常执行出块](./images/normal.png)](./images/normal.png)
