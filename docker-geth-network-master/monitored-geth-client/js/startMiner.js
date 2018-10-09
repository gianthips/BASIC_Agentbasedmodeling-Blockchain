var mining_threads = 1

function startMiner() {
	miner.setEtherbase(eth.accounts[eth.accounts[0]])
    miner.start()
}


startMiner();
