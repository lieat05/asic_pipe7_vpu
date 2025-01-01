module lieat_idu (
  input                 clock,
  input                 reset,
  
  input                 flush_req,
  input                 com_flush_sh,//stage1
  input                 lsu_flush_sh,
  input                 muldiv_flush_sh,
  input                 vpu_flush_sh,
  input                 fpu_flush_sh,

  input                 id_i_valid,
  output                id_i_ready,
  input  [`XLEN-1:0]    id_i_pc,
  input  [`XLEN-1:0]    id_i_inst,
  input                 id_i_prdt_taken,
  
  output                id_o_com_valid,
  input                 id_o_com_ready,
  output                id_o_lsu_valid,
  input                 id_o_lsu_ready,
  output                id_o_muldiv_valid,
  input                 id_o_muldiv_ready,
  output                id_o_vpu_valid,
  input                 id_o_vpu_ready,
  output                id_o_fpu_valid,
  input                 id_o_fpu_ready,
  output [`XLEN-1:0]    id_o_pc,
  output [`XLEN-1:0]    id_o_imm,
  output [`XLEN-1:0]    id_o_infobus,
  output [`REG_IDX-1:0] id_o_rs1,
  output [`REG_IDX-1:0] id_o_rs2,
  output [`REG_IDX-1:0] id_o_rd,
  output                id_o_rdwen,

  input                 wbck_valid,
  input  [4:0]          wbck_op,

  input  [`REG_IDX-1:0] if_rs1,
  output                if_src1_dep,
  
  output                pipeline_empty,
  output                lsu_muldiv_empty
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire [`XLEN-1:0]    id_pc;
wire [`XLEN-1:0]    id_inst;
wire                id_prdt_taken;

wire                dec_rs1en;
wire                dec_rs2en;
wire                dec_rdwen;
wire [`REG_IDX-1:0] dec_rs1;
wire [`REG_IDX-1:0] dec_rs2;
wire [`REG_IDX-1:0] dec_rd;
wire [`XLEN-1:0]    dec_imm;
wire [`XLEN-1:0]    dec_infobus;
wire                dec_rv32;
wire                dec_ilgl;

wire                fifo_empty;

wire [4:0]          disp_op;
wire                disp_ena;
wire                disp_valid_pre;
wire                disp_condition;

wire                if_src1_id_dep;
wire                if_src1_ex_dep;                
// ================================================================================================================================================
// INPUT SIGNAL
// ================================================================================================================================================
wire id_i_sh = id_i_valid & id_i_ready;
lieat_general_dfflr #(`XLEN) id_pc_dff(clock,reset,id_i_sh,id_i_pc,id_pc);
lieat_general_dfflr #(`XLEN) id_inst_dff(clock,reset,id_i_sh,id_i_inst,id_inst);
lieat_general_dfflr #(1)     id_prdt_taken_dff(clock,reset,id_i_sh,id_i_prdt_taken,id_prdt_taken);
// ================================================================================================================================================
// DECODE MODULE
// ================================================================================================================================================
lieat_idu_dec decode(
  .inst(id_inst),
  .prdt_taken(id_prdt_taken),
  .id_rv32(dec_rv32),
  .id_rs1en(dec_rs1en),
  .id_rs2en(dec_rs2en),
  .id_rdwen(dec_rdwen),
  .id_rs1(dec_rs1),
  .id_rs2(dec_rs2),
  .id_rd(dec_rd),
  .id_imm(dec_imm),
  .id_infobus(dec_infobus),
  .id_ilgl(dec_ilgl),
  .disp_op(disp_op)
);
// ================================================================================================================================================
// LONG_INST OITF MODULE
// ================================================================================================================================================
lieat_idu_depend depend(
  .clock(clock),
  .reset(reset),

  .com_flush(com_flush_sh),
  .lsu_flush(lsu_flush_sh),
  .muldiv_flush(muldiv_flush_sh),
  .vpu_flush(vpu_flush_sh),
  .fpu_flush(fpu_flush_sh),

  .disp_ena(disp_ena),
  .disp_op(disp_op),
  .disp_rs1en(dec_rs1en),
  .disp_rs2en(dec_rs2en),
  .disp_rdwen(dec_rdwen),
  .disp_rs1(dec_rs1),
  .disp_rs2(dec_rs2),
  .disp_rd(dec_rd),

  .wbck_ena(wbck_valid),
  .wbck_op(wbck_op),

  .if_rs1(if_rs1),
  .if_dep(if_src1_ex_dep),

  .disp_condition(disp_condition),
  .fifo_empty(fifo_empty),
  .lsu_muldiv_empty(lsu_muldiv_empty)
);
// ================================================================================================================================================
// DISP MODULE
// ================================================================================================================================================
lieat_idu_disp disp(
  .clock(clock),
  .reset(reset),

  .flush_req(flush_req),
  .id_i_valid(id_i_valid),
  .id_i_ready(id_i_ready),

  .disp_op(disp_op),
  .disp_ena(disp_ena),
  .disp_valid_pre(disp_valid_pre),
  .disp_condition(disp_condition),

  .disp_com_valid(id_o_com_valid),
  .disp_com_ready(id_o_com_ready),
  .disp_lsu_valid(id_o_lsu_valid),
  .disp_lsu_ready(id_o_lsu_ready),
  .disp_muldiv_valid(id_o_muldiv_valid),
  .disp_muldiv_ready(id_o_muldiv_ready),
  .disp_vpu_valid(id_o_vpu_valid),
  .disp_vpu_ready(id_o_vpu_ready),
  .disp_fpu_valid(id_o_fpu_valid),
  .disp_fpu_ready(id_o_fpu_ready)
);
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign if_src1_id_dep = id_o_rdwen & (id_o_rs1 == if_rs1) & disp_valid_pre;
assign if_src1_dep = if_src1_ex_dep | if_src1_id_dep;
assign id_o_pc = id_pc;
assign id_o_imm = dec_imm;
assign id_o_infobus = dec_infobus;
assign id_o_rs1 = dec_rs1;
assign id_o_rs2 = dec_rs2;
assign id_o_rd = dec_rd;
assign id_o_rdwen = dec_rdwen;
assign pipeline_empty = fifo_empty & ~id_o_com_valid & ~id_o_muldiv_valid & ~id_o_lsu_valid & ~id_o_vpu_valid & ~id_o_fpu_valid;
wire unused_ok = &{dec_rv32,dec_ilgl};
endmodule
