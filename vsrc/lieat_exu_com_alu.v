module lieat_exu_com_alu(
  input              alu_valid,
  input  [`XLEN-1:0] alu_pc,
  input  [`XLEN-1:0] alu_imm,
  input  [`XLEN-1:0] alu_src1,
  input  [`XLEN-1:0] alu_src2,
  input  [`XLEN-1:0] alu_infobus,

  output             alu_o_ebreak,
  output [`XLEN-1:0] alu_o_data
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire unused_ok = &{alu_infobus};

wire [`XLEN-1:0]    alu_mask;
wire [`XLEN-1:0]    alu_op1;
wire [`XLEN-1:0]    alu_op2;
wire                alu_op1sel;
wire                alu_op2sel;
wire                alu_ebreak;
wire                alu_op_add;
wire                alu_op_sub;
wire                alu_op_xor;
wire                alu_op_sll;
wire                alu_op_srl;
wire                alu_op_sra;
wire                alu_op_or;
wire                alu_op_and;
wire                alu_op_slt;
wire                alu_op_sltu;
wire                alu_op_lui;
wire                alu_op_unsign;
wire                alu_op_lt;
wire                alu_slt_cmp;

wire                adder_ena;
wire                adder_add;
wire                adder_sub;
wire [`XLEN:0]      adder_op1;
wire [`XLEN:0]      adder_op2;
wire [`XLEN:0]      adder_in1;
wire [`XLEN:0]      adder_in2;

wire                shifter_ena;
wire                shifter_right;
wire [`XLEN-1:0]    shifter_op1;
wire [`REG_IDX-1:0] shifter_op2;
wire [`XLEN-1:0]    shifter_in1;
wire [4:0]          shifter_in2;

wire [`XLEN  :0]    adder_res;
wire [`XLEN-1:0]    lter_res;
wire [`XLEN-1:0]    xorer_res;
wire [`XLEN-1:0]    orer_res;
wire [`XLEN-1:0]    ander_res;
wire [`XLEN-1:0]    shifter_res;
wire [`XLEN-1:0]    sraer_res;
wire [`XLEN-1:0]    sller_res;
wire [`XLEN-1:0]    srler_res;
wire [`XLEN-1:0]    luier_res;
// ================================================================================================================================================
// INFOBUS
// ================================================================================================================================================
assign alu_op1       = alu_op1sel ? alu_pc  : alu_src1;
assign alu_op2       = alu_op2sel ? alu_imm : alu_src2;
assign alu_op1sel    = alu_infobus [`INFOBUS_ALU_PC ];
assign alu_op2sel    = alu_infobus [`INFOBUS_ALU_IMM];
assign alu_ebreak    = alu_infobus [`INFOBUS_ALU_EBRK];
assign alu_op_add    = alu_infobus [`INFOBUS_ALU_ADD ];
assign alu_op_sub    = alu_infobus [`INFOBUS_ALU_SUB ];
assign alu_op_xor    = alu_infobus [`INFOBUS_ALU_XOR ];
assign alu_op_sll    = alu_infobus [`INFOBUS_ALU_SLL ];
assign alu_op_srl    = alu_infobus [`INFOBUS_ALU_SRL ];
assign alu_op_sra    = alu_infobus [`INFOBUS_ALU_SRA ];
assign alu_op_or     = alu_infobus [`INFOBUS_ALU_OR  ];
assign alu_op_and    = alu_infobus [`INFOBUS_ALU_AND ];
assign alu_op_slt    = alu_infobus [`INFOBUS_ALU_SLT ];
assign alu_op_sltu   = alu_infobus [`INFOBUS_ALU_SLTU];
assign alu_op_lui    = alu_infobus [`INFOBUS_ALU_LUI ];
assign alu_op_lt     = alu_op_slt | alu_op_sltu;
assign alu_op_unsign = alu_op_sltu;
assign alu_slt_cmp   = alu_op_lt & adder_res[`XLEN];
// ================================================================================================================================================
// ADD SUB
// ================================================================================================================================================
assign adder_ena   = adder_add | adder_sub;
assign adder_add   = alu_op_add;
assign adder_sub   = alu_op_sub | alu_op_slt | alu_op_sltu;
assign adder_op1   = ({`XLEN+1{adder_ena}} & {(~alu_op_unsign) & alu_op1[`XLEN-1],alu_op1});
assign adder_op2   = ({`XLEN+1{adder_ena}} & {(~alu_op_unsign) & alu_op2[`XLEN-1],alu_op2});
assign adder_in1   = adder_op1;
assign adder_in2   = adder_sub ? (~adder_op2 + 1'b1) : adder_op2;
assign adder_res   = adder_in1 + adder_in2;

assign lter_res    = {31'b0,alu_slt_cmp};
assign xorer_res = alu_op1 ^ alu_op2;
assign orer_res  = alu_op1 | alu_op2;
assign ander_res = alu_op1 & alu_op2;

assign shifter_ena   = alu_op_sll | alu_op_srl | alu_op_sra;
assign shifter_right = alu_op_srl | alu_op_sra;
assign shifter_op1   = ({`XLEN   {shifter_ena}} & alu_op1);
assign shifter_op2   = ({`REG_IDX{shifter_ena}} & alu_op2[4:0]);
assign shifter_in1   = (shifter_right ? {
shifter_op1[00],shifter_op1[01],shifter_op1[02],shifter_op1[03],
shifter_op1[04],shifter_op1[05],shifter_op1[06],shifter_op1[07],
shifter_op1[08],shifter_op1[09],shifter_op1[10],shifter_op1[11],
shifter_op1[12],shifter_op1[13],shifter_op1[14],shifter_op1[15],
shifter_op1[16],shifter_op1[17],shifter_op1[18],shifter_op1[19],
shifter_op1[20],shifter_op1[21],shifter_op1[22],shifter_op1[23],
shifter_op1[24],shifter_op1[25],shifter_op1[26],shifter_op1[27],
shifter_op1[28],shifter_op1[29],shifter_op1[30],shifter_op1[31]} : shifter_op1);
assign shifter_in2   = shifter_op2;
assign shifter_res   = (shifter_in1 << shifter_in2);

assign alu_mask      = (~(`XLEN'b0)) >> shifter_in2;
assign sraer_res     = (srler_res & alu_mask) | ({32{shifter_op1[31]}} & (~alu_mask));
assign sller_res     = shifter_res;
assign srler_res     = {
shifter_res[00],shifter_res[01],shifter_res[02],shifter_res[03],
shifter_res[04],shifter_res[05],shifter_res[06],shifter_res[07],
shifter_res[08],shifter_res[09],shifter_res[10],shifter_res[11],
shifter_res[12],shifter_res[13],shifter_res[14],shifter_res[15],
shifter_res[16],shifter_res[17],shifter_res[18],shifter_res[19],
shifter_res[20],shifter_res[21],shifter_res[22],shifter_res[23],
shifter_res[24],shifter_res[25],shifter_res[26],shifter_res[27],
shifter_res[28],shifter_res[29],shifter_res[30],shifter_res[31]};
assign luier_res  = alu_op2;
// ================================================================================================================================================
// OUTPUT
// ================================================================================================================================================

assign alu_o_ebreak  = alu_valid & alu_ebreak;
assign alu_o_data = 
({`XLEN{alu_op_add}} & adder_res[`XLEN-1:0]) |
({`XLEN{alu_op_sub}} & adder_res[`XLEN-1:0]) |
({`XLEN{alu_op_xor}} & xorer_res) |
({`XLEN{alu_op_or }} & orer_res ) |
({`XLEN{alu_op_and}} & ander_res) |
({`XLEN{alu_op_srl}} & srler_res) |
({`XLEN{alu_op_sll}} & sller_res) |
({`XLEN{alu_op_sra}} & sraer_res) |
({`XLEN{alu_op_lt }} & lter_res ) |
({`XLEN{alu_op_lui}} & luier_res) ;
endmodule
