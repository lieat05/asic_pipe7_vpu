module lieat_exu_vpu_vset(
  input                           clock,
  input                           reset,
  input                           flush_req,

  input                           vset_i_valid,
  output                          vset_i_ready,
  input  [`REG_IDX-1:0]           vset_i_rs1,
  input  [`REG_IDX-1:0]           vset_i_rd,
  input  [`XLEN-1:0]              vset_i_src1,
  input  [`XLEN-25:0]             vset_i_src2,
  input  [`XLEN-1:0]              vset_i_pc,
  input  [`INFOBUS_VPU_WIDTH-1:0] vset_i_infobus,
  
  output                          vset_vtype_wen,
  output [`XLEN-1:0]              vset_vtype_wdata,
  output                          vset_vl_wen,
  output [      4:0]              vset_vl_wdata,
  input  [      4:0]              vset_vl_rdata,

  output                          vset_o_valid,
  input                           vset_o_ready,
  output                          vset_o_flush,
  output [`XLEN-1:0]              vset_o_data,
  output [`XLEN-1:0]              vset_o_pc,
  output                          vset_o_wen,
  output [`REG_IDX-1:0]           vset_o_rd
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                          vset_flush_ena;

wire [31:0]                   vset_pc;
wire [4:0]                    vset_rd;
wire [31:0]                   vset_src1;
wire [7:0]                    vset_src2;
wire                          vset_rdx0;
wire                          vset_rs1x0;
wire [`INFOBUS_VPU_WIDTH-1:0] vset_infobus;

//wire                        vset_vsetvli;
wire                          vset_vsetivli;
wire                          vset_vsetvl;
wire [4:0]                    vset_avluimm;
wire [10:0]                   vset_vtypeimm;

wire                          vset_vma;
wire                          vset_vta;

wire [2:0]                    vset_sewsel;
wire [2:0]                    vset_sew;
wire                          vset_sew_8;
wire                          vset_sew_16;
wire                          vset_sew_32;

wire [2:0]                    vset_lmulsel;
wire [5:0]                    vset_lmul;
wire                          vset_lmul_mf4;
wire                          vset_lmul_mf2;
wire                          vset_lmul_m1;
wire                          vset_lmul_m2;
wire                          vset_lmul_m4;
wire                          vset_lmul_m8;

wire [31:0]                   vset_vl;
wire [31:0]                   vset_avl;
wire [31:0]                   vset_vtype;
wire [5:0]                    vset_vlmax;
// ================================================================================================================================================
// INPUT
// ================================================================================================================================================
wire vset_i_sh = vset_i_valid & vset_i_ready;
wire vset_o_sh = vset_o_valid & vset_o_ready;

lieat_general_dfflr #(1)        lsu_flush_ena_dff(clock,reset,1'b1,vset_i_sh,vset_flush_ena);
assign vset_o_flush = flush_req & vset_flush_ena;

wire vset_o_valid_set = vset_i_sh;
wire vset_o_valid_clr = vset_o_sh | vset_o_flush;
wire vset_o_valid_ena = vset_o_valid_set | vset_o_valid_clr;
wire vset_o_valid_nxt = vset_o_valid_set | ~vset_o_valid_clr;
lieat_general_dfflr #(1)        vset_o_valid_dff(clock,reset,vset_o_valid_ena,vset_o_valid_nxt,vset_o_valid);
assign vset_i_ready     = ~vset_o_valid | vset_o_sh;

lieat_general_dfflr #(1)        vset_rs1x0_dff(clock,reset,vset_i_sh,(vset_i_rs1 == 5'b0),vset_rs1x0);
lieat_general_dfflr #(1)        vset_rdx0_dff(clock,reset,vset_i_sh,(vset_i_rd == 5'b0),vset_rdx0);
lieat_general_dfflr #(`XLEN)    vset_pc_dff(clock,reset,vset_i_sh,vset_i_pc,vset_pc);
lieat_general_dfflr #(`XLEN)    vset_src1_dff(clock,reset,vset_i_sh,vset_i_src1,vset_src1);
lieat_general_dfflr #(`XLEN-24) vset_src2_dff(clock,reset,vset_i_sh,vset_i_src2[7:0],vset_src2);
lieat_general_dfflr #(`REG_IDX) vset_rd_dff(clock,reset,vset_i_sh,vset_i_rd,vset_rd);
lieat_general_dfflr #(`INFOBUS_VPU_WIDTH) vset_infobus_dff(clock,reset,vset_i_sh,vset_i_infobus,vset_infobus);
// ================================================================================================================================================
// MAIN
// ================================================================================================================================================
assign vset_vsetivli  = vset_infobus[`INFOBUS_VSET_VSETIVLI];
assign vset_vsetvl    = vset_infobus[`INFOBUS_VSET_VSETVL  ];
assign vset_avluimm   = vset_infobus[`INFOBUS_VSET_AVLUIMM ];
assign vset_vtypeimm  = vset_infobus[`INFOBUS_VSET_VTYPEIMM];

assign vset_sewsel    = vset_vsetvl ? vset_src2[5:3] : vset_vtypeimm[5:3];
assign vset_sew_8     = ~vset_sewsel[2] & ~vset_sewsel[1] & ~vset_sewsel[0];
assign vset_sew_16    = ~vset_sewsel[2] & ~vset_sewsel[1] &  vset_sewsel[0];
assign vset_sew_32    = ~vset_sewsel[2] &  vset_sewsel[1] & ~vset_sewsel[0];
assign vset_sew       = {vset_sew_32,vset_sew_16,vset_sew_8};

assign vset_lmulsel   = vset_vsetvl ? vset_src2[2:0] : vset_vtypeimm[2:0];
assign vset_lmul_mf4  =  vset_lmulsel[2] &  vset_lmulsel[1] & ~vset_lmulsel[0];
assign vset_lmul_mf2  =  vset_lmulsel[2] &  vset_lmulsel[1] &  vset_lmulsel[0];
assign vset_lmul_m1   = ~vset_lmulsel[2] & ~vset_lmulsel[1] & ~vset_lmulsel[0];
assign vset_lmul_m2   = ~vset_lmulsel[2] & ~vset_lmulsel[1] &  vset_lmulsel[0];
assign vset_lmul_m4   = ~vset_lmulsel[2] &  vset_lmulsel[1] & ~vset_lmulsel[0];
assign vset_lmul_m8   = ~vset_lmulsel[2] &  vset_lmulsel[1] &  vset_lmulsel[0];
assign vset_lmul      = {vset_lmul_m8,vset_lmul_m4,vset_lmul_m2,vset_lmul_m1,vset_lmul_mf2,vset_lmul_mf4};

assign vset_vma       = vset_vsetvl ? vset_src2[7] : vset_vtypeimm[7];
assign vset_vta       = vset_vsetvl ? vset_src2[6] : vset_vtypeimm[6];

assign vset_vlmax     = 
({6{vset_sew_32 & vset_lmul_m1 }} & 6'h1 )|
({6{vset_sew_32 & vset_lmul_m2 }} & 6'h2 )|
({6{vset_sew_32 & vset_lmul_m4 }} & 6'h4 )|
({6{vset_sew_32 & vset_lmul_m8 }} & 6'h8 )|
({6{vset_sew_16 & vset_lmul_mf2}} & 6'h1 )|
({6{vset_sew_16 & vset_lmul_m1 }} & 6'h2 )|
({6{vset_sew_16 & vset_lmul_m2 }} & 6'h4 )|
({6{vset_sew_16 & vset_lmul_m4 }} & 6'h8 )|
({6{vset_sew_16 & vset_lmul_m8 }} & 6'h10)|
({6{vset_sew_8  & vset_lmul_mf4}} & 6'h1 )|
({6{vset_sew_8  & vset_lmul_mf2}} & 6'h2 )|
({6{vset_sew_8  & vset_lmul_m1 }} & 6'h4 )|
({6{vset_sew_8  & vset_lmul_m2 }} & 6'h8 )|
({6{vset_sew_8  & vset_lmul_m4 }} & 6'h10)|
({6{vset_sew_8  & vset_lmul_m8 }} & 6'h20);

assign vset_avl      = vset_vsetivli ? {27'b0,vset_avluimm} : 
({`XLEN{~vset_rs1x0             }} & vset_src1            )|
({`XLEN{ vset_rs1x0 & ~vset_rdx0}} & 32'hffffffff         )|
({`XLEN{ vset_rs1x0 &  vset_rdx0}} & {27'b0,vset_vl_rdata});
assign vset_vl       = (vset_avl > {26'b0,vset_vlmax}) ? {26'b0,vset_vlmax} : vset_avl;
assign vset_vtype    = {21'b0,vset_vma,vset_vta,vset_sew,vset_lmul};
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign vset_o_pc        = vset_pc;
assign vset_o_rd        = vset_rd;
assign vset_o_data      = vset_vl;
assign vset_o_wen       = vset_o_valid;
assign vset_vl_wen      = vset_o_valid;
assign vset_vtype_wen   = vset_o_valid;
assign vset_vl_wdata    = vset_vl[4:0] + 5'b11111;
assign vset_vtype_wdata = vset_vtype;
wire unused_ok = &{vset_infobus,vset_vtypeimm};
endmodule
