module lieat_vregfile(
  input                 clock,
  input                 reset,

  input  [`REG_IDX-1:0] vreg_vs1,
  input  [`REG_IDX-1:0] vreg_vs2,
  output [`XLEN-1:0]    vreg_mask,
  output [`XLEN-1:0]    vreg_vsrc1_0,
  output [`XLEN-1:0]    vreg_vsrc1_1,
  output [`XLEN-1:0]    vreg_vsrc1_2,
  output [`XLEN-1:0]    vreg_vsrc1_3,
  output [`XLEN-1:0]    vreg_vsrc1_4,
  output [`XLEN-1:0]    vreg_vsrc1_5,
  output [`XLEN-1:0]    vreg_vsrc1_6,
  output [`XLEN-1:0]    vreg_vsrc1_7,
  output [`XLEN-1:0]    vreg_vsrc2_0,
  output [`XLEN-1:0]    vreg_vsrc2_1,
  output [`XLEN-1:0]    vreg_vsrc2_2,
  output [`XLEN-1:0]    vreg_vsrc2_3,
  output [`XLEN-1:0]    vreg_vsrc2_4,
  output [`XLEN-1:0]    vreg_vsrc2_5,
  output [`XLEN-1:0]    vreg_vsrc2_6,
  output [`XLEN-1:0]    vreg_vsrc2_7,
  
  input                 vreg_wvalid,
  input  [`REG_IDX-1:0] vreg_rd0,
  input  [3:0]          vreg_wmask0,
  input  [3:0]          vreg_wmask1,
  input  [3:0]          vreg_wmask2,
  input  [3:0]          vreg_wmask3,
  input  [3:0]          vreg_wmask4,
  input  [3:0]          vreg_wmask5,
  input  [3:0]          vreg_wmask6,
  input  [3:0]          vreg_wmask7,
  input  [`XLEN-1:0]    vreg_wdata0,
  input  [`XLEN-1:0]    vreg_wdata1,
  input  [`XLEN-1:0]    vreg_wdata2,
  input  [`XLEN-1:0]    vreg_wdata3,
  input  [`XLEN-1:0]    vreg_wdata4,
  input  [`XLEN-1:0]    vreg_wdata5,
  input  [`XLEN-1:0]    vreg_wdata6,
  input  [`XLEN-1:0]    vreg_wdata7
);
wire [`XLEN-1:0]      vregs [`RGIDX_NUM-1:0];
wire [`XLEN-1:0]      vreg_wdata [`RGIDX_NUM-1:0];
wire [3:0]            vreg_wmask[`RGIDX_NUM-1:0];
wire [`RGIDX_NUM-1:0] vreg_wen;

genvar i;
generate
  for(i = 0; i < `RGIDX_NUM; i = i + 1) begin
    assign vreg_wen[i] = vreg_wvalid & (
                        ( vreg_rd0       == i) | 
                        ((vreg_rd0+5'h1) == i) | 
                        ((vreg_rd0+5'h2) == i) | 
                        ((vreg_rd0+5'h3) == i) | 
                        ((vreg_rd0+5'h4) == i) | 
                        ((vreg_rd0+5'h5) == i) | 
                        ((vreg_rd0+5'h6) == i) | 
                        ((vreg_rd0+5'h7) == i));
    assign vreg_wmask[i] = ({4{(vreg_rd0      == i)}} & vreg_wmask0)|
                           ({4{(vreg_rd0+5'h1 == i)}} & vreg_wmask1)|
                           ({4{(vreg_rd0+5'h2 == i)}} & vreg_wmask2)|
                           ({4{(vreg_rd0+5'h3 == i)}} & vreg_wmask3)|
                           ({4{(vreg_rd0+5'h4 == i)}} & vreg_wmask4)|
                           ({4{(vreg_rd0+5'h5 == i)}} & vreg_wmask5)|
                           ({4{(vreg_rd0+5'h6 == i)}} & vreg_wmask6)|
                           ({4{(vreg_rd0+5'h7 == i)}} & vreg_wmask7);
    assign vreg_wdata[i] = ({32{(vreg_rd0      == i)}} & vreg_wdata0)|
                           ({32{(vreg_rd0+5'h1 == i)}} & vreg_wdata1)|
                           ({32{(vreg_rd0+5'h2 == i)}} & vreg_wdata2)|
                           ({32{(vreg_rd0+5'h3 == i)}} & vreg_wdata3)|
                           ({32{(vreg_rd0+5'h4 == i)}} & vreg_wdata4)|
                           ({32{(vreg_rd0+5'h5 == i)}} & vreg_wdata5)|
                           ({32{(vreg_rd0+5'h6 == i)}} & vreg_wdata6)|
                           ({32{(vreg_rd0+5'h7 == i)}} & vreg_wdata7);
    lieat_general_dfflrm #(`XLEN) vregfile (clock,reset,vreg_wen[i],vreg_wmask[i],vreg_wdata[i],vregs[i]); 
  end
endgenerate
assign vreg_mask    = vregs[0];
assign vreg_vsrc1_0 = vregs[vreg_vs1];
assign vreg_vsrc1_1 = vregs[vreg_vs1+5'h1];
assign vreg_vsrc1_2 = vregs[vreg_vs1+5'h2];
assign vreg_vsrc1_3 = vregs[vreg_vs1+5'h3];
assign vreg_vsrc1_4 = vregs[vreg_vs1+5'h4];
assign vreg_vsrc1_5 = vregs[vreg_vs1+5'h5];
assign vreg_vsrc1_6 = vregs[vreg_vs1+5'h6];
assign vreg_vsrc1_7 = vregs[vreg_vs1+5'h7];
assign vreg_vsrc2_0 = vregs[vreg_vs2];
assign vreg_vsrc2_1 = vregs[vreg_vs2+5'h1];
assign vreg_vsrc2_2 = vregs[vreg_vs2+5'h2];
assign vreg_vsrc2_3 = vregs[vreg_vs2+5'h3];
assign vreg_vsrc2_4 = vregs[vreg_vs2+5'h4];
assign vreg_vsrc2_5 = vregs[vreg_vs2+5'h5];
assign vreg_vsrc2_6 = vregs[vreg_vs2+5'h6];
assign vreg_vsrc2_7 = vregs[vreg_vs2+5'h7];
endmodule
