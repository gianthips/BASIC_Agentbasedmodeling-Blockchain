#!/usr/bin/env python
import docker
import re

class DockerEnv:

    client = docker.DockerClient(base_url='tcp://192.168.99.100:2375 /')
    container = None
    RobotID = None
    SmartContactAddress = None
    
    def __init__(self, RobotROSNameSpace):
        self.RobotID = self.getRobotID(RobotROSNameSpace)
        self.getContainer()
                                  
    def getContainer(self):
        DockerComposerID = int(self.RobotID) + 1
        self.container = self.client.containers.get("dockergethnetwork_eth_"\
                                                    + str(DockerComposerID))
        print("dockergethnetwork_eth_" + str(DockerComposerID))

    def getRobotID(self, RobotROSNameSpace):
        RobotROSNameSpace = re.sub("[/]", "", RobotROSNameSpace)
        RobotID = RobotROSNameSpace.replace('bot','')
        return RobotID
        
    def exec_run(self):
        return self.container.exec_run("node /root/js/query.js-aux 0xDB571079aF66EDbB1a56d22809584d39C20001D9")
        
    def check(self):
        print (self.client.containers.list())

"""if __name__ == "__main__":

    test = DockerEnv("/bot0/")
    test.getContainer()
    #print (test.exec_run())"""
    

