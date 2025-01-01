module lieat_idu_dec(
  input  [`XLEN-1:0]    inst,
  input                 prdt_taken,
  
  output                id_rv32,
  output                id_rs1en,
  output                id_rs2en,
  output                id_rdwen,
  output [`REG_IDX-1:0] id_rs1,
  output [`REG_IDX-1:0] id_rs2,
  output [`REG_IDX-1:0] id_rd,
  output [`XLEN-1:0]    id_imm,
  output [`XLEN-1:0]    id_infobus,
  output                id_ilgl,
  output [4:0]          disp_op
);
wire alu_op;
wire bjp_op;
wire lsu_op;
wire csr_op;
wire mul_op;
wire fpu_op;
wire vset_op;
wire vlsu_op;
wire vint_op;

wire [31:0] rv32_inst = inst;
wire [6:0] rv32_func7 = rv32_inst[31:25];
wire [4:0] rv32_rs2 = rv32_inst[24:20];
wire [4:0] rv32_rs1 = rv32_inst[19:15];
wire [2:0] rv32_func3 = rv32_inst[14:12];
wire [4:0] rv32_rd  = rv32_inst[11:7];
wire [6:0] opcode   = rv32_inst[6:0];
// ================================================================================================================================================
// OPCODE
// ================================================================================================================================================
wire rv32_func7_0000000 = (rv32_func7 == 7'b0000000);
wire rv32_func7_0000001 = (rv32_func7 == 7'b0000001);
wire rv32_func7_0100000 = (rv32_func7 == 7'b0100000);
wire rv32_func7_0100001 = (rv32_func7 == 7'b0100001);

wire rv32_rs2_00000 = ~rv32_rs2[4] & ~rv32_rs2[3] & ~rv32_rs2[2] & ~rv32_rs2[1] & ~rv32_rs2[0];
wire rv32_rs2_01000 = ~rv32_rs2[4] &  rv32_rs2[3] & ~rv32_rs2[2] & ~rv32_rs2[1] & ~rv32_rs2[0];
wire rv32_rs2_01011 = ~rv32_rs2[4] &  rv32_rs2[3] & ~rv32_rs2[2] &  rv32_rs2[1] &  rv32_rs2[0];
wire rv32_rs2_10000 =  rv32_rs2[4] & ~rv32_rs2[3] & ~rv32_rs2[2] & ~rv32_rs2[1] & ~rv32_rs2[0];
wire rv32_rs1_00000 = ~rv32_rs1[4] & ~rv32_rs1[3] & ~rv32_rs1[2] & ~rv32_rs1[1] & ~rv32_rs1[0];
wire rv32_rd_00000  = ~rv32_rd[4]  & ~rv32_rd[3]  & ~rv32_rd[2]  & ~rv32_rd[1]  & ~rv32_rd[0];

wire rv32_func3_000     = (rv32_func3 == 3'b000);
wire rv32_func3_001     = (rv32_func3 == 3'b001);
wire rv32_func3_010     = (rv32_func3 == 3'b010);
wire rv32_func3_011     = (rv32_func3 == 3'b011);
wire rv32_func3_100     = (rv32_func3 == 3'b100);
wire rv32_func3_101     = (rv32_func3 == 3'b101);
wire rv32_func3_110     = (rv32_func3 == 3'b110);
wire rv32_func3_111     = (rv32_func3 == 3'b111);

wire opcode_1_0_11      = opcode[1] & opcode[0];
wire opcode_4_2_000     = (opcode[4:2] == 3'b000);
wire opcode_4_2_001     = (opcode[4:2] == 3'b001);
//wire opcode_4_2_010     = (opcode[4:2] == 3'b010);
wire opcode_4_2_011     = (opcode[4:2] == 3'b011);
wire opcode_4_2_100     = (opcode[4:2] == 3'b100);
wire opcode_4_2_101     = (opcode[4:2] == 3'b101);
//wire opcode_4_2_110     = (opcode[4:2] == 3'b110);
wire opcode_4_2_111     = (opcode[4:2] == 3'b111);
wire opcode_6_5_00      = (opcode[6:5] == 2'b00);
wire opcode_6_5_01      = (opcode[6:5] == 2'b01);
wire opcode_6_5_10      = (opcode[6:5] == 2'b10);
wire opcode_6_5_11      = (opcode[6:5] == 2'b11);
// ================================================================================================================================================
// INST TYPE
// ================================================================================================================================================
wire rv32_load      = opcode_6_5_00 & opcode_4_2_000 & opcode_1_0_11;
wire rv32_store     = opcode_6_5_01 & opcode_4_2_000 & opcode_1_0_11;
//wire rv32_madd    = opcode_6_5_10 & opcode_4_2_000 & opcode_1_0_11; 
wire rv32_branch    = opcode_6_5_11 & opcode_4_2_000 & opcode_1_0_11; 
wire rv32_vload     = opcode_6_5_00 & opcode_4_2_001 & opcode_1_0_11;
wire rv32_vstore    = opcode_6_5_01 & opcode_4_2_001 & opcode_1_0_11; 
//wire rv32_msub    = opcode_6_5_10 & opcode_4_2_001 & opcode_1_0_11; 
wire rv32_jalr      = opcode_6_5_11 & opcode_4_2_001 & opcode_1_0_11; 
//wire rv32_custom0 = opcode_6_5_00 & opcode_4_2_010 & opcode_1_0_11; 
//wire rv32_custom1 = opcode_6_5_01 & opcode_4_2_010 & opcode_1_0_11; 
//wire rv32_nmsub   = opcode_6_5_10 & opcode_4_2_010 & opcode_1_0_11; 
//wire rv32_resrvd0 = opcode_6_5_11 & opcode_4_2_010 & opcode_1_0_11; 
wire rv32_miscmem   = opcode_6_5_00 & opcode_4_2_011 & opcode_1_0_11;
//wire rv32_amo     = opcode_6_5_01 & opcode_4_2_011 & opcode_1_0_11; 
//wire rv32_nmadd   = opcode_6_5_10 & opcode_4_2_011 & opcode_1_0_11; 
wire rv32_jal       = opcode_6_5_11 & opcode_4_2_011 & opcode_1_0_11; 
wire rv32_op_imm    = opcode_6_5_00 & opcode_4_2_100 & opcode_1_0_11; 
wire rv32_op        = opcode_6_5_01 & opcode_4_2_100 & opcode_1_0_11; 
//wire rv32_op_fp   = opcode_6_5_10 & opcode_4_2_100 & opcode_1_0_11; 
wire rv32_system    = opcode_6_5_11 & opcode_4_2_100 & opcode_1_0_11; 
wire rv32_auipc     = opcode_6_5_00 & opcode_4_2_101 & opcode_1_0_11; 
wire rv32_lui       = opcode_6_5_01 & opcode_4_2_101 & opcode_1_0_11; 
wire rv32_opv       = opcode_6_5_10 & opcode_4_2_101 & opcode_1_0_11; //1010111
//wire rv32_resved2 = opcode_6_5_11 & opcode_4_2_101 & opcode_1_0_11; 
//wire rv32_opimm_32= opcode_6_5_00 & opcode_4_2_110 & opcode_1_0_11; 
//wire rv32_op_32   = opcode_6_5_01 & opcode_4_2_110 & opcode_1_0_11; 
//wire rv32_custom2 = opcode_6_5_10 & opcode_4_2_110 & opcode_1_0_11; 
//wire rv32_custom3 = opcode_6_5_11 & opcode_4_2_110 & opcode_1_0_11; 
// ================================================================================================================================================
// RV32I
// ================================================================================================================================================
//wire rv32_lb      = rv32_load   & rv32_func3_000;
//wire rv32_lh      = rv32_load   & rv32_func3_001;
//wire rv32_lw      = rv32_load   & rv32_func3_010;
//wire rv32_lbu     = rv32_load   & rv32_func3_100;
//wire rv32_lhu     = rv32_load   & rv32_func3_101;
//wire rv32_sb      = rv32_store  & rv32_func3_000;
//wire rv32_sh      = rv32_store  & rv32_func3_001;
//wire rv32_sw      = rv32_store  & rv32_func3_010;
wire rv32_beq       = rv32_branch & rv32_func3_000;
wire rv32_bne       = rv32_branch & rv32_func3_001;
wire rv32_blt       = rv32_branch & rv32_func3_100;
wire rv32_bgt       = rv32_branch & rv32_func3_101;
wire rv32_bltu      = rv32_branch & rv32_func3_110;
wire rv32_bgtu      = rv32_branch & rv32_func3_111;
wire rv32_fence     = rv32_miscmem & rv32_func3_000;
wire rv32_fencei    = rv32_miscmem & rv32_func3_001;
wire rv32_addi      = rv32_op_imm & rv32_func3_000;
wire rv32_slti      = rv32_op_imm & rv32_func3_010;
wire rv32_sltiu     = rv32_op_imm & rv32_func3_011;
wire rv32_xori      = rv32_op_imm & rv32_func3_100;
wire rv32_ori       = rv32_op_imm & rv32_func3_110;
wire rv32_andi      = rv32_op_imm & rv32_func3_111;
wire rv32_slli      = rv32_op_imm & rv32_func3_001 & (rv32_func7_0000000 | rv32_func7_0000001);
wire rv32_srli      = rv32_op_imm & rv32_func3_101 & (rv32_func7_0000000 | rv32_func7_0000001);
wire rv32_srai      = rv32_op_imm & rv32_func3_101 & (rv32_func7_0100000 | rv32_func7_0100001);
wire rv32_add       = rv32_op & rv32_func3_000 & rv32_func7_0000000;
wire rv32_sub       = rv32_op & rv32_func3_000 & rv32_func7_0100000;
wire rv32_sll       = rv32_op & rv32_func3_001 & rv32_func7_0000000;
wire rv32_slt       = rv32_op & rv32_func3_010 & rv32_func7_0000000;
wire rv32_sltu      = rv32_op & rv32_func3_011 & rv32_func7_0000000;
wire rv32_xor       = rv32_op & rv32_func3_100 & rv32_func7_0000000;
wire rv32_srl       = rv32_op & rv32_func3_101 & rv32_func7_0000000;
wire rv32_sra       = rv32_op & rv32_func3_101 & rv32_func7_0100000;
wire rv32_or        = rv32_op & rv32_func3_110 & rv32_func7_0000000;
wire rv32_and       = rv32_op & rv32_func3_111 & rv32_func7_0000000;
wire rv32_ecall     = rv32_system & rv32_func3_000 & (rv32_inst[31:20] == 12'b000000000000);
wire rv32_ebreak    = rv32_system & rv32_func3_000 & (rv32_inst[31:20] == 12'b000000000001);
wire rv32_mret      = rv32_system & rv32_func3_000 & (rv32_inst[31:20] == 12'b001100000010);
wire rv32_wfi       = rv32_system & rv32_func3_000 & (rv32_inst[31:20] == 12'b0001_0000_0101);
wire rv32_csrrw     = rv32_system & rv32_func3_001; 
wire rv32_csrrs     = rv32_system & rv32_func3_010; 
wire rv32_csrrc     = rv32_system & rv32_func3_011; 
wire rv32_csrrwi    = rv32_system & rv32_func3_101; 
wire rv32_csrrsi    = rv32_system & rv32_func3_110; 
wire rv32_csrrci    = rv32_system & rv32_func3_111; 
// ================================================================================================================================================
// RISC-V M EXT
// ================================================================================================================================================
wire rv32_mul       = rv32_op & rv32_func3_000 & rv32_func7_0000001;
wire rv32_mulh      = rv32_op & rv32_func3_001 & rv32_func7_0000001;
wire rv32_mulhsu    = rv32_op & rv32_func3_010 & rv32_func7_0000001;
wire rv32_mulhu     = rv32_op & rv32_func3_011 & rv32_func7_0000001;
wire rv32_div       = rv32_op & rv32_func3_100 & rv32_func7_0000001;
wire rv32_divu      = rv32_op & rv32_func3_101 & rv32_func7_0000001;
wire rv32_rem       = rv32_op & rv32_func3_110 & rv32_func7_0000001;
wire rv32_remu      = rv32_op & rv32_func3_111 & rv32_func7_0000001;
// ================================================================================================================================================
// RISC-V V EXT
// ================================================================================================================================================
wire [5:0] rv32_func6 = rv32_inst[31:26];
wire [2:0] rv32_nf    = rv32_inst[31:29];
wire       rv32_mew   = rv32_inst[28];
wire [1:0] rv32_mop   = rv32_inst[27:26];
wire       rv32_vm    = rv32_inst[25];

wire rv32_nf_000    = ~rv32_nf[2] & ~rv32_nf[1] & ~rv32_nf[0];
wire rv32_mop_00    = ~rv32_mop[1] & ~rv32_mop[0];
wire rv32_mop_01    = ~rv32_mop[1] &  rv32_mop[0];
wire rv32_mop_10    =  rv32_mop[1] & ~rv32_mop[0];
wire rv32_mop_11    =  rv32_mop[1] &  rv32_mop[0];

wire rv32_vsetvli   = rv32_opv    & rv32_func3_111 & ~inst[31];
wire rv32_vsetivli  = rv32_opv    & rv32_func3_111 & inst[31] & inst[30];
wire rv32_vsetvl    = rv32_opv    & rv32_func3_111 & inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[25];

wire rv32_vle       = rv32_vload                   & rv32_rs2_00000            & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vse       = rv32_vstore                  & rv32_rs2_00000            & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vlm       = rv32_vload  & rv32_func3_000 & rv32_rs2_01011 &  rv32_vm & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vsm       = rv32_vstore & rv32_func3_000 & rv32_rs2_01011 &  rv32_vm & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vlse      = rv32_vload                                               & rv32_mop_10 & ~rv32_mew &  rv32_nf_000;
wire rv32_vsse      = rv32_vstore                                              & rv32_mop_10 & ~rv32_mew &  rv32_nf_000;
wire rv32_vloxei    = rv32_vload                                               & rv32_mop_11 & ~rv32_mew &  rv32_nf_000;
wire rv32_vsoxei    = rv32_vstore                                              & rv32_mop_11 & ~rv32_mew &  rv32_nf_000;
wire rv32_vluxei    = rv32_vload                                               & rv32_mop_01 & ~rv32_mew &  rv32_nf_000;
wire rv32_vsuxei    = rv32_vstore                                              & rv32_mop_01 & ~rv32_mew &  rv32_nf_000;
wire rv32_vleff     = rv32_vload                   & rv32_rs2_10000            & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vlseg     = rv32_vload                   & rv32_rs2_00000            & rv32_mop_00 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vsseg     = rv32_vstore                  & rv32_rs2_00000            & rv32_mop_00 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vlsseg    = rv32_vload                                               & rv32_mop_10 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vssseg    = rv32_vstore                                              & rv32_mop_10 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vloxsegei = rv32_vload                                               & rv32_mop_11 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vsoxsegei = rv32_vstore                                              & rv32_mop_11 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vluxsegei = rv32_vload                                               & rv32_mop_01 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vsuxsegei = rv32_vstore                                              & rv32_mop_01 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vlsegeff  = rv32_vload                   & rv32_rs2_10000            & rv32_mop_00 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vl1re     = rv32_vload                   & rv32_rs2_01000 &  rv32_vm & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vlxre     = rv32_vload                   & rv32_rs2_01000 &  rv32_vm & rv32_mop_00 & ~rv32_mew & ~rv32_nf_000;
wire rv32_vs1r      = rv32_vstore                  & rv32_rs2_01000 &  rv32_vm & rv32_mop_00 & ~rv32_mew &  rv32_nf_000;
wire rv32_vsxr      = rv32_vstore                  & rv32_rs2_01000 &  rv32_vm & rv32_mop_00 & ~rv32_mew & ~rv32_nf_000;

wire rv32_shift_ilgl = (rv32_slli | rv32_srli | rv32_srai) & (rv32_inst[25]);//should be 0
wire rv32_all01_ilgl = (inst == 32'h0) | (inst == 32'hffffffff);
wire op_ilgl         = ~(alu_op | bjp_op | lsu_op | csr_op | mul_op | vset_op);

wire rv32_need_rs1 = (~rv32_rs1_00000) & (~rv32_lui) & (~rv32_auipc) & (~rv32_jal) & (~rv32_fence) & (~rv32_fencei) & (~rv32_ecall) & (~rv32_ebreak) & (~rv32_csrrwi) & (~rv32_csrrsi) & (~rv32_csrrci) & (~rv32_vsetivli);
wire rv32_need_rs2 = (~rv32_rs2_00000) & (rv32_branch | rv32_store | rv32_op | rv32_vsetvl);
wire rv32_need_rd  = (~rv32_rd_00000) & (~rv32_branch) & (~rv32_mret) & (~rv32_store) & (~rv32_fence) & (~rv32_fencei) & (~rv32_ecall) & (~rv32_ebreak);

wire rv32_i = rv32_op_imm | rv32_jalr | rv32_load;
wire rv32_u = rv32_lui | rv32_auipc;
wire rv32_s = rv32_store;
wire rv32_b = rv32_branch;
wire rv32_j = rv32_jal;
wire rv32_need_imm = rv32_i | rv32_u | rv32_s | rv32_b | rv32_j;
wire need_imm      = id_rv32 ? rv32_need_imm : 1'b0;

wire [31:0] rv32_immi = {{20{rv32_inst[31]}},rv32_inst[31:20]};
wire [31:0] rv32_immu = {rv32_inst[31:12],12'b0};
wire [31:0] rv32_imms = {{20{rv32_inst[31]}},rv32_inst[31:25],rv32_inst[11:7]};
wire [31:0] rv32_immb = {{20{rv32_inst[31]}},rv32_inst[7],rv32_inst[30:25],rv32_inst[11:8],1'b0};
wire [31:0] rv32_immj = {{12{rv32_inst[31]}},rv32_inst[19:12],rv32_inst[20],rv32_inst[30:21],1'b0};
wire [31:0] rv32_imm  = 
({`XLEN{rv32_i}} & rv32_immi) |
({`XLEN{rv32_u}} & rv32_immu) |
({`XLEN{rv32_s}} & rv32_imms) |
({`XLEN{rv32_b}} & rv32_immb) |
({`XLEN{rv32_j}} & rv32_immj) ;
// ================================================================================================================================================
// INFOBUS
// ================================================================================================================================================
wire [`INFOBUS_ALU_WIDTH-1:0] alu_infobus;
assign alu_op = (~rv32_shift_ilgl) & ( rv32_op_imm | rv32_op & (~rv32_func7_0000001) | rv32_auipc | rv32_lui | rv32_wfi | rv32_ebreak);
assign alu_infobus[`INFOBUS_ALU_VALID ] = alu_op;
assign alu_infobus[`INFOBUS_BJP_VALID ] = ~alu_op;
assign alu_infobus[`INFOBUS_CSR_VALID ] = ~alu_op; 
assign alu_infobus[`INFOBUS_ALU_ADD   ] = rv32_add | rv32_addi | rv32_auipc;
assign alu_infobus[`INFOBUS_ALU_SUB   ] = rv32_sub;
assign alu_infobus[`INFOBUS_ALU_SLT   ] = rv32_slt | rv32_slti;
assign alu_infobus[`INFOBUS_ALU_SLTU  ] = rv32_sltu | rv32_sltiu;
assign alu_infobus[`INFOBUS_ALU_XOR   ] = rv32_xor | rv32_xori;
assign alu_infobus[`INFOBUS_ALU_SLL   ] = rv32_sll | rv32_slli;
assign alu_infobus[`INFOBUS_ALU_SRL   ] = rv32_srl | rv32_srli;
assign alu_infobus[`INFOBUS_ALU_SRA   ] = rv32_sra | rv32_srai;
assign alu_infobus[`INFOBUS_ALU_OR    ] = rv32_or  | rv32_ori;
assign alu_infobus[`INFOBUS_ALU_AND   ] = rv32_and | rv32_andi;
assign alu_infobus[`INFOBUS_ALU_LUI   ] = rv32_lui;
assign alu_infobus[`INFOBUS_ALU_IMM   ] = need_imm;
assign alu_infobus[`INFOBUS_ALU_PC    ] = rv32_auipc;
assign alu_infobus[`INFOBUS_ALU_EBRK  ] = rv32_ebreak;

wire [`INFOBUS_BJP_WIDTH-1:0] bjp_infobus;
assign bjp_op = rv32_jal | rv32_jalr | rv32_branch;
assign bjp_infobus[`INFOBUS_ALU_VALID ] = ~bjp_op;
assign bjp_infobus[`INFOBUS_BJP_VALID ] = bjp_op;
assign bjp_infobus[`INFOBUS_CSR_VALID ] = ~bjp_op; 
assign bjp_infobus[`INFOBUS_BJP_JUMP  ] = rv32_jal | rv32_jalr;
assign bjp_infobus[`INFOBUS_BJP_BPRDT ] = prdt_taken;
assign bjp_infobus[`INFOBUS_BJP_BEQ   ] = rv32_beq;
assign bjp_infobus[`INFOBUS_BJP_BNE   ] = rv32_bne;
assign bjp_infobus[`INFOBUS_BJP_BLT   ] = rv32_blt; 
assign bjp_infobus[`INFOBUS_BJP_BGT   ] = rv32_bgt ;
assign bjp_infobus[`INFOBUS_BJP_BLTU  ] = rv32_bltu;
assign bjp_infobus[`INFOBUS_BJP_BGTU  ] = rv32_bgtu;
assign bjp_infobus[`INFOBUS_BJP_BXX   ] = rv32_branch;

wire [`INFOBUS_CSR_WIDTH-1:0] csr_infobus;
assign csr_op = (rv32_system & (~rv32_func3_000)) | rv32_ecall | rv32_mret;
assign csr_infobus[`INFOBUS_ALU_VALID ] = ~csr_op;
assign csr_infobus[`INFOBUS_BJP_VALID ] = ~csr_op;
assign csr_infobus[`INFOBUS_CSR_VALID ] = csr_op;
assign csr_infobus[`INFOBUS_CSR_CSRRW ] = rv32_csrrw | rv32_csrrwi;
assign csr_infobus[`INFOBUS_CSR_CSRRS ] = rv32_csrrs | rv32_csrrsi;
assign csr_infobus[`INFOBUS_CSR_CSRRC ] = rv32_csrrc | rv32_csrrci;
assign csr_infobus[`INFOBUS_CSR_RS1IMM] = rv32_csrrwi | rv32_csrrsi | rv32_csrrci;
assign csr_infobus[`INFOBUS_CSR_ECAL  ] = rv32_ecall;
assign csr_infobus[`INFOBUS_CSR_ZIMMM ] = rv32_rs1;
assign csr_infobus[`INFOBUS_CSR_RS1IS0] = rv32_rs1_00000;
assign csr_infobus[`INFOBUS_CSR_CSRIDX] = rv32_inst[31:20];
assign csr_infobus[`INFOBUS_CSR_MRET  ] = rv32_mret;

wire [`INFOBUS_LSU_WIDTH-1:0] lsu_infobus;
assign lsu_op = rv32_load | rv32_store | rv32_fence | rv32_fencei;
assign lsu_infobus[`INFOBUS_LSU_LOAD  ] = rv32_load;
assign lsu_infobus[`INFOBUS_LSU_STORE ] = rv32_store;
assign lsu_infobus[`INFOBUS_LSU_SIZE  ] = id_rv32 ? rv32_func3[1:0] : 2'b10;
assign lsu_infobus[`INFOBUS_LSU_USIGN ] = id_rv32 ? rv32_func3[2]   : 1'b0;
//assign lsu_infobus[`INFOBUS_LSU_FENCE ] = rv32_fence;
assign lsu_infobus[`INFOBUS_LSU_FENCEI] = rv32_fencei;

wire [`INFOBUS_MUL_WIDTH-1:0] mul_infobus;
assign mul_op = rv32_op & rv32_func7_0000001;
assign mul_infobus[`INFOBUS_MUL_MUL   ] = rv32_mul    ;   
assign mul_infobus[`INFOBUS_MUL_MULH  ] = rv32_mulh   ;
assign mul_infobus[`INFOBUS_MUL_MULHSU] = rv32_mulhsu ;
assign mul_infobus[`INFOBUS_MUL_MULHU ] = rv32_mulhu  ;
assign mul_infobus[`INFOBUS_MUL_DIV   ] = rv32_div    ;
assign mul_infobus[`INFOBUS_MUL_DIVU  ] = rv32_divu   ;
assign mul_infobus[`INFOBUS_MUL_REM   ] = rv32_rem    ;
assign mul_infobus[`INFOBUS_MUL_REMU  ] = rv32_remu   ;

wire [`INFOBUS_VSET_WIDTH-1:0] vset_infobus;
assign vset_op = rv32_opv & rv32_func3_111;
assign vset_infobus[`INFOBUS_VSET_VALID   ] = vset_op;
assign vset_infobus[`INFOBUS_VLSU_VALID   ] = ~vset_op;
assign vset_infobus[`INFOBUS_VINT_VALID   ] = ~vset_op;
assign vset_infobus[`INFOBUS_VSET_VSETIVLI] = rv32_vsetivli;
assign vset_infobus[`INFOBUS_VSET_VSETVL  ] = rv32_vsetvl;
assign vset_infobus[`INFOBUS_VSET_VTYPEIMM] = rv32_vsetvli ? inst[30:20] : {1'b0,inst[29:20]};
assign vset_infobus[`INFOBUS_VSET_AVLUIMM ] = inst[19:15];

wire [`INFOBUS_VLSU_WIDTH-1:0] vlsu_infobus;
assign vlsu_op = (rv32_vload | rv32_vstore) & ~rv32_mew;
assign vlsu_infobus[`INFOBUS_VSET_VALID   ] = ~vlsu_op;
assign vlsu_infobus[`INFOBUS_VLSU_VALID   ] = vlsu_op;
assign vlsu_infobus[`INFOBUS_VINT_VALID   ] = ~vlsu_op;
assign vlsu_infobus[`INFOBUS_VLSU_LOAD    ] = rv32_vload;
assign vlsu_infobus[`INFOBUS_VLSU_STORE   ] = rv32_vstore;
assign vlsu_infobus[`INFOBUS_VLSU_UNITSTRD] = rv32_vle | rv32_vse | rv32_vlseg | rv32_vsseg;
assign vlsu_infobus[`INFOBUS_VLSU_CONSSTRD] = rv32_vlse | rv32_vsse | rv32_vlsseg | rv32_vssseg;
assign vlsu_infobus[`INFOBUS_VLSU_UNORIDX ] = rv32_vluxei | rv32_vsuxei | rv32_vluxsegei | rv32_vsuxsegei;
assign vlsu_infobus[`INFOBUS_VLSU_ORDERIDX] = rv32_vloxei | rv32_vsoxei | rv32_vloxsegei | rv32_vsoxsegei;
assign vlsu_infobus[`INFOBUS_VLSU_MSKUNIT ] = rv32_vlm | rv32_vsm;
assign vlsu_infobus[`INFOBUS_VLSU_FOFLOAD ] = rv32_vleff | rv32_vlsegeff;
assign vlsu_infobus[`INFOBUS_VLSU_WHOLEREG] = rv32_vl1re | rv32_vlxre | rv32_vs1r |rv32_vsxr;
assign vlsu_infobus[`INFOBUS_VLSU_VM      ] = rv32_vm;
assign vlsu_infobus[`INFOBUS_VLSU_NOSEG   ] = rv32_nf_000;
assign vlsu_infobus[`INFOBUS_VLSU_NF      ] = rv32_nf;
assign vlsu_infobus[`INFOBUS_VLSU_SIZE    ] = {~rv32_mew & rv32_func3_110,~rv32_mew & rv32_func3_101,~rv32_mew & rv32_func3_000};//32 16 8

wire [`INFOBUS_VINT_WIDTH-1:0] vint_infobus;
assign vint_op = rv32_opv & ~rv32_func3_111;
assign vint_infobus[`INFOBUS_VSET_VALID   ] = ~vint_op;
assign vint_infobus[`INFOBUS_VLSU_VALID   ] = ~vint_op;
assign vint_infobus[`INFOBUS_VINT_VALID   ] = vint_op;
assign vint_infobus[`INFOBUS_VINT_MASK    ] = rv32_vm;
assign vint_infobus[`INFOBUS_VINT_OPI     ] = rv32_func3_000 | rv32_func3_011 | rv32_func3_100;
assign vint_infobus[`INFOBUS_VINT_OPM     ] = rv32_func3_010 | rv32_func3_110;
assign vint_infobus[`INFOBUS_VINT_OPIVV   ] = rv32_func3_000;
assign vint_infobus[`INFOBUS_VINT_OPMVV   ] = rv32_func3_010;
assign vint_infobus[`INFOBUS_VINT_OPIVI   ] = rv32_func3_011;
assign vint_infobus[`INFOBUS_VINT_OPIVX   ] = rv32_func3_100;
assign vint_infobus[`INFOBUS_VINT_OPMVX   ] = rv32_func3_110;
assign vint_infobus[`INFOBUS_VINT_FUNC6_00] = ~rv32_func6[5] & ~rv32_func6[4];
assign vint_infobus[`INFOBUS_VINT_FUNC6_01] = ~rv32_func6[5] &  rv32_func6[4];
assign vint_infobus[`INFOBUS_VINT_FUNC6_10] =  rv32_func6[5] & ~rv32_func6[4];
assign vint_infobus[`INFOBUS_VINT_FUNC6_11] =  rv32_func6[5] &  rv32_func6[4];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0000] = ~rv32_func6[3] & ~rv32_func6[2] & ~rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0001] = ~rv32_func6[3] & ~rv32_func6[2] & ~rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0010] = ~rv32_func6[3] & ~rv32_func6[2] &  rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0011] = ~rv32_func6[3] & ~rv32_func6[2] &  rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0100] = ~rv32_func6[3] &  rv32_func6[2] & ~rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0101] = ~rv32_func6[3] &  rv32_func6[2] & ~rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0110] = ~rv32_func6[3] &  rv32_func6[2] &  rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_0111] = ~rv32_func6[3] &  rv32_func6[2] &  rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1000] =  rv32_func6[3] & ~rv32_func6[2] & ~rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1001] =  rv32_func6[3] & ~rv32_func6[2] & ~rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1010] =  rv32_func6[3] & ~rv32_func6[2] &  rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1011] =  rv32_func6[3] & ~rv32_func6[2] &  rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1100] =  rv32_func6[3] &  rv32_func6[2] & ~rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1101] =  rv32_func6[3] &  rv32_func6[2] & ~rv32_func6[1] &  rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1110] =  rv32_func6[3] &  rv32_func6[2] &  rv32_func6[1] & ~rv32_func6[0];
assign vint_infobus[`INFOBUS_VINT_FUNC6_1111] =  rv32_func6[3] &  rv32_func6[2] &  rv32_func6[1] &  rv32_func6[0];

wire [`INFOBUS_FPU_WIDTH-1:0] fpu_infobus;
assign fpu_op = 1'b0;
assign fpu_infobus = 32'b0; 
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign id_rs1     = id_rv32 ? rv32_rs1      : 0;
assign id_rs2     = id_rv32 ? rv32_rs2      : 0;
assign id_rd      = id_rv32 ? rv32_rd       : 0;
assign id_rs1en   = id_rv32 ? rv32_need_rs1 : 0;
assign id_rs2en   = id_rv32 ? rv32_need_rs2 : 0;
assign id_rdwen   = id_rv32 ? rv32_need_rd  : 0;

assign id_imm     = id_rv32 ? rv32_imm : 32'h0;
assign id_infobus =
({{(`XLEN-`INFOBUS_ALU_WIDTH){1'b0}},{`INFOBUS_ALU_WIDTH{alu_op}} & alu_infobus})|
({{(`XLEN-`INFOBUS_BJP_WIDTH){1'b0}},{`INFOBUS_BJP_WIDTH{bjp_op}} & bjp_infobus})|
({{(`XLEN-`INFOBUS_CSR_WIDTH){1'b0}},{`INFOBUS_CSR_WIDTH{csr_op}} & csr_infobus})|
({{(`XLEN-`INFOBUS_LSU_WIDTH){1'b0}},{`INFOBUS_LSU_WIDTH{lsu_op}} & lsu_infobus})|
({{(`XLEN-`INFOBUS_MUL_WIDTH){1'b0}},{`INFOBUS_MUL_WIDTH{mul_op}} & mul_infobus})|
({{(`XLEN-`INFOBUS_FPU_WIDTH){1'b0}},{`INFOBUS_FPU_WIDTH{fpu_op}} & fpu_infobus})|
({{(`XLEN-`INFOBUS_VSET_WIDTH){1'b0}},{`INFOBUS_VSET_WIDTH{vset_op}} & vset_infobus})|
({{(`XLEN-`INFOBUS_VLSU_WIDTH){1'b0}},{`INFOBUS_VLSU_WIDTH{vlsu_op}} & vlsu_infobus})|
({{(`XLEN-`INFOBUS_VINT_WIDTH){1'b0}},{`INFOBUS_VINT_WIDTH{vint_op}} & vint_infobus});
assign disp_op    = {fpu_op,(vint_op | vset_op | vlsu_op),mul_op,lsu_op,(alu_op | bjp_op | csr_op)};
assign id_ilgl    = rv32_all01_ilgl | rv32_shift_ilgl | op_ilgl;
assign id_rv32    = ~opcode_4_2_111 & opcode_1_0_11;
endmodule
