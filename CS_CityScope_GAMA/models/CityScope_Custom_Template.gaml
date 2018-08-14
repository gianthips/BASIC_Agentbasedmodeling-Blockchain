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
	int nbBlockCarUser <-10;
	int nbBlockCar <- 4;
	
	int currentHour update: (time / #hour) mod 24;
	float step <- 3 #mn;
	list<BlockCar> freeBlockCars <- nil;
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
	int startWork <- world.min_work_start + rnd (world.max_work_start - world.min_work_start);
	int endWork <- world.min_work_end + rnd (world.max_work_end - world.min_work_end);
	string nextObjective <- "home";
	point target <- nil;
	float speed <- 1 #km/#h;
	BlockCar myBlockCar <- nil;
	bool waitingForCar <- false;
	bool askingForCar <- false; //TODO
	
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
			if(myBlockCar = nil){
				askingForCar <- true;
				do askBlockCar(location,work);
			}
			if(myBlockCar != nil){
				waitingForCar <- true;
			}
	      }
	      
		  else if(nextObjective = "home"){
		    if(myBlockCar = nil){
		    	askingForCar <- true;
				do askBlockCar(location,home);
			}
			if(myBlockCar != nil){
				waitingForCar <- true;
			}
		  }
		}
	}
	
	BlockCar askBlockCar(point startPoint, building endPoint){
		freeBlockCars <- BlockCar where(each.isFree = true);
		myBlockCar <- one_of(freeBlockCars); //TODO closest_to(self)
		ask myBlockCar{
			do addPassenger(startPoint, endPoint,myself);
		}
		return myBlockCar;
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
			target <- (startPoints at 0);
			do goto target: target on: road_graph;
			if(location = target){
				objective <- "dropOff";
			}
		}
		else if (objective = "dropOff"){
			target <- any_point_in(endPoints at 0);
			do goto target: target on: road_graph;
			loop user over:passengers{
				user.location <- location;
			}
			if(location = target){
				do dropOff(passengers at 0);
				objective <- "wander";
			}
		}
		
		else if(objective = "wander"){
			do wander on: road_graph;
		}
	}
	
	action dropOff(BlockCarUser user){
		startPoints[] >-0;
		endPoints[] >-0;
		passengers[] >-0;
		user.target <- nil;
		user.waitingForCar <- false;
		user.askingForCar <- false;
		user.myBlockCar <- nil;
		if(length(passengers) = 0){ //TODO gerer plusieurs voitures
			isFree <- true;
		}
		
	}
	action addPassenger(point startPoint, building endPoint, BlockCarUser user){
		add startPoint to: startPoints;
		add endPoint to: endPoints;
		add user to: passengers;
		if(length(passengers) = nbMaxPassenger){
			isFree <- false;
		}
		objective <- "pickUp";
	}	
}

species transaction{
	BlockCarUser user;
	BlockCar driver;
	point startPoint;
	point endPoint;
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

