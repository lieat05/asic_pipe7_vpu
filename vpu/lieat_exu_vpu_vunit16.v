module lieat_exu_vpu_vunit16(
  input         clock,
  input         reset,

  input         vunit_valid,
  input  [15:0] vunit_op1,
  input  [15:0] vunit_op2,
  
  input         vunit_vadd,
  input         vunit_vsub,
  input         vunit_vrsub,

  output        vunit_o_valid,
  output [15:0] vunit_o_data
);
wire [15:0] vadd_res;
wire [15:0] vsub_res;
wire [15:0] vrsub_res;

assign vadd_res  = vunit_op1 + vunit_op2;
assign vsub_res  = vunit_op1 - vunit_op2;
assign vrsub_res = vunit_op2 - vunit_op1;
assign vunit_o_valid = vunit_valid;
assign vunit_o_data  = 
({16{vunit_vadd }} & vadd_res)|
({16{vunit_vsub }} & vsub_res)|
({16{vunit_vrsub}} & vrsub_res);

wire unused_ok = &{clock,reset};
endmodule
