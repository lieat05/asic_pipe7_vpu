module lieat_exu_com(
  input                 clock,
  input                 reset,  

  input                 com_i_valid,
  output                com_i_ready,
  input [`XLEN-1:0]     com_i_pc,
  input [`XLEN-1:0]     com_i_imm,
  input [`XLEN-1:0]     com_i_src1,
  input [`XLEN-1:0]     com_i_src2,
  input [`XLEN-1:0]     com_i_infobus,
  input [`REG_IDX-1:0]  com_i_rd,
  input                 com_i_rdwen,

  output                com_o_valid,
  input                 com_o_ready,
  output [`XLEN-1:0]    com_o_pc,
  output                com_o_wen,
  output [`REG_IDX-1:0] com_o_rd,
  output [`XLEN-1:0]    com_o_data,
  output                com_o_ebreak,
  output                com_o_flush,

  output                prdt_en,
  output [`BPU_IDX-1:0] prdt_index,
  output                prdt_res,
  //FLUSH:BRANCH_ERROR ECALL CLINT
  output [`XLEN-1:0]    flush_pc,
  output                flush_req,
  input                 flush_sh,
  //CLINT
  input                 msip_interrupt,
  input                 time_interrupt,
  //IF HOLD
  output                if_hold_req,
  input  [`XLEN-1:0]    if_hold_pc,
  input                 if_hold_rsp
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                com_i_sh;
wire                com_o_sh;

wire [`REG_IDX-1:0] com_rd;
wire                com_rdwen;
wire [`XLEN-1:0]    com_pc;
wire [`XLEN-1:0]    com_imm;
wire [`XLEN-1:0]    com_src1;
wire [`XLEN-1:0]    com_src2;
wire [`XLEN-1:0]    com_infobus;

wire                alu_valid;
wire                bjp_valid;
wire                csr_valid;

wire [`XLEN-1:0]    alu_o_data;
wire [`XLEN-1:0]    bjp_o_data;
wire [`XLEN-1:0]    csr_o_data;

wire                prdt_flush;
wire                csr_flush;
wire [`XLEN-1:0]    prdt_pc;
wire [`XLEN-1:0]    csr_flush_pc;
wire                com_flush_ena;
// ================================================================================================================================================
// INPUT SIGNAL
// ================================================================================================================================================
lieat_general_dfflr #(`XLEN) com_pc_dff(clock,reset,com_i_sh,com_i_pc,com_pc);
lieat_general_dfflr #(`XLEN) com_imm_dff(clock,reset,com_i_sh,com_i_imm,com_imm);
lieat_general_dfflr #(`XLEN) com_infobus_dff(clock,reset,com_i_sh,com_i_infobus,com_infobus);
lieat_general_dfflr #(5)     com_rd_dff(clock,reset,com_i_sh,com_i_rd,com_rd);
lieat_general_dfflr #(1)     com_rdwen_dff(clock,reset,com_i_sh,com_i_rdwen,com_rdwen);
lieat_general_dfflr #(`XLEN) com_src1_dff(clock,reset,com_i_sh,com_i_src1,com_src1);
lieat_general_dfflr #(`XLEN) com_src2_dff(clock,reset,com_i_sh,com_i_src2,com_src2);
// ================================================================================================================================================
// FLUSH CONTROL
// ================================================================================================================================================
wire flush_req_set = csr_flush | prdt_flush;
wire flush_req_clr = flush_sh;
wire flush_req_ena = flush_req_set | flush_req_clr;
wire flush_req_nxt = flush_req_set | ~flush_req_clr;
wire [`XLEN-1:0] flush_pc_nxt = csr_flush ? csr_flush_pc : prdt_pc;
lieat_general_dfflr #(1) flush_req_dff(clock,reset,flush_req_ena,flush_req_nxt,flush_req);
lieat_general_dfflr #(`XLEN) flush_pc_dff(clock,reset,flush_req_set,flush_pc_nxt,flush_pc);

lieat_general_dfflr #(1) flush_ena_dff(clock,reset,1'b1,com_i_sh,com_flush_ena);
assign com_o_flush = com_flush_ena & flush_req;
// ================================================================================================================================================
// STATE CONTROL
// ================================================================================================================================================
assign com_i_sh = com_i_valid & com_i_ready;
assign com_o_sh = com_o_valid & com_o_ready;

wire com_o_valid_pre;
wire com_o_valid_pre_set = com_i_sh;
wire com_o_valid_pre_clr = com_o_sh | com_o_flush;
wire com_o_valid_pre_ena = com_o_valid_pre_set | com_o_valid_pre_clr;
wire com_o_valid_pre_nxt = com_o_valid_pre_set | ~com_o_valid_pre_clr;
lieat_general_dfflr #(1) com_o_valid_pre_dff(clock,reset,com_o_valid_pre_ena,com_o_valid_pre_nxt,com_o_valid_pre);
assign com_o_valid = com_o_valid_pre & ~com_o_flush;

assign com_i_ready   = ~com_o_valid_pre | com_o_sh;
// ================================================================================================================================================
// COM PART
// ================================================================================================================================================
assign alu_valid = com_o_valid & com_infobus[`INFOBUS_ALU_VALID];
assign bjp_valid = com_o_valid & com_infobus[`INFOBUS_BJP_VALID];
assign csr_valid = com_o_valid & com_infobus[`INFOBUS_CSR_VALID];

assign com_o_wen = com_rdwen;
assign com_o_pc  = com_pc;
assign com_o_rd  = com_rd;
assign com_o_data = 
bjp_valid ? bjp_o_data :
csr_valid ? csr_o_data : alu_o_data;
// ================================================================================================================================================
// ALU
// ================================================================================================================================================
lieat_exu_com_alu alu(
  .alu_valid(alu_valid),
  .alu_pc(com_pc),
  .alu_imm(com_imm),
  .alu_src1(com_src1),
  .alu_src2(com_src2),
  .alu_infobus(com_infobus),

  .alu_o_ebreak(com_o_ebreak),
  .alu_o_data(alu_o_data)
);
// ================================================================================================================================================
// BJP
// ================================================================================================================================================
lieat_exu_com_bjp bjp(
  .clock(clock),
  .reset(reset),

  .bjp_valid(bjp_valid),
  .bjp_pc(com_pc),
  .bjp_imm(com_imm),
  .bjp_src1(com_src1),
  .bjp_src2(com_src2),
  .bjp_infobus(com_infobus),

  .bjp_o_data(bjp_o_data),

  .bjp_prdt_en(prdt_en),
  .bjp_prdt_index(prdt_index),
  .bjp_prdt_res(prdt_res),
  .bjp_req_prdt_flush(prdt_flush),
  .bjp_req_prdt_pc(prdt_pc)
);
// ================================================================================================================================================
// CSR
// ================================================================================================================================================
lieat_exu_com_csr csr(
  .clock(clock),
  .reset(reset),

  .csr_valid(csr_valid),
  .csr_pc(com_pc),
  .csr_src1(com_src1),
  .csr_infobus(com_infobus),
  .csr_o_data(csr_o_data),

  .csr_req_flush(csr_flush),
  .csr_req_flush_pc(csr_flush_pc),
  .time_interrupt(time_interrupt),
  .msip_interrupt(msip_interrupt),
  .if_hold_req(if_hold_req),
  .if_hold_pc(if_hold_pc),
  .if_hold_rsp(if_hold_rsp)
);
endmodule
