module lieat_general_compress32 #(
	parameter WIDTH = 16
)(
	input  logic [WIDTH-1:0] x1,
	input  logic [WIDTH-1:0] x2,
	input  logic [WIDTH-1:0] x3,
	
	output logic [WIDTH-1:0] sum_o,
	output logic [WIDTH-1:0] carry_o
);
assign sum_o[WIDTH-1:0] = x1 ^ x2 ^ x3;
assign carry_o[WIDTH-1:0] = {(x1[WIDTH-2:0] & x2[WIDTH-2:0]) | (x1[WIDTH-2:0] & x3[WIDTH-2:0]) | (x2[WIDTH-2:0] & x3[WIDTH-2:0]), 1'b0};
endmodule
