module lieat_exu_vpu(
  input                          clock,
  input                          reset,  
  input                          flush_req,
  
  input                          vpu_i_valid,
  output                         vpu_i_ready,
  input [`XLEN-1:0]              vpu_i_pc,
  input [`REG_IDX-1:0]           vpu_i_rd,
  input [`REG_IDX-1:0]           vpu_i_rs1,
  input [`REG_IDX-1:0]           vpu_i_rs2,
  input [`XLEN-1:0]              vpu_i_src1,
  input [`XLEN-1:0]              vpu_i_src2,
  input [`INFOBUS_VPU_WIDTH-1:0] vpu_i_infobus,

  output                         vpu_o_valid,
  input                          vpu_o_ready,
  output [`XLEN-1:0]             vpu_o_pc,
  output                         vpu_o_wen,
  output [`REG_IDX-1:0]          vpu_o_rd,
  output [`XLEN-1:0]             vpu_o_data,
  output                         vpu_o_flush,

  output                         vpu_req_valid,
  input                          vpu_req_ready,
  output                         vpu_req_ren,
  output                         vpu_req_wen,
  output [`XLEN-1:0]             vpu_req_addr,
  output [2:0]                   vpu_req_flag,
  output [`XLEN-1:0]             vpu_req_wdata,
  input                          vpu_rsp_valid,
  output                         vpu_rsp_ready,
  input  [`XLEN-1:0]             vpu_rsp_rdata
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                          vset_i_valid;
wire                          vset_i_ready;
wire                          vset_o_valid;
wire                          vset_o_ready;
wire                          vset_o_flush;
wire [`XLEN-1:0]              vset_o_data;
wire [`XLEN-1:0]              vset_o_pc;
wire                          vset_o_wen;
wire [`REG_IDX-1:0]           vset_o_rd;

wire                          vint_i_valid;
wire                          vint_i_ready;
wire                          vint_o_flush;
wire                          vint_o_ready;
wire                          vint_o_valid;
wire [`XLEN-1:0]              vint_o_pc;
wire [`REG_IDX-1:0]           vint_o_rd;
wire                          vint_o_vwen;
wire [3:0]                    vint_o_mask0;
wire [3:0]                    vint_o_mask1;
wire [3:0]                    vint_o_mask2;
wire [3:0]                    vint_o_mask3;
wire [3:0]                    vint_o_mask4;
wire [3:0]                    vint_o_mask5;
wire [3:0]                    vint_o_mask6;
wire [3:0]                    vint_o_mask7;
wire [`XLEN-1:0]              vint_o_data0;
wire [`XLEN-1:0]              vint_o_data1;
wire [`XLEN-1:0]              vint_o_data2;
wire [`XLEN-1:0]              vint_o_data3;
wire [`XLEN-1:0]              vint_o_data4;
wire [`XLEN-1:0]              vint_o_data5;
wire [`XLEN-1:0]              vint_o_data6;
wire [`XLEN-1:0]              vint_o_data7;

wire                          vlsu_i_valid;
wire                          vlsu_i_ready;
wire                          vlsu_o_valid;
wire                          vlsu_o_ready;
wire                          vlsu_o_flush;
wire [`XLEN-1:0]              vlsu_o_pc;
wire                          vlsu_o_vwen;
wire [`REG_IDX-1:0]           vlsu_o_rd;
wire [`XLEN-1:0]              vlsu_o_data;
wire [3:0]                    vlsu_o_mask;

wire                          vpu_o_vwen;
wire [3:0]                    vpu_o_wmask0;
wire [3:0]                    vpu_o_wmask1;
wire [3:0]                    vpu_o_wmask2;
wire [3:0]                    vpu_o_wmask3;
wire [3:0]                    vpu_o_wmask4;
wire [3:0]                    vpu_o_wmask5;
wire [3:0]                    vpu_o_wmask6;
wire [3:0]                    vpu_o_wmask7;
wire [`XLEN-1:0]              vpu_o_wdata0;
wire [`XLEN-1:0]              vpu_o_wdata1;
wire [`XLEN-1:0]              vpu_o_wdata2;
wire [`XLEN-1:0]              vpu_o_wdata3;
wire [`XLEN-1:0]              vpu_o_wdata4;
wire [`XLEN-1:0]              vpu_o_wdata5;
wire [`XLEN-1:0]              vpu_o_wdata6;
wire [`XLEN-1:0]              vpu_o_wdata7;

wire                          vcsr_vl_wen;
wire [      4:0]              vcsr_vl_wdata;
wire [      4:0]              vcsr_vl_rdata;
wire                          vcsr_vtype_wen;
wire [`XLEN-1:0]              vcsr_vtype_wdata;
wire [`XLEN-1:0]              vcsr_vtype_rdata;

wire [`REG_IDX-1:0]           vlsu_vs2;
wire [`REG_IDX-1:0]           vlsu_vs3;
wire [`REG_IDX-1:0]           vreg_vs1;
wire [`REG_IDX-1:0]           vreg_vs2;
wire [`XLEN-1:0]              vreg_mask;
wire [`XLEN-1:0]              vreg_vsrc1_0;
wire [`XLEN-1:0]              vreg_vsrc1_1;
wire [`XLEN-1:0]              vreg_vsrc1_2;
wire [`XLEN-1:0]              vreg_vsrc1_3;
wire [`XLEN-1:0]              vreg_vsrc1_4;
wire [`XLEN-1:0]              vreg_vsrc1_5;
wire [`XLEN-1:0]              vreg_vsrc1_6;
wire [`XLEN-1:0]              vreg_vsrc1_7;
wire [`XLEN-1:0]              vreg_vsrc2_0;
wire [`XLEN-1:0]              vreg_vsrc2_1;
wire [`XLEN-1:0]              vreg_vsrc2_2;
wire [`XLEN-1:0]              vreg_vsrc2_3;
wire [`XLEN-1:0]              vreg_vsrc2_4;
wire [`XLEN-1:0]              vreg_vsrc2_5;
wire [`XLEN-1:0]              vreg_vsrc2_6;
wire [`XLEN-1:0]              vreg_vsrc2_7;  
// ================================================================================================================================================
// MAIN
// ================================================================================================================================================
assign vset_i_valid = vpu_i_valid & vpu_i_infobus[`INFOBUS_VSET_VALID];
assign vint_i_valid = vpu_i_valid & vpu_i_infobus[`INFOBUS_VINT_VALID];
assign vlsu_i_valid = vpu_i_valid & vpu_i_infobus[`INFOBUS_VLSU_VALID];
assign vpu_i_ready  = (vpu_i_infobus[`INFOBUS_VSET_VALID] & vset_i_ready) | (vpu_i_infobus[`INFOBUS_VINT_VALID] & vint_i_ready) | (vpu_i_infobus[`INFOBUS_VLSU_VALID] & vlsu_i_ready);
assign vpu_o_flush  = vset_o_flush | vint_o_flush | vlsu_o_flush;

lieat_exu_vpu_vset vset(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),

  .vset_i_valid(vset_i_valid),
  .vset_i_ready(vset_i_ready),
  .vset_i_rs1(vpu_i_rs1),
  .vset_i_rd(vpu_i_rd),
  .vset_i_pc(vpu_i_pc),
  .vset_i_src1(vpu_i_src1),
  .vset_i_src2(vpu_i_src2[7:0]),
  .vset_i_infobus(vpu_i_infobus),
  
  .vset_vtype_wen(vcsr_vtype_wen),
  .vset_vtype_wdata(vcsr_vtype_wdata),
  .vset_vl_wen(vcsr_vl_wen),
  .vset_vl_wdata(vcsr_vl_wdata),
  .vset_vl_rdata(vcsr_vl_rdata),

  .vset_o_valid(vset_o_valid),
  .vset_o_ready(vset_o_ready),
  .vset_o_flush(vset_o_flush),
  .vset_o_data(vset_o_data),
  .vset_o_wen(vset_o_wen),
  .vset_o_pc(vset_o_pc),
  .vset_o_rd(vset_o_rd)
);

lieat_exu_vpu_vint vint(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),

  .vint_i_valid(vint_i_valid),
  .vint_i_ready(vint_i_ready),
  .vint_i_rd(vpu_i_rd),
  .vint_i_pc(vpu_i_pc),
  .vint_i_rs1(vpu_i_rs1),
  .vint_i_src1(vpu_i_src1),
  .vint_i_infobus(vpu_i_infobus),
  .vint_i_vsrc1_0(vreg_vsrc1_0),
  .vint_i_vsrc1_1(vreg_vsrc1_1),
  .vint_i_vsrc1_2(vreg_vsrc1_2),
  .vint_i_vsrc1_3(vreg_vsrc1_3),
  .vint_i_vsrc1_4(vreg_vsrc1_4),
  .vint_i_vsrc1_5(vreg_vsrc1_5),
  .vint_i_vsrc1_6(vreg_vsrc1_6),
  .vint_i_vsrc1_7(vreg_vsrc1_7),
  .vint_i_vsrc2_0(vreg_vsrc2_0),
  .vint_i_vsrc2_1(vreg_vsrc2_1),
  .vint_i_vsrc2_2(vreg_vsrc2_2),
  .vint_i_vsrc2_3(vreg_vsrc2_3),
  .vint_i_vsrc2_4(vreg_vsrc2_4),
  .vint_i_vsrc2_5(vreg_vsrc2_5),
  .vint_i_vsrc2_6(vreg_vsrc2_6),
  .vint_i_vsrc2_7(vreg_vsrc2_7),

  .vint_vtype(vcsr_vtype_rdata[8:6]),
  .vint_vl(vcsr_vl_rdata[4:0]),  
  .vint_mask(vreg_mask),

  .vint_o_valid(vint_o_valid),
  .vint_o_ready(vint_o_ready),
  .vint_o_flush(vint_o_flush),
  .vint_o_pc(vint_o_pc),
  .vint_o_rd(vint_o_rd),

  .vint_o_vwen(vint_o_vwen),
  .vint_o_data0(vint_o_data0),
  .vint_o_data1(vint_o_data1),
  .vint_o_data2(vint_o_data2),
  .vint_o_data3(vint_o_data3),
  .vint_o_data4(vint_o_data4),
  .vint_o_data5(vint_o_data5),
  .vint_o_data6(vint_o_data6),
  .vint_o_data7(vint_o_data7),
  .vint_o_mask0(vint_o_mask0),
  .vint_o_mask1(vint_o_mask1),
  .vint_o_mask2(vint_o_mask2),
  .vint_o_mask3(vint_o_mask3),
  .vint_o_mask4(vint_o_mask4),
  .vint_o_mask5(vint_o_mask5),
  .vint_o_mask6(vint_o_mask6),
  .vint_o_mask7(vint_o_mask7)
);

lieat_exu_vpu_vlsu vlsu(
  .clock(clock),
  .reset(reset),
  .flush_req(flush_req),

  .vlsu_i_valid(vlsu_i_valid),
  .vlsu_i_ready(vlsu_i_ready),
  .vlsu_i_rd(vpu_i_rd),
  .vlsu_i_pc(vpu_i_pc),
  .vlsu_i_src1(vpu_i_src1),
  .vlsu_i_infobus(vpu_i_infobus),

  .vlsu_vs2(vlsu_vs2),
  .vlsu_vs3(vlsu_vs3),
  .vlsu_vl(vcsr_vl_rdata[4:0]),
  .vlsu_mask(vreg_mask),
  .vlsu_vsrc2(vreg_vsrc1_0),
  .vlsu_vsrc3(vreg_vsrc2_0),

  .vlsu_o_valid(vlsu_o_valid),
  .vlsu_o_ready(vlsu_o_ready),
  .vlsu_o_flush(vlsu_o_flush),
  .vlsu_o_pc(vlsu_o_pc),
  .vlsu_o_vwen(vlsu_o_vwen),
  .vlsu_o_rd(vlsu_o_rd),
  .vlsu_o_data(vlsu_o_data),
  .vlsu_o_mask(vlsu_o_mask),

  .vlsu_req_valid(vpu_req_valid),
  .vlsu_req_ready(vpu_req_ready),
  .vlsu_req_ren(vpu_req_ren),
  .vlsu_req_wen(vpu_req_wen),
  .vlsu_req_addr(vpu_req_addr),
  .vlsu_req_flag(vpu_req_flag),
  .vlsu_req_wdata(vpu_req_wdata),
  .vlsu_rsp_valid(vpu_rsp_valid),
  .vlsu_rsp_ready(vpu_rsp_ready),
  .vlsu_rsp_rdata(vpu_rsp_rdata)
);

lieat_exu_vpu_wbu vpu_wbu(
  .vset_o_valid(vset_o_valid),
  .vset_o_ready(vset_o_ready),
  .vset_o_pc(vset_o_pc),
  .vset_o_wen(vset_o_wen),
  .vset_o_rd(vset_o_rd),
  .vset_o_data(vset_o_data),

  .vint_o_valid(vint_o_valid),
  .vint_o_ready(vint_o_ready),
  .vint_o_pc(vint_o_pc),
  .vint_o_rd(vint_o_rd),

  .vlsu_o_valid(vlsu_o_valid),
  .vlsu_o_ready(vlsu_o_ready),
  .vlsu_o_pc(vlsu_o_pc),
  .vlsu_o_vwen(vlsu_o_vwen),
  .vlsu_o_rd(vlsu_o_rd),
  .vlsu_o_data(vlsu_o_data),
  .vlsu_o_mask(vlsu_o_mask),

  .vint_o_vwen(vint_o_vwen),
  .vint_o_data0(vint_o_data0),
  .vint_o_data1(vint_o_data1),
  .vint_o_data2(vint_o_data2),
  .vint_o_data3(vint_o_data3),
  .vint_o_data4(vint_o_data4),
  .vint_o_data5(vint_o_data5),
  .vint_o_data6(vint_o_data6),
  .vint_o_data7(vint_o_data7),
  .vint_o_mask0(vint_o_mask0),
  .vint_o_mask1(vint_o_mask1),
  .vint_o_mask2(vint_o_mask2),
  .vint_o_mask3(vint_o_mask3),
  .vint_o_mask4(vint_o_mask4),
  .vint_o_mask5(vint_o_mask5),
  .vint_o_mask6(vint_o_mask6),
  .vint_o_mask7(vint_o_mask7),
  
  .vpu_o_valid(vpu_o_valid),
  .vpu_o_ready(vpu_o_ready),
  .vpu_o_pc(vpu_o_pc),
  .vpu_o_wen(vpu_o_wen),
  .vpu_o_rd(vpu_o_rd),
  .vpu_o_data(vpu_o_data),
  .vpu_o_vwen(vpu_o_vwen),
  .vpu_o_data0(vpu_o_wdata0),
  .vpu_o_data1(vpu_o_wdata1),
  .vpu_o_data2(vpu_o_wdata2),
  .vpu_o_data3(vpu_o_wdata3),
  .vpu_o_data4(vpu_o_wdata4),
  .vpu_o_data5(vpu_o_wdata5),
  .vpu_o_data6(vpu_o_wdata6),
  .vpu_o_data7(vpu_o_wdata7),
  .vpu_o_mask0(vpu_o_wmask0),
  .vpu_o_mask1(vpu_o_wmask1),
  .vpu_o_mask2(vpu_o_wmask2),
  .vpu_o_mask3(vpu_o_wmask3),
  .vpu_o_mask4(vpu_o_wmask4),
  .vpu_o_mask5(vpu_o_wmask5),
  .vpu_o_mask6(vpu_o_wmask6),
  .vpu_o_mask7(vpu_o_wmask7)  
);
// ================================================================================================================================================
// VCSRFILE
// ================================================================================================================================================
assign vreg_vs1         = vint_i_valid ? vpu_i_rs1 : vlsu_vs2;
assign vreg_vs2         = vint_i_valid ? vpu_i_rs2 : vlsu_vs3;
lieat_vcsrfile vcsrfile(
  .clock(clock),
  .reset(reset),
  .csr_vl_wen(vcsr_vl_wen),
  .csr_vl_wdata(vcsr_vl_wdata),
  .csr_vl_rdata(vcsr_vl_rdata),
  .csr_vtype_wen(vcsr_vtype_wen),
  .csr_vtype_wdata(vcsr_vtype_wdata),
  .csr_vtype_rdata(vcsr_vtype_rdata)
);

lieat_vregfile vregfile(
  .clock(clock),
  .reset(reset),
  .vreg_vs1(vreg_vs1),
  .vreg_vs2(vreg_vs2),
  .vreg_mask(vreg_mask),
  .vreg_vsrc1_0(vreg_vsrc1_0),
  .vreg_vsrc1_1(vreg_vsrc1_1),
  .vreg_vsrc1_2(vreg_vsrc1_2),
  .vreg_vsrc1_3(vreg_vsrc1_3),
  .vreg_vsrc1_4(vreg_vsrc1_4),
  .vreg_vsrc1_5(vreg_vsrc1_5),
  .vreg_vsrc1_6(vreg_vsrc1_6),
  .vreg_vsrc1_7(vreg_vsrc1_7),
  .vreg_vsrc2_0(vreg_vsrc2_0),
  .vreg_vsrc2_1(vreg_vsrc2_1),
  .vreg_vsrc2_2(vreg_vsrc2_2),
  .vreg_vsrc2_3(vreg_vsrc2_3),
  .vreg_vsrc2_4(vreg_vsrc2_4),
  .vreg_vsrc2_5(vreg_vsrc2_5),
  .vreg_vsrc2_6(vreg_vsrc2_6),
  .vreg_vsrc2_7(vreg_vsrc2_7),
  .vreg_wvalid(vpu_o_vwen),
  .vreg_rd0(vpu_o_rd),
  .vreg_wmask0(vpu_o_wmask0),
  .vreg_wmask1(vpu_o_wmask1),
  .vreg_wmask2(vpu_o_wmask2),
  .vreg_wmask3(vpu_o_wmask3),
  .vreg_wmask4(vpu_o_wmask4),
  .vreg_wmask5(vpu_o_wmask5),
  .vreg_wmask6(vpu_o_wmask6),
  .vreg_wmask7(vpu_o_wmask7),
  .vreg_wdata0(vpu_o_wdata0),
  .vreg_wdata1(vpu_o_wdata1),
  .vreg_wdata2(vpu_o_wdata2),
  .vreg_wdata3(vpu_o_wdata3),
  .vreg_wdata4(vpu_o_wdata4),
  .vreg_wdata5(vpu_o_wdata5),
  .vreg_wdata6(vpu_o_wdata6),
  .vreg_wdata7(vpu_o_wdata7)
);
wire unused_ok = &{vpu_i_src2[31:8],vcsr_vtype_rdata};
endmodule
