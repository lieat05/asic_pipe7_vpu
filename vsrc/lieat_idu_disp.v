module lieat_idu_disp(
  input       clock,
  input       reset,

  input       flush_req,
  input       id_i_valid,
  output      id_i_ready,

  input [4:0] disp_op,
  input       disp_condition,
  output      disp_ena,
  output      disp_valid_pre,
  
  output      disp_com_valid,
  input       disp_com_ready,  
  output      disp_lsu_valid,
  input       disp_lsu_ready,
  output      disp_muldiv_valid,
  input       disp_muldiv_ready,
  output      disp_vpu_valid,
  input       disp_vpu_ready,
  output      disp_fpu_valid,
  input       disp_fpu_ready
);
// ================================================================================================================================================
// VALID-READY SHAKEHAND
// ================================================================================================================================================
wire id_i_sh;
wire id_o_sh;
wire disp_com_sh;
wire disp_lsu_sh;
wire disp_muldiv_sh;
wire disp_vpu_sh;
wire disp_fpu_sh;

wire op_com;
wire op_lsu;
wire op_mul;
wire op_vpu;
wire op_fpu;

wire disp_valid;
// ================================================================================================================================================
// SHAKEHAND
// ================================================================================================================================================
assign id_i_sh = id_i_valid & id_i_ready;
assign id_o_sh = disp_com_sh | disp_lsu_sh | disp_muldiv_sh | disp_vpu_sh | disp_fpu_sh;
assign disp_com_sh = disp_com_valid & disp_com_ready;
assign disp_lsu_sh = disp_lsu_valid & disp_lsu_ready;
assign disp_muldiv_sh = disp_muldiv_valid & disp_muldiv_ready;
assign disp_vpu_sh = disp_vpu_valid & disp_vpu_ready;
assign disp_fpu_sh = disp_fpu_valid & disp_fpu_ready;
// ================================================================================================================================================
// OP_SEL
// ================================================================================================================================================
assign op_com = disp_op[0];
assign op_lsu = disp_op[1];
assign op_mul = disp_op[2];
assign op_vpu = disp_op[3];
assign op_fpu = disp_op[4];

wire disp_valid_set = id_i_sh;
wire disp_valid_clr = id_o_sh;
wire disp_valid_ena = disp_valid_set | disp_valid_clr | flush_req;
wire disp_valid_nxt = (disp_valid_set | (~disp_valid_clr)) & (~flush_req);
lieat_general_dfflr #(1) disp_valid_dff(clock,reset,disp_valid_ena,disp_valid_nxt,disp_valid_pre);
assign disp_valid = disp_valid_pre & disp_condition & (~flush_req);//case:valid but oitf_raw_dep
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign disp_ena = id_o_sh;
assign disp_com_valid = disp_valid & op_com;
assign disp_lsu_valid = disp_valid & op_lsu;
assign disp_muldiv_valid = disp_valid & op_mul;
assign disp_vpu_valid = disp_valid & op_vpu;
assign disp_fpu_valid = disp_valid & op_fpu;
assign id_i_ready = (~disp_valid_pre) | id_o_sh;
endmodule
