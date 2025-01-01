module lieat_csrfile(
  input                 clock,
  input                 reset,

  input  [`XLEN-1:0]    csr_pc,
  input                 csr_ena,
  input                 csr_write,
  input                 csr_read,
  input  [`CSR_IDX-1:0] csr_idx,
  input  [`XLEN-1:0]    csr_wdata,
  output [`XLEN-1:0]    csr_rdata,
  
  input                 csr_mret,
  input                 csr_ecall,
  input                 csr_time_interrupt,
  input                 csr_msip_interrupt,
  input  [`XLEN-1:0]    if_hold_pc,

  output [`XLEN-1:0]    mepc_pc,
  output [`XLEN-1:0]    mtvec_pc,
  output                csr_msie,
  output                csr_mtie,
  input                 if_hold_rsp
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire csr_ilgl = 1'b0;
wire csr_wen = csr_ena & (~csr_ilgl) & csr_write;
wire csr_ren = csr_ena & (~csr_ilgl) & csr_read;

wire [`XLEN-1:0] csr_mie;
wire [`XLEN-1:0] csr_mip;
wire [`XLEN-1:0] csr_mepc;
wire [`XLEN-1:0] csr_mtvec;
wire [`XLEN-1:0] csr_mcause;
wire [`XLEN-1:0] csr_mstatus;

wire             sel_mstatus = (csr_idx == `CSR_IDX'h300);
wire             mstatus_wen = (sel_mstatus & csr_wen) | (csr_time_interrupt & if_hold_rsp) | csr_msip_interrupt | csr_ecall | csr_mret;
wire             mstatus_ren = sel_mstatus & csr_ren;
wire [`XLEN-1:0] mstatus_wdata = ((csr_time_interrupt & if_hold_rsp) | csr_msip_interrupt | csr_ecall) ? {24'b0,csr_mstatus[3],7'b0} : csr_mret ? {28'b1000,csr_mstatus[7],3'b0} : csr_wdata;

wire             sel_mie     = (csr_idx == `CSR_IDX'h304);
wire             mie_wen     = sel_mie & csr_wen;
wire             mie_ren     = sel_mie & csr_ren;
wire [`XLEN-1:0] mie_wdata   = csr_wdata;

wire             sel_mtvec   = (csr_idx == `CSR_IDX'h305);
wire             mtvec_wen   = sel_mtvec & csr_wen;
wire             mtvec_ren   = sel_mtvec & csr_ren;
wire [`XLEN-1:0] mtvec_wdata = csr_wdata;

wire             sel_mepc    = (csr_idx == `CSR_IDX'h341);
wire             mepc_wen    = (sel_mepc & csr_wen) | (csr_time_interrupt & if_hold_rsp) | csr_msip_interrupt | csr_ecall;
wire             mepc_ren    = sel_mepc & csr_ren;
wire [`XLEN-1:0] mepc_wdata  = (csr_time_interrupt & if_hold_rsp) ? if_hold_pc : csr_msip_interrupt ? (csr_pc + 32'h4) : csr_ecall ? csr_pc : csr_wdata;

wire             sel_mcause  = (csr_idx == `CSR_IDX'h342);
wire             mcause_wen  = (sel_mcause & csr_wen) | (csr_time_interrupt & if_hold_rsp) | csr_msip_interrupt | csr_ecall;
wire             mcause_ren  = sel_mcause & csr_ren;
wire [`XLEN-1:0] mcause_wdata= (csr_time_interrupt & if_hold_rsp) ? 32'h80000007 : csr_msip_interrupt ? 32'h80000003 : csr_ecall ? 32'h00000080 : csr_wdata;

/*
wire             sel_mtval   = (csr_idx == `CSR_IDX'h343);
wire             mtval_wen   = sel_mtval & csr_wen;
wire             mtval_ren   = sel_mtval & csr_ren;
wire [`XLEN-1:0] mtval_wdata = csr_wdata;
wire [`XLEN-1:0] csr_mtval;
*/
wire             sel_mip     = (csr_idx == `CSR_IDX'h344);
wire             mip_wen     = sel_mip & csr_wen;
wire             mip_ren     = sel_mip & csr_ren;
wire [`XLEN-1:0] mip_wdata   = csr_wdata;


lieat_general_dfflrd #(`XLEN,32'b1000) mstatus_dff(clock,reset,mstatus_wen,mstatus_wdata,csr_mstatus);
lieat_general_dfflr #(`XLEN) mtvec_dff(clock,reset,mtvec_wen,mtvec_wdata,csr_mtvec);
lieat_general_dfflr #(`XLEN) mepc_dff(clock,reset,mepc_wen,mepc_wdata,csr_mepc);
lieat_general_dfflr #(`XLEN) mcause_dff(clock,reset,mcause_wen,mcause_wdata,csr_mcause);
lieat_general_dfflr #(`XLEN) mie_dff(clock,reset,mie_wen,mie_wdata,csr_mie);
lieat_general_dfflr #(`XLEN) mip_dff(clock,reset,mip_wen,mip_wdata,csr_mip);

assign csr_rdata = ({`XLEN{mstatus_ren}} & csr_mstatus) |
                   ({`XLEN{mtvec_ren  }} & csr_mtvec  ) |
                   ({`XLEN{mepc_ren   }} & csr_mepc   ) |
                   ({`XLEN{mcause_ren }} & csr_mcause ) |
                   ({`XLEN{mie_ren    }} & csr_mie    ) |
                   ({`XLEN{mip_ren    }} & csr_mip    ) ;
                   
assign csr_msie = csr_mstatus[3] & csr_mie[3];
assign csr_mtie = csr_mstatus[3] & csr_mie[7];
assign mtvec_pc = csr_mtvec;
assign mepc_pc  = csr_mepc;
endmodule
