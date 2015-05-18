// functions
// declaration order
// non declared vars
// scope

var x = function(a, b){
	var a = 2;
};
x(2,4);

y(2,4);
function y(a, b){
	var a = 2;
};

a = 2;
//console.log(a);
