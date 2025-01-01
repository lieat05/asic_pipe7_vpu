module lieat_idu_depend#(
  DEPTH = 7
)(
  input                clock,
  input                reset,

  input                com_flush,
  input                lsu_flush,
  input                muldiv_flush,
  input                vpu_flush,
  input                fpu_flush,

  input                disp_ena,
  input [4:0]          disp_op,
  input                disp_rs1en,
  input                disp_rs2en,
  input                disp_rdwen,
  input [`REG_IDX-1:0] disp_rs1,
  input [`REG_IDX-1:0] disp_rs2,
  input [`REG_IDX-1:0] disp_rd,

  input                wbck_ena,
  input [4:0]          wbck_op,

  input [`REG_IDX-1:0] if_rs1,
  output               if_dep,

  output               disp_condition,
  output               fifo_empty,
  output               lsu_muldiv_empty
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                disp_com;
wire                disp_lsu;
wire                disp_muldiv;
wire                disp_vpu;
wire                disp_fpu;

wire                wbck_com;
wire                wbck_lsu;
wire                wbck_muldiv;
wire                wbck_vpu;
wire                wbck_fpu;

wire [2:0]          wptr;
wire [2:0]          rptr;
wire                com_wptr;
wire                com_rptr;
wire                lsu_wptr;
wire                lsu_rptr;
wire [DEPTH-1:0]    flush_ptr;


wire [DEPTH-1:0]    oitf;//lsu muldiv others
wire [DEPTH-1:0]    oitf_set;
wire [DEPTH-1:0]    oitf_clr;
wire [DEPTH-1:0]    oitf_ena;
wire [DEPTH-1:0]    oitf_nxt;
wire [DEPTH-1:0]    oitf_vld;
wire [DEPTH-1:0]    oitf_rdwen;
wire [`REG_IDX-1:0] oitf_rd [DEPTH-1:0];

wire                oitf_o_rs1_matchrd;
wire                oitf_o_rs2_matchrd;
wire                oitf_o_rd_matchrd;

wire                disp_dep;
wire                fifo_full;
// ================================================================================================================================================
// OITF SIGNAL
// ================================================================================================================================================
assign disp_com    = disp_op[0];
assign disp_lsu    = disp_op[1];
assign disp_muldiv = disp_op[2];
assign disp_vpu    = disp_op[3];
assign disp_fpu    = disp_op[4];

assign wbck_com    = wbck_op[0];
assign wbck_lsu    = wbck_op[1];
assign wbck_muldiv = wbck_op[2];
assign wbck_vpu    = wbck_op[3];
assign wbck_fpu    = wbck_op[4];

lieat_general_dfflr #(1) com_wptr_dff(clock,reset,(disp_com & disp_ena) | com_flush,~com_wptr,com_wptr);
lieat_general_dfflr #(1) com_rptr_dff(clock,reset,wbck_com & wbck_ena,~com_rptr,com_rptr);
lieat_general_dfflr #(1) lsu_wptr_dff(clock,reset,(disp_lsu & disp_ena) | lsu_flush,~lsu_wptr,lsu_wptr);
lieat_general_dfflr #(1) lsu_rptr_dff(clock,reset,wbck_lsu & wbck_ena,~lsu_rptr,lsu_rptr);

assign wptr = 
({3{disp_com}}    & {2'b00,com_wptr}) |
({3{disp_lsu}}    & {2'b01,lsu_wptr}) |
({3{disp_muldiv}} & {3'b100        }) |
({3{disp_vpu}}    & {3'b101        }) |
({3{disp_fpu}}    & {3'b110        }) ;
assign rptr = 
({3{wbck_com}}    & {2'b00,com_rptr}) |
({3{wbck_lsu}}    & {2'b01,lsu_rptr}) |
({3{wbck_muldiv}} & {3'b100        }) |
({3{wbck_vpu}}    & {3'b101        }) |
({3{wbck_fpu}}    & {3'b110        }) ;
assign flush_ptr = {
fpu_flush,
vpu_flush,
muldiv_flush,
lsu_flush & ~lsu_wptr,
lsu_flush & lsu_wptr,
com_flush & ~com_wptr,
com_flush & com_wptr
};
genvar i;
generate 
  for(i = 0;i < DEPTH; i = i + 1) begin
    assign oitf_set[i] = disp_ena   & (wptr == i);
    assign oitf_clr[i] = (wbck_ena & rptr == i) | flush_ptr[i];
    assign oitf_ena[i] = oitf_set[i] | oitf_clr[i];
    assign oitf_nxt[i] = oitf_set[i] | (~oitf_clr[i]);
    assign oitf_vld[i] = oitf[i] & ~oitf_clr[i];
    lieat_general_dfflr #(1) oitf_dff (clock,reset,oitf_ena[i],oitf_nxt[i],oitf[i]);
    lieat_general_dfflr #(1) oitf_rdwen_dff (clock,reset,oitf_set[i],disp_rdwen,oitf_rdwen[i]);
    lieat_general_dfflr #(`REG_IDX) oitf_rd_dff (clock,reset,oitf_set[i],disp_rd,oitf_rd[i]);
  end
endgenerate
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign oitf_o_rs1_matchrd =
(oitf_vld[2] & disp_rs1en & oitf_rdwen[2] & (disp_rs1 == oitf_rd[2]))|
(oitf_vld[3] & disp_rs1en & oitf_rdwen[3] & (disp_rs1 == oitf_rd[3]))|
(oitf_vld[4] & disp_rs1en & oitf_rdwen[4] & (disp_rs1 == oitf_rd[4]))|
(oitf_vld[6] & disp_rs1en & oitf_rdwen[6] & (disp_rs1 == oitf_rd[6]));
assign oitf_o_rs2_matchrd =
(oitf_vld[2] & disp_rs2en & oitf_rdwen[2] & (disp_rs2 == oitf_rd[2]))|
(oitf_vld[3] & disp_rs2en & oitf_rdwen[3] & (disp_rs2 == oitf_rd[3]))|
(oitf_vld[4] & disp_rs2en & oitf_rdwen[4] & (disp_rs2 == oitf_rd[4]))|
(oitf_vld[6] & disp_rs2en & oitf_rdwen[6] & (disp_rs2 == oitf_rd[6]));
assign oitf_o_rd_matchrd =
(oitf_vld[2] & disp_rdwen & oitf_rdwen[2] & (disp_rd  == oitf_rd[2]))|
(oitf_vld[3] & disp_rdwen & oitf_rdwen[3] & (disp_rd  == oitf_rd[3]))|
(oitf_vld[4] & disp_rdwen & oitf_rdwen[4] & (disp_rd  == oitf_rd[4]))|
(oitf_vld[6] & disp_rdwen & oitf_rdwen[6] & (disp_rd  == oitf_rd[6]));
assign if_dep =
(oitf_vld[2] & oitf_rdwen[2] & (if_rs1   == oitf_rd[2]))|
(oitf_vld[3] & oitf_rdwen[3] & (if_rs1   == oitf_rd[3]))|
(oitf_vld[4] & oitf_rdwen[4] & (if_rs1   == oitf_rd[4]))|
(oitf_vld[6] & oitf_rdwen[6] & (if_rs1   == oitf_rd[6]));

assign disp_dep         = oitf_o_rs1_matchrd | oitf_o_rs2_matchrd | oitf_o_rd_matchrd;
assign fifo_full        = (disp_com & oitf_vld[0] & oitf_vld[1]) | (disp_lsu & oitf_vld[2] & oitf_vld[3]) | (disp_muldiv & oitf_vld[4]) | (disp_vpu & oitf_vld[5]);
assign disp_condition   = ~disp_dep & ~fifo_full;

assign lsu_muldiv_empty = ~oitf[2] & ~oitf[3] & ~oitf[4] & ~oitf[5];//DPI-C
assign fifo_empty       = ~oitf[0] & ~oitf[1] & ~oitf[2] & ~oitf[3] & ~oitf[4] & ~oitf[5];
wire unused_ok = &{oitf_rdwen};
endmodule
