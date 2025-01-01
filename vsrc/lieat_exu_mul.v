module lieat_exu_mul(
  input              clock,
  input              reset,

  input              mul_i_valid,
  output             mul_i_ready,
  input              mul_i_signed1,
  input              mul_i_signed2,
  input  [`XLEN-1:0] mul_i_multiplicand,
  input  [`XLEN-1:0] mul_i_multiplier,

  output             mul_o_valid,
  input              mul_o_ready,
  output [`XLEN-1:0] mul_o_resh,
  output [`XLEN-1:0] mul_o_resl
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
localparam         STATE_IDLE = 6'b000001;//quot_neg rem_neg
localparam         STATE_PRE  = 6'b000010;
localparam         STATE_CYC0 = 6'b000100;
localparam         STATE_CYC1 = 6'b001000;
localparam         STATE_CYC2 = 6'b010000;
localparam         STATE_POS  = 6'b100000;

localparam         STATE_IDLE_BIT = 0;
localparam         STATE_PRE_BIT  = 1;
localparam         STATE_CYC0_BIT = 2;
localparam         STATE_CYC1_BIT = 3;
localparam         STATE_CYC2_BIT = 4;
localparam         STATE_POS_BIT  = 5;

wire               mul_i_sh = mul_i_valid & mul_i_ready;
wire               mul_o_sh = mul_o_valid & mul_o_ready;

reg [5:0]          state_r;
reg [5:0]          state_nxt;

wire               mul_i_zero;
wire               multiplicand_neg;
wire               multiplier_neg;
wire [`XLEN-1:0]   multiplicand_inv;
wire [`XLEN-1:0]   multiplier_inv;

wire               res_neg;
wire               res_neg_ena;
wire               res_neg_nxt;

wire               abs_ena;
wire               multiplier_abs_sign;
wire [`XLEN-1:0]   multiplicand_abs;
wire [`XLEN-1:0]   multiplicand_absneg;
wire [`XLEN-1:0]   multiplier_abs_nxt;
wire [`XLEN-1:0]   multiplicand_abs_nxt;
wire [`XLEN-1:0]   multiplicand_absneg_nxt;

wire [8:0]         booth_sel;
wire [3:0]         booth_bits0;
wire [3:0]         booth_bits1;
wire [3:0]         booth_bits2;
wire [3:0]         booth_bits3;
wire [3:0]         booth_bits0_nxt;
wire [3:0]         booth_bits1_nxt;
wire [3:0]         booth_bits2_nxt;
wire [3:0]         booth_bits3_nxt;

wire [`XLEN*2-1:0] partial_product_0;
wire [`XLEN*2-1:0] partial_product_1;
wire [`XLEN*2-1:0] partial_product_2;
wire [`XLEN*2-1:0] partial_product_3;
wire [`XLEN*2-1:0] partial_product_extend;

wire [`XLEN*2-1:0] intermediate_sum1;
wire [`XLEN*2-1:0] intermediate_sum2;
wire [`XLEN*2-1:0] intermediate_sum3;
wire [`XLEN*2-1:0] intermediate_sum4;
wire [`XLEN*2-1:0] intermediate_sum5;
wire [`XLEN*2-1:0] intermediate_sum6;
wire [`XLEN*2-1:0] intermediate_sum7;
wire [`XLEN*2-1:0] intermediate_sum8;

wire [`XLEN*2-1:0] mul_res;
wire [`XLEN*2-1:0] mul_res_cycle;
wire [`XLEN*2-1:0] mul_res_nxt;
// ================================================================================================================================================
// STATE Ctrl Logic
// ================================================================================================================================================
assign mul_i_ready = state_r[STATE_IDLE_BIT];
assign mul_o_valid = state_r[STATE_POS_BIT];

always @(*) begin
  case(state_r)
    STATE_IDLE:state_nxt = mul_i_sh ? (mul_i_zero ? STATE_POS : STATE_PRE) : STATE_IDLE;
    STATE_PRE :state_nxt = STATE_CYC0;
    STATE_CYC0:state_nxt = STATE_CYC1;
    STATE_CYC1:state_nxt = STATE_CYC2;
    STATE_CYC2:state_nxt = STATE_POS ;
    STATE_POS :state_nxt = mul_o_sh   ? STATE_IDLE : STATE_POS;
    default:state_nxt = STATE_IDLE;
  endcase
end
lieat_general_dffrd #(.DW(6),.DEFAULT(STATE_IDLE)) mul_state(clock,reset,state_nxt,state_r);
// ================================================================================================================================================
// PRE PREPARE
// ================================================================================================================================================
assign mul_i_zero = (mul_i_multiplicand == 32'h0) | (mul_i_multiplier == 32'h0);
assign multiplicand_neg = mul_i_signed1 & mul_i_multiplicand[`XLEN-1];
assign multiplier_neg   = mul_i_signed2 & mul_i_multiplier[`XLEN-1];
assign multiplicand_inv = -mul_i_multiplicand;
assign multiplier_inv   = -mul_i_multiplier;

assign res_neg_ena = mul_i_sh;
assign res_neg_nxt = multiplicand_neg ^ multiplier_neg;
lieat_general_dfflr #(1) res_neg_dff(clock,reset,res_neg_ena,res_neg_nxt,res_neg);

assign abs_ena = mul_i_sh;
assign multiplier_abs_nxt      = multiplier_neg   ? multiplier_inv   : mul_i_multiplier;
assign multiplicand_abs_nxt    = multiplicand_neg ? multiplicand_inv : mul_i_multiplicand;
assign multiplicand_absneg_nxt = -multiplicand_abs_nxt;

lieat_general_dfflr #(`XLEN) multiplicand_abs_dff(clock,reset,abs_ena,multiplicand_abs_nxt,multiplicand_abs);
lieat_general_dfflr #(`XLEN) multiplicand_absneg_dff(clock,reset,abs_ena,multiplicand_absneg_nxt,multiplicand_absneg);
lieat_general_dfflr #(1)     multiplier_abs_sign_dff(clock,reset,abs_ena,multiplier_abs_nxt[31],multiplier_abs_sign);//generate booth
// ================================================================================================================================================
// CYCLE
// ================================================================================================================================================
assign booth_sel = 
({9{mul_i_sh               }} &  multiplier_abs_nxt[31:23]    ) |
({9{state_r[STATE_PRE_BIT ]}} &  multiplier_abs_nxt[23:15]    ) |
({9{state_r[STATE_CYC0_BIT]}} &  multiplier_abs_nxt[15: 7]    ) |
({9{state_r[STATE_CYC1_BIT]}} & {multiplier_abs_nxt[7 : 0],1'b0});

assign booth_bits0_nxt = {
(booth_sel[2:0] == 3'b001) | (booth_sel[2:0] == 3'b010),
(booth_sel[2:0] == 3'b101) | (booth_sel[2:0] == 3'b110),
(booth_sel[2:0] == 3'b011),
(booth_sel[2:0] == 3'b100)
};
assign booth_bits1_nxt = {
(booth_sel[4:2] == 3'b001) | (booth_sel[4:2] == 3'b010),
(booth_sel[4:2] == 3'b101) | (booth_sel[4:2] == 3'b110),
(booth_sel[4:2] == 3'b011),
(booth_sel[4:2] == 3'b100)
};
assign booth_bits2_nxt = {
(booth_sel[6:4] == 3'b001) | (booth_sel[6:4] == 3'b010),
(booth_sel[6:4] == 3'b101) | (booth_sel[6:4] == 3'b110),
(booth_sel[6:4] == 3'b011),
(booth_sel[6:4] == 3'b100)
};
assign booth_bits3_nxt = {
(booth_sel[8:6] == 3'b001) | (booth_sel[8:6] == 3'b010),
(booth_sel[8:6] == 3'b101) | (booth_sel[8:6] == 3'b110),
(booth_sel[8:6] == 3'b011),
(booth_sel[8:6] == 3'b100)
};
lieat_general_dfflr #(4) booth_bits0_dff(clock,reset,1'b1,booth_bits0_nxt,booth_bits0);
lieat_general_dfflr #(4) booth_bits1_dff(clock,reset,1'b1,booth_bits1_nxt,booth_bits1);
lieat_general_dfflr #(4) booth_bits2_dff(clock,reset,1'b1,booth_bits2_nxt,booth_bits2);
lieat_general_dfflr #(4) booth_bits3_dff(clock,reset,1'b1,booth_bits3_nxt,booth_bits3);

assign partial_product_0 = 
({`XLEN*2{booth_bits0[3]}} & {32'h0,multiplicand_abs}) | 
({`XLEN*2{booth_bits0[2]}} & {32'hffffffff,multiplicand_absneg}) | 
({`XLEN*2{booth_bits0[1]}} & {31'b0,multiplicand_abs,1'b0}) | 
({`XLEN*2{booth_bits0[0]}} & {31'h7fffffff,multiplicand_absneg,1'b0});
assign partial_product_1 = 
({`XLEN*2{booth_bits1[3]}} & {32'h0,multiplicand_abs}) | 
({`XLEN*2{booth_bits1[2]}} & {32'hffffffff,multiplicand_absneg}) | 
({`XLEN*2{booth_bits1[1]}} & {31'b0,multiplicand_abs,1'b0}) | 
({`XLEN*2{booth_bits1[0]}} & {31'h7fffffff,multiplicand_absneg,1'b0});
assign partial_product_2 = 
({`XLEN*2{booth_bits2[3]}} & {32'h0,multiplicand_abs}) | 
({`XLEN*2{booth_bits2[2]}} & {32'hffffffff,multiplicand_absneg}) | 
({`XLEN*2{booth_bits2[1]}} & {31'b0,multiplicand_abs,1'b0}) | 
({`XLEN*2{booth_bits2[0]}} & {31'h7fffffff,multiplicand_absneg,1'b0});
assign partial_product_3 = 
({`XLEN*2{booth_bits3[3]}} & {32'h0,multiplicand_abs}) | 
({`XLEN*2{booth_bits3[2]}} & {32'hffffffff,multiplicand_absneg}) | 
({`XLEN*2{booth_bits3[1]}} & {31'b0,multiplicand_abs,1'b0}) | 
({`XLEN*2{booth_bits3[0]}} & {31'h7fffffff,multiplicand_absneg,1'b0});

assign partial_product_extend = {`XLEN*2{state_r[STATE_PRE_BIT] & multiplier_abs_sign}} & {32'h0,multiplicand_abs};
// ================================================================================================================================================
// COMPRESS ADD
// ================================================================================================================================================
lieat_general_compress32 #(`XLEN*2) mul_add1(partial_product_0,partial_product_1 << 2,partial_product_2 << 4,intermediate_sum1,intermediate_sum2);
lieat_general_compress32 #(`XLEN*2) mul_add2(partial_product_3 << 6, partial_product_extend << 8, mul_res << 8,intermediate_sum3,intermediate_sum4);
lieat_general_compress32 #(`XLEN*2) mul_add3(intermediate_sum1,intermediate_sum2,intermediate_sum3,intermediate_sum5,intermediate_sum6);
lieat_general_compress32 #(`XLEN*2) mul_add4(intermediate_sum4,intermediate_sum5,intermediate_sum6,intermediate_sum7,intermediate_sum8);
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign mul_res_cycle = intermediate_sum7 + intermediate_sum8;
assign mul_res_nxt = 
({`XLEN*2{state_r[STATE_CYC2_BIT] &  res_neg}} & -mul_res_cycle) |
({`XLEN*2{state_r[STATE_CYC2_BIT] & ~res_neg}} &  mul_res_cycle) |
({`XLEN*2{state_r[STATE_POS_BIT ]           }} &  mul_res      ) |
({`XLEN*2{state_r[STATE_CYC1_BIT]           }} &  mul_res_cycle) |
({`XLEN*2{state_r[STATE_CYC0_BIT]           }} &  mul_res_cycle) |
({`XLEN*2{state_r[STATE_PRE_BIT ]           }} &  mul_res_cycle) ;
lieat_general_dfflr #(2*`XLEN) mul_res_dff(clock,reset,1'b1,mul_res_nxt,mul_res);
assign mul_o_resh  = mul_res[63:32];
assign mul_o_resl  = mul_res[31:0];
endmodule
