/* verilator lint_off DECLFILENAME */
module lieat_general_dfflrs # (//l:使用loaden使能 r:允许reset异步复位 s:默认输出全1
    parameter DW = 32
)(
  input                     clock,
  input                     reset,
  input                     loaden,
  input         [DW-1:0]    din,
  output reg    [DW-1:0]    qout
);
reg          reset_sync1;
reg          reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    reset_sync1 <= 1'b1;
    reset_sync2 <= 1'b1;
  end else begin
    reset_sync1 <= 1'b0;
    reset_sync2 <= reset_sync1;
  end
end

always @(posedge clock) begin
  if(reset_sync2) begin
    qout <= {DW{1'b1}};
  end 
  else if(loaden) begin
    qout <= din;  
  end
end
endmodule

module lieat_general_dfflr # (//l:使用loaden使能 r:允许reset异步复位 s:默认输出全1
    parameter DW = 32
)(
  input                     clock,
  input                     reset,
  input                     loaden,
  input         [DW-1:0]    din,
  output reg    [DW-1:0]    qout
);

reg          reset_sync1;
reg          reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    reset_sync1 <= 1'b1;
    reset_sync2 <= 1'b1;
  end else begin
    reset_sync1 <= 1'b0;
    reset_sync2 <= reset_sync1;
  end
end

always @(posedge clock) begin
  if(reset_sync2) begin
    qout <= {DW{1'b0}};
  end 
  else if(loaden) begin
    qout <= din;  
  end
end
endmodule

module lieat_general_dfflrd # (//l:使用loaden使能 r:允许reset异步复位 d:自定义默认输出
    parameter DW = 32,
    parameter DEFAULT = 32'h80000000
)(
  input                     clock,
  input                     reset,
  input                     loaden,
  input         [DW-1:0]    din,
  output reg    [DW-1:0]    qout
);

reg          reset_sync1;
reg          reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    reset_sync1 <= 1'b1;
    reset_sync2 <= 1'b1;
  end else begin
    reset_sync1 <= 1'b0;
    reset_sync2 <= reset_sync1;
  end
end

always @(posedge clock) begin
  if(reset_sync2) begin
    qout <= DEFAULT;
  end 
  else if(loaden) begin
    qout <= din;  
  end
end
endmodule

module lieat_general_dffrd # (//l:使用loaden使能 r:允许reset异步复位 d:自定义默认输出
    parameter DW = 32,
    parameter DEFAULT = 32'h80000000
)(
  input                     clock,
  input                     reset,
  input         [DW-1:0]    din,
  output reg    [DW-1:0]    qout
);

reg          reset_sync1;
reg          reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    reset_sync1 <= 1'b1;
    reset_sync2 <= 1'b1;
  end else begin
    reset_sync1 <= 1'b0;
    reset_sync2 <= reset_sync1;
  end
end

always @(posedge clock) begin
  if(reset_sync2) begin
    qout <= DEFAULT;
  end 
  else begin
    qout <= din;  
  end
end
endmodule

module lieat_general_dffr # (//l:使用loaden使能 r:允许reset异步复位 s:默认输出全1
    parameter DW = 32
)(
  input                     clock,
  input                     reset,
  input         [DW-1:0]    din,
  output reg    [DW-1:0]    qout
);

reg          reset_sync1;
reg          reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    reset_sync1 <= 1'b1;
    reset_sync2 <= 1'b1;
  end else begin
    reset_sync1 <= 1'b0;
    reset_sync2 <= reset_sync1;
  end
end

always @(posedge clock) begin
  if(reset_sync2) begin
    qout <= {DW{1'b0}};
  end 
  else begin
    qout <= din;  
  end
end
endmodule

module lieat_general_dfflrm # (//l:使用loaden使能 r:允许reset异步复位 s:默认输出全1
    parameter DW = 32
)(
  input                     clock,
  input                     reset,
  input                     loaden,
  input         [3:0]       mask,
  input         [DW-1:0]    din,
  output reg    [DW-1:0]    qout
);

reg          reset_sync1;
reg          reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    reset_sync1 <= 1'b1;
    reset_sync2 <= 1'b1;
  end else begin
    reset_sync1 <= 1'b0;
    reset_sync2 <= reset_sync1;
  end
end

always @(posedge clock) begin
  if(reset_sync2) begin
    qout <= {DW{1'b0}};
  end 
  else if(loaden) begin
    if(mask[3]) qout[31:24] <= din[31:24];
    if(mask[2]) qout[23:16] <= din[23:16];
    if(mask[1]) qout[15: 8] <= din[15: 8];
    if(mask[0]) qout[ 7: 0] <= din[ 7: 0];
  end
end
endmodule
