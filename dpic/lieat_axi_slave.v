module lieat_axi_slave(
  // ================================================================================================================================================
  // SLAVE
  // ================================================================================================================================================
  output             io_slave_awready,
  input              io_slave_awvalid,
  input  [31:0]      io_slave_awaddr,
  input  [3:0]       io_slave_awid,
  input  [7:0]       io_slave_awlen,
  input  [2:0]       io_slave_awsize,
  input  [1:0]       io_slave_awburst,

  output             io_slave_wready,
  input              io_slave_wvalid,
  input  [63:0]      io_slave_wdata,
  input  [7:0]       io_slave_wstrb,
  input              io_slave_wlast,

  input              io_slave_bready,
  output             io_slave_bvalid,
  output [1:0]       io_slave_bresp,
  output [3:0]       io_slave_bid,

  output             io_slave_arready,
  input              io_slave_arvalid,
  input  [31:0]      io_slave_araddr,
  input  [3:0]       io_slave_arid,
  input  [7:0]       io_slave_arlen,
  input  [2:0]       io_slave_arsize,
  input  [1:0]       io_slave_arburst,

  input              io_slave_rready,
  output             io_slave_rvalid,
  output [1:0]       io_slave_rresp,
  output [63:0]      io_slave_rdata,
  output             io_slave_rlast,
  output [3:0]       io_slave_rid,
  // ================================================================================================================================================
  // SRAM
  // ================================================================================================================================================
  output             sram_axi_arvalid,
  input              sram_axi_arready,
  output [`XLEN-1:0] sram_axi_araddr,
  output [2:0]       sram_axi_arsize,
  output [3:0]       sram_axi_arid,

  input              sram_axi_rvalid,
  output             sram_axi_rready,
  input  [63:0]      sram_axi_rdata,
  input  [3:0]       sram_axi_rid,

  output             sram_axi_awvalid,
  input              sram_axi_awready,
  output [`XLEN-1:0] sram_axi_awaddr,
  output [2:0]       sram_axi_awsize,  
  output [3:0]       sram_axi_awid,

  output             sram_axi_wvalid,
  input              sram_axi_wready,
  output [63:0]      sram_axi_wdata,

  input              sram_axi_bvalid,
  output             sram_axi_bready,
  input  [1:0]       sram_axi_bresp,
  input  [3:0]       sram_axi_bid
);
wire unused_ok = &{io_slave_awlen,io_slave_arlen,io_slave_awburst,io_slave_wstrb,io_slave_wlast,io_slave_arsize,io_slave_arburst};
assign sram_axi_arvalid = io_slave_arvalid;
assign sram_axi_araddr  = io_slave_araddr;
assign sram_axi_arsize  = io_slave_arsize;
assign sram_axi_arid    = io_slave_arid;
assign sram_axi_rready  = io_slave_rready;
assign sram_axi_awvalid = io_slave_awvalid;
assign sram_axi_awaddr  = io_slave_awaddr;
assign sram_axi_awsize  = io_slave_awsize;
assign sram_axi_awid    = io_slave_awid;
assign sram_axi_wvalid  = io_slave_wvalid;
assign sram_axi_wdata   = io_slave_wdata;
assign sram_axi_bready  = io_slave_bready;

assign io_slave_awready = sram_axi_awready;
assign io_slave_wready  = sram_axi_wready;
assign io_slave_bvalid  = sram_axi_bvalid;
assign io_slave_bresp   = sram_axi_bresp;
assign io_slave_bid     = sram_axi_bid;
assign io_slave_arready = sram_axi_arready;
assign io_slave_rvalid  = sram_axi_rvalid;
assign io_slave_rresp   = 2'b0;
assign io_slave_rdata   = sram_axi_rdata;
assign io_slave_rlast   = 1'b0;
assign io_slave_rid     = sram_axi_rid;
endmodule
