const fs = require('fs');
const solc = require('solc');
const Web3 = require('web3');
const path = require('path');
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

async function deploy(contract_path, id_bot) {

    let accounts = await web3.eth.getAccounts();
    let password = '';
    let account = accounts[id_bot];
    let confirmed = await web3.eth.personal.unlockAccount(account, password,0)
        .then((response) => {
                console.log(response);
        }).catch((error) => {
                console.log(error);
        });

    let code = fs.readFileSync(contract_path).toString();
    let compiledCode = solc.compile(code);
    let contract_filename = path.basename(contract_path);
    let contract_name = contract_filename.replace(".sol", "");
    let interface_name = ':'+ "AskingCar";
    let abi = JSON.parse(compiledCode.contracts[interface_name].interface);
    let bytecode = compiledCode.contracts[interface_name].bytecode;
    let VotingContract = new web3.eth.Contract(abi, account, {from: account, gas: 49000, data: '0x' + bytecode});

    // Parameters for the Voting contract
    // This should be removed in order to generalize the contract

    let contractInstance = await VotingContract.deploy({
         arguments: [id_bot]
    })
    .send({
        from: account,
        gas: 1900000
    }, (err, txHash) => {
        console.log('send:', err, txHash);
    })
    .on('error', (err) => {
        console.log('error:', err);
    })
    .on('transactionHash', (err) => {
        console.log('transactionHash:', err);
    })
    .on('receipt', (receipt) => {
        console.log('receipt:', receipt);
    });
}
const args = process.argv;
deploy(process.argv[2], process.argv[3])
 .then(() => console.log('Success'))
 .catch(err => console.log('Script failed:', err));