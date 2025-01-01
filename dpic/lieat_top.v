`include "defines.v"
`include "lieat_general_dff.v"
module lieat_top(
  input clock,
  input reset
);
// ================================================================================================================================================
// CORE
// ================================================================================================================================================
lieat_core core(
  .clock(clock),
  .reset(reset),

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
// ================================================================================================================================================
// SRAM
// ================================================================================================================================================
lieat_sram sram(
  .clock(clock),
  .reset(reset),
  .sram_axi_arvalid(sram_axi_arvalid),
  .sram_axi_arready(sram_axi_arready),
  .sram_axi_araddr(sram_axi_araddr),
  .sram_axi_arsize(sram_axi_arsize),
  .sram_axi_arid(sram_axi_arid),
  .sram_axi_rvalid(sram_axi_rvalid),
  .sram_axi_rready(sram_axi_rready),
  .sram_axi_rdata(sram_axi_rdata),
  .sram_axi_rid(sram_axi_rid),
  .sram_axi_awvalid(sram_axi_awvalid),
  .sram_axi_awready(sram_axi_awready),
  .sram_axi_awaddr(sram_axi_awaddr),
  .sram_axi_awsize(sram_axi_awsize),
  .sram_axi_awid(sram_axi_awid),
  .sram_axi_wvalid(sram_axi_wvalid),
  .sram_axi_wready(sram_axi_wready),
  .sram_axi_wdata(sram_axi_wdata),
  .sram_axi_bvalid(sram_axi_bvalid),
  .sram_axi_bready(sram_axi_bready),
  .sram_axi_bresp(sram_axi_bresp),
  .sram_axi_bid(sram_axi_bid)
);
// ================================================================================================================================================
// AXI-Lite
// ================================================================================================================================================
wire        io_master_awready;
wire        io_master_awvalid;
wire [31:0] io_master_awaddr;
wire [3:0]  io_master_awid;
wire [7:0]  io_master_awlen;
wire [2:0]  io_master_awsize;
wire [1:0]  io_master_awburst;

wire        io_master_wready;
wire        io_master_wvalid;
wire [63:0] io_master_wdata;
wire [7:0]  io_master_wstrb;
wire        io_master_wlast;

wire        io_master_bready;
wire        io_master_bvalid;
wire [1:0]  io_master_bresp;
wire [3:0]  io_master_bid;

wire        io_master_arready;
wire        io_master_arvalid;
wire [31:0] io_master_araddr;
wire [3:0]  io_master_arid;
wire [7:0]  io_master_arlen;
wire [2:0]  io_master_arsize;
wire [1:0]  io_master_arburst;

wire        io_master_rready;
wire        io_master_rvalid;
wire [1:0]  io_master_rresp;
wire [63:0] io_master_rdata;
wire        io_master_rlast;
wire [3:0]  io_master_rid;

wire        sram_axi_awready;
wire        sram_axi_awvalid;
wire [31:0] sram_axi_awaddr;
wire [3:0]  sram_axi_awid;
wire [2:0]  sram_axi_awsize;

wire        sram_axi_wready;
wire        sram_axi_wvalid;
wire [63:0] sram_axi_wdata;

wire        sram_axi_bready;
wire        sram_axi_bvalid;
wire [1:0]  sram_axi_bresp;
wire [3:0]  sram_axi_bid;

wire        sram_axi_arready;
wire        sram_axi_arvalid;
wire [31:0] sram_axi_araddr;
wire [3:0]  sram_axi_arid;
wire [2:0]  sram_axi_arsize;

wire        sram_axi_rready;
wire        sram_axi_rvalid;
wire [63:0] sram_axi_rdata;
wire [3:0]  sram_axi_rid;

lieat_axi_slave axi_slave(
  .io_slave_awready(io_master_awready),
  .io_slave_awvalid(io_master_awvalid),
  .io_slave_awaddr(io_master_awaddr),
  .io_slave_awid(io_master_awid),
  .io_slave_awlen(io_master_awlen),
  .io_slave_awsize(io_master_awsize),
  .io_slave_awburst(io_master_awburst),

  .io_slave_wready(io_master_wready),
  .io_slave_wvalid(io_master_wvalid),
  .io_slave_wdata(io_master_wdata),
  .io_slave_wstrb(io_master_wstrb),
  .io_slave_wlast(io_master_wlast),

  .io_slave_bready(io_master_bready),
  .io_slave_bvalid(io_master_bvalid),
  .io_slave_bresp(io_master_bresp),
  .io_slave_bid(io_master_bid),

  .io_slave_arready(io_master_arready),
  .io_slave_arvalid(io_master_arvalid),
  .io_slave_araddr(io_master_araddr),
  .io_slave_arid(io_master_arid),
  .io_slave_arlen(io_master_arlen),
  .io_slave_arsize(io_master_arsize),
  .io_slave_arburst(io_master_arburst),

  .io_slave_rready(io_master_rready),
  .io_slave_rvalid(io_master_rvalid),
  .io_slave_rresp(io_master_rresp),
  .io_slave_rdata(io_master_rdata),
  .io_slave_rlast(io_master_rlast),
  .io_slave_rid(io_master_rid),

  .sram_axi_arvalid(sram_axi_arvalid),
  .sram_axi_arready(sram_axi_arready),
  .sram_axi_araddr(sram_axi_araddr),
  .sram_axi_arsize(sram_axi_arsize),
  .sram_axi_arid(sram_axi_arid),
  .sram_axi_rvalid(sram_axi_rvalid),
  .sram_axi_rready(sram_axi_rready),
  .sram_axi_rdata(sram_axi_rdata),
  .sram_axi_rid(sram_axi_rid),
  .sram_axi_awvalid(sram_axi_awvalid),
  .sram_axi_awready(sram_axi_awready),
  .sram_axi_awaddr(sram_axi_awaddr),
  .sram_axi_awsize(sram_axi_awsize),
  .sram_axi_awid(sram_axi_awid),
  .sram_axi_wvalid(sram_axi_wvalid),
  .sram_axi_wready(sram_axi_wready),
  .sram_axi_wdata(sram_axi_wdata),
  .sram_axi_bvalid(sram_axi_bvalid),
  .sram_axi_bready(sram_axi_bready),
  .sram_axi_bresp(sram_axi_bresp),
  .sram_axi_bid(sram_axi_bid)
);
endmodule
