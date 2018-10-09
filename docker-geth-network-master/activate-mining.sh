#!/bin/bash
for((i=1; i<= $1; i++)) 
do
	docker exec -it docker-geth-network-master_eth_$i geth attach ipc://root/.ethereum/devchain/geth.ipc
done
