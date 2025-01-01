module lieat_exu_wbu(
  input                 clock,
  input                 reset,

  input                 com_wbck_valid,
  output                com_wbck_ready,
  input [`XLEN-1:0]     com_wbck_pc,
  input                 com_wbck_en,
  input [`REG_IDX-1:0]  com_wbck_rd,
  input [`XLEN-1:0]     com_wbck_data,
  input                 com_wbck_ebreak,

  input                 lsu_wbck_valid,
  output                lsu_wbck_ready,
  input [`XLEN-1:0]     lsu_wbck_pc,
  input                 lsu_wbck_en,
  input [`XLEN-1:0]     lsu_wbck_data,
  input [`REG_IDX-1:0]  lsu_wbck_rd,
  input                 lsu_wbck_mmio,

  input                 muldiv_wbck_valid,
  output                muldiv_wbck_ready,
  input [`XLEN-1:0]     muldiv_wbck_pc,
  input                 muldiv_wbck_en,
  input [`XLEN-1:0]     muldiv_wbck_data,
  input [`REG_IDX-1:0]  muldiv_wbck_rd,

  input                 vpu_wbck_valid,
  output                vpu_wbck_ready,
  input [`XLEN-1:0]     vpu_wbck_pc,
  input                 vpu_wbck_en,
  input [`XLEN-1:0]     vpu_wbck_data,
  input [`REG_IDX-1:0]  vpu_wbck_rd,

  input                 fpu_wbck_valid,
  output                fpu_wbck_ready,
  input [`XLEN-1:0]     fpu_wbck_pc,
  input                 fpu_wbck_en,
  input [`XLEN-1:0]     fpu_wbck_data,
  input [`REG_IDX-1:0]  fpu_wbck_rd,

  output                wbck_o_valid,
  output [4:0]          wbck_o_op,
  output [`XLEN-1:0]    wbck_o_pc,
  output                wbck_o_en,
  output [`REG_IDX-1:0] wbck_o_rd,
  output [`XLEN-1:0]    wbck_o_data,
  output                wbck_o_lsu,
  output                wbck_o_ebreak
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                wbck_i_sh;
wire                wbck_i_valid;
wire                wbck_i_ready;

wire                sel_vpu    =  vpu_wbck_valid;
wire                sel_fpu    = ~vpu_wbck_valid &  fpu_wbck_valid;
wire                sel_muldiv = ~vpu_wbck_valid & ~fpu_wbck_valid &  muldiv_wbck_valid;
wire                sel_lsu    = ~vpu_wbck_valid & ~fpu_wbck_valid & ~muldiv_wbck_valid &  lsu_wbck_valid;
wire                sel_com    = ~vpu_wbck_valid & ~fpu_wbck_valid & ~muldiv_wbck_valid & ~lsu_wbck_valid & com_wbck_valid;

wire                wbck_i_en;
wire                wbck_i_lsu;//DPIC
wire                wbck_i_ebreak;//DPIC
wire [4:0]          wbck_i_op;
wire [`XLEN-1:0]    wbck_i_data;
wire [`XLEN-1:0]    wbck_i_pc;//DPIC
wire [`REG_IDX-1:0] wbck_i_rd;
// ================================================================================================================================================
// WBU
// ================================================================================================================================================
assign wbck_i_sh    = wbck_i_valid & wbck_i_ready;
assign wbck_i_ready = 1'b1;
assign wbck_i_valid = com_wbck_valid | lsu_wbck_valid | muldiv_wbck_valid | vpu_wbck_valid;
assign vpu_wbck_ready    = 1'b1;
assign fpu_wbck_ready    = ~vpu_wbck_valid;
assign muldiv_wbck_ready = ~vpu_wbck_valid & ~fpu_wbck_valid;
assign lsu_wbck_ready    = ~vpu_wbck_valid & ~fpu_wbck_valid & ~muldiv_wbck_valid;
assign com_wbck_ready    = ~vpu_wbck_valid & ~fpu_wbck_valid & ~muldiv_wbck_valid & ~lsu_wbck_valid;

wire wbck_o_valid_set = wbck_i_sh;
wire wbck_o_valid_clr = wbck_o_valid;
wire wbck_o_valid_ena = wbck_o_valid_set | wbck_o_valid_clr;
wire wbck_o_valid_nxt = wbck_o_valid_set | ~wbck_o_valid_clr;
lieat_general_dfflr #(1) wbck_o_valid_dff(clock,reset,wbck_o_valid_ena,wbck_o_valid_nxt,wbck_o_valid);

assign wbck_i_op    = {sel_fpu,sel_vpu,sel_muldiv,sel_lsu,sel_com};
assign wbck_i_en    = 
(sel_vpu    & vpu_wbck_en   ) |
(sel_fpu    & fpu_wbck_en   ) |
(sel_muldiv & muldiv_wbck_en) |
(sel_lsu    & lsu_wbck_en   ) |
(sel_com    & com_wbck_en   ) ;
assign wbck_i_pc    = 
({`XLEN{sel_vpu   }} & vpu_wbck_pc   ) |
({`XLEN{sel_fpu   }} & fpu_wbck_pc   ) |
({`XLEN{sel_muldiv}} & muldiv_wbck_pc) |
({`XLEN{sel_lsu   }} & lsu_wbck_pc   ) |
({`XLEN{sel_com   }} & com_wbck_pc   ) ;//DPIC
assign wbck_i_rd    = 
({`REG_IDX{sel_vpu   }} & vpu_wbck_rd   ) |
({`REG_IDX{sel_fpu   }} & fpu_wbck_rd   ) |
({`REG_IDX{sel_muldiv}} & muldiv_wbck_rd) |
({`REG_IDX{sel_lsu   }} & lsu_wbck_rd   ) |
({`REG_IDX{sel_com   }} & com_wbck_rd   ) ;
assign wbck_i_data  = 
({`XLEN{sel_vpu   }} & vpu_wbck_data   ) |
({`XLEN{sel_fpu   }} & fpu_wbck_data   ) |
({`XLEN{sel_muldiv}} & muldiv_wbck_data) |
({`XLEN{sel_lsu   }} & lsu_wbck_data   ) |
({`XLEN{sel_com   }} & com_wbck_data   ) ;
assign wbck_i_lsu   = sel_lsu & lsu_wbck_mmio & lsu_wbck_en;
assign wbck_i_ebreak= sel_com & com_wbck_ebreak;

lieat_general_dfflr #(1) wbck_o_en_dff(clock,reset,wbck_i_sh,wbck_i_en,wbck_o_en);
lieat_general_dfflr #(5) wbck_o_op_dff(clock,reset,wbck_i_sh,wbck_i_op,wbck_o_op);
lieat_general_dfflr #(5) wbck_o_rd_dff(clock,reset,wbck_i_sh,wbck_i_rd,wbck_o_rd);
lieat_general_dfflr #(`XLEN) wbck_o_data_dff(clock,reset,wbck_i_sh,wbck_i_data,wbck_o_data);
lieat_general_dfflr #(1) wbck_o_lsu_dff(clock,reset,wbck_i_sh,wbck_i_lsu,wbck_o_lsu);//DPIC
lieat_general_dfflr #(1) wbck_o_ebreak_dff(clock,reset,wbck_i_sh,wbck_i_ebreak,wbck_o_ebreak);//DPIC
lieat_general_dfflr #(`XLEN) wbck_o_pc_dff(clock,reset,wbck_i_sh,wbck_i_pc,wbck_o_pc);//DPIC

endmodule
