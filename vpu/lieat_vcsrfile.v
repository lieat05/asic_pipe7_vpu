module lieat_vcsrfile(
  input                 clock,
  input                 reset,

  input                 csr_vl_wen,
  input  [      4:0]    csr_vl_wdata,
  output [      4:0]    csr_vl_rdata,

  input                 csr_vtype_wen,
  input  [`XLEN-1:0]    csr_vtype_wdata,
  output [`XLEN-1:0]    csr_vtype_rdata
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire [      4:0] csr_vl;
wire [`XLEN-1:0] csr_vtype;

lieat_general_dfflr #(5)     vl_dff(clock,reset,csr_vl_wen,csr_vl_wdata,csr_vl);
lieat_general_dfflr #(`XLEN) vtype_dff(clock,reset,csr_vtype_wen,csr_vtype_wdata,csr_vtype);

assign csr_vtype_rdata = csr_vtype;
assign csr_vl_rdata    = csr_vl;
endmodule
