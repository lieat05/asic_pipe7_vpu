module lieat_exu_lsu(
  input                          clock,
  input                          reset,
  input                          flush_req,

  input                          lsu_i_valid,
  output                         lsu_i_ready,
  input [`XLEN-1:0]              lsu_i_pc,
  input [`XLEN-1:0]              lsu_i_imm,
  input [`XLEN-1:0]              lsu_i_src1,
  input [`XLEN-1:0]              lsu_i_src2,
  input [`INFOBUS_LSU_WIDTH-1:0] lsu_i_infobus,
  input [`REG_IDX-1:0]           lsu_i_rd,
  input                          lsu_i_rdwen,

  output                         lsu_req_valid,
  input                          lsu_req_ready,
  output                         lsu_req_ren,
  output                         lsu_req_wen,
  output [`XLEN-1:0]             lsu_req_addr,
  output [2:0]                   lsu_req_flag,
  output [`XLEN-1:0]             lsu_req_wdata,
  output                         lsu_req_fencei,

  input                          lsu_rsp_valid,
  output                         lsu_rsp_ready,
  input  [`XLEN-1:0]             lsu_rsp_rdata,
  input                          lsu_rsp_fencei_over,

  output                         lsu_o_valid,
  input                          lsu_o_ready,
  output [`XLEN-1:0]             lsu_o_pc,
  output                         lsu_o_wen,
  output [`REG_IDX-1:0]          lsu_o_rd,
  output [`XLEN-1:0]             lsu_o_data,
  output                         lsu_o_fencei_finish,
  output                         lsu_o_flush,

  output                         clint_timeset_wen,
  output [1:0]                   clint_timeset_bsel,//200_4000 200_4004 200_BFF8 200_BFFC
  output [31:0]                  clint_timeset_wdata,
  input  [31:0]                  clint_timeset_rdata,
  output                         clint_msipset_wen,
  output [31:0]                  clint_msipset_wdata,
  input  [31:0]                  clint_msipset_rdata
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                          lsu_i_sh = lsu_i_valid & lsu_i_ready;
wire                          lsu_req_sh = lsu_req_valid & lsu_req_ready;
wire                          lsu_flush_ena;
wire                          lsu_req_valid_pre;

wire [`XLEN-1:0]              lsu_i_addr;
wire                          lsu_rdwen;
wire [`XLEN-1:0]              lsu_pc;
wire [`XLEN-1:0]              lsu_src2;
wire [`XLEN-1:0]              lsu_addr;
wire [`REG_IDX-1:0]           lsu_rd;
wire [`INFOBUS_LSU_WIDTH-1:0] lsu_infobus;

wire                          lsu_rsp_wen;
wire [`XLEN-1:0]              lsu_rsp_pc;
wire [`REG_IDX-1:0]           lsu_rsp_rd;

wire                          clint_valid;
wire                          clint_msip_valid;
wire                          clint_time_valid;
// ================================================================================================================================================
// FLUSH CONTROL
// ================================================================================================================================================
lieat_general_dfflr #(1)        lsu_flush_ena_dff(clock,reset,1'b1,lsu_i_sh,lsu_flush_ena);
assign lsu_o_flush = lsu_flush_ena & flush_req;
// ================================================================================================================================================
// STAGE: INPUT
// ================================================================================================================================================
assign lsu_i_addr = lsu_i_src1 + lsu_i_imm;
assign lsu_i_ready = ~lsu_req_valid_pre | lsu_req_sh;

lieat_general_dfflr #(1)                  lsu_rdwen_dff(clock,reset,lsu_i_sh,lsu_i_rdwen,lsu_rdwen);
lieat_general_dfflr #(`XLEN)              lsu_pc_dff(clock,reset,lsu_i_sh,lsu_i_pc,lsu_pc);
lieat_general_dfflr #(`XLEN)              lsu_src1_dff(clock,reset,lsu_i_sh,lsu_i_addr,lsu_addr);
lieat_general_dfflr #(`XLEN)              lsu_src2_dff(clock,reset,lsu_i_sh,lsu_i_src2,lsu_src2);
lieat_general_dfflr #(`REG_IDX)           lsu_rd_dff(clock,reset,lsu_i_sh,lsu_i_rd,lsu_rd);
lieat_general_dfflr #(`INFOBUS_LSU_WIDTH) lsu_infobus_dff(clock,reset,lsu_i_sh,lsu_i_infobus,lsu_infobus);
// ================================================================================================================================================
// STAGE: REQ
// ================================================================================================================================================
wire [1:0] lsu_sizesel  = lsu_infobus[`INFOBUS_LSU_SIZE];
wire       lsu_usignsel = lsu_infobus[`INFOBUS_LSU_USIGN];
wire       lsu_load     = lsu_infobus[`INFOBUS_LSU_LOAD];
wire       lsu_store    = lsu_infobus[`INFOBUS_LSU_STORE];
wire       lsu_fencei   = lsu_infobus[`INFOBUS_LSU_FENCEI];

wire lsu_req_valid_pre_set = lsu_i_sh;
wire lsu_req_valid_pre_clr = lsu_req_sh | lsu_o_flush | clint_valid;
wire lsu_req_valid_pre_ena = lsu_req_valid_pre_set | lsu_req_valid_pre_clr;
wire lsu_req_valid_pre_nxt = lsu_req_valid_pre_set | (~lsu_req_valid_pre_clr);
lieat_general_dfflr #(1) lsu_req_valid_pre_dff(clock,reset,lsu_req_valid_pre_ena,lsu_req_valid_pre_nxt,lsu_req_valid_pre);

assign lsu_req_valid = lsu_req_valid_pre & ~lsu_o_flush & (lsu_addr[31:24] != 8'h02);
assign lsu_req_ren   = lsu_load;
assign lsu_req_wen   = lsu_store;
assign lsu_req_flag  = {lsu_usignsel,lsu_sizesel};
assign lsu_req_addr  = lsu_addr;
assign lsu_req_wdata = lsu_src2;
assign lsu_req_fencei= lsu_fencei;
// ================================================================================================================================================
// STAGE: RSP
// ================================================================================================================================================
lieat_general_dfflr #(`XLEN)    lsu_o_pc_dff(clock,reset,lsu_req_sh | clint_valid,lsu_pc,lsu_rsp_pc);
lieat_general_dfflr #(`REG_IDX) lsu_o_rd_dff(clock,reset,lsu_req_sh,lsu_rd,lsu_rsp_rd);
lieat_general_dfflr #(1)        lsu_o_wen_dff(clock,reset,lsu_req_sh,lsu_rdwen,lsu_rsp_wen);
lieat_general_dfflr #(1)        lsu_o_fencei_dff(clock,reset,1'b1,lsu_rsp_fencei_over,lsu_o_fencei_finish);

assign lsu_rsp_ready = lsu_o_ready;
assign lsu_o_valid   = lsu_rsp_valid | clint_valid;
assign lsu_o_data    = clint_msip_valid ? clint_msipset_rdata : clint_time_valid ? clint_timeset_rdata : lsu_rsp_rdata;
assign lsu_o_pc      = clint_valid ? lsu_pc : lsu_rsp_pc;
assign lsu_o_rd      = clint_valid ? lsu_rd : lsu_rsp_rd;
assign lsu_o_wen     = clint_valid ? lsu_rdwen : lsu_rsp_wen;

assign clint_timeset_wen   = clint_time_valid & lsu_req_wen;
assign clint_msipset_wen   = clint_msip_valid & lsu_req_wen;
assign clint_timeset_bsel  = {2{(lsu_req_addr[31:16] == 16'h0200)}} & {
(lsu_req_addr[15:0] == 16'hbff8)|(lsu_req_addr[15:0] == 16'hbffc),
(lsu_req_addr[15:0] == 16'h4004)|(lsu_req_addr[15:0] == 16'hbffc)};
assign clint_timeset_wdata = lsu_req_wdata;
assign clint_msipset_wdata = lsu_req_wdata;
assign clint_valid = clint_msip_valid | clint_time_valid;
assign clint_msip_valid = lsu_flush_ena & ~lsu_o_flush & (lsu_req_addr == 32'h02000000);
assign clint_time_valid = lsu_flush_ena & ~lsu_o_flush & (lsu_req_addr[31:16] == 16'h0200) & 
((lsu_req_addr[15:0] == 16'h4000) | (lsu_req_addr[15:0] == 16'h4004) | (lsu_req_addr[15:0] == 16'hBFF8) | (lsu_req_addr[15:0] == 16'hBFFC));
endmodule
