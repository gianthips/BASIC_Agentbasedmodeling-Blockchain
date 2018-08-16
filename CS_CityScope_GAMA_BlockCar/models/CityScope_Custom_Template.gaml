/***
* Name: CustomableCityScope
* Author: Arnaud Grignard
* Description: This is a custom template to create any species on top of the orginal CityScope Main model.
* Tags: Tag1, Tag2, TagN
***/



model CityScope_Custom_Template


import "CityScope_main.gaml"

/* Insert your model definition here */

global{
	int nbBlockCarUser <-2;
	int nbBlockCar <- 1;
	
	int currentHour update: (time / #hour) mod 24;
	float step <- 3 #mn;
	list<BlockCar> freeBlockCars <- nil;
	
	int distanceStart <- 1000;
	int distanceEnd <- 1000;
	init{
	}
	
	action  customInit{
		 create BlockCar number: nbBlockCar;
		 freeBlockCars <- BlockCar where(each.isFree = "true");
	     create BlockCarUser number: nbBlockCarUser{
		     home <- one_of(world.building where (each.usage = "R"));
			 location <- any_location_in (home);
			 work <- one_of(world.building where (each.usage = "O"));
		}
  }
}

species BlockCarUser skills:[moving]{
	building home;
	building work;
	int startWork <- 7;//world.min_work_start + rnd (world.max_work_start - world.min_work_start); //TODO
	int endWork <- world.min_work_end + rnd (world.max_work_end - world.min_work_end);
	string nextObjective <- "home";
	point target <- nil;
	BlockCar myBlockCar <- nil;
	bool waitingForCar <- false;
	bool askingForCar <- false; //TODO ce truc sert juste pour l'affichage : utile?
	bool inCar <- false;
	list<BlockCarUser> copassengers <- nil;
	bool inAGroup <- false;
	Transaction currentTransaction <- nil;
	float waitTime update: (step * cycle);
	
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
		if(waitingForCar = true){
		}
		else if(target != nil){
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
			waitTime <- 0.0;
		}
		if(myBlockCar = nil){
			askingForCar <- true;
			if(inAGroup = false){
				copassengers <- findPeople();
				if(length(copassengers) > 1){
					inAGroup <- true;
					loop user over: copassengers{
						user.inAGroup <- true;
					}
					do askBlockCar;
					loop user over: copassengers{
						user.myBlockCar <- self.myBlockCar;
					}
					ask myBlockCar{
						do addPassengers(myself.copassengers);
					}
				}
			}			
		  }
		  if(myBlockCar != nil){
			waitingForCar <- true;
			currentTransaction.driver <- myBlockCar;
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


species BlockCar skills:[moving]{
	int nbMaxPassenger <- 1; //TODO Mettre 4
	list<point> startPoints <- [];
	list<building> endPoints <- [];
	list<BlockCarUser> passengers <- [];
	point target <- nil;
	float speed <- 1 #km/#h;
	bool isFree <- true;
	string objective <- "wander";
	list<Transaction> currentTransactions;
	int indexPassenger <- 0;
		
	aspect base{
		if(isFree = true){
			draw circle(20#m) color:#green;
		}
		else{
			draw circle(20#m) color:#red;
		}
	}
	
	reflex move{
		if(objective = "pickUp"){
			target <- (startPoints at indexPassenger);
			do goto target: target on: road_graph;
			loop user over:passengers{
				if(user.inCar = true){
					user.location <- location;	
				}
			}
			
			if(location = target){
				(passengers at indexPassenger).inCar <- true;
				indexPassenger <- indexPassenger + 1;
				if(indexPassenger = length(passengers)){
					objective <- "dropOff";
					indexPassenger <- 0;
				}
			}
		}
		else if (objective = "dropOff"){
			target <- any_point_in(endPoints at indexPassenger);
			do goto target: target on: road_graph;
			loop user over:passengers{
				if(user.inCar = true){
					user.location <- location;	
				}
			}
			if(location = target){
				do dropOff(passengers at indexPassenger);
				indexPassenger <- indexPassenger + 1;
				if(indexPassenger = length(passengers)){
					passengers <- nil;
					startPoints <- nil;
					endPoints <- nil;
					isFree <- true;
					objective <- "wander";
					indexPassenger <- 0;
				}
			}
		}
		
		else if(objective = "wander"){
			do wander on: road_graph;
		}
	}
	
	action dropOff(BlockCarUser user){
		user.target <- nil;
		user.waitingForCar <- false;
		user.askingForCar <- false;
		user.inCar <- false;
		user.myBlockCar <- nil;	
		user.inAGroup <- false;
		(user.currentTransaction).endHour <- currentHour; //TODO WRITE TRANSACTION IN A CVS FILE
		user.currentTransaction <- nil; //TODO faire ca plus propre	
	}
	
	action addPassengers(list<BlockCarUser> users){ //TODO mabe mieux d'utilisr les transactions et pas les users ?
		isFree <- false;
		self.passengers <- users;
		loop user over: users{
			add user.currentTransaction to:currentTransactions;
			add user.location to: startPoints;
			if(user.nextObjective = "home"){
				add user.home to: endPoints;
			}
			else{
				add user.work to: endPoints;
			}
		}
		objective <- "pickUp";
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
}

experiment customizedExperiment type:gui parent:CityScopeMain{
	output{
		display CityScopeAndCustomSpecies type:opengl parent:CityScopeVirtual{
			species BlockCar aspect:base;
			species BlockCarUser aspect:base;
			
			
		}
		display CustomSpeciesOnly type:opengl{
			species BlockCar aspect:base;
			species BlockCarUser  aspect:base;
				
		}
	}
}

