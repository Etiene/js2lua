// functions
// declaration order
// non declared vars
// scope


x(2,4); //should ERROR
var x = function(a, b){
	var a = 2;
};
x(2,4);

y(2,4); //should be OK
function y(a, b){
	var a = 2;
};

var b = a; //should ERROR

var c = 1 > 3; //should be OK