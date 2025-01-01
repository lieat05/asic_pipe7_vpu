module lieat_exu_com_csr(
  input                 clock,
  input                 reset,
  
  input                 csr_valid,
  input  [`XLEN-1:0]    csr_pc,
  input  [`XLEN-1:0]    csr_src1,
  input  [`XLEN-1:0]    csr_infobus,
  output [`XLEN-1:0]    csr_o_data,

  output                csr_req_flush,
  output [`XLEN-1:0]    csr_req_flush_pc,

  input                 time_interrupt,
  input                 msip_interrupt,
  output                if_hold_req,//time interrupt
  input  [`XLEN-1:0]    if_hold_pc,
  input                 if_hold_rsp
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire [`XLEN-1:0]    csr_op1;
wire [`XLEN-1:0]    csr_op2;
wire [4:0]          csr_imm;
wire [`XLEN-1:0]    csr_res;
wire                csr_mret;
wire                csr_ecall;
wire                csr_csrrw;
wire                csr_csrrs;
wire                csr_csrrc;
wire                csr_rs1imm;
wire [`CSR_IDX-1:0] csr_csridx;

wire                csr_reg_ena;
wire                csr_reg_write;
wire                csr_reg_read;
wire [`CSR_IDX-1:0] csr_reg_idx;
wire [`XLEN-1:0]    csr_reg_wdata;
wire [`XLEN-1:0]    csr_reg_rdata;

wire                csr_msie;
wire                csr_mtie;
wire [`XLEN-1:0]    mepc_pc;
wire [`XLEN-1:0]    mtvec_pc;
wire                mtip_valid;
wire                msip_valid;
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
assign csr_req_flush    = csr_mret | csr_ecall | (mtip_valid & if_hold_rsp) | msip_valid;
assign csr_req_flush_pc = csr_mret ? mepc_pc : mtvec_pc;

assign csr_op1          = csr_rs1imm ? {27'b0,csr_imm} : csr_src1;
assign csr_op2          = csr_reg_rdata;
assign csr_imm          = csr_infobus[`INFOBUS_CSR_ZIMMM ];
assign csr_res          = ({`XLEN{csr_csrrw}} & (csr_op1)) | ({`XLEN{csr_csrrs}} & (csr_op1 | csr_op2 )) | ({`XLEN{csr_csrrc}} & (~csr_op1 & csr_op2)) ;
assign csr_mret         = csr_valid & csr_infobus[`INFOBUS_CSR_MRET  ];
assign csr_ecall        = csr_valid & csr_infobus[`INFOBUS_CSR_ECAL  ];
assign csr_csrrw        = csr_infobus[`INFOBUS_CSR_CSRRW ];
assign csr_csrrs        = csr_infobus[`INFOBUS_CSR_CSRRS ];
assign csr_csrrc        = csr_infobus[`INFOBUS_CSR_CSRRC ];
assign csr_rs1imm       = csr_infobus[`INFOBUS_CSR_RS1IMM];
assign csr_csridx       = csr_infobus[`INFOBUS_CSR_CSRIDX];

assign csr_reg_ena      = csr_valid;
assign csr_reg_write    = (csr_csrrw | csr_csrrc | csr_csrrs);
assign csr_reg_read     = csr_valid;
assign csr_reg_idx      = csr_csridx;
assign csr_reg_wdata    = csr_res;

assign mtip_valid       = time_interrupt & csr_mtie;
assign msip_valid       = msip_interrupt & csr_msie; 

assign if_hold_req      = mtip_valid;
assign csr_o_data       = csr_reg_rdata;

lieat_csrfile csrreg(
  .clock(clock),
  .reset(reset),
  .csr_pc(csr_pc),
  .csr_ena(csr_reg_ena),
  .csr_write(csr_reg_write),
  .csr_read(csr_reg_read),
  .csr_idx(csr_reg_idx),
  .csr_wdata(csr_reg_wdata),
  .csr_rdata(csr_reg_rdata),
  
  .csr_mret(csr_mret),
  .csr_ecall(csr_ecall),
  .csr_time_interrupt(mtip_valid),
  .csr_msip_interrupt(msip_valid),
  .if_hold_pc(if_hold_pc),
  .if_hold_rsp(if_hold_rsp),
  .csr_msie(csr_msie),
  .csr_mtie(csr_mtie),
  .mtvec_pc(mtvec_pc),
  .mepc_pc(mepc_pc)
);
wire unused_ok = &{csr_infobus};
endmodule
