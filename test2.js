var x = 2.3 + 2;
//this is a comment
if(x < 1){
	x++;
	//var b; //dando erro, nao era pra dar
	var b = 2;
	//console.log(x); 
	if(x < 0 ){
		x = 0;
	}
}else if (4 == x){
	x++;
	// an empty block is accepted JS code
}else if (3 == x){
	// this should be ok
}
else if (2 == x){

}else if (1 == x){
	x++;
	var test = function(hey,ho,lets,go){

		x = 3;
	}; // semicolon optional here too

	function test3(hey,ho,lets,go){

		x = x + 5;
		x%=2;
	};

	//; node accepts a semicolon here too



}else {
	//test2();   // this should trigger a non declared error - it doesnt yet
}
//; node accepts a semicolon here too
/*this is a comment*/



