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
	int nbBlockCarUser <- 10;
	int nbBlockCar <- 1;
	int currentHour update: (time / #hour) mod 24;
	float step <- 1 #mn;
	list<BlockCar> freeBlockCars <- nil;
	init{
	}
	
	action  customInit{
		 create BlockCar number: nbBlockCar;
		 freeBlockCars <- BlockCar where(each.isFree = "true");
	     create BlockCarUser number: nbBlockCarUser{
		     home <- one_of(world.amenity);
			 location <- any_location_in (home);
			 work <- one_of(world.building);
		}
  }
}

species BlockCarUser skills:[moving]{
	building home;
	building work;
	int startWork <- 7 ;
	int endWork <- 16  ;
	string nextObjective <- "home";
	point target <- nil;
	float speed <- 1 #km/#h;
	BlockCar myBlockCar <- nil;
	bool visible <- true;
	
	reflex updateTarget {
		if(currentHour > startWork and currentHour < endWork and nextObjective = "home"){
			target <- any_point_in(work);
			nextObjective <- "work";
			write("Objective: "+nextObjective);
		}
		else if(currentHour > endWork and nextObjective = "work"){
			target <- any_point_in(home);
			nextObjective <- "home";
			write("Objective: "+nextObjective);
		}
	} 
	reflex move{
		if(target != nil){
		  if(nextObjective = "work"){
			  //do askBlockCar(location,work);
		      do goto target: target on: road_graph  ;
	      }
		  else if(nextObjective = "home"){
		    //do askBlockCar(location, home);
		    do goto target: target on: road_graph  ;
		  }
		}
		
		if(target = location){
			target <- nil;
		}
	}
	
	action askBlockCar(point startPoint, building endPoint){
		freeBlockCars <- BlockCar where(each.isFree = true);
		myBlockCar <- one_of(freeBlockCars); //TODO closest_to(self
		ask myBlockCar{
			do addPassenger(startPoint, endPoint); //TODO gérer le return ?
		}
	}
	aspect base{
		draw circle(10#m) color:#red;
	}
}


species BlockCar skills:[moving]{
	int nbMaxPassenger <- 1; //TODO Mettre 4
	int currentNbPassenger <- 0;
	list<point> startPoints <- [];
	list<building> endPoints <- [];
	float speed <- 0.1 #km/#h;
	bool toPickUp <- false;
	bool toDropOff <- false;
	
	bool isFree <- true;
	
	aspect base{
		draw circle(10#m) color:#blue;
	}
	
	reflex move{
		if(isFree = false and currentNbPassenger >=1){
			point target <- (startPoints at 0);
			do goto target: target on: road_graph;
			if(location = target){
				do dropOff;
			}
		}
		else{
			do wander on: road_graph;
		}
	}
	
	action dropOff{
		point target <- {10.0,10.0};//any_point_in(endPoints at 0);
		do goto target: target on: road_graph;
		startPoints[] >- 0;
		endPoints[] >-0;
		currentNbPassenger <- currentNbPassenger - 1;
		isFree <- true;
		
	}
	action addPassenger(point startPoint, building endPoint){
		bool ret <- false;
		if(currentNbPassenger < nbMaxPassenger){
			isFree <- false;
			add startPoint to: startPoints;
			add endPoint to: endPoints;
			ret <- true;
			currentNbPassenger <- currentNbPassenger + 1;
		}
		return ret;
		
	}
	
	action setFree(bool val){
		isFree <- val;
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
			species BlockCarUser aspect:base;
			species BlockCar aspect:base;
			
		}
		display CustomSpeciesOnly type:opengl{
			species BlockCarUser aspect:base;
			species BlockCar aspect:base;	
		}
	}
}

