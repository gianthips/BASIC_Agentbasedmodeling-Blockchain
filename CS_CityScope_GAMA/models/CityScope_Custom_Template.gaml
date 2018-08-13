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
		create BlockCar number: nbBlockCar;
		}
		
	reflex creationUser{
		if(cycle = 1){
			create BlockCarUser number: nbBlockCarUser{
				home <- one_of(world.amenity);
				location <- any_location_in (home);
				write(location);
				work <- one_of(world.building);
				write(any_location_in(work));
				write("-------------------------");
			}
		}
	}
}

species BlockCarUser skills:[moving]{
	building home;
	building work;
	int startWork <- 7 ;
	int endWork <- 16  ;
	string nextObjective <- "work";
	building target <- nil;
	float speed <- 0.1 #km/#h;
	BlockCar myBlockCar <- nil;
	
	reflex updateTarget {
		if(currentHour > startWork and currentHour < endWork){
			target <- work;
		}
		else if(currentHour > endWork){
			target <- home;
		}
	} 
	reflex move{
		if(target != nil){
		  point togoTarget <- any_point_in(target);
		  write(togoTarget);	
		  if(target = work and nextObjective = "work"){
			  //do askBlockCar(location,work);
		      do goto target: togoTarget on: road_graph  ;
		      nextObjective <- "home";
	      }
		  else if(target = home and nextObjective = "home"){
		    do goto target: togoTarget on: road_graph  ;
		    nextObjective <- "work"; 
		  }
		}
		
	    target <- nil;
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
	}
	
	action dropOff{
		point target <- any_point_in(endPoints at 0);
		do goto target: target on: road_graph;
		if(location = target){
			isFree <- true;
			write("coucou");
		}
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

