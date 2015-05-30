//function y(){ return 2 }
function y(){
	x++;
}

x = 5;

x = 2 * 5 + 3; 

x = x + 2;

x = 2 + x;

x = y() + 4;

x = 4 + y() / 3;

var z = function(){

}

if(x*3){

}

//x = 2 + ; errors well! :)

// x = + 2; -- bugged

//x = 6; y(); //the first semicolon is mandatory
//x = 6 y(); //errors
//x = 6
//y(); does not error