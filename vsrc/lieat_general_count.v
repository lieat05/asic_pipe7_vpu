module lieat_general_count(
input              count_ena,
output [`XLEN-1:0] count_num
);
lieat_general_dfflr #(`XLEN) count_dff(clock,reset,count_ena,count_num+1'b1,count_num);
endmodule