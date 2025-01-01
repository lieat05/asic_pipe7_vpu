/* verilator lint_off DECLFILENAME */
module lieat_general_64x64_sram(
  input         clock,
  input         reset,
  input         WEn,
  input  [5:0]  A,
  input  [63:0] D,
  output [63:0] Q
);
wire [63:0] sram [63:0];
wire [63:0] sram_wen;

genvar i;
generate
  for(i = 0; i < 64; i = i + 1) begin
    assign sram_wen[i] = ((A == i) & WEn);
    lieat_general_dfflr #(64) x64_sram(clock,reset,sram_wen[i],D,sram[i]); 
  end
endgenerate
assign Q = sram[A];
endmodule

module lieat_general_128x64_sram(
  input         clock,
  input         reset,
  input         WEn,
  input  [6:0]  A,
  input  [63:0] D,
  output [63:0] Q
);
wire [63:0] sram [127:0];
wire [127:0] sram_wen;

genvar i;
generate
  for(i = 0; i < 128; i = i + 1) begin
    assign sram_wen[i] = ((A == i) & WEn);
    lieat_general_dfflr #(64) x64_sram(clock,reset,sram_wen[i],D,sram[i]); 
  end
endgenerate
assign Q = sram[A];
endmodule

module lieat_general_256x64_sram(
  input         clock,
  input         reset,
  input         WEn,
  input  [7:0]  A,
  input  [63:0] D,
  output [63:0] Q
);
wire [63:0] sram [255:0];
wire [255:0] sram_wen;

genvar i;
generate
  for(i = 0; i < 256; i = i + 1) begin
    assign sram_wen[i] = ((A == i) & WEn);
    lieat_general_dfflr #(64) x64_sram(clock,reset,sram_wen[i],D,sram[i]); 
  end
endgenerate
assign Q = sram[A];
endmodule

