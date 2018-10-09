/**
* Name: Socket_TCP
* Author: Luana Marrocco
* Description: Communication with a Python server
* Tags: Network, TCP, Socket
*/
model Socket_TCP


global {
	init {
	}

}

species NetworkingClient skills: [network]
{
	string name;
	string dest;

	reflex receive {
		if (length(mailbox) > 0){
			write mailbox;
		}
	}
	
	action sendMessage (string msg, string typeUser,string nameUser, string info){
		list<string> splittedName <- nameUser split_with typeUser;
		string Id <- splittedName at 0;
		msg <- msg + Id + ";" + info;
		//write(msg);
		do send to: "send" contents: msg;
	}
}

experiment "TCP Client Test" type: gui
{
	output
	{
	}

}
