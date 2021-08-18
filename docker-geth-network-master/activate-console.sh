#!/bin/bash
for((i=1; i<= $1; i++)) 
do
	docker exec -it dockergethnetworkmaster_eth_$i bash
done
