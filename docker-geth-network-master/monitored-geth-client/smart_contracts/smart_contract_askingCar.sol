pragma solidity ^0.4.18; // We have to specify what version of compiler this code will compile with

contract AskingCar {

        struct Transaction{
                bytes32 idTransaction;
                bytes32 idPassenger;
                bytes32 idCar;
                bytes32 startPoint;
                bytes32 endPoint;
                int startHour;
                int endHour;
        }

        string  private idCar;

        mapping (bytes32 => Transaction) private transactions;
        bytes32[] private idsTransaction;

        /*
        * Constructor of the contract
        */
        function AskingCar(string id) public {
                idCar = id;
        }

        /*
        * Function that will add the info of the passeger
        */
        function addTransactionInfo(bytes32 idTrans, bytes32 idPass, bytes32 idCar, bytes32 start, bytes32 end, int hour){
                var transaction = transactions[idTrans];
                transaction.idTransaction = idTrans;
                transaction.idPassenger = idPass;
                transaction.idCar = idCar;
                transaction.startPoint = start;
                transaction.endPoint = end;
                transaction.startHour = hour;

                idsTransaction.push(idTrans)-1;
        }
         /*
        * Function that will add the end hour of the drive
        * when the drive is finised
        */
        function addEndHour(bytes32 idTransaction, int endHour){
                if(validTransaction(idTransaction)){
                    transactions[idTransaction].endHour = endHour;
                 }
        }

        /*
        *Check if the transaction is assigned to this contract
        */

        function validTransaction(bytes32 idTrans) view public returns (bool) {
                for(uint i = 0; i < idsTransaction.length; i++) {
                        if (idsTransaction[i] == idTrans) {
                                return true;
                        }
                }
                return false;
        }

}

