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
	int nbBlockCar <- 10;
	init{
		create BlockCarUser number: nbBlockCarUser;
		create BlockCar number: nbBlockCar;
	}
}

species BlockCarUser parent:people skills:[moving]{
	reflex move{
		do wander on: road_graph;
	}
	aspect base{
		draw circle(10#m) color:#red;
	}
}


species BlockCar skills:[moving]{
	int nbMaxPassenger <- 1; //TODO Mettre 4
	int currentNbPassenger <- 0;
	bool isFree <- true;
	point target <- nil;
	
	aspect base{
		draw circle(10#m) color:#blue;
	}
	
	reflex move{
		if(isFree = true){
			do wander on: road_graph;
		}
		
		else{
			do goto target: target on: road_graph;
			isFree <- true;
		}
	}
	
	action setLocation(point destination){
		target <- destination;
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

