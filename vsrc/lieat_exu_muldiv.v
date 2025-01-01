module lieat_exu_muldiv(
  input                           clock,
  input                           reset,
  input                           flush_req,
  
  input                           muldiv_i_valid,
  output                          muldiv_i_ready,
  input  [`XLEN-1:0]              muldiv_i_pc,
  input  [`XLEN-1:0]              muldiv_i_src1,
  input  [`XLEN-1:0]              muldiv_i_src2,
  input  [`INFOBUS_MUL_WIDTH-1:0] muldiv_i_infobus,
  input  [`REG_IDX-1:0]           muldiv_i_rd,
  input                           muldiv_i_rdwen,

  output                          muldiv_o_valid,
  input                           muldiv_o_ready,
  output [`XLEN-1:0]              muldiv_o_pc,
  output                          muldiv_o_wen,
  output [`REG_IDX-1:0]           muldiv_o_rd,
  output [`XLEN-1:0]              muldiv_o_data,
  output                          muldiv_o_flush
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                          muldiv_rdwen;
wire [`XLEN-1:0]              muldiv_src1;
wire [`XLEN-1:0]              muldiv_src2;
wire [`XLEN-1:0]              muldiv_pc;
wire [`REG_IDX-1:0]           muldiv_rd;
wire [`INFOBUS_MUL_WIDTH-1:0] muldiv_infobus;
wire                          muldiv_flush_ena;

wire                          muldiv_i_sh;
wire                          muldiv_o_sh;
wire                          div_req_sh;
wire                          mul_req_sh;
wire                          muldiv_req_sh;

wire                          mul_req_valid;
wire                          div_req_valid;
wire                          mul_req_ready;
wire                          div_req_ready;
wire                          muldiv_req_valid;

wire                          op_mul;
wire                          op_div;
wire                          mul_low;
wire                          mul_high;
wire                          div_quot;
wire                          div_rem;
wire                          muldiv_mul;
wire                          muldiv_mulh;
wire                          muldiv_mulhsu;
wire                          muldiv_mulhu;
wire                          muldiv_div;
wire                          muldiv_divu;
wire                          muldiv_rem;
wire                          muldiv_remu;

wire                          mul_req_signed1;
wire                          mul_req_signed2;
wire [`XLEN-1:0]              mul_req_multiplicand;
wire [`XLEN-1:0]              mul_req_multiplier;
wire [`XLEN-1:0]              mul_o_resl;
wire [`XLEN-1:0]              mul_o_resh;
wire                          mul_o_valid;

wire                          div_req_signed;
wire [`XLEN-1:0]              div_req_dividend;
wire [`XLEN-1:0]              div_req_divisor;
wire [`XLEN-1:0]              div_o_quot;
wire [`XLEN-1:0]              div_o_rem;
wire                          div_o_valid;
// ================================================================================================================================================
// INPUT SIGNAL
// ================================================================================================================================================
assign muldiv_i_sh   = muldiv_i_valid & muldiv_i_ready;
assign muldiv_o_sh   = muldiv_o_valid & muldiv_o_ready;
assign div_req_sh    = div_req_valid & div_req_ready;
assign mul_req_sh    = mul_req_valid & mul_req_ready;
assign muldiv_req_sh = mul_req_sh | div_req_sh;

assign op_mul        = muldiv_mul | muldiv_mulh | muldiv_mulhsu | muldiv_mulhu;
assign op_div        = muldiv_div | muldiv_divu | muldiv_rem    | muldiv_remu;
assign mul_low       = muldiv_mul;
assign mul_high      = muldiv_mulh | muldiv_mulhsu | muldiv_mulhu;
assign div_quot      = muldiv_div | muldiv_divu;
assign div_rem       = muldiv_rem | muldiv_remu;
assign muldiv_mul    = muldiv_infobus[`INFOBUS_MUL_MUL   ];
assign muldiv_mulh   = muldiv_infobus[`INFOBUS_MUL_MULH  ];
assign muldiv_mulhsu = muldiv_infobus[`INFOBUS_MUL_MULHSU];
assign muldiv_mulhu  = muldiv_infobus[`INFOBUS_MUL_MULHU ];
assign muldiv_div    = muldiv_infobus[`INFOBUS_MUL_DIV   ];
assign muldiv_divu   = muldiv_infobus[`INFOBUS_MUL_DIVU  ];
assign muldiv_rem    = muldiv_infobus[`INFOBUS_MUL_REM   ];
assign muldiv_remu   = muldiv_infobus[`INFOBUS_MUL_REMU  ];

lieat_general_dfflr #(1)                  muldiv_rdwen_dff(clock,reset,muldiv_i_sh,muldiv_i_rdwen,muldiv_rdwen);
lieat_general_dfflr #(`XLEN)              muldiv_src1_dff(clock,reset,muldiv_i_sh,muldiv_i_src1,muldiv_src1);
lieat_general_dfflr #(`XLEN)              muldiv_src2_dff(clock,reset,muldiv_i_sh,muldiv_i_src2,muldiv_src2);
lieat_general_dfflr #(`XLEN)              muldiv_pc_dff(clock,reset,muldiv_i_sh,muldiv_i_pc,muldiv_pc);
lieat_general_dfflr #(`REG_IDX)           muldiv_rd_dff(clock,reset,muldiv_i_sh,muldiv_i_rd,muldiv_rd);
lieat_general_dfflr #(`INFOBUS_MUL_WIDTH) muldiv_infobus_dff(clock,reset,muldiv_i_sh,muldiv_i_infobus,muldiv_infobus);
// ================================================================================================================================================
// FLUSH CONTROL
// ================================================================================================================================================
lieat_general_dfflr #(1)        muldiv_flush_ena_dff(clock,reset,1'b1,muldiv_i_sh,muldiv_flush_ena);
assign muldiv_o_flush = muldiv_flush_ena & flush_req;
// ================================================================================================================================================
// STATE CONTROL
// ================================================================================================================================================
wire muldiv_req_valid_pre;
wire muldiv_req_valid_pre_set = muldiv_i_sh;
wire muldiv_req_valid_pre_clr = muldiv_req_sh | muldiv_o_flush;
wire muldiv_req_valid_pre_ena = muldiv_req_valid_pre_set | muldiv_req_valid_pre_clr;
wire muldiv_req_valid_pre_nxt = muldiv_req_valid_pre_set | ~muldiv_req_valid_pre_clr;
lieat_general_dfflr #(1) muldiv_req_valid_pre_dff(clock,reset,muldiv_req_valid_pre_ena,muldiv_req_valid_pre_nxt,muldiv_req_valid_pre);
assign muldiv_req_valid     = muldiv_req_valid_pre & ~muldiv_o_flush;
assign muldiv_i_ready       = ~muldiv_req_valid_pre | muldiv_o_sh;

assign mul_req_valid        = muldiv_req_valid & op_mul;
assign mul_req_signed1      = muldiv_mulh | muldiv_mulhsu;
assign mul_req_signed2      = muldiv_mulh;
assign mul_req_multiplicand = muldiv_src1;
assign mul_req_multiplier   = muldiv_src2;
assign div_req_valid        = muldiv_req_valid & op_div;
assign div_req_signed       = muldiv_div | muldiv_rem;
assign div_req_dividend     = muldiv_src1;
assign div_req_divisor      = muldiv_src2;

lieat_exu_mul mul(
  .clock(clock),
  .reset(reset),
  .mul_i_valid(mul_req_valid),
  .mul_i_ready(mul_req_ready),
  .mul_i_signed1(mul_req_signed1),
  .mul_i_signed2(mul_req_signed2),
  .mul_i_multiplicand(mul_req_multiplicand),
  .mul_i_multiplier(mul_req_multiplier),
  .mul_o_valid(mul_o_valid),
  .mul_o_ready(muldiv_o_ready),
  .mul_o_resh(mul_o_resh),
  .mul_o_resl(mul_o_resl)
);

lieat_exu_div div(
  .clock(clock),
  .reset(reset),
  .div_i_valid(div_req_valid),
  .div_i_ready(div_req_ready),
  .div_i_signed(div_req_signed),
  .div_i_dividend(div_req_dividend),
  .div_i_divisor(div_req_divisor),
  .div_o_valid(div_o_valid),
  .div_o_ready(muldiv_o_ready),
  .div_o_quot(div_o_quot),
  .div_o_rem(div_o_rem)
);
// ================================================================================================================================================
// OUTPUT
// ================================================================================================================================================
assign muldiv_o_pc    = muldiv_pc;
assign muldiv_o_rd    = muldiv_rd;
assign muldiv_o_wen   = muldiv_rdwen;
assign muldiv_o_data = ({`XLEN{mul_low }} & mul_o_resl) | 
                       ({`XLEN{mul_high}} & mul_o_resh) |
                       ({`XLEN{div_quot}} & div_o_quot) |
                       ({`XLEN{div_rem }} & div_o_rem) ;
assign muldiv_o_valid = mul_o_valid | div_o_valid;
endmodule
