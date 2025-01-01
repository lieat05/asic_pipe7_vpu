module lieat_exu_fpu(
  input                          clock,
  input                          reset,  
  input                          flush_req,
  
  input                          fpu_i_valid,
  output                         fpu_i_ready,
  input [`XLEN-1:0]              fpu_i_pc,
  input [`REG_IDX-1:0]           fpu_i_rd,
  input                          fpu_i_rdwen,
  input [`XLEN-1:0]              fpu_i_imm,
  input [`XLEN-1:0]              fpu_i_src1,
  input [`XLEN-1:0]              fpu_i_src2,
  input [31:0]                   fpu_i_infobus,

  output                         fpu_o_valid,
  input                          fpu_o_ready,
  output [`XLEN-1:0]             fpu_o_pc,
  output                         fpu_o_wen,
  output [`REG_IDX-1:0]          fpu_o_rd,
  output [`XLEN-1:0]             fpu_o_data,
  output                         fpu_o_flush
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire                fpu_i_sh = fpu_i_valid & fpu_i_ready;
wire                fpu_flush_ena;

wire [`XLEN-1:0]    fpu_pc;
wire [`XLEN-1:0]    fpu_imm;
wire [`XLEN-1:0]    fpu_infobus;
wire [`REG_IDX-1:0] fpu_rd;
wire [`XLEN-1:0]    fpu_src1;
wire [`XLEN-1:0]    fpu_src2;
wire                fpu_rdwen;

wire [2:0][31:0]    fpu_operands;
wire [2:0]          fpu_rnd_mode;
wire [3:0]          fpu_op;
wire                fpu_op_mod;
wire [2:0]          fpu_src_fmt;
wire [2:0]          fpu_dst_fmt;
wire [1:0]          fpu_int_fmt;
wire                fpu_vectorial_op;
wire                fpu_tag;
wire                fpu_simd_mask;
wire [31:0]         fpu_result;
wire [4:0]          fpu_status;
wire                fpu_busy;
// ================================================================================================================================================
// INPUT SIGNAL
// ================================================================================================================================================
lieat_general_dfflr #(`XLEN) fpu_pc_dff(clock,reset,fpu_i_sh,fpu_i_pc,fpu_pc);
lieat_general_dfflr #(`XLEN) fpu_imm_dff(clock,reset,fpu_i_sh,fpu_i_imm,fpu_imm);
lieat_general_dfflr #(`XLEN) fpu_infobus_dff(clock,reset,fpu_i_sh,fpu_i_infobus,fpu_infobus);
lieat_general_dfflr #(5)     fpu_rd_dff(clock,reset,fpu_i_sh,fpu_i_rd,fpu_rd);
lieat_general_dfflr #(1)     fpu_rdwen_dff(clock,reset,fpu_i_sh,fpu_i_rdwen,fpu_rdwen);
lieat_general_dfflr #(`XLEN) fpu_src1_dff(clock,reset,fpu_i_sh,fpu_i_src1,fpu_src1);
lieat_general_dfflr #(`XLEN) fpu_src2_dff(clock,reset,fpu_i_sh,fpu_i_src2,fpu_src2);

lieat_general_dfflr #(1) flush_ena_dff(clock,reset,1'b1,fpu_i_sh,fpu_flush_ena);
assign fpu_o_flush = fpu_flush_ena & flush_req;
// ================================================================================================================================================
// MAIN
// ================================================================================================================================================
wire unused_ok = &{fpu_infobus,fpu_status,fpu_busy};
assign fpu_operands     = {fpu_imm,fpu_src1,fpu_src2};
assign fpu_rnd_mode     = 3'b0;
assign fpu_op           = fpu_infobus[3:0];
assign fpu_op_mod       = fpu_infobus[4];
assign fpu_src_fmt      = fpu_infobus[7:5];
assign fpu_dst_fmt      = fpu_infobus[10:8];
assign fpu_int_fmt      = fpu_infobus[12:11];
assign fpu_vectorial_op = fpu_infobus[13];
assign fpu_tag          = fpu_infobus[14];
assign fpu_simd_mask    = fpu_infobus[15];

fpnew_top #(
  fpnew_pkg::RV32F,//features
  fpnew_pkg::DEFAULT_SNITCH,//Implementation
  logic,//TagType
  0,//TrueSIMDClass
  0//EnableSIMDMask
) lieat_fpu(
  .clk_i(clock),
  .rst_ni(~reset),
  .operands_i(fpu_operands),
  .rnd_mode_i(fpu_rnd_mode),
  .op_i(fpu_op),
  .op_mod_i(fpu_op_mod),
  .src_fmt_i(fpu_src_fmt),
  .dst_fmt_i(fpu_dst_fmt),
  .int_fmt_i(fpu_int_fmt),
  .vectorial_op_i(fpu_vectorial_op),
  .tag_i(fpu_tag),
  .simd_mask_i(fpu_simd_mask),
  .in_valid_i(fpu_i_valid),
  .in_ready_o(fpu_i_ready),
  .flush_i(fpu_o_flush),
  .result_o(fpu_result),
  .status_o(fpu_status),
  .tag_o(fpu_tag),
  .out_valid_o(fpu_o_valid),
  .out_ready_i(fpu_o_ready),
  .busy_o(fpu_busy)
);
assign fpu_o_wen = fpu_rdwen;
assign fpu_o_rd = fpu_rd;
assign fpu_o_pc = fpu_pc;
assign fpu_o_data = fpu_result;
endmodule
