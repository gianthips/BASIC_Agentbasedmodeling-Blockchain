/**
* Name: Socket_TCP_HelloWorld_Client
* Author: Arnaud Grignard
* Description: Two clients are communicated throught the Socket TCP protocol.
* Tags: Network, TCP, Socket
*/
model Socket_TCP_HelloWorld_Client


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
		write(msg);
		do send to: "send" contents: msg;
	}
}

experiment "TCP Client Test" type: gui
{
	output
	{
	}

}
