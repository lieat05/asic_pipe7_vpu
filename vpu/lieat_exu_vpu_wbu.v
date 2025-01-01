module lieat_exu_vpu_wbu(
  input                 vset_o_valid,
  output                vset_o_ready,
  input  [`XLEN-1:0]    vset_o_pc,
  input                 vset_o_wen,
  input  [`REG_IDX-1:0] vset_o_rd,
  input  [`XLEN-1:0]    vset_o_data,

  input                 vint_o_valid,
  output                vint_o_ready,
  input  [`XLEN-1:0]    vint_o_pc,
  input  [`REG_IDX-1:0] vint_o_rd,

  input                 vlsu_o_valid,
  output                vlsu_o_ready,
  input  [`XLEN-1:0]    vlsu_o_pc,
  input  [`REG_IDX-1:0] vlsu_o_rd,
  input  [`XLEN-1:0]    vlsu_o_data,
  input                 vlsu_o_vwen,
  input  [3:0]          vlsu_o_mask,

  input                 vint_o_vwen,
  input  [`XLEN-1:0]    vint_o_data0,
  input  [`XLEN-1:0]    vint_o_data1,
  input  [`XLEN-1:0]    vint_o_data2,
  input  [`XLEN-1:0]    vint_o_data3,
  input  [`XLEN-1:0]    vint_o_data4,
  input  [`XLEN-1:0]    vint_o_data5,
  input  [`XLEN-1:0]    vint_o_data6,
  input  [`XLEN-1:0]    vint_o_data7,
  input  [3:0]          vint_o_mask0,
  input  [3:0]          vint_o_mask1,
  input  [3:0]          vint_o_mask2,
  input  [3:0]          vint_o_mask3,
  input  [3:0]          vint_o_mask4,
  input  [3:0]          vint_o_mask5,
  input  [3:0]          vint_o_mask6,
  input  [3:0]          vint_o_mask7,

  output                vpu_o_valid,
  input                 vpu_o_ready,
  output [`XLEN-1:0]    vpu_o_pc,
  output                vpu_o_wen,
  output [`REG_IDX-1:0] vpu_o_rd,
  output [`XLEN-1:0]    vpu_o_data,
  
  output                vpu_o_vwen,
  output [`XLEN-1:0]    vpu_o_data0,
  output [`XLEN-1:0]    vpu_o_data1,
  output [`XLEN-1:0]    vpu_o_data2,
  output [`XLEN-1:0]    vpu_o_data3,
  output [`XLEN-1:0]    vpu_o_data4,
  output [`XLEN-1:0]    vpu_o_data5,
  output [`XLEN-1:0]    vpu_o_data6,
  output [`XLEN-1:0]    vpu_o_data7,
  output [3:0]          vpu_o_mask0,
  output [3:0]          vpu_o_mask1,
  output [3:0]          vpu_o_mask2,
  output [3:0]          vpu_o_mask3,
  output [3:0]          vpu_o_mask4,
  output [3:0]          vpu_o_mask5,
  output [3:0]          vpu_o_mask6,
  output [3:0]          vpu_o_mask7
);
wire sel_vlsu =  vlsu_o_valid;
wire sel_vint = ~vlsu_o_valid &  vint_o_valid;
wire sel_vset = ~vlsu_o_valid & ~vint_o_valid & vset_o_valid;

assign vset_o_ready = vpu_o_ready & ~vlsu_o_valid & ~vint_o_valid;
assign vint_o_ready = vpu_o_ready & ~vlsu_o_valid;
assign vlsu_o_ready = vpu_o_ready;

assign vpu_o_valid = vset_o_valid | vint_o_valid | vlsu_o_valid;
assign vpu_o_pc    = ({`XLEN{sel_vlsu}} & vlsu_o_pc  ) | ({`XLEN{sel_vint}} & vint_o_pc  ) | ({`XLEN{sel_vset}} & vset_o_pc  );
assign vpu_o_wen   =                                                                         (       sel_vset   & vset_o_wen );
assign vpu_o_rd    = ({ 5{vlsu_o_vwen}} & vlsu_o_rd  ) | ({    5{sel_vint}} & vint_o_rd  ) | ({    5{sel_vset}} & vset_o_rd  );
assign vpu_o_data  =                                                                         ({`XLEN{sel_vset}} & vset_o_data);
assign vpu_o_vwen  = vlsu_o_vwen | vint_o_vwen;

assign vpu_o_data0 = vlsu_o_vwen ? vlsu_o_data : vint_o_data0;
assign vpu_o_data1 = vint_o_data1;
assign vpu_o_data2 = vint_o_data2;
assign vpu_o_data3 = vint_o_data3;
assign vpu_o_data4 = vint_o_data4;
assign vpu_o_data5 = vint_o_data5;
assign vpu_o_data6 = vint_o_data6;
assign vpu_o_data7 = vint_o_data7;
assign vpu_o_mask0 = vlsu_o_vwen ? vlsu_o_mask : vint_o_mask0;
assign vpu_o_mask1 = vint_o_mask1;
assign vpu_o_mask2 = vint_o_mask2;
assign vpu_o_mask3 = vint_o_mask3;
assign vpu_o_mask4 = vint_o_mask4;
assign vpu_o_mask5 = vint_o_mask5;
assign vpu_o_mask6 = vint_o_mask6;
assign vpu_o_mask7 = vint_o_mask7;
endmodule
