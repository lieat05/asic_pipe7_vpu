module lieat_general_lzc(
  input  logic [31:0] in_i,
  output logic [4:0]  cnt_o,
  output logic        empty_o
);
wire [31:0] lzc_is_which;
wire [4:0] lzc_0_7;
wire [4:0] lzc_8_15;
wire [4:0] lzc_16_23;
wire [4:0] lzc_24_31;
genvar i;
generate 
  assign lzc_is_which[0]  = in_i[31];
  assign lzc_is_which[1]  = ~in_i[31];
  for (i = 2; i < 32; i = i + 1) begin
    assign lzc_is_which[i] = (in_i[31:32-i] == 0);
  end
endgenerate
  assign lzc_0_7 = lzc_is_which[7] ? 5'b00111 : lzc_is_which[6] ? 5'b00110 : lzc_is_which[5] ? 5'b00101 : lzc_is_which[4] ? 5'b00100 :
lzc_is_which[3] ? 5'b00011 : lzc_is_which[2] ? 5'b00010 : lzc_is_which[1] ? 5'b00001 : lzc_is_which[0] ? 5'b00000 : 5'b00000;
  assign lzc_8_15 = lzc_is_which[15] ? 5'b01111 : lzc_is_which[14] ? 5'b01110 : lzc_is_which[13] ? 5'b01101 : lzc_is_which[12] ? 5'b01100 :
lzc_is_which[11] ? 5'b01011 : lzc_is_which[10] ? 5'b01010 : lzc_is_which[9 ] ? 5'b01001 : lzc_is_which[8 ] ? 5'b01000 : 5'b00000;
  assign lzc_16_23 = lzc_is_which[23] ? 5'b10111 : lzc_is_which[22] ? 5'b10110 : lzc_is_which[21] ? 5'b10101 : lzc_is_which[20] ? 5'b10100 :
lzc_is_which[19] ? 5'b10011 : lzc_is_which[18] ? 5'b10010 : lzc_is_which[17] ? 5'b10001 : lzc_is_which[16] ? 5'b10000 : 5'b00000;
  assign lzc_24_31 = lzc_is_which[31] ? 5'b11111 : lzc_is_which[30] ? 5'b11110 : lzc_is_which[29] ? 5'b11101 : lzc_is_which[28] ? 5'b11100 :
lzc_is_which[27] ? 5'b11011 : lzc_is_which[26] ? 5'b11010 : lzc_is_which[25] ? 5'b11001 : lzc_is_which[24] ? 5'b11000 : 5'b00000;
  assign cnt_o = lzc_is_which[24] ? lzc_24_31 :
                 lzc_is_which[16] ? lzc_16_23 :
                 lzc_is_which[8 ] ? lzc_8_15  : lzc_0_7;
  assign empty_o = (in_i == 32'h0);
endmodule
