import socket
import sys
import threading
import docker_env_car
import docker_env_user

class ConnectionInterface:
    
    def __init__(self):
        self.HOST = ''   # Symbolic name meaning all available interfaces
        self.PORT = 8887 # Arbitrary non-privileged port
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        print('Socket created')
        s.settimeout(None)
        self.bindSocket(s)
        self.dockerEnvCarList = []
        self.dockerEnvUserList = []
        
        #now keep talking with the client
        while 1:
            #wait to accept a connection - blocking call
            conn, addr = s.accept()
            #print('Connected with ', addr[0] , ':' , str(addr[1]))
             
            #start new thread takes 1st argument as a function name to be run, second is the tuple of arguments to the function.
            thread.start_new_thread(self.clientthread ,(conn,))
         
        s.close()

    #Function for binding the socket
    def bindSocket(self, s):
        try:
            s.bind((self.HOST, self.PORT))
        except socket.error as msg:
            print('Bind failed. Error Code : ', str(msg[0]), ' Message ', msg[1])
            sys.exit()
             
        print('Socket bind complete')
        #Start listening on socket
        s.listen(10)
        print('Socket now listening')
        
    #Function for handling connections. This will be used to create threads
    def clientthread(self,conn):
        #Sending message to connected client
        conn.send(b'Welcome to the server. Type something and hit enter\n') #send only takes string
         
        #infinite loop so that function do not terminate and thread do not end.
        while True:
             
            #Receiving from client
            data = conn.recv(1024)
            words = self.dataProcessing(data)
            if(words[0] == "Car"):
                if(words[1] == "Creation"):
                    self.createEnvCar(int(words[2]))

                    
            elif(words[0] == "User"):
                if(words[1] == "Creation"):
                    self.createEnvUser(int(words[2]))
                    
                elif(words[1] == "Transaction"):
                    info = words[3].split(":")
                    print("Create transaction with car " + info[2])
                    dockerEnvOfWantedCar = self.dockerEnvCarList[int(info[2])]
                    contractAddress = dockerEnvOfWantedCar.getContractAddress()
                    self.dockerEnvUserList[int(words[2])].exec_query(contractAddress, info[1],words[3]) #TODO ajouter info dan exec_qury info = liste

                elif(words[1] == "addEndHour"):
                    info = words[3].split(":")
                    print("Adding end hour")
                    idCar = info[2].replace(")","");
                    dockerEnvOfWantedCar = self.dockerEnvCarList[int(idCar)]
                    contractAddress = dockerEnvOfWantedCar.getContractAddress()
                    self.dockerEnvUserList[int(words[2])].exec_query_addHour(contractAddress, words[3]) #TODO ajouter info dan exec_qury info = liste
		#conn.send(b'Le serveur a recu la transaction\n')
            else : 
                break     
        
        #came out of loop
        conn.close()
		
    #Function for creating the connection between a car and the docker 
    def createEnvCar(self, ID):
        test = docker_env_car.DockerEnvCar(ID)
        self.dockerEnvCarList.append(test)
        print("Contract of car " + str(ID) + " was deployed ") 
       
    #Function for creating the connection between a user and the docker 
    def createEnvUser(self, ID):
        test = docker_env_user.DockerEnvUser(ID)
        self.dockerEnvUserList.append(test)
    #Function for extract the good information from the receiving message
    def dataProcessing(self,data):
        data = data.decode()
        words = data.split("<contents class=\"string\">&lt;string&gt;")
        words = words[1].split("&lt;/string&gt;</contents>@n@")
        words = words[0].split(";")
        return words
        
if __name__ == "__main__":
    server = ConnectionInterface()
    

