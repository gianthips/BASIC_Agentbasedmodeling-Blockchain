/***
* Name: CustomableCityScope
* Author: Luana Marrocco
* Description: This is a custom template to create any species on top of the orginal CityScope Main model.
* Tags: Tag1, Tag2, TagN
***/



model CityScope_Custom_Template


import "CityScope_main.gaml"
import "UserClient.gaml"

/* Insert your model definition here */

global{
	int nbBlockCarUser <- 20 ;
	int nbBlockCar <- 2; //This should be smaller or equal to the number of accounts present in the genesis blocks
	
	int currentHour update: (time / #hour) mod 24;
	int currentDay update: (time /#day);
	float step <- 0.1 #mn;
	list<BlockCar> freeBlockCars <- nil;
	
	int distanceStart <- 1000;
	int distanceEnd <- 1000;
	init{
	}
		
	reflex stopSim{
		if(currentDay = 7){
			do pause;
		}
	}
	action  customInit{
		 create BlockCar number: nbBlockCar;
		 freeBlockCars <- BlockCar where(each.isFree = "true");
	     create BlockCarUser number: nbBlockCarUser{
		     home <- one_of(world.building where (each.usage = "R"));
			 location <- any_location_in (home);
			 work <- one_of(world.building where (each.usage = "O"));
			 socialClass <- home.usage;
		}
  }
}

species BlockCarUser skills:[moving]{
	building home;
	building work;
	int startWork <- world.min_work_start + rnd (world.max_work_start - world.min_work_start);
	int endWork <- world.min_work_end + rnd (world.max_work_end - world.min_work_end);
	string socialClass;
	string nextObjective <- "home";
	point target <- nil;
	BlockCar myBlockCar <- nil;
	bool waitingForCar <- false;
	bool askingForCar <- false;
	bool inCar <- false;
	list<BlockCarUser> copassengers <- nil;
	bool inAGroup <- false;
	Transaction currentTransaction <- nil;
	float waitTime;
	float maxWaitTime <- 15.0;
	
	NetworkingClient userClient <- nil;
	
	init{
		create NetworkingClient {
			do connect to: "localhost" protocol: "tcp_client" port: 8887 with_name: "Client";
			myself.userClient <- self;
			do sendMessage("User;Creation;", "BlockCarUser", myself.name, "");
		}
	}
	
	
	reflex updateTarget {
		if(currentHour > startWork and currentHour < endWork and (nextObjective = "home")){
			target <- any_point_in(work);
			nextObjective <- "work";
		}
		else if(currentHour > endWork and (nextObjective = "work")){
			target <- any_point_in(home);
			nextObjective <- "home";
		}
	} 
	
	reflex move{
		if(target != nil){
		  if(nextObjective = "work"){
		  	do movement(home,work);
		  }	      
		  else if(nextObjective = "home"){
		  	do movement(work,home);
		  }
		}
	}
	
	action movement(building start, building end){
		if(currentTransaction = nil){
			do createAndAddTransaction(start, end);
			waitTime <- step*cycle;
		}
		if(myBlockCar = nil){
			askingForCar <- true;
			if(inAGroup = false){
				copassengers <- findPeople();
				if(length(copassengers) > 1 or (step*cycle - waitTime) > maxWaitTime){
					inAGroup <- true;
					loop user over: copassengers{
						user.inAGroup <- true;
					}
					do findCarAndUpdateGroup;
				}
			}			
		  }
		  if(inAGroup = true and myBlockCar = nil){
			do findCarAndUpdateGroup;
		  }
		  if(myBlockCar != nil){
			waitingForCar <- true;
			target <- nil;
			currentTransaction.driver <- myBlockCar;
			ask userClient{
				string info <- myself.currentTransaction.getString();
				do sendMessage("User;Transaction;","BlockCarUser", myself.name, info);
			}
		  }
	}
	
	action findCarAndUpdateGroup{
		do askBlockCar; 
		loop user over: copassengers{
			user.myBlockCar <- self.myBlockCar;
		}
		ask myBlockCar{
			do addPassengers(myself.copassengers);
		}
	}
	
	BlockCar askBlockCar{
		freeBlockCars <- BlockCar where(each.isFree = true);
		myBlockCar <- freeBlockCars closest_to(self);
		return myBlockCar;
	}
	
	list<BlockCarUser> findPeople{
		list<BlockCarUser> peoples <- nil;
		peoples <- BlockCarUser where(each.askingForCar = true and each.inAGroup = false and each distance_to self < distanceStart and each.target distance_to self.target < distanceEnd);
		return peoples;
	}
	
	
	action createAndAddTransaction(building start, building end){
		create Transaction returns: trans{
			user<-myself;
			startPoint <-start;
			endPoint <- end;
			startHour <- currentHour;					
		}
		currentTransaction <- trans at 0;
	}
	
	aspect base{
		if(askingForCar = true){
			draw circle(15#m) color:#blue;
		}
		else{
			draw circle(5#m) color:#blue;
		}
		
	}
}


species BlockCar skills:[moving, network]{
	list<point> startPoints <- [];
	list<point> endPoints <- [];
	list<BlockCarUser> passengers <- [];
	point final_target <- nil;
	float speed <- 30 #km/#h;
	bool isFree <- true;
	string objective <- "wander";
	//list<Transaction> currentTransactions;
	int indexPassenger <- 0;
	int indexNext <- -1;
	NetworkingClient userClient <- nil;
	
	init{
		create NetworkingClient {
			do connect to: "localhost" protocol: "tcp_client" port: 8887 with_name: "Client";
			myself.userClient <- self;
			do sendMessage("Car;Creation;", "BlockCar",myself.name, "");
		}
	}	
	aspect base{
		if(isFree = true){
			draw triangle(30) color:#green rotate:heading + 90;
		}
		else{
			draw triangle(30) color:#red rotate:heading + 90;
		}
	}
	
	reflex move{
		if(objective = "pickUp"){
			if (indexNext = -1){
				indexNext <- findNextTarget(passengers, startPoints, "pickUp");
			}
			final_target <- (startPoints at indexNext);	
			do goto target: final_target on: road_graph;
			loop user over:passengers{
				if(user.inCar = true){
					user.location <- location;	
				}
			}
			
			if(location = final_target){
				(passengers at indexNext).inCar <- true;
				(passengers at indexNext).waitingForCar <- false;
				indexPassenger <- indexPassenger + 1;
				if(indexPassenger = length(passengers)){
					objective <- "dropOff";
					indexPassenger <- 0;
				}
				indexNext <- -1;
			}
		}
		else if (objective = "dropOff"){
			if(indexNext = -1){
				indexNext <- findNextTarget(passengers, endPoints, "dropOff");
			}
			final_target <- endPoints at indexNext;
			do goto target: final_target on: road_graph;
			loop user over:passengers{
				if(user.inCar = true){
					user.location <- location;	
				}
			}
			if(location = final_target){
				do dropOff(passengers at indexNext);
				put {1000,1000,1000} at: indexNext in: endPoints;
				indexPassenger <- indexPassenger + 1;
				if(indexPassenger = length(passengers)){
					passengers <- nil;
					startPoints <- nil;
					endPoints <- nil;
					isFree <- true;
					objective <- "wander";
					indexPassenger <- 0;
				}
				indexNext <- -1;
			}
		}
		
		else if(objective = "wander"){
			do wander on: road_graph;
		}
	}
	
	action dropOff(BlockCarUser user){
		(user.currentTransaction).endHour <- currentHour;
		ask user{
			ask userClient{
				string info <- myself.currentTransaction.getStringEndHour();
				do sendMessage("User;addEndHour;","BlockCarUser", myself.name, info);
			}
		}
		user.target <- nil;
		user.askingForCar <- false;
		user.inCar <- false;
		user.myBlockCar <- nil;	
		user.inAGroup <- false;
		user.waitingForCar <- false;
		user.currentTransaction <- nil;	
	}
	
	action saveTransaction(Transaction trans){
		save [trans.user.name,trans.driver.name, trans.startPoint.name, trans.endPoint.name,trans.startHour,trans.endHour] to: "../results/simulation.csv" type:"csv" rewrite: false;
	}
	
	action addPassengers(list<BlockCarUser> users){
		isFree <- false;
		self.passengers <- users;
		loop user over: users{
			//add user.currentTransaction to:currentTransactions;
			add user.location to: startPoints;
			if(user.nextObjective = "home"){
				add any_point_in(user.home) to: endPoints;
			}
			else{
				add any_point_in(user.work) to: endPoints;
			}
		}
		objective <- "pickUp";
	}
	
	int findNextTarget(list<BlockCarUser> listNextUser, list<point> listNextDestination, string str){
		int index <- 0;
		if(str = "pickUp"){
			BlockCarUser nextAcceptable <- (listNextUser where (each.waitingForCar = true)) closest_to(self) ;
			if(nextAcceptable != nil){
				loop while: ((listNextUser at index) != nextAcceptable){
					index <- index + 1;
				}
			}		
		}
		else{
			point next <- listNextDestination closest_to(self);
			loop while: ((listNextDestination at index) != next){
				index <- index + 1;
			}
		}
		return index;
	}	
}

species Transaction{
	BlockCarUser user <- nil;
	BlockCar driver <- nil;
	building startPoint <- nil;
	building endPoint <- nil;
	int startHour;
	int endHour;
	
	bool finished <- false;
	
	string getString{
		list<string> splittedName <- user.name split_with "BlockCarUser";
		string userName <- splittedName at 0;
		splittedName <- driver.name split_with "BlockCar";
		string driverName <- splittedName at 0;
		splittedName <- name split_with "Transaction";
		string transName <- splittedName at 0;
		string startPts <- startPoint.name;
		string endPts <- endPoint.name;
		
		return "(" + transName + ":" + userName + ":" + driverName + ":" + startPts + ":" + endPts + ":" + string(startHour) +")" ;
	}
	
	string getStringEndHour{
		list<string> splittedName <-  name split_with "Transaction";
		string transName <- splittedName at 0;
		splittedName <- driver.name split_with "BlockCar";
		string driverName <- splittedName at 0;
		return "(" + transName + ":"+ string(endHour) + ":"+driverName+")" ;
	}
}

experiment customizedExperiment type:gui parent:CityScopeMain{
	output{
		display CustomSpeciesOnly type:opengl{
			species BlockCar aspect:base;
			species BlockCarUser  aspect:base;
			//species building aspect:base;
			//species road aspect: base;
				
		}
	}
}

