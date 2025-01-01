module lieat_exu_vpu_vunit32(
  input              clock,
  input              reset,

  input              vunit_valid,
  input  [`XLEN-1:0] vunit_op1,
  input  [`XLEN-1:0] vunit_op2,
  
  input              vunit_vadd,
  input              vunit_vsub,
  input              vunit_vrsub,

  output             vunit_o_valid,
  output [`XLEN-1:0] vunit_o_data
);
wire [`XLEN-1:0] vadd_res;
wire [`XLEN-1:0] vsub_res;
wire [`XLEN-1:0] vrsub_res;

assign vadd_res  = vunit_op1 + vunit_op2;
assign vsub_res  = vunit_op1 - vunit_op2;
assign vrsub_res = vunit_op2 - vunit_op1;
assign vunit_o_valid = vunit_valid;
assign vunit_o_data  = 
({`XLEN{vunit_vadd }} & vadd_res)|
({`XLEN{vunit_vsub }} & vsub_res)|
({`XLEN{vunit_vrsub}} & vrsub_res);

wire unused_ok = &{clock,reset};
endmodule
