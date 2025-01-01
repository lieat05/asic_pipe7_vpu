module lieat_exu_div(
  input              clock,
  input              reset,
  input              div_i_valid,
  output             div_i_ready,
  input              div_i_signed,
  input  [`XLEN-1:0] div_i_dividend,
  input  [`XLEN-1:0] div_i_divisor,

  output             div_o_valid,
  input              div_o_ready,
  output [`XLEN-1:0] div_o_quot,
  output [`XLEN-1:0] div_o_rem
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
localparam QUOT_NEG_2 = 0;
localparam QUOT_NEG_1 = 1;
localparam QUOT_ZERO  = 2;
localparam QUOT_POS_1 = 3;
localparam QUOT_POS_2 = 4;
localparam QUOT_ONEHOT_ZERO  = 5'b0_0100;
localparam QUOT_ONEHOT_POS_1 = 5'b0_1000;
localparam QUOT_ONEHOT_POS_2 = 5'b1_0000;

localparam STATE_IDLE_BIT = 0;
localparam STATE_PRE0_BIT = 1;
localparam STATE_PRE1_BIT = 2;
localparam STATE_ITER_BIT = 3;
localparam STATE_POS0_BIT = 4;
localparam STATE_POS1_BIT = 5;

localparam STATE_IDLE = 6'b000001;//quot_neg rem_neg
localparam STATE_PRE0 = 6'b000010;
localparam STATE_PRE1 = 6'b000100;
localparam STATE_ITER = 6'b001000;
localparam STATE_POS0 = 6'b010000;
localparam STATE_POS1 = 6'b100000;

reg [5:0]             div_state_r;
reg [5:0]             div_state_nxt;

wire                  div_i_sh = div_i_valid & div_i_ready;
wire                  div_o_sh = div_o_valid & div_o_ready;

wire [`LZC_WIDTH:0]   lzc_diff;
wire [`LZC_WIDTH:0]   lzc_diff_nxt;

wire                  divisor_is_zero;
wire                  divisor_is_one;
wire                  dividend_too_big;//dividend is too big and divisor is too small
wire                  dividend_too_big_en;
wire                  dividend_too_big_nxt;
wire                  dividend_too_small;//dividend < divisor
wire                  dividend_too_small_en;
wire                  dividend_too_small_nxt;

wire                  skip_iter;

wire                  rem_neg;
wire                  rem_neg_nxt;
wire                  rem_neg_ena;
wire                  quot_neg;
wire                  quot_neg_nxt;
wire                  quot_neg_ena;

wire                  dividend_neg;
wire                  divisor_neg;
wire [`XLEN-1:0]      inv1;
wire [`XLEN-1:0]      inv2;

wire [`XLEN-1:0]      dividend_abs_pre;
wire [`XLEN-1:0]      divisor_abs_pre;
wire [`XLEN-1:0]      normalized_dividend;
wire [`XLEN-1:0]      normalized_divisor;

wire [`XLEN:0]        divisor_abs;
wire [`XLEN:0]        dividend_abs;
wire                  abs_ena;
wire [`XLEN:0]        divisor_abs_nxt;
wire [`XLEN:0]        dividend_abs_nxt;

wire                  lzc_ena;
wire [`LZC_WIDTH:0]   divisor_lzc;
wire [`LZC_WIDTH:0]   dividend_lzc;
wire [`LZC_WIDTH:0]   divisor_lzc_nxt;
wire [`LZC_WIDTH:0]   dividend_lzc_nxt;

wire [`LZC_WIDTH-1:0] shifter_num;
wire [`XLEN-1:0]      shifter_din;
wire                  shifter_extend_msb;

wire [`XLEN-1:0]      shifter_res_s0;
wire [`XLEN-1:0]      shifter_res_s1;
wire [`XLEN-1:0]      shifter_res_s2;
wire [`XLEN-1:0]      shifter_res_s3;
wire [`XLEN-1:0]      shifter_res;

wire                  special_divisor;
wire                  special_divisor_nxt;
wire [4:0]            qds_para_neg1;
wire [2:0]            qds_para_neg0;
wire [1:0]            qds_para_pos1;
wire [4:0]            qds_para_pos2;
wire [4:0]            qds_para_neg1_nxt;
wire [2:0]            qds_para_neg0_nxt;
wire [1:0]            qds_para_pos1_nxt;
wire [4:0]            qds_para_pos2_nxt;

wire                  qds_para_en;

wire                  r_shift;
wire [`XLEN+3:0]      rem_init_value;
wire [`XLEN+3:0]      rem_sum_init_value;
wire [`XLEN+3:0]      rem_carry_init_value;

wire [`LZC_WIDTH-1:0] pre_rem_trunc_14;
wire [`LZC_WIDTH-1:0] pre_m_pos_1;
wire [`LZC_WIDTH-1:0] pre_m_pos_2;

wire [1:0]            pre_cmp_res;
wire [`LZC_WIDTH-1:0] prev_quot_digit;
wire [`LZC_WIDTH-1:0] prev_quot_digit_init_value;

wire                  prev_quot_digit_en;
wire [`LZC_WIDTH-1:0] prev_quot_digit_nxt;
wire [`XLEN-1:0]      iter_cycle_quot_nxt;
wire [`XLEN-1:0]      iter_cycle_quot_minus_1_nxt;

wire                  iter_quot_en;
wire [`XLEN-1:0]      iter_quot;
wire [`XLEN-1:0]      iter_quot_minus_1;
wire [`XLEN-1:0]      iter_quot_nxt;
wire [`XLEN-1:0]      iter_quot_minus_1_nxt;

wire [`LZC_WIDTH-2:0] iter_num;
wire                  iter_num_en;
wire [`LZC_WIDTH-2:0] iter_num_nxt;
wire                  final_iter;

wire [`XLEN+3:0]      rem_sum;
wire [`XLEN+3:0]      rem_carry;
wire                  rem_en;
wire [`XLEN+3:0]      rem_sum_nxt;
wire [`XLEN+3:0]      rem_carry_nxt;

wire [`LZC_WIDTH-1:0] quot_digit_iter_end;
wire [`XLEN+3:0]      rem_sum_iter_end;
wire [`XLEN+3:0]      rem_carry_iter_end;

wire [`XLEN+3:0]      csa_3_2_x1;
wire [`XLEN+3:0]      csa_3_2_x2;
wire [`XLEN+3:0]      csa_3_2_x3;
wire                  csa_3_2_carry_unused;

wire [`XLEN+3:0]      nrdnt_rem_nxt_x0;
wire [`XLEN+3:0]      nrdnt_rem_nxt_x1;
wire [`XLEN+3:0]      nrdnt_rem_plsu_d_nxt_x0;
wire [`XLEN+3:0]      nrdnt_rem_plsu_d_nxt_x1;
wire [`XLEN+3:0]      nrdnt_rem_plsu_d_nxt_x2;
wire [`XLEN+3:0]      nrdnt_rem_plsu_d_nxt_x3;
wire [`XLEN+3:0]      nrdnt_rem_nxt;
wire [`XLEN+3:0]      nrdnt_rem_plus_d_nxt;

wire [`XLEN:0]        nrdnt_rem;
wire [`XLEN:0]        nrdnt_rem_plus_d;
wire                  nrdnt_rem_is_zero;
wire                  need_corr;
wire [`XLEN:0]        pre_shifted_rem;
wire [`XLEN-1:0]      final_rem;
wire [`XLEN-1:0]      final_quot;
// ================================================================================================================================================
// STATE Ctrl Logic
// ================================================================================================================================================
always @(*) begin
  case(div_state_r)
    STATE_IDLE:div_state_nxt = div_i_sh   ? STATE_PRE0 : STATE_IDLE;
    STATE_PRE0:div_state_nxt = STATE_PRE1;
    STATE_PRE1:div_state_nxt = skip_iter  ? STATE_POS0 : STATE_ITER;
    STATE_ITER:div_state_nxt = final_iter ? STATE_POS0 : STATE_ITER;
    STATE_POS0:div_state_nxt = STATE_POS1;
    STATE_POS1:div_state_nxt = div_o_sh   ? STATE_IDLE : STATE_POS1;
    default:div_state_nxt = STATE_IDLE;
  endcase
end
lieat_general_dffrd #(
  .DW(6),
  .DEFAULT(STATE_IDLE)
) div_state(clock,reset,div_state_nxt,div_state_r);
// ================================================================================================================================================
// SPECIAL CASE
// ================================================================================================================================================
assign lzc_diff     = {1'b0, divisor_lzc[0 +: `LZC_WIDTH]}     - {1'b0, dividend_lzc[0 +: `LZC_WIDTH]};
assign lzc_diff_nxt = {1'b0, divisor_lzc_nxt[0 +: `LZC_WIDTH]} - {1'b0, dividend_lzc_nxt[0 +: `LZC_WIDTH]};

assign divisor_is_zero = divisor_lzc[`LZC_WIDTH];//valid from PRE1
assign divisor_is_one  = (divisor_lzc_nxt[`LZC_WIDTH-1:0] == 5'b11111);//valid when POS0

assign dividend_too_big_en  = div_state_r[STATE_PRE0_BIT];
assign dividend_too_small_en = div_state_r[STATE_PRE0_BIT];
assign dividend_too_big_nxt = divisor_is_one & dividend_abs[`XLEN-1];
assign dividend_too_small_nxt = lzc_diff_nxt[`LZC_WIDTH] | dividend_lzc_nxt[`LZC_WIDTH];
lieat_general_dfflr #(1) dividend_too_big_dff(clock,reset,dividend_too_big_en,dividend_too_big_nxt,dividend_too_big);
lieat_general_dfflr #(1) dividend_too_small_dff(clock,reset,dividend_too_small_en,dividend_too_small_nxt,dividend_too_small);

assign skip_iter = dividend_too_small | divisor_is_zero | dividend_too_big;//no iter
// ================================================================================================================================================
// OUTPUT SIGN
// ================================================================================================================================================
assign rem_neg_ena  = div_i_sh;
assign quot_neg_ena = div_i_sh | (div_state_r[STATE_PRE1_BIT] & divisor_is_zero);
assign rem_neg_nxt  = dividend_neg;
assign quot_neg_nxt = div_state_r[STATE_IDLE_BIT] ? (dividend_neg ^ divisor_neg) : 1'b0;
lieat_general_dfflr #(1) quot_neg_dff(clock,reset,quot_neg_ena,quot_neg_nxt,quot_neg);
lieat_general_dfflr #(1) rem_neg_dff(clock,reset,rem_neg_ena,rem_neg_nxt,rem_neg);
// ================================================================================================================================================
// ABS
// ================================================================================================================================================
assign dividend_neg = div_i_signed & div_i_dividend[`XLEN-1];
assign divisor_neg  = div_i_signed & div_i_divisor[`XLEN-1];
assign inv1 = -(div_state_r[STATE_IDLE_BIT] ? div_i_dividend : iter_quot);          //dividend or iter_quot
assign inv2 = -(div_state_r[STATE_IDLE_BIT] ? div_i_divisor  : iter_quot_minus_1);  //divisor  or iter_quot_minus_1

assign dividend_abs_pre = dividend_neg ? inv1 : div_i_dividend;
assign divisor_abs_pre  = divisor_neg  ? inv2 : div_i_divisor;
assign normalized_dividend = dividend_abs[`XLEN-1:0] << dividend_lzc_nxt[`LZC_WIDTH-1:0];//reg state:PRE0
assign normalized_divisor  = divisor_abs[`XLEN-1:0]  << divisor_lzc_nxt[`LZC_WIDTH-1:0];//reg state:PRE0

assign abs_ena          = div_i_sh | div_state_r[STATE_PRE0_BIT] | div_state_r[STATE_POS0_BIT];
assign divisor_abs_nxt  = 
({(`XLEN+1){div_state_r[STATE_IDLE_BIT]}} & {1'b0,divisor_abs_pre    }) |
({(`XLEN+1){div_state_r[STATE_PRE0_BIT]}} & {1'b0,normalized_divisor }) |
({(`XLEN+1){div_state_r[STATE_POS0_BIT]}} & nrdnt_rem_plus_d_nxt[3 +: `XLEN+1]);
assign dividend_abs_nxt = 
({(`XLEN+1){div_state_r[STATE_IDLE_BIT]}} & {1'b0,dividend_abs_pre   }) |
({(`XLEN+1){div_state_r[STATE_PRE0_BIT]}} & {1'b0,normalized_dividend}) |
({(`XLEN+1){div_state_r[STATE_POS0_BIT]}} & nrdnt_rem_nxt[3 +: `XLEN+1]);
lieat_general_dfflr #(`XLEN+1) dividend_abs_dff(clock,reset,abs_ena,dividend_abs_nxt,dividend_abs);
lieat_general_dfflr #(`XLEN+1) divisor_abs_dff(clock,reset,abs_ena,divisor_abs_nxt,divisor_abs);
// ================================================================================================================================================
// LZC and Normalize
// ================================================================================================================================================
lieat_general_lzc lzc_dividend (
	.in_i(dividend_abs[`XLEN-1:0]),
	.cnt_o(dividend_lzc_nxt[`LZC_WIDTH-1:0]),
	.empty_o(dividend_lzc_nxt[`LZC_WIDTH])
);

lieat_general_lzc lzc_divisor (
	.in_i(divisor_abs[`XLEN-1:0]),
	.cnt_o(divisor_lzc_nxt[`LZC_WIDTH-1:0]),
	.empty_o(divisor_lzc_nxt[`LZC_WIDTH])
);
assign lzc_ena = div_state_r[STATE_PRE0_BIT];
lieat_general_dfflr #(`LZC_WIDTH+1) dividend_lzc_dff(clock,reset,lzc_ena,dividend_lzc_nxt,dividend_lzc);
lieat_general_dfflr #(`LZC_WIDTH+1) divisor_lzc_dff(clock,reset,lzc_ena,divisor_lzc_nxt,divisor_lzc);
// ================================================================================================================================================
// SHIFTER
// ================================================================================================================================================
assign shifter_num = div_state_r[STATE_PRE1_BIT] ? dividend_lzc[`LZC_WIDTH-1:0] : ((dividend_too_small | divisor_is_zero) ? {(`LZC_WIDTH){1'b0}} : divisor_lzc[`LZC_WIDTH-1:0]);
assign shifter_din = div_state_r[STATE_PRE1_BIT] ? dividend_abs[`XLEN-1:0] : pre_shifted_rem[`XLEN-1:0];
assign shifter_extend_msb = div_state_r[STATE_POS1_BIT] & rem_neg & pre_shifted_rem[`XLEN];

assign shifter_res_s0 = shifter_num[0] ? {{(1 ){shifter_extend_msb}},shifter_din[`XLEN-1:1]} : shifter_din;
assign shifter_res_s1 = shifter_num[1] ? {{(2 ){shifter_extend_msb}},shifter_res_s0[`XLEN-1:2]} : shifter_res_s0;
assign shifter_res_s2 = shifter_num[2] ? {{(4 ){shifter_extend_msb}},shifter_res_s1[`XLEN-1:4]} : shifter_res_s1;
assign shifter_res_s3 = shifter_num[3] ? {{(8 ){shifter_extend_msb}},shifter_res_s2[`XLEN-1:8]} : shifter_res_s2;
assign shifter_res    = shifter_num[4] ? {{(16){shifter_extend_msb}},shifter_res_s3[`XLEN-1:16]} : shifter_res_s3;
// ================================================================================================================================================
// Choose the parameters for CMP, according to the value of the normalized_d[(WIDTH - 2) -: 3]
// ================================================================================================================================================
assign qds_para_neg1_nxt = 
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b000}} & 5'b0_1101)|  // 000: m[-1] = -13, -m[-1] = +13 = 00_1101 -> ext(-m[-1]) = 00_11010
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b001}} & 5'b0_1111)|  // 001: m[-1] = -15, -m[-1] = +15 = 00_1111 -> ext(-m[-1]) = 00_11110
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b010}} & 5'b1_0000)|  // 010: m[-1] = -16, -m[-1] = +16 = 01_0000 -> ext(-m[-1]) = 01_00000
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b011}} & 5'b1_0010)|  // 011: m[-1] = -17, -m[-1] = +17 = 01_0001 -> ext(-m[-1]) = 01_00010
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b100}} & 5'b1_0011)|  // 100: m[-1] = -19, -m[-1] = +19 = 01_0011 -> ext(-m[-1]) = 01_00110
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b101}} & 5'b1_0100)|  // 101: m[-1] = -20, -m[-1] = +20 = 01_0100 -> ext(-m[-1]) = 01_01000
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b110}} & 5'b1_0110)|  // 110: m[-1] = -22, -m[-1] = +22 = 01_0110 -> ext(-m[-1]) = 01_01100
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b111}} & 5'b1_1000);  // 111: m[-1] = -24, -m[-1] = +24 = 01_1000 -> ext(-m[-1]) = 01_10000
assign qds_para_neg0_nxt = 
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b000}} & 3'b010)|  // 000: m[-0] = -4, -m[-0] = +4 = 000_0100
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b001}} & 3'b011)|  // 001: m[-0] = -6, -m[-0] = +6 = 000_0110
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b010}} & 3'b011)|  // 010: m[-0] = -6, -m[-0] = +6 = 000_0110
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b011}} & 3'b011)|  // 011: m[-0] = -6, -m[-0] = +6 = 000_0110
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b100}} & 3'b011)|  // 100: m[-0] = -6, -m[-0] = +6 = 000_0110
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b101}} & 3'b100)|  // 101: m[-0] = -8, -m[-0] = +8 = 000_1000
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b110}} & 3'b100)|  // 110: m[-0] = -8, -m[-0] = +8 = 000_1000
({(3){divisor_abs[(`XLEN-2) -: 3] == 3'b111}} & 3'b100);  // 111: m[-0] = -8, -m[-0] = +8 = 000_1000
assign qds_para_pos1_nxt = 
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b000}} & 2'b10)|  // 000: m[+1] = +4, -m[+1] = -4 = 111_1100
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b001}} & 2'b10)|  // 001: m[+1] = +4, -m[+1] = -4 = 111_1100
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b010}} & 2'b10)|  // 010: m[+1] = +4, -m[+1] = -4 = 111_1100
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b011}} & 2'b10)|  // 011: m[+1] = +4, -m[+1] = -4 = 111_1100
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b100}} & 2'b01)|  // 100: m[+1] = +6, -m[+1] = -6 = 111_1010
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b101}} & 2'b01)|  // 101: m[+1] = +6, -m[+1] = -6 = 111_1010
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b110}} & 2'b01)|  // 110: m[+1] = +6, -m[+1] = -6 = 111_1010
({(2){divisor_abs[(`XLEN-2) -: 3] == 3'b111}} & 2'b00);  // 111: m[+1] = +8, -m[+1] = -8 = 111_1000
assign qds_para_pos2_nxt = 
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b000}} & 5'b1_0100)|  // 000: m[+2] = +12, -m[+2] = -12 = 11_0100 -> ext(-m[+2]) = 11_01000
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b001}} & 5'b1_0010)|  // 001: m[+2] = +14, -m[+2] = -14 = 11_0010 -> ext(-m[+2]) = 11_00100
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b010}} & 5'b1_0001)|  // 010: m[+2] = +15, -m[+2] = -15 = 11_0001 -> ext(-m[+2]) = 11_00010
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b011}} & 5'b1_0000)|  // 011: m[+2] = +16, -m[+2] = -16 = 11_0000 -> ext(-m[+2]) = 11_00000
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b100}} & 5'b0_1110)|  // 100: m[+2] = +18, -m[+2] = -18 = 10_1110 -> ext(-m[+2]) = 10_11100
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b101}} & 5'b0_1100)|  // 101: m[+2] = +20, -m[+2] = -20 = 10_1100 -> ext(-m[+2]) = 10_11000
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b110}} & 5'b0_1010)|  // 110: m[+2] = +22, -m[+2] = -22 = 10_1010 -> ext(-m[+2]) = 10_10100
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b111}} & 5'b0_1010);  // 111: m[+2] = +22, -m[+2] = -22 = 10_1010 -> ext(-m[+2]) = 10_10100
assign special_divisor_nxt = (divisor_abs[(`XLEN-2) -: 3] == 3'b000) | (divisor_abs[(`XLEN-2) -: 3] == 3'b100);
assign qds_para_en = div_state_r[STATE_PRE1_BIT];
lieat_general_dfflr #(5) qds_para_neg1_dff(clock,reset,qds_para_en,qds_para_neg1_nxt,qds_para_neg1);
lieat_general_dfflr #(3) qds_para_neg0_dff(clock,reset,qds_para_en,qds_para_neg0_nxt,qds_para_neg0);
lieat_general_dfflr #(2) qds_para_pos1_dff(clock,reset,qds_para_en,qds_para_pos1_nxt,qds_para_pos1);
lieat_general_dfflr #(5) qds_para_pos2_dff(clock,reset,qds_para_en,qds_para_pos2_nxt,qds_para_pos2);
lieat_general_dfflr #(1) special_divisor_dff(clock,reset,qds_para_en,special_divisor_nxt,special_divisor);
// ================================================================================================================================================
// Get iter_num, and some initial value for different regs.
// ================================================================================================================================================
assign r_shift = lzc_diff[0];
assign rem_init_value = {3'b0,r_shift ? {1'b0, dividend_abs[`XLEN-1:0]} : {dividend_abs[`XLEN-1:0], 1'b0}};
assign rem_sum_init_value  = (dividend_too_small | divisor_is_zero) ? {1'b0, shifter_res, 3'b0} : 
                              dividend_too_big                      ? {(`XLEN+4){1'b0}}         : rem_init_value;
assign rem_carry_init_value = {`XLEN+4{1'b0}};
assign pre_rem_trunc_14 = {1'b0,rem_init_value[`XLEN -: `LZC_WIDTH-1]};
assign pre_m_pos_1 = 
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b000}} & 5'b0_0100)|  // 000: m[+1] =  +4 = 0_0100;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b001}} & 5'b0_0100)|  // 001: m[+1] =  +4 = 0_0100;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b010}} & 5'b0_0100)|  // 010: m[+1] =  +4 = 0_0100;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b011}} & 5'b0_0100)|  // 011: m[+1] =  +4 = 0_0100;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b100}} & 5'b0_0110)|  // 100: m[+1] =  +6 = 0_0110;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b101}} & 5'b0_0110)|  // 101: m[+1] =  +6 = 0_0110;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b110}} & 5'b0_0110)|  // 110: m[+1] =  +6 = 0_0110;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b111}} & 5'b0_1000);  // 111: m[+1] =  +8 = 0_1000;
assign pre_m_pos_2 = 
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b000}} & 5'b0_1100)|  // 000: m[+2] = +12 = 0_1100;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b001}} & 5'b0_1110)|  // 001: m[+2] = +14 = 0_1110;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b010}} & 5'b0_1111)|  // 010: m[+2] = +15 = 0_1111;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b011}} & 5'b1_0000)|  // 011: m[+2] = +16 = 1_0000;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b100}} & 5'b1_0010)|  // 100: m[+2] = +18 = 1_0010;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b101}} & 5'b1_0100)|  // 101: m[+2] = +20 = 1_0100;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b110}} & 5'b1_0110)|  // 110: m[+2] = +22 = 1_0110;
({(5){divisor_abs[(`XLEN-2) -: 3] == 3'b111}} & 5'b1_0110);  // 111: m[+2] = +22 = 1_0110;
assign pre_cmp_res = {(pre_rem_trunc_14 >= pre_m_pos_1), (pre_rem_trunc_14 >= pre_m_pos_2)};
assign prev_quot_digit_init_value = pre_cmp_res[0] ? QUOT_ONEHOT_POS_2 : pre_cmp_res[1] ? QUOT_ONEHOT_POS_1 : QUOT_ONEHOT_ZERO;
assign prev_quot_digit_en = div_state_r[STATE_PRE1_BIT] | div_state_r[STATE_ITER_BIT];
assign prev_quot_digit_nxt= div_state_r[STATE_PRE1_BIT] ? prev_quot_digit_init_value : quot_digit_iter_end;
lieat_general_dfflr #(5) prev_quot_digit_dff(clock,reset,prev_quot_digit_en,prev_quot_digit_nxt,prev_quot_digit);
// ================================================================================================================================================
//  ITER
// ================================================================================================================================================
assign iter_cycle_quot_nxt = 
({(`XLEN){prev_quot_digit[QUOT_POS_2]}} & {iter_quot			  [`XLEN-3:0], 2'b10})|
({(`XLEN){prev_quot_digit[QUOT_POS_1]}} & {iter_quot			  [`XLEN-3:0], 2'b01})|
({(`XLEN){prev_quot_digit[QUOT_ZERO ]}} & {iter_quot			  [`XLEN-3:0], 2'b00})|
({(`XLEN){prev_quot_digit[QUOT_NEG_1]}} & {iter_quot_minus_1[`XLEN-3:0], 2'b11})|
({(`XLEN){prev_quot_digit[QUOT_NEG_2]}} & {iter_quot_minus_1[`XLEN-3:0], 2'b10});
assign iter_cycle_quot_minus_1_nxt = 
({(`XLEN){prev_quot_digit[QUOT_POS_2]}} & {iter_quot			  [`XLEN-3:0], 2'b01})|
({(`XLEN){prev_quot_digit[QUOT_POS_1]}} & {iter_quot			  [`XLEN-3:0], 2'b00})|
({(`XLEN){prev_quot_digit[QUOT_ZERO ]}} & {iter_quot_minus_1[`XLEN-3:0], 2'b11})|
({(`XLEN){prev_quot_digit[QUOT_NEG_1]}} & {iter_quot_minus_1[`XLEN-3:0], 2'b10})|
({(`XLEN){prev_quot_digit[QUOT_NEG_2]}} & {iter_quot_minus_1[`XLEN-3:0], 2'b01});

assign iter_quot_en = div_state_r[STATE_PRE1_BIT] | div_state_r[STATE_ITER_BIT] | div_state_r[STATE_POS0_BIT];
assign iter_quot_nxt =         
div_state_r[STATE_PRE1_BIT] ? (divisor_is_zero ? {(`XLEN){1'b1}} : dividend_too_big ? dividend_abs[`XLEN-1:0] : {(`XLEN){1'b0}}) :
div_state_r[STATE_ITER_BIT] ? iter_cycle_quot_nxt        : (quot_neg ? inv1 : iter_quot);
assign iter_quot_minus_1_nxt = 
div_state_r[STATE_PRE1_BIT] ? (divisor_is_zero ? {(`XLEN){1'b1}} : dividend_too_big ? dividend_abs[`XLEN-1:0] : {(`XLEN){1'b0}}) :
div_state_r[STATE_ITER_BIT] ? iter_cycle_quot_minus_1_nxt : (quot_neg ? inv2 : iter_quot_minus_1);
lieat_general_dfflr #(`XLEN) iter_quot_dff(clock,reset,iter_quot_en,iter_quot_nxt,iter_quot);
lieat_general_dfflr #(`XLEN) iter_quot_minus_1_dff(clock,reset,iter_quot_en,iter_quot_minus_1_nxt,iter_quot_minus_1);

assign iter_num_en = div_state_r[STATE_PRE1_BIT] | div_state_r[STATE_ITER_BIT];
assign iter_num_nxt = div_state_r[STATE_PRE1_BIT] ? (lzc_diff[`LZC_WIDTH-1:1] + {{(`LZC_WIDTH - 2){1'b0}}, lzc_diff[0]}) : (iter_num - {{(`LZC_WIDTH - 2){1'b0}}, 1'b1});
lieat_general_dfflr #(`LZC_WIDTH-1) iter_num_dff(clock,reset,iter_num_en,iter_num_nxt,iter_num);                               
assign final_iter = (iter_num == {(`LZC_WIDTH-1){1'b0}});

assign rem_en = div_state_r[STATE_PRE1_BIT] | div_state_r[STATE_ITER_BIT];
assign rem_sum_nxt   = div_state_r[STATE_PRE1_BIT] ? rem_sum_init_value   : rem_sum_iter_end;
assign rem_carry_nxt = div_state_r[STATE_PRE1_BIT] ? rem_carry_init_value : rem_carry_iter_end;
lieat_general_dfflr #(`XLEN+4) rem_sum_dff(clock,reset,rem_en,rem_sum_nxt,rem_sum);
lieat_general_dfflr #(`XLEN+4) rem_carry_dff(clock,reset,rem_en,rem_carry_nxt,rem_carry);

lieat_general_radix_4_qds #(
	.WIDTH(`XLEN)
) u_qds (
	.rem_sum_i(rem_sum),
	.rem_carry_i(rem_carry),
	.divisor_i(divisor_abs[`XLEN-1:0]),
	.qds_para_neg_1_i(qds_para_neg1),
	.qds_para_neg_0_i(qds_para_neg0),
	.qds_para_pos_1_i(qds_para_pos1),
	.qds_para_pos_2_i(qds_para_pos2),
	.special_divisor_i(special_divisor),
	.prev_quot_digit_i(prev_quot_digit),
	.quot_digit_o(quot_digit_iter_end)
);

assign csa_3_2_x1 = {rem_sum  [0 +: (`XLEN+2)], 2'b0};
assign csa_3_2_x2 = {rem_carry[0 +: (`XLEN+2)], 2'b0};
assign csa_3_2_x3 = 
  ({(`XLEN+4){prev_quot_digit[QUOT_NEG_2]}} & {divisor_abs[`XLEN-1:0], 4'b0})
| ({(`XLEN+4){prev_quot_digit[QUOT_NEG_1]}} & {1'b0, divisor_abs[`XLEN-1:0], 3'b0})
| ({(`XLEN+4){prev_quot_digit[QUOT_POS_1]}} & ~{1'b0, divisor_abs[`XLEN-1:0], 3'b0})
| ({(`XLEN+4){prev_quot_digit[QUOT_POS_2]}} & ~{divisor_abs[`XLEN-1:0], 4'b0});
lieat_general_compress32 #(
	.WIDTH(`XLEN+4)
) u_csa_3_2 (
	.x1(csa_3_2_x1),
	.x2(csa_3_2_x2),
	.x3(csa_3_2_x3),
	.sum_o(rem_sum_iter_end),
	.carry_o({rem_carry_iter_end[1 +: (`XLEN+3)], csa_3_2_carry_unused})
);
assign rem_carry_iter_end[0] = (prev_quot_digit[QUOT_POS_1] | prev_quot_digit[QUOT_POS_2]);
// ================================================================================================================================================
// Post Process
// ================================================================================================================================================
// If(rem <= 0), 
// rem = (-rem_sum) + (-rem_carry) = ~rem_sum + ~rem_carry + 2'b10;
// If(rem <= 0), 
// rem_plus_d = ~rem_sum + ~rem_carry + ~normalized_d + 2'b11;
lieat_general_compress32 #(`XLEN+4) nrdnt_rem_add1(({(`XLEN+4){rem_neg}} ^ rem_sum),({(`XLEN+4){rem_neg}} ^ rem_carry),({{(`XLEN+2){1'b0}}, rem_neg, 1'b0}),nrdnt_rem_nxt_x0,nrdnt_rem_nxt_x1);
lieat_general_compress32 #(`XLEN+4) nrdnt_rem_plsu_d_add1(({(`XLEN+4){rem_neg}} ^ rem_sum),({(`XLEN+4){rem_neg}} ^ rem_carry),({(`XLEN+4){rem_neg}} ^ {1'b0, divisor_abs[`XLEN-1:0], 3'b0}),nrdnt_rem_plsu_d_nxt_x0,nrdnt_rem_plsu_d_nxt_x1);
lieat_general_compress32 #(`XLEN+4) nrdnt_rem_plsu_d_add2(nrdnt_rem_plsu_d_nxt_x0,nrdnt_rem_plsu_d_nxt_x1,({{(`XLEN+2){1'b0}}, rem_neg, rem_neg}),nrdnt_rem_plsu_d_nxt_x2,nrdnt_rem_plsu_d_nxt_x3);
assign nrdnt_rem_nxt = nrdnt_rem_nxt_x0 + nrdnt_rem_nxt_x1;
assign nrdnt_rem_plus_d_nxt = nrdnt_rem_plsu_d_nxt_x2 + nrdnt_rem_plsu_d_nxt_x3;
// Let's assume:
// quo/quo_pre is the ABS value.
// If (rem >= 0), 
// need_corr = 0 <-> "rem_pre" belongs to [ 0, +D), quo = quo_pre - 0, rem = (rem_pre + 0) >> divisor_lzc;
// need_corr = 1 <-> "rem_pre" belongs to (-D,  0), quo = quo_pre - 1, rem = (rem_pre + D) >> divisor_lzc;
// If (rem <= 0), 
// need_corr = 0 <-> "rem_pre" belongs to (-D,  0], quo = quo_pre - 0, rem = (rem_pre - 0) >> divisor_lzc;
// need_corr = 1 <-> "rem_pre" belongs to ( 0, +D), quo = quo_pre - 1, rem = (rem_pre - D) >> divisor_lzc;
assign nrdnt_rem 			    = dividend_abs;
assign nrdnt_rem_plus_d 	= divisor_abs;
assign nrdnt_rem_is_zero 	= ~(|nrdnt_rem);
assign need_corr = (~divisor_is_zero & ~dividend_too_big) & (rem_neg ? (~nrdnt_rem[`XLEN] & ~nrdnt_rem_is_zero) : nrdnt_rem[`XLEN]);
assign pre_shifted_rem = need_corr ? nrdnt_rem_plus_d : nrdnt_rem;
assign final_rem = shifter_res;
assign final_quot = need_corr ? iter_quot_minus_1 : iter_quot;
// ================================================================================================================================================
// output signals
// ================================================================================================================================================
assign div_i_ready    = div_state_r[STATE_IDLE_BIT];
assign div_o_valid    = div_state_r[STATE_POS1_BIT];
assign div_o_quot     = final_quot;
assign div_o_rem      = final_rem;

wire unused_ok = &{nrdnt_rem_nxt[2:0],nrdnt_rem_plus_d_nxt[2:0],lzc_diff_nxt[4:0],dividend_lzc[5],lzc_diff[5]};
endmodule
