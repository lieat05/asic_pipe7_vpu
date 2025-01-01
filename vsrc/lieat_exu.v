module lieat_exu(
  input                 clock,
  input                 reset,
  
  input [`XLEN-1:0]     ex_i_pc,
  input [`XLEN-1:0]     ex_i_imm,
  input [`XLEN-1:0]     ex_i_infobus,
  input [`REG_IDX-1:0]  ex_i_rd,
  input                 ex_i_rdwen,
  input [`REG_IDX-1:0]  if_i_rs1,
  input [`REG_IDX-1:0]  ex_i_rs1,
  input [`REG_IDX-1:0]  ex_i_rs2,
  input [`XLEN-1:0]     if_i_reg_src1,
  input [`XLEN-1:0]     ex_i_reg_src1,
  input [`XLEN-1:0]     ex_i_reg_src2,

  input                 com_i_valid,
  output                com_i_ready,
  input                 lsu_i_valid,
  output                lsu_i_ready,
  input                 muldiv_i_valid,
  output                muldiv_i_ready,
  input                 vpu_i_valid,
  output                vpu_i_ready,
  input                 fpu_i_valid,
  output                fpu_i_ready,

  output [`XLEN-1:0]    wbck_o_pc,
  output [4:0]          wbck_o_op,
  output                wbck_o_valid,
  output                wbck_o_en,
  output [`REG_IDX-1:0] wbck_o_rd,
  output [`XLEN-1:0]    wbck_o_data,
  output                wbck_o_lsu,
  output                wbck_o_ebreak,
  
  output                com_o_flush,
  output                lsu_o_flush,
  output                muldiv_o_flush,
  output                vpu_o_flush,
  output                fpu_o_flush,

  output                dcache_axi_arvalid,
  input                 dcache_axi_arready,
  output [`XLEN-1:0]    dcache_axi_araddr,
  output [2:0]          dcache_axi_arsize,
  input                 dcache_axi_rvalid,
  output                dcache_axi_rready,
  input  [63:0]         dcache_axi_rdata,
  output                dcache_axi_awvalid,
  input                 dcache_axi_awready,
  output [`XLEN-1:0]    dcache_axi_awaddr,
  output [2:0]          dcache_axi_awsize,
  output                dcache_axi_wvalid,
  input                 dcache_axi_wready,
  output [63:0]         dcache_axi_wdata,
  output [7:0]          dcache_axi_wstrb,
  input                 dcache_axi_bvalid,
  output                dcache_axi_bready,
  input  [1:0]          dcache_axi_bresp,

  output                ex_to_callback_prdt_en,
  output [`BPU_IDX-1:0] ex_to_callback_prdt_index,
  output                ex_to_callback_prdt_res,
  
  output                ex_to_flush_req,
  output [`XLEN-1:0]    ex_to_flush_pc,
  input                 if_to_flush_sh,
  
  output                prdt_fenceifinish,
  
  output [`XLEN-1:0]    if_src1,
  output                if_hold_req,
  input  [`XLEN-1:0]    if_hold_pc,
  input                 if_hold_rsp,

  output                clint_timeset_wen,
  output [1:0]          clint_timeset_bsel,//200_4000 200_4004 200_BFF8 200_BFFC
  output [31:0]         clint_timeset_wdata,
  input  [31:0]         clint_timeset_rdata,
  output                clint_msipset_wen,
  output [31:0]         clint_msipset_wdata,
  input  [31:0]         clint_msipset_rdata,
  input                 msip_interrupt,
  input                 time_interrupt
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                flush_req;

wire [`XLEN-1:0]    ex_i_src1;
wire [`XLEN-1:0]    ex_i_src2;

wire                com_o_valid;
wire                com_o_ready;
wire                com_o_wen;
wire [`XLEN-1:0]    com_o_pc;
wire [`XLEN-1:0]    com_o_data;
wire [`REG_IDX-1:0] com_o_rd;
wire                com_o_ebreak;

wire                lsu_o_valid;
wire                lsu_o_ready;
wire                lsu_o_wen;
wire [`XLEN-1:0]    lsu_o_pc;
wire [`XLEN-1:0]    lsu_o_data;
wire [`REG_IDX-1:0] lsu_o_rd;
wire                lsu_o_mmio;

wire                muldiv_o_valid;
wire                muldiv_o_ready;
wire                muldiv_o_wen;
wire [`XLEN-1:0]    muldiv_o_pc;
wire [`XLEN-1:0]    muldiv_o_data;
wire [`REG_IDX-1:0] muldiv_o_rd;

wire                vpu_o_valid;
wire                vpu_o_ready;
wire                vpu_o_wen;
wire [`XLEN-1:0]    vpu_o_pc;
wire [`XLEN-1:0]    vpu_o_data;
wire [`REG_IDX-1:0] vpu_o_rd;

wire                fpu_o_valid;
wire                fpu_o_ready;
wire                fpu_o_wen;
wire [`XLEN-1:0]    fpu_o_pc;
wire [`XLEN-1:0]    fpu_o_data;
wire [`REG_IDX-1:0] fpu_o_rd;

wire                lsu_req_valid;
wire                lsu_req_ready;
wire                lsu_req_ren;
wire                lsu_req_wen;
wire [`XLEN-1:0]    lsu_req_addr;
wire [2:0]          lsu_req_flag;
wire                lsu_req_fencei;
wire [`XLEN-1:0]    lsu_req_wdata;
wire                lsu_rsp_valid;
wire                lsu_rsp_ready;
wire [`XLEN-1:0]    lsu_rsp_rdata;
wire                lsu_rsp_fencei_over;

wire                vpu_req_valid;
wire                vpu_req_ready;
wire                vpu_req_ren;
wire                vpu_req_wen;
wire [`XLEN-1:0]    vpu_req_addr;
wire [2:0]          vpu_req_flag;
wire [`XLEN-1:0]    vpu_req_wdata;
wire                vpu_rsp_valid;
wire                vpu_rsp_ready;
wire [`XLEN-1:0]    vpu_rsp_rdata;
// ================================================================================================================================================
// FORWARD SRC
// ================================================================================================================================================
assign if_src1   = com_o_valid & com_o_wen & (com_o_rd == if_i_rs1) ? com_o_data : wbck_o_valid & wbck_o_en & (wbck_o_rd == if_i_rs1) ? wbck_o_data : if_i_reg_src1;
assign ex_i_src1 = com_o_valid & com_o_wen & (com_o_rd == ex_i_rs1) ? com_o_data : wbck_o_valid & wbck_o_en & (wbck_o_rd == ex_i_rs1) ? wbck_o_data : ex_i_reg_src1;
assign ex_i_src2 = com_o_valid & com_o_wen & (com_o_rd == ex_i_rs2) ? com_o_data : wbck_o_valid & wbck_o_en & (wbck_o_rd == ex_i_rs2) ? wbck_o_data : ex_i_reg_src2;
// ================================================================================================================================================
// COM
// ================================================================================================================================================
lieat_exu_com com(
  .clock(clock),
  .reset(reset),
  
  .com_i_valid(com_i_valid),
  .com_i_ready(com_i_ready),
  .com_i_pc(ex_i_pc),
  .com_i_imm(ex_i_imm),
  .com_i_infobus(ex_i_infobus),
  .com_i_rd(ex_i_rd),
  .com_i_rdwen(ex_i_rdwen),
  .com_i_src1(ex_i_src1),
  .com_i_src2(ex_i_src2),

  .com_o_valid(com_o_valid),
  .com_o_ready(com_o_ready),
  .com_o_pc(com_o_pc),
  .com_o_wen(com_o_wen),
  .com_o_rd(com_o_rd),
  .com_o_data(com_o_data),
  .com_o_ebreak(com_o_ebreak),
  .com_o_flush(com_o_flush),

  .prdt_en(ex_to_callback_prdt_en),
  .prdt_index(ex_to_callback_prdt_index),
  .prdt_res(ex_to_callback_prdt_res),
  //FLUSH:BRANCH_ERROR ECALL CLINT
  .flush_req(flush_req),
  .flush_pc(ex_to_flush_pc),
  .flush_sh(if_to_flush_sh),
  //CLINT
  .msip_interrupt(msip_interrupt),
  .time_interrupt(time_interrupt),
  //IF HOLD
  .if_hold_req(if_hold_req),
  .if_hold_pc(if_hold_pc),
  .if_hold_rsp(if_hold_rsp)
);
assign ex_to_flush_req = flush_req;
// ================================================================================================================================================
// LSU
// ================================================================================================================================================
lieat_exu_lsu lsu(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),
  .lsu_i_valid(lsu_i_valid),
  .lsu_i_ready(lsu_i_ready),
  .lsu_i_pc(ex_i_pc),
  .lsu_i_imm(ex_i_imm),
  .lsu_i_src1(ex_i_src1),
  .lsu_i_src2(ex_i_src2),
  .lsu_i_infobus(ex_i_infobus[`INFOBUS_LSU_WIDTH-1:0]),
  .lsu_i_rd(ex_i_rd),
  .lsu_i_rdwen(ex_i_rdwen),

  .lsu_req_valid(lsu_req_valid),
  .lsu_req_ready(lsu_req_ready),
  .lsu_req_ren(lsu_req_ren),
  .lsu_req_wen(lsu_req_wen),
  .lsu_req_addr(lsu_req_addr),
  .lsu_req_flag(lsu_req_flag),
  .lsu_req_wdata(lsu_req_wdata),
  .lsu_req_fencei(lsu_req_fencei),

  .lsu_rsp_valid(lsu_rsp_valid),
  .lsu_rsp_ready(lsu_rsp_ready),
  .lsu_rsp_rdata(lsu_rsp_rdata),
  .lsu_rsp_fencei_over(lsu_rsp_fencei_over),
  .lsu_o_valid(lsu_o_valid),
  .lsu_o_ready(lsu_o_ready),
  .lsu_o_pc(lsu_o_pc),
  .lsu_o_wen(lsu_o_wen),
  .lsu_o_rd(lsu_o_rd),
  .lsu_o_data(lsu_o_data),
  .lsu_o_fencei_finish(prdt_fenceifinish),
  .lsu_o_flush(lsu_o_flush),

  .clint_timeset_wen(clint_timeset_wen),
  .clint_timeset_bsel(clint_timeset_bsel),
  .clint_timeset_wdata(clint_timeset_wdata),
  .clint_timeset_rdata(clint_timeset_rdata),
  .clint_msipset_wen(clint_msipset_wen),
  .clint_msipset_wdata(clint_msipset_wdata),
  .clint_msipset_rdata(clint_msipset_rdata)
);
// ================================================================================================================================================
// MULDIV
// ================================================================================================================================================
lieat_exu_muldiv muldiv(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),
  .muldiv_i_valid(muldiv_i_valid),
  .muldiv_i_ready(muldiv_i_ready),
  .muldiv_i_pc(ex_i_pc),
  .muldiv_i_src1(ex_i_src1),
  .muldiv_i_src2(ex_i_src2),
  .muldiv_i_infobus(ex_i_infobus[`INFOBUS_MUL_WIDTH-1:0]),
  .muldiv_i_rd(ex_i_rd),
  .muldiv_i_rdwen(ex_i_rdwen),

  .muldiv_o_valid(muldiv_o_valid),
  .muldiv_o_ready(muldiv_o_ready),
  .muldiv_o_pc(muldiv_o_pc),
  .muldiv_o_wen(muldiv_o_wen),
  .muldiv_o_rd(muldiv_o_rd),
  .muldiv_o_data(muldiv_o_data),
  .muldiv_o_flush(muldiv_o_flush)
);
// ================================================================================================================================================
// VPU
// ================================================================================================================================================
`ifdef VPU_VALID
lieat_exu_vpu vpu(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),
  .vpu_i_valid(vpu_i_valid),
  .vpu_i_ready(vpu_i_ready),
  .vpu_i_pc(ex_i_pc),
  .vpu_i_rs1(ex_i_rs1),
  .vpu_i_rs2(ex_i_rs2),
  .vpu_i_src1(ex_i_src1),
  .vpu_i_src2(ex_i_src2),
  .vpu_i_infobus(ex_i_infobus[`INFOBUS_VPU_WIDTH-1:0]),
  .vpu_i_rd(ex_i_rd),

  .vpu_o_valid(vpu_o_valid),
  .vpu_o_ready(vpu_o_ready),
  .vpu_o_pc(vpu_o_pc),
  .vpu_o_wen(vpu_o_wen),
  .vpu_o_rd(vpu_o_rd),
  .vpu_o_data(vpu_o_data),
  .vpu_o_flush(vpu_o_flush),

  .vpu_req_valid(vpu_req_valid),
  .vpu_req_ready(vpu_req_ready),
  .vpu_req_ren(vpu_req_ren),
  .vpu_req_wen(vpu_req_wen),
  .vpu_req_addr(vpu_req_addr),
  .vpu_req_flag(vpu_req_flag),
  .vpu_req_wdata(vpu_req_wdata),
  .vpu_rsp_valid(vpu_rsp_valid),
  .vpu_rsp_ready(vpu_rsp_ready),
  .vpu_rsp_rdata(vpu_rsp_rdata)
);
`else
  wire unused_ok = &{vpu_i_valid,vpu_o_ready,vpu_req_ready,vpu_rsp_valid,vpu_rsp_rdata};
  assign vpu_o_valid = 1'b0;
  assign vpu_i_ready = 1'b0;
  assign vpu_o_pc    = 32'h0;
  assign vpu_o_wen   = 1'b0;
  assign vpu_o_rd    = 5'b0;
  assign vpu_o_data  = 32'h0;
  assign vpu_o_flush = 1'b0; 
  assign vpu_req_valid = 1'b0;
  assign vpu_req_ren = 1'b0;
  assign vpu_req_wen = 1'b0;
  assign vpu_req_addr = 32'b0;
  assign vpu_req_flag = 3'b0;
  assign vpu_req_wdata = 32'b0;
  assign vpu_rsp_ready = 1'b0;
`endif

`ifdef FPU_VALID
lieat_exu_fpu fpu(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),
  .fpu_i_valid(fpu_i_valid),
  .fpu_i_ready(fpu_i_ready),
  .fpu_i_pc(ex_i_pc),
  .fpu_i_imm(ex_i_imm),
  .fpu_i_src1(ex_i_src1),
  .fpu_i_src2(ex_i_src2),
  .fpu_i_infobus(ex_i_infobus),
  .fpu_i_rd(ex_i_rd),
  .fpu_i_rdwen(ex_i_rdwen),
  
  .fpu_o_valid(fpu_o_valid),
  .fpu_o_ready(fpu_o_ready),
  .fpu_o_pc(fpu_o_pc),
  .fpu_o_wen(fpu_o_wen),
  .fpu_o_rd(fpu_o_rd),
  .fpu_o_data(fpu_o_data),
  .fpu_o_flush(fpu_o_flush)
);
`else
  wire unused_ok = &{fpu_i_valid,fpu_o_ready};
  assign fpu_o_valid = 1'b0;
  assign fpu_i_ready = 1'b0;
  assign fpu_o_pc    = 32'h0;
  assign fpu_o_wen   = 1'b0;
  assign fpu_o_rd    = 5'b0;
  assign fpu_o_data  = 32'h0;
  assign fpu_o_flush = 1'b0; 
`endif
// ================================================================================================================================================
// WBCK
// ================================================================================================================================================
lieat_exu_wbu wbu(
  .clock(clock),
  .reset(reset),

  .com_wbck_valid(com_o_valid),
  .com_wbck_ready(com_o_ready),
  .com_wbck_pc(com_o_pc),
  .com_wbck_en(com_o_wen),
  .com_wbck_rd(com_o_rd),
  .com_wbck_data(com_o_data),
  .com_wbck_ebreak(com_o_ebreak),

  .lsu_wbck_valid(lsu_o_valid),
  .lsu_wbck_ready(lsu_o_ready),
  .lsu_wbck_pc(lsu_o_pc),
  .lsu_wbck_en(lsu_o_wen),
  .lsu_wbck_rd(lsu_o_rd),
  .lsu_wbck_data(lsu_o_data),
  .lsu_wbck_mmio(lsu_o_mmio),

  .muldiv_wbck_valid(muldiv_o_valid),
  .muldiv_wbck_ready(muldiv_o_ready),
  .muldiv_wbck_pc(muldiv_o_pc),
  .muldiv_wbck_en(muldiv_o_wen),
  .muldiv_wbck_rd(muldiv_o_rd),
  .muldiv_wbck_data(muldiv_o_data),

  .vpu_wbck_valid(vpu_o_valid),
  .vpu_wbck_ready(vpu_o_ready),
  .vpu_wbck_pc(vpu_o_pc),
  .vpu_wbck_en(vpu_o_wen),
  .vpu_wbck_rd(vpu_o_rd),
  .vpu_wbck_data(vpu_o_data),

  .fpu_wbck_valid(fpu_o_valid),
  .fpu_wbck_ready(fpu_o_ready),
  .fpu_wbck_pc(fpu_o_pc),
  .fpu_wbck_en(fpu_o_wen),
  .fpu_wbck_rd(fpu_o_rd),
  .fpu_wbck_data(fpu_o_data),

  .wbck_o_valid(wbck_o_valid),
  .wbck_o_op(wbck_o_op),
  .wbck_o_pc(wbck_o_pc),
  .wbck_o_en(wbck_o_en),
  .wbck_o_rd(wbck_o_rd),
  .wbck_o_data(wbck_o_data),
  .wbck_o_lsu(wbck_o_lsu),
  .wbck_o_ebreak(wbck_o_ebreak)
);
// ================================================================================================================================================
// LSU TO DCACHE:REQ AND RSP
// ================================================================================================================================================
lieat_exu_dcache dcache(
  .clock(clock),
  .reset(reset),
  .lsu_req_valid(lsu_req_valid),
  .lsu_req_ready(lsu_req_ready),
  .lsu_req_ren(lsu_req_ren),
  .lsu_req_wen(lsu_req_wen),
  .lsu_req_addr(lsu_req_addr),
  .lsu_req_flag(lsu_req_flag),
  .lsu_req_wdata(lsu_req_wdata),
  .lsu_rsp_valid(lsu_rsp_valid),
  .lsu_rsp_ready(lsu_rsp_ready),
  .lsu_rsp_rdata(lsu_rsp_rdata),
  .lsu_req_fencei(lsu_req_fencei),
  .lsu_rsp_fencei_over(lsu_rsp_fencei_over),
  .lsu_rsp_mmio(lsu_o_mmio),
  .vpu_req_valid(vpu_req_valid),
  .vpu_req_ready(vpu_req_ready),
  .vpu_req_ren(vpu_req_ren),
  .vpu_req_wen(vpu_req_wen),
  .vpu_req_addr(vpu_req_addr),
  .vpu_req_flag(vpu_req_flag),
  .vpu_req_wdata(vpu_req_wdata),
  .vpu_rsp_valid(vpu_rsp_valid),
  .vpu_rsp_ready(vpu_rsp_ready),
  .vpu_rsp_rdata(vpu_rsp_rdata),
  .dcache_axi_arvalid(dcache_axi_arvalid),
  .dcache_axi_arready(dcache_axi_arready),
  .dcache_axi_araddr(dcache_axi_araddr),
  .dcache_axi_arsize(dcache_axi_arsize),
  .dcache_axi_rvalid(dcache_axi_rvalid),
  .dcache_axi_rready(dcache_axi_rready),
  .dcache_axi_rdata(dcache_axi_rdata),
  .dcache_axi_awvalid(dcache_axi_awvalid),
  .dcache_axi_awready(dcache_axi_awready),
  .dcache_axi_awaddr(dcache_axi_awaddr),
  .dcache_axi_awsize(dcache_axi_awsize),
  .dcache_axi_wvalid(dcache_axi_wvalid),
  .dcache_axi_wready(dcache_axi_wready),
  .dcache_axi_wdata(dcache_axi_wdata),
  .dcache_axi_wstrb(dcache_axi_wstrb),
  .dcache_axi_bvalid(dcache_axi_bvalid),
  .dcache_axi_bready(dcache_axi_bready),
  .dcache_axi_bresp(dcache_axi_bresp)
);
endmodule
