module lieat_ifu_icache # (
  parameter CACHE_WAY  = 2,//cache has 2 ways: 1KB
  parameter INDEX_LEN  = 6, //each way has 64 blocks
  parameter CACHE_SIZE = 64,
  parameter TAG_LEN  = 24,
  parameter OFFSET_LEN = 2 //each block has 8 bytes
)(
  input                 clock,
  input                 reset,

  input                 flush_req,
  input                 fencei_req,
  input                 pipeline_empty,
  input                 if_hold_req,
  output                if_hold_rsp,

  output                if_o_valid,
  input                 if_o_ready,

  input                 ifetch_req_valid,
  output                ifetch_req_ready,
  input  [`XLEN-1:0]    ifetch_req_pc,

  output                ifetch_rsp_valid,
  output [`XLEN-1:0]    ifetch_rsp_pc,
  output [`BPU_IDX-1:0] ifetch_rsp_index,
  output [`XLEN-1:0]    ifetch_rsp_inst,

  output [`XLEN-1:0]    icache_axi_araddr,
  output                icache_axi_arvalid,
  input                 icache_axi_arready,
  input  [`XLEN*2-1:0]  icache_axi_rdata,
  input                 icache_axi_rvalid,
  output                icache_axi_rready
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
localparam STATE_IDE = 6'b000001;
localparam STATE_AR  = 6'b000010;
localparam STATE_R   = 6'b000100;
localparam STATE_ARF = 6'b001000;
localparam STATE_RF  = 6'b010000;
localparam STATE_VLD = 6'b100000;

localparam STATE_IDE_BIT = 0;
localparam STATE_AR_BIT  = 1;
localparam STATE_R_BIT   = 2;
localparam STATE_ARF_BIT = 3;
localparam STATE_RF_BIT  = 4;
localparam STATE_VLD_BIT = 5;

reg [5:0]            state_r;
reg [5:0]            state_nxt;

wire                 ar_sh;
wire                 ifetch_req_sh;
wire                 if_o_sh;

wire                 ifetch_req_hit;
wire                 ifetch_req_hit0;
wire                 ifetch_req_hit1;
wire                 ifetch_req_miss;
wire                 ifetch_req_miss1;
wire [TAG_LEN-1:0]   ifetch_req_tag;
wire [INDEX_LEN-1:0] ifetch_req_index;
wire [`XLEN-1:0]     ifetch_rsp_inst_nxt;

wire                 icache_hit;
wire                 icache_hit1;
wire                 icache_miss1;
wire [TAG_LEN-1:0]   icache_tag;
wire [INDEX_LEN-1:0] icache_index;
wire [`XLEN-1:0]     icache_pc;

reg  [TAG_LEN+4:0]   icache_extend [CACHE_SIZE-1:0][CACHE_WAY-1:0];//TAG_LEN + VALID_BIT1 + LRU_BIT 4

wire                 icache_sram_reset;
wire                 icache_sram_wen;
wire [ 5:0]          icache_sram_addr;
wire [63:0]          icache_sram_data;
wire [63:0]          icache_sram_rdata;
// ================================================================================================================================================
// STATE CONTROL
// ================================================================================================================================================
assign ar_sh  = icache_axi_arvalid & icache_axi_arready;
assign ifetch_req_sh = ifetch_req_valid & ifetch_req_ready;
assign if_o_sh = if_o_valid & if_o_ready;

always @(*) begin
  case(state_r)
    STATE_IDE: state_nxt = {
    ifetch_req_sh & ifetch_req_hit,
    2'b0,
    ifetch_req_sh & ifetch_req_miss & icache_axi_arready,
    ifetch_req_sh & ifetch_req_miss & ~icache_axi_arready,
    ~ifetch_req_sh
    };
    STATE_AR : state_nxt = {
    1'b0,
    ar_sh & flush_req,
    ~icache_axi_arready & flush_req,
    ar_sh & ~flush_req,
    ~icache_axi_arready & ~flush_req,
    1'b0
    };
    STATE_R  : state_nxt = {
    (~flush_req & icache_axi_rvalid) | (ifetch_req_sh & ifetch_req_hit),
    flush_req & ~icache_axi_rvalid,
    1'b0,
    ~flush_req & ~icache_axi_rvalid,
    (flush_req & icache_axi_rvalid & ifetch_req_miss),
    1'b0
    };
    STATE_ARF: state_nxt = {
    1'b0,
    ar_sh,
    ~ar_sh,
    3'b0
    };
    STATE_RF : state_nxt = {
    (ifetch_req_sh & ifetch_req_hit),
    ~icache_axi_rvalid,
    1'b0,
    icache_axi_rvalid & ifetch_req_miss & icache_axi_arready,
    icache_axi_rvalid & ifetch_req_miss & ~icache_axi_arready,
    1'b0
    };
    STATE_VLD: state_nxt = {
    (ifetch_req_sh & ifetch_req_hit) | (~flush_req & ~if_o_sh),
    2'b0,
    ifetch_req_sh & ifetch_req_miss & icache_axi_arready,
    ifetch_req_sh & ifetch_req_miss & ~icache_axi_arready,
    if_o_sh & ~ifetch_req_sh
    };
    default:state_nxt = STATE_IDE;
  endcase
end

lieat_general_dffrd #(
  .DW(6),
  .DEFAULT(STATE_IDE)
) icache_state(clock,reset,state_nxt,state_r);
// ================================================================================================================================================
// CACHE MODULE
// ================================================================================================================================================
assign ifetch_req_tag   = ifetch_req_pc[`XLEN-1:OFFSET_LEN+INDEX_LEN];
assign ifetch_req_index = ifetch_req_pc[OFFSET_LEN+INDEX_LEN-1:OFFSET_LEN];
assign icache_tag       = icache_pc[`XLEN-1:OFFSET_LEN+INDEX_LEN];
assign icache_index     = icache_pc[OFFSET_LEN+INDEX_LEN-1:OFFSET_LEN];

assign ifetch_req_hit  = ifetch_req_hit0 | ifetch_req_hit1;
assign ifetch_req_miss = ~ifetch_req_hit;
assign ifetch_req_hit0 = ~ (|(icache_extend[ifetch_req_index][0][TAG_LEN+4:4] ^ {ifetch_req_tag,1'b1}));
assign ifetch_req_hit1 = ~ (|(icache_extend[ifetch_req_index][1][TAG_LEN+4:4] ^ {ifetch_req_tag,1'b1}));
assign ifetch_req_miss1 = icache_extend[ifetch_req_index][0][3:0] < icache_extend[ifetch_req_index][1][3:0];

lieat_general_dfflr #(1)     icache_hit_dff(clock,reset,ifetch_req_sh,ifetch_req_hit,icache_hit);
lieat_general_dfflr #(1)     icache_hit1_dff(clock,reset,ifetch_req_sh,ifetch_req_hit1,icache_hit1);
lieat_general_dfflr #(1)     icache_miss1_dff(clock,reset,ifetch_req_sh,ifetch_req_miss1,icache_miss1);
lieat_general_dfflr #(`XLEN) icache_pc_dff(clock,reset,ifetch_req_sh,ifetch_req_pc,icache_pc);

reg icache_reset_sync1;
reg icache_reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    icache_reset_sync1 <= 1'b1;
    icache_reset_sync2 <= 1'b1;
  end else begin
    icache_reset_sync1 <= 1'b0;
    icache_reset_sync2 <= icache_reset_sync1;
  end
end

always@(posedge clock) begin
  if(icache_reset_sync2) begin
    for(int i = 0;i < CACHE_SIZE; i = i + 1)begin
      for(int j = 0; j < CACHE_WAY; j = j + 1)begin
        icache_extend[i][j] <= 0;
      end
    end
  end
  else if(fencei_req)begin
    for(int i = 0;i < CACHE_SIZE; i = i + 1)begin
      for(int j = 0; j < CACHE_WAY; j = j + 1)begin
        icache_extend[i][j] <= 0;
      end
    end
  end
  else if(icache_hit & ifetch_req_valid) begin
    icache_extend[icache_index][icache_hit1][3:0] <= 4'b0;
    icache_extend[icache_index][~icache_hit1][3:0] <= (icache_extend[icache_index][~icache_hit1][3:0] == 4'b1111) ? 4'b1111 : (icache_extend[icache_index][~icache_hit1][3:0] + 1);
  end
  else if(icache_sram_wen) begin
    icache_extend[icache_index][icache_miss1] <= {icache_tag,5'b10000};
    icache_extend[icache_index][~icache_miss1][3:0] <= icache_extend[icache_index][~icache_miss1][3:0]+1;
  end
end
assign icache_sram_reset = reset;
assign icache_sram_wen = (icache_axi_rvalid & ~flush_req);
assign icache_sram_addr= ifetch_req_valid ? ifetch_req_index : icache_index;
assign icache_sram_data= icache_miss1 ? {icache_axi_rdata[31:0],icache_sram_rdata[31:0]} : {icache_sram_rdata[63:32],icache_axi_rdata[31:0]};
lieat_general_64x64_sram icache_sram(clock,icache_sram_reset,icache_sram_wen,icache_sram_addr,icache_sram_data,icache_sram_rdata);
// ================================================================================================================================================
// CHANNEL: INTERACTIVE WITH IFETCH
// ================================================================================================================================================
assign if_hold_rsp = pipeline_empty & state_r[STATE_VLD_BIT] & ~flush_req;
wire interrupt_need_wait;
wire interrupt_need_wait_r;
wire interrupt_need_wait_ena = if_hold_req |  if_hold_rsp;
wire interrupt_need_wait_nxt = if_hold_req | ~if_hold_rsp;
lieat_general_dfflr #(1) time_interrupt_need_wait_r_dff(clock,reset,interrupt_need_wait_ena,interrupt_need_wait_nxt,interrupt_need_wait_r);
assign interrupt_need_wait = if_hold_req | interrupt_need_wait_r;

assign ifetch_req_ready = 
(state_r[STATE_IDE_BIT]) | 
(state_r[STATE_RF_BIT] & icache_axi_rvalid) | 
(state_r[STATE_R_BIT] & icache_axi_rvalid & flush_req) | 
(state_r[STATE_VLD_BIT] & (flush_req | if_o_sh));

wire ifetch_inst_valid = icache_sram_wen | (ifetch_req_sh & ifetch_req_hit);
assign ifetch_rsp_inst_nxt = 
({`XLEN{ifetch_req_sh & ifetch_req_hit0}} & icache_sram_rdata[31:0 ])|
({`XLEN{ifetch_req_sh & ifetch_req_hit1}} & icache_sram_rdata[63:32])|
({`XLEN{icache_sram_wen}} & icache_axi_rdata[31:0]);

assign ifetch_rsp_pc = icache_pc;
assign ifetch_rsp_index = icache_pc[`BPU_IDX+1:2];
lieat_general_dfflr #(1) ifetch_rsp_valid_dff(clock,reset,1'b1,ifetch_inst_valid,ifetch_rsp_valid);
lieat_general_dfflr #(`XLEN) ifetch_rsp_inst_dff(clock,reset,ifetch_inst_valid,ifetch_rsp_inst_nxt,ifetch_rsp_inst);
assign if_o_valid = (state_r[STATE_VLD_BIT] & ~flush_req) & ~interrupt_need_wait;
// ================================================================================================================================================
// CHANNEL: INTERACTIVE WITH DRAM
// ================================================================================================================================================
assign icache_axi_arvalid = (ifetch_req_sh & ifetch_req_miss) | (state_r[STATE_AR_BIT]) | (state_r[STATE_ARF_BIT]);
assign icache_axi_araddr  = ifetch_req_sh ? ifetch_req_pc : icache_pc;
assign icache_axi_rready  = 1'b1;
// ================================================================================================================================================
// ICACHE DPIC_COUNT
// ================================================================================================================================================
`ifdef DPIC_VALID
  wire unused_ok = &{icache_axi_rdata[63:32]};
  wire [`XLEN-1:0] hit_count;
  wire [`XLEN-1:0] miss_count;
  wire hit_ena  = ifetch_req_sh & ifetch_req_hit;
  wire miss_ena = ifetch_req_sh & ifetch_req_miss;
  lieat_general_dfflr #(`XLEN) hit_count_dff(clock,reset,hit_ena,hit_count+1'b1,hit_count);
  lieat_general_dfflr #(`XLEN) miss_count_dff(clock,reset,miss_ena,miss_count+1'b1,miss_count);
  import "DPI-C" function void icache_dpic(input int hit_count,input int miss_count);
  always @(posedge clock or posedge reset) icache_dpic(hit_count,miss_count);
`endif
endmodule
