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
	int nbBlockCarUser <- 1;
	int nbBlockCar <- 1;
	int currentHour update: (time / #hour) mod 24;
	float step <- 5 #mn;
	list<BlockCar> freeBlockCars <- nil;
	init{
		create BlockCarUser number: nbBlockCarUser{
			home <- one_of(world.getBuildings());
			if(home = nil){
				write("Coucou");
			}	
			location <- any_location_in (home);
			work <- one_of(world.getBuildings());
		}
		//create BlockCar number: nbBlockCar;
		//freeBlockCars <- BlockCar where(each.isFree = "true");
		}
}

species BlockCarUser skills:[moving]{
	building home;
	building work;
	int startWork <- 7 ;
	int endWork <- 16  ;
	string nextObjective <- "work";
	point target <- nil;
	float speed <- 4 #km/#h;
	
	reflex updateTarget {
		if(currentHour > startWork and currentHour < endWork){
			target <- any_point_in(work);
		}
		if(currentHour < startWork or currentHour > endWork){
			target <- any_point_in(home);
		}
	} 
	reflex move{
		//do wander on: road_graph;
		if(target = work and nextObjective = "work"){
	      do goto target: target on: road_graph  ;
	      nextObjective <- "home"; 
	    }
	    if(target = home and nextObjective = "home"){
	      do goto target: target on: road_graph  ;
	      nextObjective <- "work"; 
	    }
		if (target = location) {
			target <- nil ;
		}
	}
	
	action askBlockCar(point startPoint, point endPoint){
		BlockCar myBlockCar <- one_of(freeBlockCars); //TODO closest_to(self)
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
	list<point> endPoints <- [];
	
	bool isFree <- true;
	
	aspect base{
		draw circle(10#m) color:#blue;
	}
	
	reflex move{
		if(isFree = true){
			do wander on: road_graph;
		}
		
		else{
			do goto target: startPoints[1] on: road_graph;
			do goto target: endPoints[1] on: road_graph;
			isFree <- true;
			freeBlockCars <- BlockCar where(each.isFree = "true");
		}
	}
	
	action addPassenger(point startPoint, point endPoint){
		bool ret <- false;
		if(currentNbPassenger < 4){
			isFree <- false;
			freeBlockCars <- BlockCar where(each.isFree = "true");
			startPoints[currentNbPassenger+1] <- startPoint;
			endPoints[currentNbPassenger+1] <- endPoint;
			ret <- true;
			currentNbPassenger <- currentNbPassenger + 1;
		}
		return ret;
		
	}
	
	action setFree(bool val){
		isFree <- val;
	}
	
	
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

