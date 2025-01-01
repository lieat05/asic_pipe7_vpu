module lieat_ifu_bpu # (
  parameter INDEX_NUM  = 1 << `BPU_IDX,
  parameter BHR_SIZE   = 2,
  parameter PHT_SIZE   = 4 // 自动计算PHT大小
)(
  input                clock,
  input                reset,
  
  input [`BPU_IDX-1:0] index,
  output               bxx_taken,

  input                prdt_result,
  input [`BPU_IDX-1:0] prdt_index,
  input                prdt_en
);
reg [BHR_SIZE-1:0] branch_history_table [INDEX_NUM-1:0];//BHR
reg [1:0] pattern_history_table[INDEX_NUM-1:0][PHT_SIZE-1:0];//PHT

wire [BHR_SIZE-1:0] branch_history = branch_history_table[index];
wire [1:0] prdt_result_history = branch_history_table[prdt_index];
assign bxx_taken = pattern_history_table[index][branch_history][1]; // 判断分支是否被预测为 taken

reg bpu_reset_sync1;
reg bpu_reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    bpu_reset_sync1 <= 1'b1;
    bpu_reset_sync2 <= 1'b1;
  end else begin
    bpu_reset_sync1 <= 1'b0;
    bpu_reset_sync2 <= bpu_reset_sync1;
  end
end

always@(posedge clock) begin
  integer i, j; // 正确声明变量
  if(bpu_reset_sync2) begin
    for(i = 0; i < INDEX_NUM; i = i + 1)begin
      for(j = 0; j < PHT_SIZE; j = j + 1)begin
        pattern_history_table[i][j] <= 2'b10; // 初始化为弱 taken
      end
      branch_history_table[i] <= 2'b00; // 分支历史寄存器初始化
    end
  end
  else if(prdt_en) begin
    case (pattern_history_table[prdt_index][prdt_result_history])
      2'b00: pattern_history_table[prdt_index][prdt_result_history] <= (prdt_result) ? 2'b01 : 2'b00;
      2'b01: pattern_history_table[prdt_index][prdt_result_history] <= (prdt_result) ? 2'b10 : 2'b00;
      2'b10: pattern_history_table[prdt_index][prdt_result_history] <= (prdt_result) ? 2'b11 : 2'b01;
      2'b11: pattern_history_table[prdt_index][prdt_result_history] <= (prdt_result) ? 2'b11 : 2'b10;
    endcase
    branch_history_table[prdt_index] <= {prdt_result_history[0], prdt_result}; // 更新分支历史寄存器
  end
end
endmodule
