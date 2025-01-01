module lieat_ifu_ifetch_rsp(
  input                 clock,
  input                 reset,
  
  input                 rsp_i_valid,
  input  [`BPU_IDX-1:0] rsp_i_index,
  input  [`XLEN-1:0]    rsp_i_inst,

  output                rsp_o_rs1en,
  output [`REG_IDX-1:0] rsp_o_rs1,
  output                rsp_o_jal,
  output                rsp_o_bxx,
  output [`XLEN-1:0]    rsp_o_immb,
  output                rsp_o_nojump,
  output                rsp_o_prdt_taken,
  output                rsp_o_fencei,

  input                 prdt_en,
  input  [`BPU_IDX-1:0] prdt_index,
  input                 prdt_result
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                dec_bxx;
wire                dec_jal;
wire                dec_rs1en;
wire                dec_nojump;
wire                dec_fencei;
wire [`XLEN-1:0]    dec_immb;
wire [`REG_IDX-1:0] dec_rs1;
wire                bxx_taken;
wire                rsp_o_prdt_taken_r;
// ================================================================================================================================================
// DECODE MODULE
// ================================================================================================================================================
lieat_ifu_dec if_decode(
  .inst(rsp_i_inst),
  .dec_rs1(dec_rs1),
  .dec_rs1en(dec_rs1en),
  .dec_immb(dec_immb),
  .dec_bxx(dec_bxx),
  .dec_jal(dec_jal),
  .dec_nojump(dec_nojump),
  .dec_fencei(dec_fencei)
);
// ================================================================================================================================================
//  PRDT MODULE
// ================================================================================================================================================
lieat_ifu_bpu bpu(
  .clock(clock),
  .reset(reset),
  .index(rsp_i_index),
  .bxx_taken(bxx_taken),
  .prdt_result(prdt_result),
  .prdt_index(prdt_index),
  .prdt_en(prdt_en)
);
assign rsp_o_rs1en      = dec_rs1en;
assign rsp_o_rs1        = dec_rs1;
assign rsp_o_immb       = dec_immb;
assign rsp_o_fencei     = dec_fencei;
assign rsp_o_jal        = dec_jal;//jal jalr
assign rsp_o_bxx        = dec_bxx;
assign rsp_o_nojump     = dec_nojump;
assign rsp_o_prdt_taken = rsp_i_valid ? bxx_taken : rsp_o_prdt_taken_r;
lieat_general_dfflr #(1) bxx_taken_dff(clock,reset,rsp_i_valid,bxx_taken,rsp_o_prdt_taken_r);
endmodule
