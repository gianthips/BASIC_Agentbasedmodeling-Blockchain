#!/usr/bin/env python
import docker
import re

class DockerEnvUser:

    client = docker.DockerClient(base_url='tcp://192.168.99.100:2375 /')
    container = None
    UserID = None
    
    
    def __init__(self, UserId):
        self.UserID = UserId
        self.getContainer()

                                  
    def getContainer(self):
        DockerComposerID = 1 #Par défaut, on dit qu'ils se connecte au noeud 1
        self.container = self.client.containers.get("dockergethnetwork_eth_"\
                                                    + str(DockerComposerID))        
        
    def check(self):
        print (self.client.containers.list())

        
    def exec_query(self, smartContractAddress, userId, info):
        response = self.container.exec_run("node /root/js/query.js-aux /root/smart_contracts/smart_contract_askCar.sol " + smartContractAddress + " " + str(userId) + " " + info) #TODO remplacer le 0 par le compte de chaque user
        print (response)
        return response
        
    def exec_query_addHour(self, smartContractAddress, info):
        response = self.container.exec_run("node /root/js/query_endHour.js-aux /root/smart_contracts/smart_contract_askCar.sol " + smartContractAddress + " " + str(0) + " " + info) #TODO remplacer le 0 par le compte de chaque user
        print (response)
        return response        