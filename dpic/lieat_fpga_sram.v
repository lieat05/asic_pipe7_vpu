/* verilator lint_off ASSIGNDLY */
module lieat_sram #(
  parameter delay = 1
)(
  input                clock,
  input                reset,
  //AR channel
  input                sram_axi_arvalid,
  output               sram_axi_arready,
  input  [`XLEN-1:0]   sram_axi_araddr,
  input  [2:0]         sram_axi_arsize,
  input  [3:0]         sram_axi_arid,
  //R channel
  output               sram_axi_rvalid,
  input                sram_axi_rready,
  output [`XLEN*2-1:0] sram_axi_rdata,
  output [3:0]         sram_axi_rid,
  //AW channel
  input                sram_axi_awvalid,
  output               sram_axi_awready,
  input  [`XLEN-1:0]   sram_axi_awaddr,
  input  [2:0]         sram_axi_awsize,
  input  [3:0]         sram_axi_awid,
  //W channel
  input                sram_axi_wvalid,
  output               sram_axi_wready,
  input  [`XLEN*2-1:0] sram_axi_wdata,
  //B channel
  output               sram_axi_bvalid,
  input                sram_axi_bready,
  output [1:0]         sram_axi_bresp,
  output [3:0]         sram_axi_bid
);
wire unused_ok = &{sram_axi_awid};
// ================================================================================================================================================
// WHEN NEED DELAY
// ================================================================================================================================================
reg sram_ar_delay;
reg sram_aw_delay;

always @(posedge clock or negedge reset) begin
  if(ar_sh) if(delay != 0) begin
    if(delay == 1)sram_ar_delay <= ar_sh;
    else sram_ar_delay <= #(delay*2-2) ar_sh;
  end
  if(r_sh) sram_ar_delay <= 1'b0;
  if(aw_sh & w_sh) if(delay != 0) begin
    if(delay == 1)sram_aw_delay <= aw_sh;
    else sram_aw_delay <= #(delay*2-2) aw_sh;
  end
  if(b_sh) sram_aw_delay <= 1'b0;
end
// ================================================================================================================================================
// VALID-READY CHANNEL
// ================================================================================================================================================
wire ar_sh = sram_axi_arvalid & sram_axi_arready;
wire r_sh  = sram_axi_rvalid  & sram_axi_rready ;
wire aw_sh = sram_axi_awvalid & sram_axi_awready;
wire w_sh  = sram_axi_wvalid  & sram_axi_wready ;
wire b_sh  = sram_axi_bvalid  & sram_axi_bready ;

wire sram_axi_arready_set = r_sh;
wire sram_axi_arready_clr = ar_sh;
wire sram_axi_arready_ena = sram_axi_arready_set | sram_axi_arready_clr;
wire sram_axi_arready_nxt = sram_axi_arready_set | (~sram_axi_arready_clr);
lieat_general_dfflrs #(1) sram_axi_arready_dff (clock,reset,sram_axi_arready_ena,sram_axi_arready_nxt,sram_axi_arready);
wire sram_axi_rvalid_set  = (delay == 0) ? ar_sh : (~r_sh & sram_ar_delay);
wire sram_axi_rvalid_clr  = r_sh;
wire sram_axi_rvalid_ena  = sram_axi_rvalid_set | sram_axi_rvalid_clr;
wire sram_axi_rvalid_nxt  = sram_axi_rvalid_set | (~sram_axi_rvalid_clr);
lieat_general_dfflr #(1) sram_axi_rvalid_dff (clock,reset,sram_axi_rvalid_ena,sram_axi_rvalid_nxt,sram_axi_rvalid);
wire sram_axi_awready_set = b_sh;
wire sram_axi_awready_clr = aw_sh;
wire sram_axi_awready_ena = sram_axi_awready_set | sram_axi_awready_clr;
wire sram_axi_awready_nxt = sram_axi_awready_set | (~sram_axi_awready_clr);
lieat_general_dfflrs #(1) sram_axi_awready_dff (clock,reset,sram_axi_awready_ena,sram_axi_awready_nxt,sram_axi_awready);
wire sram_axi_wready_set  = b_sh;
wire sram_axi_wready_clr  = w_sh;
wire sram_axi_wready_ena  = sram_axi_wready_set | sram_axi_wready_clr;
wire sram_axi_wready_nxt  = sram_axi_wready_set | (~sram_axi_wready_clr);
lieat_general_dfflrs #(1) sram_axi_wready_dff (clock,reset,sram_axi_wready_ena,sram_axi_wready_nxt,sram_axi_wready);
wire sram_axi_bvalid_set  = (delay == 0) ? (aw_sh & w_sh) : (~b_sh & sram_aw_delay);//to be changed
wire sram_axi_bvalid_clr  = b_sh;
wire sram_axi_bvalid_ena  = sram_axi_bvalid_set | sram_axi_bvalid_clr;
wire sram_axi_bvalid_nxt  = sram_axi_bvalid_set | (~sram_axi_bvalid_clr);
lieat_general_dfflr #(1) sram_axi_bvalid_dff (clock,reset,sram_axi_bvalid_ena,sram_axi_bvalid_nxt,sram_axi_bvalid);

wire [3:0] r_channel_id;
wire [3:0] r_channel_id_nxt = ar_sh ? sram_axi_arid : 4'b0;
lieat_general_dfflr #(4) r_channel_id_dff(clock,reset,(ar_sh | r_sh),r_channel_id_nxt,r_channel_id);
wire [3:0] w_channel_id = 4'b0001;
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign sram_axi_rid   = r_channel_id;
assign sram_axi_bid   = w_channel_id;
assign sram_axi_bresp = sram_axi_bvalid ? 2'b01 : 2'b00;
assign sram_axi_rdata = sram_rdata;
// ================================================================================================================================================
// SRAM:DPI-C
// ================================================================================================================================================
wire [`XLEN-1:0] sram_raddr = sram_axi_araddr;
wire [7:0]       sram_rsize = (sram_axi_arsize == 3'b000) ? 8'd1 :
                              (sram_axi_arsize == 3'b001) ? 8'd2 :
                              (sram_axi_arsize == 3'b010) ? 8'd4 : 
                              (sram_axi_arsize == 3'b011) ? 8'd8 : 8'd0;
reg  [`XLEN*2-1:0] sram_rdata;

wire [`XLEN-1:0] sram_waddr = sram_axi_awaddr;
wire [7:0]       sram_wsize = (sram_axi_awsize == 3'b000) ? 8'd1 :
                              (sram_axi_awsize == 3'b001) ? 8'd2 :
                              (sram_axi_awsize == 3'b010) ? 8'd4 : 
                              (sram_axi_arsize == 3'b011) ? 8'd8 : 8'd0;
wire [`XLEN*2-1:0] sram_wdata = sram_axi_wdata;

wire [`XLEN-1:0] sram_inst_nxt;
wire [`XLEN-1:0] sram_inst;
lieat_general_dfflr #(`XLEN) sram_inst_dff(clock,reset,sram_inst_ena,sram_inst_nxt,sram_inst);
import "DPI-C" function void pmem_read(input int sram_raddr,output longint sram_rdata,input byte sram_rsize);
import "DPI-C" function void pmem_write(input int sram_waddr,input longint sram_wdata,input byte sram_wsize);

always @(posedge clock or negedge reset) begin
  if(ar_sh) pmem_read(sram_raddr, sram_rdata, sram_rsize);
  if(aw_sh & w_sh) pmem_write(sram_waddr,sram_wdata, sram_wsize);
end


endmodule
