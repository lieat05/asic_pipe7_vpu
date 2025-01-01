module lieat_exu_vpu_vint(
  input                           clock,
  input                           reset,
  input                           flush_req,

  input                           vint_i_valid,
  output                          vint_i_ready,
  input  [`REG_IDX-1:0]           vint_i_rd,
  input  [`REG_IDX-1:0]           vint_i_rs1,
  input  [`XLEN-1:0]              vint_i_src1,//avl
  input  [`XLEN-1:0]              vint_i_pc,
  input  [`INFOBUS_VPU_WIDTH-1:0] vint_i_infobus,
  input  [`XLEN-1:0]              vint_i_vsrc1_0,
  input  [`XLEN-1:0]              vint_i_vsrc1_1,
  input  [`XLEN-1:0]              vint_i_vsrc1_2,
  input  [`XLEN-1:0]              vint_i_vsrc1_3,
  input  [`XLEN-1:0]              vint_i_vsrc1_4,
  input  [`XLEN-1:0]              vint_i_vsrc1_5,
  input  [`XLEN-1:0]              vint_i_vsrc1_6,
  input  [`XLEN-1:0]              vint_i_vsrc1_7,
  input  [`XLEN-1:0]              vint_i_vsrc2_0,
  input  [`XLEN-1:0]              vint_i_vsrc2_1,
  input  [`XLEN-1:0]              vint_i_vsrc2_2,
  input  [`XLEN-1:0]              vint_i_vsrc2_3,
  input  [`XLEN-1:0]              vint_i_vsrc2_4,
  input  [`XLEN-1:0]              vint_i_vsrc2_5,
  input  [`XLEN-1:0]              vint_i_vsrc2_6,
  input  [`XLEN-1:0]              vint_i_vsrc2_7,


  input  [      4:0]              vint_vl,
  input  [      2:0]              vint_vtype,
  input  [`XLEN-1:0]              vint_mask,//v0.t

  output                          vint_o_valid,
  input                           vint_o_ready,
  output                          vint_o_flush,
  output [`XLEN-1:0]              vint_o_pc,
  output [`REG_IDX-1:0]           vint_o_rd,
  
  output                          vint_o_vwen,
  output [`XLEN-1:0]              vint_o_data0,
  output [`XLEN-1:0]              vint_o_data1,
  output [`XLEN-1:0]              vint_o_data2,
  output [`XLEN-1:0]              vint_o_data3,
  output [`XLEN-1:0]              vint_o_data4,
  output [`XLEN-1:0]              vint_o_data5,
  output [`XLEN-1:0]              vint_o_data6,
  output [`XLEN-1:0]              vint_o_data7,
  output [3:0]                    vint_o_mask0,
  output [3:0]                    vint_o_mask1,
  output [3:0]                    vint_o_mask2,
  output [3:0]                    vint_o_mask3,
  output [3:0]                    vint_o_mask4,
  output [3:0]                    vint_o_mask5,
  output [3:0]                    vint_o_mask6,
  output [3:0]                    vint_o_mask7
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                          vint_flush_ena;
wire [4:0]                    vint_rd;
wire [4:0]                    vint_rs1;
wire [31:0]                   vint_pc;
wire [31:0]                   vint_src1;
wire [`INFOBUS_VPU_WIDTH-1:0] vint_infobus;
wire [`XLEN-1:0]              vint_vsrc1_0;
wire [`XLEN-1:0]              vint_vsrc1_1;
wire [`XLEN-1:0]              vint_vsrc1_2;
wire [`XLEN-1:0]              vint_vsrc1_3;
wire [`XLEN-1:0]              vint_vsrc1_4;
wire [`XLEN-1:0]              vint_vsrc1_5;
wire [`XLEN-1:0]              vint_vsrc1_6;
wire [`XLEN-1:0]              vint_vsrc1_7;
wire [`XLEN-1:0]              vint_vsrc2_0;
wire [`XLEN-1:0]              vint_vsrc2_1;
wire [`XLEN-1:0]              vint_vsrc2_2;
wire [`XLEN-1:0]              vint_vsrc2_3;
wire [`XLEN-1:0]              vint_vsrc2_4;
wire [`XLEN-1:0]              vint_vsrc2_5;
wire [`XLEN-1:0]              vint_vsrc2_6;
wire [`XLEN-1:0]              vint_vsrc2_7;

wire [2:0]                    vint_sizesel;//32 16 08
wire [31:0]                   vint_masksel;
wire [31:0]                   vint_imm;

wire                          vint_valid;
wire                          vint32_valid;
wire                          vint16_valid;
wire                          vint08_valid;
wire                          vint32_o_valid;
wire                          vint16_o_valid;
wire                          vint08_o_valid;

wire                          vunit0_32bit_o_valid;
wire                          vunit1_32bit_o_valid;
wire                          vunit2_32bit_o_valid;
wire                          vunit3_32bit_o_valid;
wire                          vunit4_32bit_o_valid;
wire                          vunit5_32bit_o_valid;
wire                          vunit6_32bit_o_valid;
wire                          vunit7_32bit_o_valid;

wire                          vunit0_16bit_o_valid;
wire                          vunit1_16bit_o_valid;
wire                          vunit2_16bit_o_valid;
wire                          vunit3_16bit_o_valid;
wire                          vunit4_16bit_o_valid;
wire                          vunit5_16bit_o_valid;
wire                          vunit6_16bit_o_valid;
wire                          vunit7_16bit_o_valid;
wire                          vunit8_16bit_o_valid;
wire                          vunit9_16bit_o_valid;
wire                          vunita_16bit_o_valid;
wire                          vunitb_16bit_o_valid;
wire                          vunitc_16bit_o_valid;
wire                          vunitd_16bit_o_valid;
wire                          vunite_16bit_o_valid;
wire                          vunitf_16bit_o_valid;

wire                          vunit00_08bit_o_valid;
wire                          vunit01_08bit_o_valid;
wire                          vunit02_08bit_o_valid;
wire                          vunit03_08bit_o_valid;
wire                          vunit04_08bit_o_valid;
wire                          vunit05_08bit_o_valid;
wire                          vunit06_08bit_o_valid;
wire                          vunit07_08bit_o_valid;
wire                          vunit08_08bit_o_valid;
wire                          vunit09_08bit_o_valid;
wire                          vunit10_08bit_o_valid;
wire                          vunit11_08bit_o_valid;
wire                          vunit12_08bit_o_valid;
wire                          vunit13_08bit_o_valid;
wire                          vunit14_08bit_o_valid;
wire                          vunit15_08bit_o_valid;
wire                          vunit16_08bit_o_valid;
wire                          vunit17_08bit_o_valid;
wire                          vunit18_08bit_o_valid;
wire                          vunit19_08bit_o_valid;
wire                          vunit20_08bit_o_valid;
wire                          vunit21_08bit_o_valid;
wire                          vunit22_08bit_o_valid;
wire                          vunit23_08bit_o_valid;
wire                          vunit24_08bit_o_valid;
wire                          vunit25_08bit_o_valid;
wire                          vunit26_08bit_o_valid;
wire                          vunit27_08bit_o_valid;
wire                          vunit28_08bit_o_valid;
wire                          vunit29_08bit_o_valid;
wire                          vunit30_08bit_o_valid;
wire                          vunit31_08bit_o_valid;

wire [31:0]                   vunit0_32bit_o_data;
wire [31:0]                   vunit1_32bit_o_data;
wire [31:0]                   vunit2_32bit_o_data;
wire [31:0]                   vunit3_32bit_o_data;
wire [31:0]                   vunit4_32bit_o_data;
wire [31:0]                   vunit5_32bit_o_data;
wire [31:0]                   vunit6_32bit_o_data;
wire [31:0]                   vunit7_32bit_o_data;

wire [15:0]                   vunit0_16bit_o_data;
wire [15:0]                   vunit1_16bit_o_data;
wire [15:0]                   vunit2_16bit_o_data;
wire [15:0]                   vunit3_16bit_o_data;
wire [15:0]                   vunit4_16bit_o_data;
wire [15:0]                   vunit5_16bit_o_data;
wire [15:0]                   vunit6_16bit_o_data;
wire [15:0]                   vunit7_16bit_o_data;
wire [15:0]                   vunit8_16bit_o_data;
wire [15:0]                   vunit9_16bit_o_data;
wire [15:0]                   vunita_16bit_o_data;
wire [15:0]                   vunitb_16bit_o_data;
wire [15:0]                   vunitc_16bit_o_data;
wire [15:0]                   vunitd_16bit_o_data;
wire [15:0]                   vunite_16bit_o_data;
wire [15:0]                   vunitf_16bit_o_data;

wire [7:0]                    vunit00_08bit_o_data;
wire [7:0]                    vunit01_08bit_o_data;
wire [7:0]                    vunit02_08bit_o_data;
wire [7:0]                    vunit03_08bit_o_data;
wire [7:0]                    vunit04_08bit_o_data;
wire [7:0]                    vunit05_08bit_o_data;
wire [7:0]                    vunit06_08bit_o_data;
wire [7:0]                    vunit07_08bit_o_data;
wire [7:0]                    vunit08_08bit_o_data;
wire [7:0]                    vunit09_08bit_o_data;
wire [7:0]                    vunit10_08bit_o_data;
wire [7:0]                    vunit11_08bit_o_data;
wire [7:0]                    vunit12_08bit_o_data;
wire [7:0]                    vunit13_08bit_o_data;
wire [7:0]                    vunit14_08bit_o_data;
wire [7:0]                    vunit15_08bit_o_data;
wire [7:0]                    vunit16_08bit_o_data;
wire [7:0]                    vunit17_08bit_o_data;
wire [7:0]                    vunit18_08bit_o_data;
wire [7:0]                    vunit19_08bit_o_data;
wire [7:0]                    vunit20_08bit_o_data;
wire [7:0]                    vunit21_08bit_o_data;
wire [7:0]                    vunit22_08bit_o_data;
wire [7:0]                    vunit23_08bit_o_data;
wire [7:0]                    vunit24_08bit_o_data;
wire [7:0]                    vunit25_08bit_o_data;
wire [7:0]                    vunit26_08bit_o_data;
wire [7:0]                    vunit27_08bit_o_data;
wire [7:0]                    vunit28_08bit_o_data;
wire [7:0]                    vunit29_08bit_o_data;
wire [7:0]                    vunit30_08bit_o_data;
wire [7:0]                    vunit31_08bit_o_data;

wire [31:0]                   vunit0_32bit_op1;
wire [31:0]                   vunit1_32bit_op1;
wire [31:0]                   vunit2_32bit_op1;
wire [31:0]                   vunit3_32bit_op1;
wire [31:0]                   vunit4_32bit_op1;
wire [31:0]                   vunit5_32bit_op1;
wire [31:0]                   vunit6_32bit_op1;
wire [31:0]                   vunit7_32bit_op1;

wire [15:0]                   vunit0_16bit_op1;
wire [15:0]                   vunit1_16bit_op1;
wire [15:0]                   vunit2_16bit_op1;
wire [15:0]                   vunit3_16bit_op1;
wire [15:0]                   vunit4_16bit_op1;
wire [15:0]                   vunit5_16bit_op1;
wire [15:0]                   vunit6_16bit_op1;
wire [15:0]                   vunit7_16bit_op1;
wire [15:0]                   vunit8_16bit_op1;
wire [15:0]                   vunit9_16bit_op1;
wire [15:0]                   vunita_16bit_op1;
wire [15:0]                   vunitb_16bit_op1;
wire [15:0]                   vunitc_16bit_op1;
wire [15:0]                   vunitd_16bit_op1;
wire [15:0]                   vunite_16bit_op1;
wire [15:0]                   vunitf_16bit_op1;
wire [ 7:0]                   vunit00_08bit_op1;
wire [ 7:0]                   vunit01_08bit_op1;
wire [ 7:0]                   vunit02_08bit_op1;
wire [ 7:0]                   vunit03_08bit_op1;
wire [ 7:0]                   vunit04_08bit_op1;
wire [ 7:0]                   vunit05_08bit_op1;
wire [ 7:0]                   vunit06_08bit_op1;
wire [ 7:0]                   vunit07_08bit_op1;
wire [ 7:0]                   vunit08_08bit_op1;
wire [ 7:0]                   vunit09_08bit_op1;
wire [ 7:0]                   vunit10_08bit_op1;
wire [ 7:0]                   vunit11_08bit_op1;
wire [ 7:0]                   vunit12_08bit_op1;
wire [ 7:0]                   vunit13_08bit_op1;
wire [ 7:0]                   vunit14_08bit_op1;
wire [ 7:0]                   vunit15_08bit_op1;
wire [ 7:0]                   vunit16_08bit_op1;
wire [ 7:0]                   vunit17_08bit_op1;
wire [ 7:0]                   vunit18_08bit_op1;
wire [ 7:0]                   vunit19_08bit_op1;
wire [ 7:0]                   vunit20_08bit_op1;
wire [ 7:0]                   vunit21_08bit_op1;
wire [ 7:0]                   vunit22_08bit_op1;
wire [ 7:0]                   vunit23_08bit_op1;
wire [ 7:0]                   vunit24_08bit_op1;
wire [ 7:0]                   vunit25_08bit_op1;
wire [ 7:0]                   vunit26_08bit_op1;
wire [ 7:0]                   vunit27_08bit_op1;
wire [ 7:0]                   vunit28_08bit_op1;
wire [ 7:0]                   vunit29_08bit_op1;
wire [ 7:0]                   vunit30_08bit_op1;
wire [ 7:0]                   vunit31_08bit_op1;
wire [31:0]                   vunit0_32bit_op2;
wire [31:0]                   vunit1_32bit_op2;
wire [31:0]                   vunit2_32bit_op2;
wire [31:0]                   vunit3_32bit_op2;
wire [31:0]                   vunit4_32bit_op2;
wire [31:0]                   vunit5_32bit_op2;
wire [31:0]                   vunit6_32bit_op2;
wire [31:0]                   vunit7_32bit_op2;
wire [15:0]                   vunit0_16bit_op2;
wire [15:0]                   vunit1_16bit_op2;
wire [15:0]                   vunit2_16bit_op2;
wire [15:0]                   vunit3_16bit_op2;
wire [15:0]                   vunit4_16bit_op2;
wire [15:0]                   vunit5_16bit_op2;
wire [15:0]                   vunit6_16bit_op2;
wire [15:0]                   vunit7_16bit_op2;
wire [15:0]                   vunit8_16bit_op2;
wire [15:0]                   vunit9_16bit_op2;
wire [15:0]                   vunita_16bit_op2;
wire [15:0]                   vunitb_16bit_op2;
wire [15:0]                   vunitc_16bit_op2;
wire [15:0]                   vunitd_16bit_op2;
wire [15:0]                   vunite_16bit_op2;
wire [15:0]                   vunitf_16bit_op2;
wire [ 7:0]                   vunit00_08bit_op2;
wire [ 7:0]                   vunit01_08bit_op2;
wire [ 7:0]                   vunit02_08bit_op2;
wire [ 7:0]                   vunit03_08bit_op2;
wire [ 7:0]                   vunit04_08bit_op2;
wire [ 7:0]                   vunit05_08bit_op2;
wire [ 7:0]                   vunit06_08bit_op2;
wire [ 7:0]                   vunit07_08bit_op2;
wire [ 7:0]                   vunit08_08bit_op2;
wire [ 7:0]                   vunit09_08bit_op2;
wire [ 7:0]                   vunit10_08bit_op2;
wire [ 7:0]                   vunit11_08bit_op2;
wire [ 7:0]                   vunit12_08bit_op2;
wire [ 7:0]                   vunit13_08bit_op2;
wire [ 7:0]                   vunit14_08bit_op2;
wire [ 7:0]                   vunit15_08bit_op2;
wire [ 7:0]                   vunit16_08bit_op2;
wire [ 7:0]                   vunit17_08bit_op2;
wire [ 7:0]                   vunit18_08bit_op2;
wire [ 7:0]                   vunit19_08bit_op2;
wire [ 7:0]                   vunit20_08bit_op2;
wire [ 7:0]                   vunit21_08bit_op2;
wire [ 7:0]                   vunit22_08bit_op2;
wire [ 7:0]                   vunit23_08bit_op2;
wire [ 7:0]                   vunit24_08bit_op2;
wire [ 7:0]                   vunit25_08bit_op2;
wire [ 7:0]                   vunit26_08bit_op2;
wire [ 7:0]                   vunit27_08bit_op2;
wire [ 7:0]                   vunit28_08bit_op2;
wire [ 7:0]                   vunit29_08bit_op2;
wire [ 7:0]                   vunit30_08bit_op2;
wire [ 7:0]                   vunit31_08bit_op2;

wire                          vint_vm       = vint_infobus[`INFOBUS_VINT_MASK];
wire                          vint_opi      = vint_infobus[`INFOBUS_VINT_OPI];
//wire                          vint_opm      = vint_infobus[`INFOBUS_VINT_OPM];
wire                          vint_vv       = vint_infobus[`INFOBUS_VINT_OPIVV] | vint_infobus[`INFOBUS_VINT_OPMVV];
wire                          vint_vx       = vint_infobus[`INFOBUS_VINT_OPIVX] | vint_infobus[`INFOBUS_VINT_OPMVX];
wire                          vint_vi       = vint_infobus[`INFOBUS_VINT_OPIVI];

wire                          vint_vadd     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0000];
wire                          vint_vsub     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0010];
wire                          vint_vrsub    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0011];
/*
wire                          vint_vwaddu   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_0000];
wire                          vint_vwadd    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_0001];
wire                          vint_vwsubu   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_0010];
wire                          vint_vwsub    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_0011];
wire                          vint_vzextvf8 = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010] & ~vint_rs1[4] & ~vint_rs1[3] & ~vint_rs1[2] &  vint_rs1[1] & ~vint_rs1[0];
wire                          vint_vsextvf8 = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010] & ~vint_rs1[4] & ~vint_rs1[3] & ~vint_rs1[2] &  vint_rs1[1] &  vint_rs1[0];
wire                          vint_vzextvf4 = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010] & ~vint_rs1[4] & ~vint_rs1[3] &  vint_rs1[2] & ~vint_rs1[1] & ~vint_rs1[0];
wire                          vint_vsextvf4 = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010] & ~vint_rs1[4] & ~vint_rs1[3] &  vint_rs1[2] & ~vint_rs1[1] &  vint_rs1[0];
wire                          vint_vzextvf2 = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010] & ~vint_rs1[4] & ~vint_rs1[3] & ~vint_rs1[2] &  vint_rs1[1] & ~vint_rs1[0];
wire                          vint_vsextvf2 = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010] & ~vint_rs1[4] & ~vint_rs1[3] & ~vint_rs1[2] &  vint_rs1[1] & ~vint_rs1[0];
wire                          vint_vadc     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0000];
wire                          vint_vmadc    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0001];
wire                          vint_vsbc     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0010];
wire                          vint_vmsbc    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0011];
wire                          vint_vand     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_1001];
wire                          vint_vor      = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_1010];
wire                          vint_vxor     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_1011];
wire                          vint_vsll     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0101];
wire                          vint_vsrl     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1000];
wire                          vint_vsra     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1001];
wire                          vint_vnsrl    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1100];
wire                          vint_vnsra    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1011];
wire                          vint_vmseq    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1000];
wire                          vint_vmsne    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1001];
wire                          vint_vmsltu   = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1010];
wire                          vint_vmslt    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1011];
wire                          vint_vmsleu   = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1100];
wire                          vint_vmsle    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1101];
wire                          vint_vmsgtu   = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1110];
wire                          vint_vmsgt    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_1111];
wire                          vint_vminu    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0100];
wire                          vint_vmin     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0101];
wire                          vint_vmaxu    = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0110];
wire                          vint_vmax     = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_00] & vint_infobus[`INFOBUS_VINT_FUNC6_0111];
wire                          vint_vmul     = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0101];
wire                          vint_vmulh    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0111];
wire                          vint_vmulhu   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0100];
wire                          vint_vmulhsu  = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0110];
wire                          vint_vdivu    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0000];
wire                          vint_vdiv     = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0001];
wire                          vint_vremu    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0010];
wire                          vint_vrem     = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_0011];
wire                          vint_vwmul    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1011];
wire                          vint_vwmulu   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1000];
wire                          vint_vwmulsu  = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1010];
wire                          vint_vmacc    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1101];
wire                          vint_vnmsac   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1111];
wire                          vint_vmadd    = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1001];
wire                          vint_vnmsub   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_10] & vint_infobus[`INFOBUS_VINT_FUNC6_1011];
wire                          vint_vwmaccu  = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1100];
wire                          vint_vwmacc   = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1101];
wire                          vint_vwmaccsu = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1111];
wire                          vint_vwmaccus = vint_opm & vint_infobus[`INFOBUS_VINT_FUNC6_11] & vint_infobus[`INFOBUS_VINT_FUNC6_1110];
wire                          vint_vmerge   = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0111];
wire                          vint_vmv      = vint_opi & vint_infobus[`INFOBUS_VINT_FUNC6_01] & vint_infobus[`INFOBUS_VINT_FUNC6_0111];
*/
// ================================================================================================================================================
// INPUT
// ================================================================================================================================================
wire vint_i_sh = vint_i_valid & vint_i_ready;
wire vint_o_sh = vint_o_valid & vint_o_ready;

lieat_general_dfflr #(1)        lsu_flush_ena_dff(clock,reset,1'b1,vint_i_sh,vint_flush_ena);
assign vint_o_flush = flush_req & vint_flush_ena;

wire vint_valid_set = vint_i_sh;
wire vint_valid_clr = vint_o_sh | vint_o_flush;
wire vint_valid_ena = vint_valid_set | vint_valid_clr;
wire vint_valid_nxt = vint_valid_set | ~vint_valid_clr;
lieat_general_dfflr #(1)        vint_valid_dff(clock,reset,vint_valid_ena,vint_valid_nxt,vint_valid);
assign vint_i_ready     = ~vint_valid | vint_o_sh;

lieat_general_dfflr #(`XLEN)    vint_pc_dff(clock,reset,vint_i_sh,vint_i_pc,vint_pc);
lieat_general_dfflr #(`XLEN)    vint_src1_dff(clock,reset,vint_i_sh,vint_i_src1,vint_src1);
lieat_general_dfflr #(`REG_IDX) vint_rd_dff(clock,reset,vint_i_sh,vint_i_rd,vint_rd);
lieat_general_dfflr #(`REG_IDX) vint_rs1_dff(clock,reset,vint_i_sh,vint_i_rs1,vint_rs1);
lieat_general_dfflr #(`INFOBUS_VPU_WIDTH) vint_infobus_dff(clock,reset,vint_i_sh,vint_i_infobus,vint_infobus);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_0_dff(clock,reset,vint_i_sh,vint_i_vsrc1_0,vint_vsrc1_0);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_1_dff(clock,reset,vint_i_sh,vint_i_vsrc1_1,vint_vsrc1_1);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_2_dff(clock,reset,vint_i_sh,vint_i_vsrc1_2,vint_vsrc1_2);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_3_dff(clock,reset,vint_i_sh,vint_i_vsrc1_3,vint_vsrc1_3);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_4_dff(clock,reset,vint_i_sh,vint_i_vsrc1_4,vint_vsrc1_4);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_5_dff(clock,reset,vint_i_sh,vint_i_vsrc1_5,vint_vsrc1_5);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_6_dff(clock,reset,vint_i_sh,vint_i_vsrc1_6,vint_vsrc1_6);
lieat_general_dfflr #(`XLEN)    vint_vsrc1_7_dff(clock,reset,vint_i_sh,vint_i_vsrc1_7,vint_vsrc1_7);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_0_dff(clock,reset,vint_i_sh,vint_i_vsrc2_0,vint_vsrc2_0);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_1_dff(clock,reset,vint_i_sh,vint_i_vsrc2_1,vint_vsrc2_1);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_2_dff(clock,reset,vint_i_sh,vint_i_vsrc2_2,vint_vsrc2_2);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_3_dff(clock,reset,vint_i_sh,vint_i_vsrc2_3,vint_vsrc2_3);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_4_dff(clock,reset,vint_i_sh,vint_i_vsrc2_4,vint_vsrc2_4);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_5_dff(clock,reset,vint_i_sh,vint_i_vsrc2_5,vint_vsrc2_5);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_6_dff(clock,reset,vint_i_sh,vint_i_vsrc2_6,vint_vsrc2_6);
lieat_general_dfflr #(`XLEN)    vint_vsrc2_7_dff(clock,reset,vint_i_sh,vint_i_vsrc2_7,vint_vsrc2_7);
// ================================================================================================================================================
// DATA SEL
// ================================================================================================================================================
assign vint_imm  = {{27{vint_rs1[4]}},vint_rs1};
//assign vint_uimm = {27'b0,vint_rs1};

assign vint_sizesel = vint_vtype;
assign vint_masksel = ({`XLEN{vint_vm}} | vint_mask) & (32'hFFFFFFFF >> (5'b11111 - vint_vl));
assign vint32_valid = vint_valid & vint_sizesel[2];
assign vint16_valid = vint_valid & vint_sizesel[1];
assign vint08_valid = vint_valid & vint_sizesel[0];

assign vunit0_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_0) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit1_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_1) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit2_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_2) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit3_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_3) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit4_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_4) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit5_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_5) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit6_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_6) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);
assign vunit7_32bit_op1 = ({32{vint_vv}} & vint_vsrc1_7) | ({32{vint_vx}} & vint_src1) | ({32{vint_vi}} & vint_imm);

assign vunit0_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_0[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit1_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_0[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit2_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_1[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit3_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_1[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit4_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_2[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit5_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_2[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit6_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_3[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit7_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_3[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit8_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_4[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunit9_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_4[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunita_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_5[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunitb_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_5[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunitc_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_6[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunitd_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_6[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunite_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_7[15: 0]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);
assign vunitf_16bit_op1 = ({16{vint_vv}} & vint_vsrc1_7[31:16]) | ({16{vint_vx}} & vint_src1[15: 0]) | ({16{vint_vi}} & vint_imm[15: 0]);

assign vunit00_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_0[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit01_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_0[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit02_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_0[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit03_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_0[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit04_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_1[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit05_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_1[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit06_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_1[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit07_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_1[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit08_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_2[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit09_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_2[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit10_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_2[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit11_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_2[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit12_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_3[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit13_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_3[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit14_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_3[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit15_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_3[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit16_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_4[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit17_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_4[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit18_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_4[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit19_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_4[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit20_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_5[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit21_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_5[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit22_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_5[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit23_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_5[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit24_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_6[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit25_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_6[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit26_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_6[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit27_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_6[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit28_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_7[ 7: 0]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit29_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_7[15: 8]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit30_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_7[23:16]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);
assign vunit31_08bit_op1 = ({ 8{vint_vv}} & vint_vsrc1_7[31:24]) | ({ 8{vint_vx}} & vint_src1[ 7: 0]) | ({ 8{vint_vi}} & vint_imm[ 7: 0]);

assign vunit0_32bit_op2 = vint_vsrc2_0;
assign vunit1_32bit_op2 = vint_vsrc2_1;
assign vunit2_32bit_op2 = vint_vsrc2_2;
assign vunit3_32bit_op2 = vint_vsrc2_3;
assign vunit4_32bit_op2 = vint_vsrc2_4;
assign vunit5_32bit_op2 = vint_vsrc2_5;
assign vunit6_32bit_op2 = vint_vsrc2_6;
assign vunit7_32bit_op2 = vint_vsrc2_7;

assign vunit0_16bit_op2 = vint_vsrc2_0[15: 0];
assign vunit1_16bit_op2 = vint_vsrc2_0[31:16];
assign vunit2_16bit_op2 = vint_vsrc2_1[15: 0];
assign vunit3_16bit_op2 = vint_vsrc2_1[31:16];
assign vunit4_16bit_op2 = vint_vsrc2_2[15: 0];
assign vunit5_16bit_op2 = vint_vsrc2_2[31:16];
assign vunit6_16bit_op2 = vint_vsrc2_3[15: 0];
assign vunit7_16bit_op2 = vint_vsrc2_3[31:16];
assign vunit8_16bit_op2 = vint_vsrc2_4[15: 0];
assign vunit9_16bit_op2 = vint_vsrc2_4[31:16];
assign vunita_16bit_op2 = vint_vsrc2_5[15: 0];
assign vunitb_16bit_op2 = vint_vsrc2_5[31:16];
assign vunitc_16bit_op2 = vint_vsrc2_6[15: 0];
assign vunitd_16bit_op2 = vint_vsrc2_6[31:16];
assign vunite_16bit_op2 = vint_vsrc2_7[15: 0];
assign vunitf_16bit_op2 = vint_vsrc2_7[31:16];
assign vunit00_08bit_op2 = vint_vsrc2_0[ 7: 0];
assign vunit01_08bit_op2 = vint_vsrc2_0[15: 8];
assign vunit02_08bit_op2 = vint_vsrc2_0[23:16];
assign vunit03_08bit_op2 = vint_vsrc2_0[31:24];
assign vunit04_08bit_op2 = vint_vsrc2_1[ 7: 0];
assign vunit05_08bit_op2 = vint_vsrc2_1[15: 8];
assign vunit06_08bit_op2 = vint_vsrc2_1[23:16];
assign vunit07_08bit_op2 = vint_vsrc2_1[31:24];
assign vunit08_08bit_op2 = vint_vsrc2_2[ 7: 0];
assign vunit09_08bit_op2 = vint_vsrc2_2[15: 8];
assign vunit10_08bit_op2 = vint_vsrc2_2[23:16];
assign vunit11_08bit_op2 = vint_vsrc2_2[31:24];
assign vunit12_08bit_op2 = vint_vsrc2_3[ 7: 0];
assign vunit13_08bit_op2 = vint_vsrc2_3[15: 8];
assign vunit14_08bit_op2 = vint_vsrc2_3[23:16];
assign vunit15_08bit_op2 = vint_vsrc2_3[31:24];
assign vunit16_08bit_op2 = vint_vsrc2_4[ 7: 0];
assign vunit17_08bit_op2 = vint_vsrc2_4[15: 8];
assign vunit18_08bit_op2 = vint_vsrc2_4[23:16];
assign vunit19_08bit_op2 = vint_vsrc2_4[31:24];
assign vunit20_08bit_op2 = vint_vsrc2_5[ 7: 0];
assign vunit21_08bit_op2 = vint_vsrc2_5[15: 8];
assign vunit22_08bit_op2 = vint_vsrc2_5[23:16];
assign vunit23_08bit_op2 = vint_vsrc2_5[31:24];
assign vunit24_08bit_op2 = vint_vsrc2_6[ 7: 0];
assign vunit25_08bit_op2 = vint_vsrc2_6[15: 8];
assign vunit26_08bit_op2 = vint_vsrc2_6[23:16];
assign vunit27_08bit_op2 = vint_vsrc2_6[31:24];
assign vunit28_08bit_op2 = vint_vsrc2_7[ 7: 0];
assign vunit29_08bit_op2 = vint_vsrc2_7[15: 8];
assign vunit30_08bit_op2 = vint_vsrc2_7[23:16];
assign vunit31_08bit_op2 = vint_vsrc2_7[31:24];

lieat_exu_vpu_vunit32 vunit32_0(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit0_32bit_op1),.vunit_op2(vunit0_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit0_32bit_o_valid),.vunit_o_data(vunit0_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_1(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit1_32bit_op1),.vunit_op2(vunit1_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit1_32bit_o_valid),.vunit_o_data(vunit1_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_2(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit2_32bit_op1),.vunit_op2(vunit2_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit2_32bit_o_valid),.vunit_o_data(vunit2_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_3(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit3_32bit_op1),.vunit_op2(vunit3_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit3_32bit_o_valid),.vunit_o_data(vunit3_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_4(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit4_32bit_op1),.vunit_op2(vunit4_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit4_32bit_o_valid),.vunit_o_data(vunit4_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_5(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit5_32bit_op1),.vunit_op2(vunit5_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit5_32bit_o_valid),.vunit_o_data(vunit5_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_6(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit6_32bit_op1),.vunit_op2(vunit6_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit6_32bit_o_valid),.vunit_o_data(vunit6_32bit_o_data));
lieat_exu_vpu_vunit32 vunit32_7(.clock(clock),.reset(reset),.vunit_valid(vint32_valid),.vunit_op1(vunit7_32bit_op1),.vunit_op2(vunit7_32bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit7_32bit_o_valid),.vunit_o_data(vunit7_32bit_o_data));
lieat_exu_vpu_vunit16 vunit16_0(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit0_16bit_op1),.vunit_op2(vunit0_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit0_16bit_o_valid),.vunit_o_data(vunit0_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_1(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit1_16bit_op1),.vunit_op2(vunit1_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit1_16bit_o_valid),.vunit_o_data(vunit1_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_2(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit2_16bit_op1),.vunit_op2(vunit2_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit2_16bit_o_valid),.vunit_o_data(vunit2_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_3(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit3_16bit_op1),.vunit_op2(vunit3_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit3_16bit_o_valid),.vunit_o_data(vunit3_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_4(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit4_16bit_op1),.vunit_op2(vunit4_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit4_16bit_o_valid),.vunit_o_data(vunit4_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_5(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit5_16bit_op1),.vunit_op2(vunit5_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit5_16bit_o_valid),.vunit_o_data(vunit5_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_6(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit6_16bit_op1),.vunit_op2(vunit6_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit6_16bit_o_valid),.vunit_o_data(vunit6_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_7(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit7_16bit_op1),.vunit_op2(vunit7_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit7_16bit_o_valid),.vunit_o_data(vunit7_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_8(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit8_16bit_op1),.vunit_op2(vunit8_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit8_16bit_o_valid),.vunit_o_data(vunit8_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_9(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunit9_16bit_op1),.vunit_op2(vunit9_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit9_16bit_o_valid),.vunit_o_data(vunit9_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_a(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunita_16bit_op1),.vunit_op2(vunita_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunita_16bit_o_valid),.vunit_o_data(vunita_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_b(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunitb_16bit_op1),.vunit_op2(vunitb_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunitb_16bit_o_valid),.vunit_o_data(vunitb_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_c(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunitc_16bit_op1),.vunit_op2(vunitc_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunitc_16bit_o_valid),.vunit_o_data(vunitc_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_d(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunitd_16bit_op1),.vunit_op2(vunitd_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunitd_16bit_o_valid),.vunit_o_data(vunitd_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_e(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunite_16bit_op1),.vunit_op2(vunite_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunite_16bit_o_valid),.vunit_o_data(vunite_16bit_o_data));
lieat_exu_vpu_vunit16 vunit16_f(.clock(clock),.reset(reset),.vunit_valid(vint16_valid),.vunit_op1(vunitf_16bit_op1),.vunit_op2(vunitf_16bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunitf_16bit_o_valid),.vunit_o_data(vunitf_16bit_o_data));

lieat_exu_vpu_vunit08 vunit08_00(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit00_08bit_op1),.vunit_op2(vunit00_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit00_08bit_o_valid),.vunit_o_data(vunit00_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_01(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit01_08bit_op1),.vunit_op2(vunit01_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit01_08bit_o_valid),.vunit_o_data(vunit01_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_02(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit02_08bit_op1),.vunit_op2(vunit02_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit02_08bit_o_valid),.vunit_o_data(vunit02_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_03(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit03_08bit_op1),.vunit_op2(vunit03_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit03_08bit_o_valid),.vunit_o_data(vunit03_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_04(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit04_08bit_op1),.vunit_op2(vunit04_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit04_08bit_o_valid),.vunit_o_data(vunit04_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_05(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit05_08bit_op1),.vunit_op2(vunit05_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit05_08bit_o_valid),.vunit_o_data(vunit05_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_06(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit06_08bit_op1),.vunit_op2(vunit06_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit06_08bit_o_valid),.vunit_o_data(vunit06_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_07(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit07_08bit_op1),.vunit_op2(vunit07_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit07_08bit_o_valid),.vunit_o_data(vunit07_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_08(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit08_08bit_op1),.vunit_op2(vunit08_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit08_08bit_o_valid),.vunit_o_data(vunit08_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_09(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit09_08bit_op1),.vunit_op2(vunit09_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit09_08bit_o_valid),.vunit_o_data(vunit09_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_10(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit10_08bit_op1),.vunit_op2(vunit10_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit10_08bit_o_valid),.vunit_o_data(vunit10_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_11(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit11_08bit_op1),.vunit_op2(vunit11_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit11_08bit_o_valid),.vunit_o_data(vunit11_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_12(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit12_08bit_op1),.vunit_op2(vunit12_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit12_08bit_o_valid),.vunit_o_data(vunit12_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_13(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit13_08bit_op1),.vunit_op2(vunit13_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit13_08bit_o_valid),.vunit_o_data(vunit13_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_14(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit14_08bit_op1),.vunit_op2(vunit14_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit14_08bit_o_valid),.vunit_o_data(vunit14_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_15(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit15_08bit_op1),.vunit_op2(vunit15_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit15_08bit_o_valid),.vunit_o_data(vunit15_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_16(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit16_08bit_op1),.vunit_op2(vunit16_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit16_08bit_o_valid),.vunit_o_data(vunit16_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_17(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit17_08bit_op1),.vunit_op2(vunit17_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit17_08bit_o_valid),.vunit_o_data(vunit17_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_18(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit18_08bit_op1),.vunit_op2(vunit18_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit18_08bit_o_valid),.vunit_o_data(vunit18_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_19(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit19_08bit_op1),.vunit_op2(vunit19_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit19_08bit_o_valid),.vunit_o_data(vunit19_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_20(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit20_08bit_op1),.vunit_op2(vunit20_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit20_08bit_o_valid),.vunit_o_data(vunit20_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_21(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit21_08bit_op1),.vunit_op2(vunit21_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit21_08bit_o_valid),.vunit_o_data(vunit21_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_22(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit22_08bit_op1),.vunit_op2(vunit22_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit22_08bit_o_valid),.vunit_o_data(vunit22_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_23(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit23_08bit_op1),.vunit_op2(vunit23_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit23_08bit_o_valid),.vunit_o_data(vunit23_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_24(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit24_08bit_op1),.vunit_op2(vunit24_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit24_08bit_o_valid),.vunit_o_data(vunit24_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_25(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit25_08bit_op1),.vunit_op2(vunit25_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit25_08bit_o_valid),.vunit_o_data(vunit25_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_26(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit26_08bit_op1),.vunit_op2(vunit26_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit26_08bit_o_valid),.vunit_o_data(vunit26_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_27(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit27_08bit_op1),.vunit_op2(vunit27_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit27_08bit_o_valid),.vunit_o_data(vunit27_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_28(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit28_08bit_op1),.vunit_op2(vunit28_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit28_08bit_o_valid),.vunit_o_data(vunit28_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_29(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit29_08bit_op1),.vunit_op2(vunit29_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit29_08bit_o_valid),.vunit_o_data(vunit29_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_30(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit30_08bit_op1),.vunit_op2(vunit30_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit30_08bit_o_valid),.vunit_o_data(vunit30_08bit_o_data));
lieat_exu_vpu_vunit08 vunit08_31(.clock(clock),.reset(reset),.vunit_valid(vint08_valid),.vunit_op1(vunit31_08bit_op1),.vunit_op2(vunit31_08bit_op2),.vunit_vadd(vint_vadd),.vunit_vsub(vint_vsub),.vunit_vrsub(vint_vrsub),.vunit_o_valid(vunit31_08bit_o_valid),.vunit_o_data(vunit31_08bit_o_data));

assign vint32_o_valid = vunit0_32bit_o_valid & vunit1_32bit_o_valid & vunit2_32bit_o_valid & vunit3_32bit_o_valid & 
                        vunit4_32bit_o_valid & vunit5_32bit_o_valid & vunit6_32bit_o_valid & vunit7_32bit_o_valid;
assign vint16_o_valid = vunit0_16bit_o_valid & vunit1_16bit_o_valid & vunit2_16bit_o_valid & vunit3_16bit_o_valid & 
                        vunit4_16bit_o_valid & vunit5_16bit_o_valid & vunit6_16bit_o_valid & vunit7_16bit_o_valid &
                        vunit8_16bit_o_valid & vunit9_16bit_o_valid & vunita_16bit_o_valid & vunitb_16bit_o_valid & 
                        vunitc_16bit_o_valid & vunitd_16bit_o_valid & vunite_16bit_o_valid & vunitf_16bit_o_valid;
assign vint08_o_valid = vunit00_08bit_o_valid & vunit01_08bit_o_valid & vunit02_08bit_o_valid & vunit03_08bit_o_valid & 
                        vunit04_08bit_o_valid & vunit05_08bit_o_valid & vunit06_08bit_o_valid & vunit07_08bit_o_valid &
                        vunit08_08bit_o_valid & vunit09_08bit_o_valid & vunit10_08bit_o_valid & vunit11_08bit_o_valid & 
                        vunit12_08bit_o_valid & vunit13_08bit_o_valid & vunit14_08bit_o_valid & vunit15_08bit_o_valid &
                        vunit16_08bit_o_valid & vunit17_08bit_o_valid & vunit18_08bit_o_valid & vunit19_08bit_o_valid & 
                        vunit20_08bit_o_valid & vunit21_08bit_o_valid & vunit22_08bit_o_valid & vunit23_08bit_o_valid &
                        vunit24_08bit_o_valid & vunit25_08bit_o_valid & vunit26_08bit_o_valid & vunit27_08bit_o_valid & 
                        vunit28_08bit_o_valid & vunit29_08bit_o_valid & vunit30_08bit_o_valid & vunit31_08bit_o_valid ;
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
wire unused_ok = &{vint_infobus};
assign vint_o_valid = (vint_sizesel[2] & vint32_o_valid) | (vint_sizesel[1] & vint16_o_valid) | (vint_sizesel[0] & vint08_o_valid);
assign vint_o_pc    = vint_pc;
assign vint_o_rd    = vint_rd;
assign vint_o_vwen  = vint_o_valid;
assign vint_o_data0 = ({`XLEN{vint_sizesel[2]}} & vunit0_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunit1_16bit_o_data,vunit0_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit03_08bit_o_data,vunit02_08bit_o_data,vunit01_08bit_o_data,vunit00_08bit_o_data});
assign vint_o_data1 = ({`XLEN{vint_sizesel[2]}} & vunit1_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunit3_16bit_o_data,vunit2_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit07_08bit_o_data,vunit06_08bit_o_data,vunit05_08bit_o_data,vunit04_08bit_o_data});
assign vint_o_data2 = ({`XLEN{vint_sizesel[2]}} & vunit2_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunit5_16bit_o_data,vunit4_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit11_08bit_o_data,vunit10_08bit_o_data,vunit09_08bit_o_data,vunit08_08bit_o_data});
assign vint_o_data3 = ({`XLEN{vint_sizesel[2]}} & vunit3_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunit7_16bit_o_data,vunit6_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit15_08bit_o_data,vunit14_08bit_o_data,vunit13_08bit_o_data,vunit12_08bit_o_data});
assign vint_o_data4 = ({`XLEN{vint_sizesel[2]}} & vunit4_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunit9_16bit_o_data,vunit8_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit19_08bit_o_data,vunit18_08bit_o_data,vunit17_08bit_o_data,vunit16_08bit_o_data});
assign vint_o_data5 = ({`XLEN{vint_sizesel[2]}} & vunit5_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunitb_16bit_o_data,vunita_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit23_08bit_o_data,vunit22_08bit_o_data,vunit21_08bit_o_data,vunit20_08bit_o_data});
assign vint_o_data6 = ({`XLEN{vint_sizesel[2]}} & vunit6_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunitd_16bit_o_data,vunitc_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit27_08bit_o_data,vunit26_08bit_o_data,vunit25_08bit_o_data,vunit24_08bit_o_data});
assign vint_o_data7 = ({`XLEN{vint_sizesel[2]}} & vunit7_32bit_o_data) | ({`XLEN{vint_sizesel[1]}} & {vunitf_16bit_o_data,vunite_16bit_o_data}) | ({`XLEN{vint_sizesel[0]}} & {vunit31_08bit_o_data,vunit30_08bit_o_data,vunit29_08bit_o_data,vunit28_08bit_o_data});
assign vint_o_mask0 = {
(vint_masksel[ 0] & vint_sizesel[0]) | (vint_masksel[ 0] & vint_sizesel[1]) | (vint_masksel[0] & vint_sizesel[2]),
(vint_masksel[ 1] & vint_sizesel[0]) | (vint_masksel[ 0] & vint_sizesel[1]) | (vint_masksel[0] & vint_sizesel[2]),
(vint_masksel[ 2] & vint_sizesel[0]) | (vint_masksel[ 1] & vint_sizesel[1]) | (vint_masksel[0] & vint_sizesel[2]),
(vint_masksel[ 3] & vint_sizesel[0]) | (vint_masksel[ 1] & vint_sizesel[1]) | (vint_masksel[0] & vint_sizesel[2])};
assign vint_o_mask1 = {
(vint_masksel[ 4] & vint_sizesel[0]) | (vint_masksel[ 2] & vint_sizesel[1]) | (vint_masksel[1] & vint_sizesel[2]),
(vint_masksel[ 5] & vint_sizesel[0]) | (vint_masksel[ 2] & vint_sizesel[1]) | (vint_masksel[1] & vint_sizesel[2]),
(vint_masksel[ 6] & vint_sizesel[0]) | (vint_masksel[ 3] & vint_sizesel[1]) | (vint_masksel[1] & vint_sizesel[2]),
(vint_masksel[ 7] & vint_sizesel[0]) | (vint_masksel[ 3] & vint_sizesel[1]) | (vint_masksel[1] & vint_sizesel[2])};
assign vint_o_mask2 = {
(vint_masksel[ 8] & vint_sizesel[0]) | (vint_masksel[ 4] & vint_sizesel[1]) | (vint_masksel[2] & vint_sizesel[2]),
(vint_masksel[ 9] & vint_sizesel[0]) | (vint_masksel[ 4] & vint_sizesel[1]) | (vint_masksel[2] & vint_sizesel[2]),
(vint_masksel[10] & vint_sizesel[0]) | (vint_masksel[ 5] & vint_sizesel[1]) | (vint_masksel[2] & vint_sizesel[2]),
(vint_masksel[11] & vint_sizesel[0]) | (vint_masksel[ 5] & vint_sizesel[1]) | (vint_masksel[2] & vint_sizesel[2])};
assign vint_o_mask3 = {
(vint_masksel[12] & vint_sizesel[0]) | (vint_masksel[ 6] & vint_sizesel[1]) | (vint_masksel[3] & vint_sizesel[2]),
(vint_masksel[13] & vint_sizesel[0]) | (vint_masksel[ 6] & vint_sizesel[1]) | (vint_masksel[3] & vint_sizesel[2]),
(vint_masksel[14] & vint_sizesel[0]) | (vint_masksel[ 7] & vint_sizesel[1]) | (vint_masksel[3] & vint_sizesel[2]),
(vint_masksel[15] & vint_sizesel[0]) | (vint_masksel[ 7] & vint_sizesel[1]) | (vint_masksel[3] & vint_sizesel[2])};
assign vint_o_mask4 = {
(vint_masksel[16] & vint_sizesel[0]) | (vint_masksel[ 8] & vint_sizesel[1]) | (vint_masksel[4] & vint_sizesel[2]),
(vint_masksel[17] & vint_sizesel[0]) | (vint_masksel[ 8] & vint_sizesel[1]) | (vint_masksel[4] & vint_sizesel[2]),
(vint_masksel[18] & vint_sizesel[0]) | (vint_masksel[ 9] & vint_sizesel[1]) | (vint_masksel[4] & vint_sizesel[2]),
(vint_masksel[19] & vint_sizesel[0]) | (vint_masksel[ 9] & vint_sizesel[1]) | (vint_masksel[4] & vint_sizesel[2])};
assign vint_o_mask5 = {
(vint_masksel[20] & vint_sizesel[0]) | (vint_masksel[10] & vint_sizesel[1]) | (vint_masksel[5] & vint_sizesel[2]),
(vint_masksel[21] & vint_sizesel[0]) | (vint_masksel[10] & vint_sizesel[1]) | (vint_masksel[5] & vint_sizesel[2]),
(vint_masksel[22] & vint_sizesel[0]) | (vint_masksel[11] & vint_sizesel[1]) | (vint_masksel[5] & vint_sizesel[2]),
(vint_masksel[23] & vint_sizesel[0]) | (vint_masksel[11] & vint_sizesel[1]) | (vint_masksel[5] & vint_sizesel[2])};
assign vint_o_mask6 = {
(vint_masksel[24] & vint_sizesel[0]) | (vint_masksel[12] & vint_sizesel[1]) | (vint_masksel[6] & vint_sizesel[2]),
(vint_masksel[25] & vint_sizesel[0]) | (vint_masksel[12] & vint_sizesel[1]) | (vint_masksel[6] & vint_sizesel[2]),
(vint_masksel[26] & vint_sizesel[0]) | (vint_masksel[13] & vint_sizesel[1]) | (vint_masksel[6] & vint_sizesel[2]),
(vint_masksel[27] & vint_sizesel[0]) | (vint_masksel[13] & vint_sizesel[1]) | (vint_masksel[6] & vint_sizesel[2])};
assign vint_o_mask7 = {
(vint_masksel[28] & vint_sizesel[0]) | (vint_masksel[14] & vint_sizesel[1]) | (vint_masksel[7] & vint_sizesel[2]),
(vint_masksel[29] & vint_sizesel[0]) | (vint_masksel[14] & vint_sizesel[1]) | (vint_masksel[7] & vint_sizesel[2]),
(vint_masksel[30] & vint_sizesel[0]) | (vint_masksel[15] & vint_sizesel[1]) | (vint_masksel[7] & vint_sizesel[2]),
(vint_masksel[31] & vint_sizesel[0]) | (vint_masksel[15] & vint_sizesel[1]) | (vint_masksel[7] & vint_sizesel[2])};
endmodule
