module lieat_clint(
  input        clock,
  input        reset,

  input        clint_timeset_wen,
  input [1:0]  clint_timeset_bsel,//200_4000 200_4004 200_BFF8 200_BFFC
  input [31:0] clint_timeset_wdata,
  output[31:0] clint_timeset_rdata,
  
  input        clint_msipset_wen,
  input [31:0] clint_msipset_wdata,
  output[31:0] clint_msipset_rdata,

  output       time_interrupt,
  output       msip_interrupt
);
reg [31:0] clint_mtime0;
reg [31:0] clint_mtime1;
reg [31:0] clint_mtimecmp0;
reg [31:0] clint_mtimecmp1;
reg [31:0] clint_msip;
reg clint_intime;

lieat_general_dfflr  #(`XLEN) clint_mtime0_dff(clock,reset,1'b1,clint_mtime0 + 32'h1,clint_mtime0);
lieat_general_dfflr  #(`XLEN) clint_mtime1_dff(clock,reset,1'b1,(clint_mtime0 == 32'hffffffff) ? (clint_mtime1 + 32'h1) : clint_mtime1,clint_mtime1);
lieat_general_dfflrs #(`XLEN) clint_mtimecmp0_dff(clock,reset,(clint_timeset_wen & ~clint_timeset_bsel[1] & ~clint_timeset_bsel[0]),clint_timeset_wdata,clint_mtimecmp0);
lieat_general_dfflrs #(`XLEN) clint_mtimecmp1_dff(clock,reset,(clint_timeset_wen & ~clint_timeset_bsel[1] &  clint_timeset_bsel[0]),clint_timeset_wdata,clint_mtimecmp1);
lieat_general_dfflr  #(`XLEN) clint_msip_dff(clock,reset,clint_msipset_wen,clint_msipset_wdata,clint_msip);
lieat_general_dfflrs #(1)     clint_intime_dff(clock,reset,1'b1,({clint_mtimecmp1,clint_mtimecmp0} > {clint_mtime1,clint_mtime0}),clint_intime);

assign clint_timeset_rdata = 
({32{~clint_timeset_bsel[1] & ~clint_timeset_bsel[0]}} & clint_mtimecmp0) | 
({32{~clint_timeset_bsel[1] &  clint_timeset_bsel[0]}} & clint_mtimecmp1) | 
({32{ clint_timeset_bsel[1] & ~clint_timeset_bsel[0]}} & clint_mtime0   ) | 
({32{ clint_timeset_bsel[1] &  clint_timeset_bsel[0]}} & clint_mtime1   ) ; 
assign clint_msipset_rdata = clint_msip;
assign time_interrupt = ~clint_intime;
assign msip_interrupt = clint_msip[0];
endmodule
