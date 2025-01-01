module lieat_core(
  input         clock,
  input         reset,
  input         io_master_awready,
  output        io_master_awvalid,
  output [3:0]  io_master_awid,
  output [31:0] io_master_awaddr,
  output [7:0]  io_master_awlen,
  output [2:0]  io_master_awsize,
  output [1:0]  io_master_awburst,

  input         io_master_wready,
  output        io_master_wvalid,
  output [63:0] io_master_wdata,
  output [7:0]  io_master_wstrb,
  output        io_master_wlast,

  output        io_master_bready,
  input         io_master_bvalid,
  input  [3:0]  io_master_bid,
  input  [1:0]  io_master_bresp,

  input         io_master_arready,
  output        io_master_arvalid,
  output [3:0]  io_master_arid,
  output [31:0] io_master_araddr,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,

  output        io_master_rready,
  input         io_master_rvalid,
  input  [3:0]  io_master_rid,
  input  [1:0]  io_master_rresp,
  input  [63:0] io_master_rdata,
  input         io_master_rlast
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                icache_axi_arvalid;
wire                icache_axi_arready;
wire [`XLEN-1:0]    icache_axi_araddr;
wire                icache_axi_rvalid;
wire                icache_axi_rready;
wire [`AXILEN-1:0]  icache_axi_rdata;
wire                dcache_axi_arvalid;
wire                dcache_axi_arready;
wire [`XLEN-1:0]    dcache_axi_araddr;
wire [2:0]          dcache_axi_arsize;
wire                dcache_axi_rvalid;
wire                dcache_axi_rready;
wire [`AXILEN-1:0]  dcache_axi_rdata;
wire                dcache_axi_awvalid;
wire                dcache_axi_awready;
wire [`XLEN-1:0]    dcache_axi_awaddr;
wire [2:0]          dcache_axi_awsize;
wire                dcache_axi_wvalid;
wire                dcache_axi_wready;
wire [`AXILEN-1:0]  dcache_axi_wdata;
wire [7:0]          dcache_axi_wstrb;
wire                dcache_axi_bvalid;
wire                dcache_axi_bready;
wire [1:0]          dcache_axi_bresp;

wire                if_o_valid;
wire                if_o_ready;
wire [`XLEN-1:0]    if_o_pc;
wire [`XLEN-1:0]    if_o_inst;
wire                if_o_prdt_taken;

wire                id_o_com_valid;
wire                id_o_com_ready;
wire                id_o_lsu_valid;
wire                id_o_lsu_ready;
wire                id_o_muldiv_valid;
wire                id_o_muldiv_ready;
wire                id_o_vpu_valid;
wire                id_o_vpu_ready;
wire                id_o_fpu_valid;
wire                id_o_fpu_ready;

wire [`XLEN-1:0]    id_o_pc;
wire [`XLEN-1:0]    id_o_imm;
wire [`XLEN-1:0]    id_o_infobus;
wire [`REG_IDX-1:0] id_o_rs1;
wire [`REG_IDX-1:0] id_o_rs2;
wire [`REG_IDX-1:0] id_o_rd;
wire                id_o_rdwen;
wire [`XLEN-1:0]    id_o_reg_src1;
wire [`XLEN-1:0]    id_o_reg_src2;

wire                wbck_o_valid;
wire [4:0]          wbck_o_op;
wire                wbck_o_en;
wire [`XLEN-1:0]    wbck_o_pc;
wire [`REG_IDX-1:0] wbck_o_rd;
wire [`XLEN-1:0]    wbck_o_data;
wire                wbck_o_lsu;
wire                wbck_o_ebreak;

wire                prdt_en;
wire [`BPU_IDX-1:0] prdt_index;
wire                prdt_res;

wire [`REG_IDX-1:0] if_rs1;
wire [`XLEN-1:0]    if_src1;
wire [`XLEN-1:0]    if_reg_src1;
wire                if_src1_dep;

wire                flush_req;
wire [`XLEN-1:0]    flush_pc;
wire                flush_ready;
wire                com_o_flush;
wire                lsu_o_flush;
wire                muldiv_o_flush;
wire                vpu_o_flush;
wire                fpu_o_flush;

wire                longi_empty;
wire                pipeline_empty;

wire                if_hold_req;
wire                if_hold_rsp;
wire                fencei_finish;

wire                time_interrupt;
wire                msip_interrupt;
wire                clint_timeset_wen;
wire                clint_msipset_wen;
wire [1:0]          clint_timeset_bsel;
wire [`XLEN-1:0]    clint_timeset_wdata;
wire [`XLEN-1:0]    clint_msipset_wdata;
wire [`XLEN-1:0]    clint_timeset_rdata;
wire [`XLEN-1:0]    clint_msipset_rdata;
// ================================================================================================================================================
// IFU
// ================================================================================================================================================
lieat_ifu ifu(
  .clock(clock),
  .reset(reset),
  //TO IDU
  .if_o_valid(if_o_valid),
  .if_o_ready(if_o_ready),
  .if_o_pc(if_o_pc),
  .if_o_inst(if_o_inst),
  .if_o_prdt_taken(if_o_prdt_taken),
  //TO DRAM
  .icache_axi_arvalid(icache_axi_arvalid),
  .icache_axi_arready(icache_axi_arready),
  .icache_axi_araddr(icache_axi_araddr),
  .icache_axi_rvalid(icache_axi_rvalid),
  .icache_axi_rready(icache_axi_rready),
  .icache_axi_rdata(icache_axi_rdata),
  //FROM EXU:PRDT CALLBACK
  .if_prdt_en(prdt_en),
  .if_prdt_index(prdt_index),
  .if_prdt_res(prdt_res),
  //FROM EXU:FLUSH
  .if_flush_req(flush_req),
  .if_flush_pc(flush_pc),
  .if_flush_ready(flush_ready),
  //FROM EXU:fencei_finish
  .if_fencei_finish(fencei_finish),
  //FROM CLINT:
  .if_pipeline_empty(pipeline_empty),
  .if_hold_req(if_hold_req),
  .if_hold_rsp(if_hold_rsp),
  //FROM REGFILE:jalr fetch src1
  .if_rs1(if_rs1),
  .if_src1(if_src1),
  .if_src1_dep(if_src1_dep)
);
// ================================================================================================================================================
// IDU
// ================================================================================================================================================
lieat_idu idu(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),
  .com_flush_sh(com_o_flush),
  .lsu_flush_sh(lsu_o_flush),
  .muldiv_flush_sh(muldiv_o_flush),
  .vpu_flush_sh(vpu_o_flush),
  .fpu_flush_sh(fpu_o_flush),
  //FROM IFU
  .id_i_valid(if_o_valid),
  .id_i_ready(if_o_ready),
  .id_i_pc(if_o_pc),
  .id_i_inst(if_o_inst),
  .id_i_prdt_taken(if_o_prdt_taken),
  //TO EXU
  .id_o_com_valid(id_o_com_valid),
  .id_o_com_ready(id_o_com_ready),
  .id_o_lsu_valid(id_o_lsu_valid),
  .id_o_lsu_ready(id_o_lsu_ready),
  .id_o_muldiv_valid(id_o_muldiv_valid),
  .id_o_muldiv_ready(id_o_muldiv_ready),
  .id_o_vpu_valid(id_o_vpu_valid),
  .id_o_vpu_ready(id_o_vpu_ready),
  .id_o_fpu_valid(id_o_fpu_valid),
  .id_o_fpu_ready(id_o_fpu_ready),
  .id_o_pc(id_o_pc),
  .id_o_imm(id_o_imm),
  .id_o_infobus(id_o_infobus),
  .id_o_rs1(id_o_rs1),
  .id_o_rs2(id_o_rs2),
  .id_o_rd(id_o_rd),
  .id_o_rdwen(id_o_rdwen),
  //FROM EXU:OITF WBCK
  .wbck_op(wbck_o_op),
  .wbck_valid(wbck_o_valid),
  //FROM EXU:RS1
  .if_rs1(if_rs1),
  .if_src1_dep(if_src1_dep),
  //FROM EXU:FLUSH
  .pipeline_empty(pipeline_empty),
  .lsu_muldiv_empty(longi_empty)
);
// ================================================================================================================================================
// EXU
// ================================================================================================================================================
lieat_exu exu(
  .clock(clock),
  .reset(reset),
  //FROM IDU
  .ex_i_pc(id_o_pc),
  .ex_i_imm(id_o_imm),
  .ex_i_infobus(id_o_infobus),
  .ex_i_rd(id_o_rd),
  .ex_i_rdwen(id_o_rdwen),
  .ex_i_rs1(id_o_rs1),
  .ex_i_rs2(id_o_rs2),
  .if_i_rs1(if_rs1),
  .ex_i_reg_src1(id_o_reg_src1),
  .ex_i_reg_src2(id_o_reg_src2),
  .if_i_reg_src1(if_reg_src1),
  //FROM IDU
  .com_i_valid(id_o_com_valid),
  .com_i_ready(id_o_com_ready),
  .lsu_i_valid(id_o_lsu_valid),
  .lsu_i_ready(id_o_lsu_ready),
  .muldiv_i_valid(id_o_muldiv_valid),
  .muldiv_i_ready(id_o_muldiv_ready),
  .vpu_i_valid(id_o_vpu_valid),
  .vpu_i_ready(id_o_vpu_ready),
  .fpu_i_valid(id_o_fpu_valid),
  .fpu_i_ready(id_o_fpu_ready),
  
  //WBCK
  .wbck_o_valid(wbck_o_valid),
  .wbck_o_op(wbck_o_op),
  .wbck_o_pc(wbck_o_pc),
  .wbck_o_en(wbck_o_en),
  .wbck_o_rd(wbck_o_rd),
  .wbck_o_data(wbck_o_data),
  .wbck_o_lsu(wbck_o_lsu),
  .wbck_o_ebreak(wbck_o_ebreak),
  //FROM IDU:LONGI DEP
  .com_o_flush(com_o_flush),
  .lsu_o_flush(lsu_o_flush),
  .muldiv_o_flush(muldiv_o_flush),
  .vpu_o_flush(vpu_o_flush),
  .fpu_o_flush(fpu_o_flush),
  //DCACHE:AXI SRAM
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
  .dcache_axi_bresp(dcache_axi_bresp),
  //TO IFU:PRDT prdt
  .ex_to_callback_prdt_en(prdt_en),
  .ex_to_callback_prdt_index(prdt_index),
  .ex_to_callback_prdt_res(prdt_res),
  //FROM EXU:FLUSH
  .ex_to_flush_req(flush_req),
  .ex_to_flush_pc(flush_pc),
  .if_to_flush_sh(flush_ready),

  .prdt_fenceifinish(fencei_finish),

  .if_src1(if_src1),
  .if_hold_req(if_hold_req),
  .if_hold_rsp(if_hold_rsp),
  .if_hold_pc(if_o_pc),
  //CLINT
  .time_interrupt(time_interrupt),
  .msip_interrupt(msip_interrupt),
  .clint_timeset_wen(clint_timeset_wen),
  .clint_timeset_bsel(clint_timeset_bsel),
  .clint_timeset_wdata(clint_timeset_wdata),
  .clint_timeset_rdata(clint_timeset_rdata),
  .clint_msipset_wen(clint_msipset_wen),
  .clint_msipset_wdata(clint_msipset_wdata),
  .clint_msipset_rdata(clint_msipset_rdata)
);
// ================================================================================================================================================
// Regfile and Difftest
// ================================================================================================================================================
lieat_regfile regfile(
  .clock(clock),
  .reset(reset),

  .ifu_rs1(if_rs1),
  .ifu_src1(if_reg_src1),
  .exu_rs1(id_o_rs1),
  .exu_rs2(id_o_rs2),
  .exu_src1(id_o_reg_src1),
  .exu_src2(id_o_reg_src2),

  .wb_pc(wbck_o_pc),
  .wb_valid(wbck_o_valid),
  .wb_en(wbck_o_en),
  .wb_rd(wbck_o_rd),
  .wb_data(wbck_o_data),
  .wb_lsu(wbck_o_lsu),
  .wb_ebreak(wbck_o_ebreak),
  .longi_empty(longi_empty)
);
// ================================================================================================================================================
// CLINT
// ================================================================================================================================================
lieat_clint clint(
  .clock(clock),
  .reset(reset),
  .time_interrupt(time_interrupt),
  .msip_interrupt(msip_interrupt),
  .clint_timeset_wen(clint_timeset_wen),
  .clint_timeset_bsel(clint_timeset_bsel),
  .clint_timeset_wdata(clint_timeset_wdata),
  .clint_timeset_rdata(clint_timeset_rdata),
  .clint_msipset_wen(clint_msipset_wen),
  .clint_msipset_wdata(clint_msipset_wdata),
  .clint_msipset_rdata(clint_msipset_rdata)
);
// ================================================================================================================================================
// AXI MASTER
// ================================================================================================================================================
lieat_axi_master axi_master(
  .clock(clock),
  .reset(reset),
  .icache_axi_arvalid(icache_axi_arvalid),
  .icache_axi_arready(icache_axi_arready),
  .icache_axi_araddr(icache_axi_araddr),
  .icache_axi_rvalid(icache_axi_rvalid),
  .icache_axi_rready(icache_axi_rready),
  .icache_axi_rdata(icache_axi_rdata),
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
  .dcache_axi_bresp(dcache_axi_bresp),

  .io_master_awready(io_master_awready),
  .io_master_awvalid(io_master_awvalid),
  .io_master_awaddr(io_master_awaddr),
  .io_master_awid(io_master_awid),
  .io_master_awlen(io_master_awlen),
  .io_master_awsize(io_master_awsize),
  .io_master_awburst(io_master_awburst),

  .io_master_wready(io_master_wready),
  .io_master_wvalid(io_master_wvalid),
  .io_master_wdata(io_master_wdata),
  .io_master_wstrb(io_master_wstrb),
  .io_master_wlast(io_master_wlast),

  .io_master_bready(io_master_bready),
  .io_master_bvalid(io_master_bvalid),
  .io_master_bresp(io_master_bresp),
  .io_master_bid(io_master_bid),

  .io_master_arready(io_master_arready),
  .io_master_arvalid(io_master_arvalid),
  .io_master_araddr(io_master_araddr),
  .io_master_arid(io_master_arid),
  .io_master_arlen(io_master_arlen),
  .io_master_arsize(io_master_arsize),
  .io_master_arburst(io_master_arburst),

  .io_master_rready(io_master_rready),
  .io_master_rvalid(io_master_rvalid),
  .io_master_rresp(io_master_rresp),
  .io_master_rdata(io_master_rdata),
  .io_master_rlast(io_master_rlast),
  .io_master_rid(io_master_rid)
);
endmodule
