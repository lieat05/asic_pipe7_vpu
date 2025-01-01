module lieat_ifu(
  input                 clock,
  input                 reset,

  output                if_o_valid,
  input                 if_o_ready,
  output [`XLEN-1:0]    if_o_pc,
  output [`XLEN-1:0]    if_o_inst,
  output                if_o_prdt_taken,

  output                icache_axi_arvalid,
  input                 icache_axi_arready,
  output [`XLEN-1:0]    icache_axi_araddr,
  input                 icache_axi_rvalid,
  output                icache_axi_rready,
  input  [63:0]         icache_axi_rdata,
  //if-ex
  output [`REG_IDX-1:0] if_rs1,
  input  [`XLEN-1:0]    if_src1,
  input                 if_src1_dep,

  input                 if_prdt_en,
  input                 if_prdt_res,
  input  [`BPU_IDX-1:0] if_prdt_index,

  input                 if_flush_req,
  input  [`XLEN-1:0]    if_flush_pc,
  output                if_flush_ready,

  input                 if_hold_req,
  output                if_hold_rsp,//id ex if empty
  input                 if_pipeline_empty,//id empty and ex empty

  input                 if_fencei_finish
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                ifetch_req_valid;
wire                ifetch_req_ready;
wire [`XLEN-1:0]    ifetch_req_pc;

wire                ifetch_rsp_valid;
wire                ifetch_rsp_rs1en;
wire                ifetch_rsp_fencei;
wire                ifetch_rsp_jal;
wire                ifetch_rsp_bxx;
wire                ifetch_rsp_nojump;
wire [`BPU_IDX-1:0] ifetch_rsp_index;
wire [`XLEN-1:0]    ifetch_rsp_immb;
wire [`XLEN-1:0]    ifetch_rsp_pc;
wire [`XLEN-1:0]    ifetch_rsp_inst;
// ================================================================================================================================================
// STAGE1:GENERARE_PC(AGU)  IFETCH_REQ
// ================================================================================================================================================
lieat_ifu_ifetch_req ifu_stage1(
  .clock(clock),
  .reset(reset),
  
  .req_i_flush(if_flush_req),
  .req_i_flush_pc(if_flush_pc),

  .req_i_valid(if_o_valid),
  .req_i_pc(ifetch_rsp_pc),
  .req_i_jal(ifetch_rsp_jal),
  .req_i_bxx(ifetch_rsp_bxx),
  .req_i_bxx_taken(if_o_prdt_taken),
  .req_i_rs1en(ifetch_rsp_rs1en),
  .req_i_rs1dep(if_src1_dep),
  .req_i_src1(if_src1),
  .req_i_immb(ifetch_rsp_immb),
  .req_i_nojump(ifetch_rsp_nojump),
  .req_i_fencei(ifetch_rsp_fencei),
  .req_i_fencei_over(if_fencei_finish),

  .req_o_valid(ifetch_req_valid),
  .req_o_ready(ifetch_req_ready),
  .req_o_pc(ifetch_req_pc)
);
// ================================================================================================================================================
// ICACHE
// ================================================================================================================================================
lieat_ifu_icache icache(
  .clock(clock),
  .reset(reset),

  .if_o_valid(if_o_valid),
  .if_o_ready(if_o_ready),

  .flush_req(if_flush_req),
  .fencei_req(ifetch_rsp_fencei),
  .pipeline_empty(if_pipeline_empty),
  .if_hold_req(if_hold_req),
  .if_hold_rsp(if_hold_rsp),

  .ifetch_req_valid(ifetch_req_valid),
  .ifetch_req_ready(ifetch_req_ready),
  .ifetch_req_pc(ifetch_req_pc),

  .ifetch_rsp_valid(ifetch_rsp_valid),
  .ifetch_rsp_pc(ifetch_rsp_pc),
  .ifetch_rsp_inst(ifetch_rsp_inst),
  .ifetch_rsp_index(ifetch_rsp_index),

  .icache_axi_arvalid(icache_axi_arvalid),
  .icache_axi_arready(icache_axi_arready),
  .icache_axi_araddr(icache_axi_araddr),
  .icache_axi_rvalid(icache_axi_rvalid),
  .icache_axi_rready(icache_axi_rready),
  .icache_axi_rdata(icache_axi_rdata)
);
// ================================================================================================================================================
// STAGE2:IFETCH_RSP BPU
// ================================================================================================================================================
lieat_ifu_ifetch_rsp ifu_stage2(
  .clock(clock),
  .reset(reset),
  
  .rsp_i_valid(ifetch_rsp_valid),
  .rsp_i_index(ifetch_rsp_index),
  .rsp_i_inst(if_o_inst),

  .rsp_o_rs1(if_rs1),
  .rsp_o_rs1en(ifetch_rsp_rs1en),
  .rsp_o_immb(ifetch_rsp_immb),
  .rsp_o_fencei(ifetch_rsp_fencei),
  .rsp_o_jal(ifetch_rsp_jal),
  .rsp_o_bxx(ifetch_rsp_bxx),
  .rsp_o_nojump(ifetch_rsp_nojump),
  .rsp_o_prdt_taken(if_o_prdt_taken),

  .prdt_en(if_prdt_en),
  .prdt_result(if_prdt_res),
  .prdt_index(if_prdt_index)
);
// ================================================================================================================================================
// OUTPUT SINGAL
// ================================================================================================================================================
assign if_o_pc = ifetch_rsp_pc;
assign if_o_inst = ifetch_rsp_inst;
assign if_flush_ready  = ifetch_req_ready;
// ================================================================================================================================================
// FLUSH DPIC_COUNT
// ================================================================================================================================================
`ifdef DPIC_VALID
  wire [`XLEN-1:0] flush_count;
  wire flush_ena = if_flush_req & if_flush_ready;
  lieat_general_dfflr #(`XLEN) flush_count_dff(clock,reset,flush_ena,flush_count+1'b1,flush_count);
  import "DPI-C" function void flush_dpic(input int flush_count);
  always @(posedge clock or posedge reset) flush_dpic(flush_count);
`endif
endmodule
