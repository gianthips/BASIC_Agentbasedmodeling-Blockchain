/**
* Name: CityScope Kendall
* Author: Arnaud Grignard
* Description: Agent-based model running on the CityScope Platform. Actually used on 2 different cities.
*/

model CityScope

global {
	string cityScopeCity;
	// GIS FILE //	
	file bound_shapefile <- file("../includes/"+cityScopeCity+"/Bounds.shp");
	file buildings_shapefile <- file("../includes/"+cityScopeCity+"/Buildings.shp");
	file roads_shapefile <- file("../includes/"+cityScopeCity+"/Roads.shp");
	file amenities_shapefile <- file("../includes/"+cityScopeCity+"/Amenities.shp");
	file table_bound_shapefile <- file("../includes/"+cityScopeCity+"/table_bounds.shp");
	file imageRaster <- file('../includes/images/gama_black.png') ;
	geometry shape <- envelope(bound_shapefile);
	graph road_graph;
	graph<people, people> interaction_graph;
	
	//////////// CITYMATRIX   //////////////
	map<string, unknown> cityMatrixData;
	list<map<string, int>> cityMatrixCell;
	list<float> density_array;
	int toggle1;
	map<int,list> citymatrix_map_settings<- [-1::["Green","Green"],0::["R","L"],1::["R","M"],2::["R","S"],3::["O","L"],4::["O","M"],5::["O","S"],6::["A","Road"],7::["A","Plaza"]];	
	map<string,rgb> color_map<- ["R"::#white, "O"::#gray,"S"::#gamablue, "M"::#gamaorange, "L"::#gamared, "Green"::#green, "Plaza"::#brown, "Road"::#gray]; 
	list scale_string<- ["S", "M", "L"];
	list usage_string<- ["R", "O"]; 
	
	//PARAMETERS
	bool moveOnRoadNetworkGlobal <- true parameter: "Move on road network:" category: "Simulation";
	int distance parameter: 'distance ' category: "Visualization" min: 1 <- 100#m;	
	bool drawInteraction <- false parameter: "Draw Interaction:" category: "Visualization";
	bool cityMatrix <-true parameter: "CityMatrix:" category: "Environment";
	bool onlineGrid <-true parameter: "Online Grid:" category: "Environment";
	bool localHost <-false parameter: "Local Host:" category: "Environment";
	bool dynamicGrid <-true parameter: "Update Grid:" category: "Environment";
	bool realAmenity <-true parameter: "Real Amenities:" category: "Environment";
	int refresh <- 50 min: 1 max:1000 parameter: "Refresh rate (cycle):" category: "Environment";
	
	float step <- 10 #sec;
	int current_hour update: (time / #hour) mod 24 ;
	int min_work_start <-4 ;
	int max_work_start <- 10;
	int min_lunch_start <- 11;
	int max_lunch_start <- 13;
	int min_rework_start <- 14;
	int max_rework_start <- 16;
	int min_dinner_start <- 18;
	int max_dinner_start <- 20;
	int min_work_end <- 21; 
	int max_work_end <- 22; 
	float min_speed <- 4 #km / #h;
	float max_speed <- 6 #km / #h; 
	float angle;
	point center;
	float brickSize;
	string cityIOUrl;
	
	init {
		write "cityScopeCity" + cityScopeCity + " w:" + world.shape.width + " h:" + world.shape.height;
		create building from: buildings_shapefile with: [usage::string(read ("Usage")),scale::string(read ("Scale"))];
		create road from: roads_shapefile ;
		if(cityScopeCity= "volpe"){
			angle <- -9.74;
			center <-{3305,2075};
			brickSize <- 70.0;
		}
		if(cityScopeCity= "andorra"){
			angle <-3.0;
			center <-{2525,830};
			brickSize <- 37.5;
		}
		
		if(localHost=false and cityMatrix = true){
			cityIOUrl <-"https://cityio.media.mit.edu/api/table/citymatrix_"+cityScopeCity;
		}
		else{
			cityIOUrl <-"http://localhost:8080/table/citymatrix_"+cityScopeCity;
		}
		
	    road_graph <- as_edge_graph(road);
		create table from: table_bound_shapefile;
        
        if(realAmenity = true){
          create amenity from: amenities_shapefile{
		    scale <- scale_string[rnd(2)];	
		    fromGrid<-false;
		    size<-10+rnd(20);
		  }		
        }
	    if(cityMatrix = true){
	    	do initGrid;
	    }	
	    do initPop;		
	}
	
		action initPop{
		  write "initPop"; 
		  ask people {do die;}
		  ask building where  (each.usage="R"){
		    create people number: (cityScopeCity = "volpe") ? shape.area/2000 : (flip(0.1) ? 1 : 0){//shape.area/2000 {
				living_place <- myself;
				location <- any_location_in (living_place);
				scale <- myself.scale;	
				speed <- min_speed + rnd (max_speed - min_speed) ;
				initialSpeed <-speed;
				time_to_work <- min_work_start + rnd (max_work_start - min_work_start) ;
				time_to_lunch <- min_lunch_start + rnd (max_lunch_start - min_lunch_start) ;
				time_to_rework <- min_rework_start + rnd (max_rework_start - min_rework_start) ;
				time_to_dinner <- min_dinner_start + rnd (max_dinner_start - min_dinner_start) ;
				time_to_sleep <- min_work_end + rnd (max_work_end - min_work_end) ;
				working_place <- one_of(building  where (each.usage="O" and each.scale=scale)) ;
				eating_place <- one_of(amenity where (each.scale=scale )) ;
				dining_place <- one_of(amenity where (each.scale=scale )) ;
				objective <- "resting"; 
			}				
		  }
		}
	
	action initGrid{
  		ask amenity where (each.fromGrid=true){
  			do die;
  		}
		if(onlineGrid = true){
		  cityMatrixData <- json_file(cityIOUrl).contents;
	    }
	    else{
	      cityMatrixData <- json_file("../includes/cityIO_Kendall.json").contents;
	    }	
		cityMatrixCell <- cityMatrixData["grid"];
		density_array <- cityMatrixData["objects"]["density"];
		toggle1 <- int(cityMatrixData["objects"]["toggle1"]);	
		loop l over: cityMatrixCell { 
		      create amenity {
		      	  id <-int(l["type"]);
		      	  x<-l["x"];
		      	  y<-l["y"];
				  location <- {	center.x + (13-l["x"])*brickSize,	center.y+ l["y"]*brickSize};  
				  location<- {(location.x * cos(angle) + location.y * sin(angle)),-location.x * sin(angle) + location.y * cos(angle)};
				  shape <- square(brickSize*0.9) at_location location;	
				  size<-10+rnd(10);
				  fromGrid<-true;  
				  scale <- citymatrix_map_settings[id][1];
				  color<-color_map[scale];
              }	        
        }
        ask amenity{
          if ((x = 0 and y = 0) and fromGrid = true){
            do die;
          }
        }		
	}
	

	
	reflex updateGrid when: ((cycle mod refresh) = 0) and (dynamicGrid = true) and (cityMatrix=true){	
		do initGrid;
	}
	
	reflex updateGraph when:(drawInteraction = true or toggle1 = 7){
		interaction_graph <- graph<people, people>(people as_distance_graph(distance));
	}
	
	reflex updatePop when: ((cycle mod 8640) = 0){
		do initPop;
	}
}

species building schedules: []{
	string usage;
	string scale;
	int depth;	
	aspect base {	
     	draw shape color: rgb(50,50,50,125);
	}
	aspect usage{
		draw shape color: color_map[usage];
	}
	aspect scale{
		draw shape color: color_map[scale];
	}
	aspect demoScreen{
		if(toggle1=1){
			draw shape color: color_map[usage];
		}
		if(toggle1=2){
			if(usage="O"){
			  draw shape color: color_map[scale];
			}
			
		}
		if(toggle1=3){
			if(usage="R"){
			  draw shape color: color_map[scale];
			}
		}
	}
	aspect demoTable{
		if(toggle1=2){
			draw shape color: color_map[usage];
		}
		if(toggle1=3){
			draw shape color: color_map[scale];
		}
	}
}

species road  schedules: []{
	rgb color <- #red ;
	aspect base {
		draw shape color: rgb(125,125,125,75) ;
	}
}

species people skills:[moving]{
	rgb color <- #yellow ; 
	float initialSpeed;
	building living_place <- nil ;
	building working_place <- nil ;
	amenity eating_place<-nil;
	amenity dining_place<-nil;
	int time_to_work ;
	int time_to_lunch;
	int time_to_rework;
	int time_to_dinner;
	int time_to_sleep;
	string objective ;
	string curMovingMode<-"wandering";	
	string scale;
	string usage; 
	point the_target <- nil ;
	int degree;
	float radius;
	bool moveOnRoad<-true;
	
	action travellingMode{
		curMovingMode <- "travelling";
		speed <-initialSpeed;	
	}
	
    reflex updateTargetAndObjective {
		
		if(current_hour > time_to_work and current_hour < time_to_lunch  and objective = "resting"){
			objective <- "working" ;
			the_target <- any_location_in (working_place);
			do travellingMode;			
	    }
	
	    if(current_hour > time_to_lunch and current_hour < time_to_rework and objective = "working"){
			objective <- "eating" ;
			the_target <- any_location_in (eating_place); 
			do travellingMode;
	    } 
	
	    if (current_hour > time_to_rework and current_hour < time_to_dinner  and objective = "eating"){
			objective <- "reworking" ;
			the_target <- any_location_in (working_place);
			do travellingMode;
	    } 
	    if(current_hour > time_to_dinner and current_hour < time_to_sleep  and objective = "reworking"){
			objective <- "dinning" ;
			the_target <- any_location_in (dining_place);
			do travellingMode;
	    } 
	
	    if(current_hour > time_to_sleep and (current_hour < 24) and objective = "dinning"){
			objective <- "resting" ;
			the_target <- any_location_in (living_place);
			do travellingMode;
	    } 
		
	} 
	 
	reflex move {
	    if(moveOnRoad = true and the_target !=nil){
	      do goto target: the_target on: road_graph ; 
	    }else{
	      do goto target: the_target;
	    }
		
		if (the_target = location) {
			the_target <- nil ;
			curMovingMode <- "wandering";
		}
		if(curMovingMode = "wandering"){
			do wander speed:0.5 #km / #h;
		}
	}
		
	aspect scale{
      draw circle(14) color: color_map[scale];
	}
	
	aspect scaleTable{
		if(toggle1 >4)
		{
		  draw circle(4) color: color_map[scale];	
		}
      
	}
}

species amenity schedules:[]{
	int id;
	string scale;
	bool fromGrid;
	float density <-0.0;
	rgb color;
	int x;
	int y;
	int size;

	aspect onScreen {
		if(fromGrid){
			draw shape rotated_by -angle color: rgb(color.red, color.green, color.blue,75);
		}
		else{
			if (toggle1 =  6){
			  draw circle(size) empty:true border:#white color: #white;
		      draw circle(size) color: rgb(255,255,255,125);	
			}
		}
	}
	
    aspect onTable {
		if(!fromGrid){
			if (toggle1 =  6){
			  draw circle(size) empty:true border:#white color: #white;
		      draw circle(size) color: rgb(255,255,255,125);	
			}
		}
	}
}

species table{
	aspect base {
		draw shape empty:true border:rgb(75,75,75) color: rgb(75,75,75) ;
	}	
}



experiment CityScopeVolpe type: gui {
	parameter 'CityScope:' var: cityScopeCity category: 'GIS' <-"volpe" among:["volpe", "andorra"];
	float minimum_cycle_duration <- 0.02;
	output {	
		display CityScope  type:opengl background:#black toolbar:true{
			species table aspect:base refresh:false;
			species road aspect: base;
			species building aspect:usage;
			species amenity aspect: onScreen ;
			
			graphics "text" 
			{
               draw string(current_hour) + "h" color: # white font: font("Helvetica", 25, #italic) at: {world.shape.width*0.85,world.shape.height*0.975};
               draw imageRaster size:40#px at:{world.shape.width*0.95, world.shape.height*0.95};
               draw rectangle(900,700) rotated_by 9.74 color:#black at: { 2500, 2150};
            }
             graphics "density"{
             	point hpos<-{world.shape.width*0.85,world.shape.height*0.675};
             	int barW<-60;
             	int factor<-20;
             	loop i from: 0 to: length(density_array) -1{
             		draw rectangle(barW,density_array[i]*factor) color: (i=0 or i=3) ? #gamablue : ((i=1 or i=4) ? #gamaorange: #gamared) at: {hpos.x+barW*1.1*i,hpos.y-density_array[i]*factor/2};
             	}
            }
            graphics "time"{
             	point hpos<-{world.shape.width*0.85,world.shape.height*0.7};
             	int barW<-20;
             	int factor<-20;
            	draw rectangle(barW*current_hour+1,50) color:#gamablue at: {hpos.x+barW*current_hour*0.5,hpos.y};//{hpos.x+current_hour*barW/2,hpos.y-density_array[0]*factor/2};
            	
            }
            graphics "interaction_graph" {
				if (interaction_graph != nil  and (drawInteraction = true or toggle1=7) ) {	
					loop eg over: interaction_graph.edges {
                        people src <- interaction_graph source_of eg;
                        people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points)  color:(src.scale = target.scale) ? color_map[src.scale] : #green;
					}
				} 	
			}
			species people aspect:scale;
			
		}			
	}
}









