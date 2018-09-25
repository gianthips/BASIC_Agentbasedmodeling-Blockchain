const fs = require('fs');
const solc = require('solc');
const Web3 = require('web3');
const path = require('path');
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

async function query(contract_path, contract_address, id, info) {
    let accounts = await web3.eth.getAccounts();
    let password = '';
    let account = accounts[id];
    let confirmed = await web3.eth.personal.unlockAccount(account, password, 0)
        .then((response) => {
                console.log(response);
        }).catch((error) => {
                console.log(error);
        });

    let code = fs.readFileSync(contract_path).toString();
    let compiledCode = solc.compile(code);
    let contract_filename = path.basename(contract_path);
    let contract_name = contract_filename.replace(".sol", "");
    let interface_name = ':' + "AskingCar";
    let abi = JSON.parse(compiledCode.contracts[interface_name].interface);
    let Contract = new web3.eth.Contract(abi, contract_address);

    //Specific to my contract
    info = info.replace("(", "");
    info = info.replace(")","");
    infoList = info.split(":");
    let idTrans = web3.utils.asciiToHex(infoList[0]);
    let endHour = parseInt(infoList[1]);
    let receipt = await Contract.methods.addEndHour(idTrans, endHour).send({from: account});
 
}

const args = process.argv;
query(process.argv[2], process.argv[3], process.argv[4], process.argv[5])
.then(() => console.log('Success'))
.catch(err => console.log('Script failed:', err));

