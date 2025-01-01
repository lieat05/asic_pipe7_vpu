module lieat_ifu_dec(
  input  [`XLEN-1:0]    inst,
  output [`REG_IDX-1:0] dec_rs1,
  output                dec_rs1en,
  output [`XLEN-1:0]    dec_immb,
  output                dec_bxx,
  output                dec_jal,
  output                dec_nojump,
  output                dec_fencei
);
wire dec_jalr;
wire opcode_6_5_11  =  inst[6] &  inst[5];
wire opcode_6_5_00  = ~inst[6] & ~inst[5];
wire opcode_4_2_000 = ~inst[4] & ~inst[3] & ~inst[2];
wire opcode_4_2_001 = ~inst[4] & ~inst[3] &  inst[2];
wire opcode_4_2_011 = ~inst[4] &  inst[3] &  inst[2];
wire opcode_1_0_11  =  inst[1] &  inst[0];

wire [`XLEN-1:0] imm_jal = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
wire [`XLEN-1:0] imm_jalr= {{20{inst[31]}},inst[31:20]};
wire [`XLEN-1:0] imm_bxx = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};

assign dec_rs1 = inst[19:15];
assign dec_rs1en = dec_jalr;
assign dec_jal     = opcode_6_5_11 & opcode_4_2_011 & opcode_1_0_11;
assign dec_jalr    = opcode_6_5_11 & opcode_4_2_001 & opcode_1_0_11;
assign dec_bxx     = opcode_6_5_11 & opcode_4_2_000 & opcode_1_0_11;//beq bne blt bge bltu bgeu
assign dec_nojump  = ~(inst[6] & inst[5] & ~inst[4]);
assign dec_fencei  = opcode_6_5_00 & opcode_4_2_011 & opcode_1_0_11 & (~inst[14] & ~inst[13] & inst[12]);
assign dec_immb   = 
({`XLEN{(dec_jal )}} & imm_jal ) |
({`XLEN{(dec_jalr)}} & imm_jalr) |
({`XLEN{(dec_bxx )}} & imm_bxx ) ;
endmodule
