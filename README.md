# BASIC : towards a Blockchained Agent-based SImulator for Cities

This repository contains the code for the paper:

L. Marrocco, E. Castello Ferrer, A. Bucchiarone, A. Grignard, L. Alonso, K. Larson, and A. ‘Sandy’ Pentland, 2019. BASIC: towards a Blockchained Agent-based SImulator for Cities.

This paper aims to present a tool that combines an agent-based simulator with the Ethereum blockchain. This repository contains three main parts:

##### Agent-based simulator
The simulation represents the city of Cambridge with people and Autonomous vehicles (AVs) and is made by using the [Gama Plateform](https://gama-platform.github.io/). A previous work called [CityScope](https://github.com/CityScope/CS_Simulation_GAMA) was used as starting point for this one.


##### Docker Container
In order to add the blockchain network to the simulation, [Docker containers](https://docs.docker.com/install/) are used. 

##### Python Interface for the connection 
The connection between the simulation and the containers is made by using a [Python](https://www.python.org/downloads/) interface.

## Getting Started
### Prerequisites
First, clone this repesitory.

You will need to have [Python](https://www.python.org/downloads/), [Docker](https://docs.docker.com/install/) and [Gama](https://gama-platform.github.io/) installed on your computer.

### Running the simulation

#### 1. Run the docker composer

Go inside the docker (docker-geth-network-master) folder and run an Ethereum Docker cluster by running the following:

```
$ docker-compose up
```

By default this will create:

* 1 Ethereum Bootstrapped container
* 1 Ethereum node (which connects to the bootstrapped container on launch)
* 1 Netstats container (with a Web UI to view activity in the cluster)
* 10 accounts pre-filled with Ether (you can modify or create more accounts by looking at `files/genesis.json`.) 


To access the Netstats Web UI:

```
open http://$(docker-machine ip default):3000
```

Each AV of the simulation is connected to node (running in a container). Thus, the number of docker containers needed must be same as the number of AVs you want to create in the simulation. You can scale the number of Ethereum nodes by running:

```
docker-compose scale eth=3
``` 

You need to have at least one node mining in the simulation. To get attached to the `geth` JavaScript console on the node you can run the following
```
docker exec -it docker-geth-network-master_eth_1 geth attach ipc://root/.ethereum/devchain/geth.ipc
```
Then you can do `miner.start()` to activate the mining of the node. You can verify if it's mining by inspecting `web3.eth.mining`. Your node will start mining when the DAG File will be fully generated.

See the [Javascript Runtime](https://github.com/ethereum/go-ethereum/wiki/JavaScript-Console) docs for more.


#### 2. Run the python server

In the PythonInterface folder, run :

```
py connection_interface.py
``` 
#### 3. Run the simulation

The last step will be to run the simulation. To do so, import the AgentBased_Simulator folder in the Gama interface and make sure that the number of AVs you created in the simulation is equal to the number of nodes of your blockchain network. When it's done, launch the experiment. Before to be able to start it, wait that each AV deployed his smart contract. You will receive a confirmation message in the Python console with the address of the deployed smart contract. When the smart contracts are all deployed, you can start the simulation. 
 
---
