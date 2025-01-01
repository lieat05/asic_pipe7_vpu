module lieat_exu_dcache #(
  parameter CACHE_WAY = 2,
  parameter INDEX_LEN = 8,
  parameter CACHE_SIZE = 1 << INDEX_LEN,
  parameter TAG_WIDTH  = 30 - INDEX_LEN,
  parameter OFFSET_LEN = 2,
  parameter SYNC_SIZE = INDEX_LEN+1
)(
  input                clock,
  input                reset,
  //LSU
  input                lsu_req_valid,
  output               lsu_req_ready,
  input                lsu_req_ren,
  input                lsu_req_wen,
  input  [`XLEN-1:0]   lsu_req_addr,
  input  [2:0]         lsu_req_flag,
  input  [`XLEN-1:0]   lsu_req_wdata,
  output               lsu_rsp_valid,
  input                lsu_rsp_ready,
  output [`XLEN-1:0]   lsu_rsp_rdata,
  input                lsu_req_fencei,
  output               lsu_rsp_fencei_over,
  output               lsu_rsp_mmio,
  //VPU
  input                vpu_req_valid,
  output               vpu_req_ready,
  input                vpu_req_ren,
  input                vpu_req_wen,
  input  [`XLEN-1:0]   vpu_req_addr,
  input  [2:0]         vpu_req_flag,
  input  [`XLEN-1:0]   vpu_req_wdata,
  output               vpu_rsp_valid,
  input                vpu_rsp_ready,
  output [`XLEN-1:0]   vpu_rsp_rdata,
  //AR channel
  output               dcache_axi_arvalid,
  input                dcache_axi_arready,
  output [`XLEN-1:0]   dcache_axi_araddr,
  output [2:0]         dcache_axi_arsize,
  //R channel
  input                dcache_axi_rvalid,
  output               dcache_axi_rready,
  input  [`AXILEN-1:0] dcache_axi_rdata,
  //AW channel
  output               dcache_axi_awvalid,
  input                dcache_axi_awready,
  output [`XLEN-1:0]   dcache_axi_awaddr,
  output [2:0]         dcache_axi_awsize,
  //W channel
  output               dcache_axi_wvalid,
  input                dcache_axi_wready,
  output [`AXILEN-1:0] dcache_axi_wdata,
  output [7:0]         dcache_axi_wstrb,
  //B channel
  input                dcache_axi_bvalid,
  output               dcache_axi_bready,
  input  [1:0]         dcache_axi_bresp
);

// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire lsu_req_sh = lsu_req_valid & lsu_req_ready;
wire lsu_rsp_sh = lsu_rsp_valid & lsu_rsp_ready;
wire vpu_req_sh = vpu_req_valid & vpu_req_ready;
wire vpu_rsp_sh = vpu_rsp_valid & vpu_rsp_ready;
wire dcache_req_sh = lsu_req_sh | vpu_req_sh;
wire dcache_rsp_sh = lsu_rsp_sh | vpu_rsp_sh;

wire aw_sh  = dcache_axi_awvalid & dcache_axi_awready;
wire w_sh   = dcache_axi_wvalid & dcache_axi_wready;
wire ar_sh  = dcache_axi_arvalid & dcache_axi_arready;
wire r_sh   = dcache_axi_rvalid & dcache_axi_rready;
wire b_sh   = dcache_axi_bvalid & dcache_axi_bready;

localparam STATE_IDLE = 3'b001;
localparam STATE_BUSY = 3'b010;
localparam STATE_VALD = 3'b100;
localparam STATE_IDLE_BIT = 0;
localparam STATE_BUSY_BIT = 1;
localparam STATE_VALD_BIT = 2;

localparam STATER_IDE = 3'b001;
localparam STATER_AR  = 3'b010;
localparam STATER_R   = 3'b100;
localparam STATER_AR_BIT  = 1;
localparam STATER_R_BIT   = 2;

localparam STATEW_IDE = 5'b00001;
localparam STATEW_AWW = 5'b00010;
localparam STATEW_AW  = 5'b00100;
localparam STATEW_W   = 5'b01000;
localparam STATEW_B   = 5'b10000;
localparam STATEW_AWW_BIT = 1;
localparam STATEW_AW_BIT  = 2;
localparam STATEW_W_BIT   = 3;
localparam STATEW_B_BIT   = 4;

reg [2:0]            state_r;
reg [2:0]            state_rr;
reg [4:0]            state_wr;
reg [2:0]            state_nxt;
reg [2:0]            state_rnxt;
reg [4:0]            state_wnxt;

wire [INDEX_LEN:0]   count;
wire [INDEX_LEN:0]   count_nxt;
wire                 count_ena;
wire                 count_over;
wire                 sync_clean;
wire                 sync_valid;
wire                 sync_finish;

wire [TAG_WIDTH-1:0] lsu_req_tag;
wire [INDEX_LEN-1:0] lsu_req_index;
wire                 lsu_req_inaddr;
wire                 lsu_req_hit_or_miss;
wire                 lsu_req_hit_sel;
wire                 lsu_req_miss_sel;
wire                 lsu_req_clean_or_dirty;
wire                 lsu_req_read_outaddr;
wire                 lsu_req_read_hit;
wire                 lsu_req_read_miss;
wire                 lsu_req_read_miss_wb;
wire                 lsu_req_write_outaddr;
wire                 lsu_req_write_hit;
wire                 lsu_req_write_miss;
wire                 lsu_req_write_miss_wb;
wire                 lsu_req_write_miss_rd;
wire                 lsu_req_write_miss_wbrd;
wire                 lsu_req_axi_idle;
wire                 lsu_req_axi_read;
wire                 lsu_req_axi_write;
wire                 lsu_req_axi_wbrd;

wire [TAG_WIDTH-1:0] vpu_req_tag;
wire [INDEX_LEN-1:0] vpu_req_index;
wire                 vpu_req_inaddr;
wire                 vpu_req_hit_or_miss;
wire                 vpu_req_hit_sel;
wire                 vpu_req_miss_sel;
wire                 vpu_req_clean_or_dirty;
wire                 vpu_req_read_outaddr;
wire                 vpu_req_read_hit;
wire                 vpu_req_read_miss;
wire                 vpu_req_read_miss_wb;
wire                 vpu_req_write_outaddr;
wire                 vpu_req_write_hit;
wire                 vpu_req_write_miss;
wire                 vpu_req_write_miss_wb;
wire                 vpu_req_write_miss_rd;
wire                 vpu_req_write_miss_wbrd;
wire                 vpu_req_axi_idle;
wire                 vpu_req_axi_read;
wire                 vpu_req_axi_write;
wire                 vpu_req_axi_wbrd;

wire                 dcache_req_ren;
wire [2:0]           dcache_req_flag;
wire [`XLEN-1:0]     dcache_req_addr;
wire [`XLEN-1:0]     dcache_req_wdata;
wire [INDEX_LEN-1:0] dcache_req_index;
wire                 dcache_req_inaddr;
wire                 dcache_req_hit_or_miss;
wire                 dcache_req_hit_sel;
wire                 dcache_req_miss_sel;
wire                 dcache_req_clean_or_dirty;
wire                 dcache_req_read_outaddr;
wire                 dcache_req_write_outaddr;
wire                 dcache_req_axi_idle;
wire                 dcache_req_axi_read;
wire                 dcache_req_axi_write;
wire                 dcache_req_axi_wbrd;

wire                 dcache_vpu;
wire                 dcache_req_ready;
wire [`XLEN-1:0]     dcache_rsp_rdata;
wire                 dcache_rsp_valid;
wire                 dcache_rsp_ready;

wire [2:0]           dcache_flag;
wire [`XLEN-1:0]     dcache_addr;
wire [`XLEN-1:0]     dcache_wdata;
wire [TAG_WIDTH-1:0] dcache_tag;
wire [INDEX_LEN-1:0] dcache_index;
wire [1:0]           dcache_bytesel;
wire                 dcache_hsel;
wire                 dcache_msel;
wire                 dcache_len1;
wire                 dcache_len2;
wire                 dcache_len4;
wire                 dcache_inaddr;
wire                 dcache_ren_or_wen;
wire                 dcache_hit_or_miss;
wire                 dcache_clean_or_dirty;
wire                 dcache_fencei;
wire                 dcache_read_outaddr;
wire                 dcache_read_hit;
wire                 dcache_read_miss;//no need wb
wire                 dcache_read_miss_wb;
wire                 dcache_write_outaddr;
wire                 dcache_write_hit;
wire                 dcache_write_miss;
wire                 dcache_write_miss_wb;
wire                 dcache_write_miss_rd;
wire                 dcache_write_miss_wbrd;
wire                 dcache_axi_read;
wire                 dcache_axi_write;
wire                 dcache_axi_wbrd;
wire                 dcache_axi_sync;
wire [`XLEN-1:0]     dcache_rdata_sel;
wire [`XLEN-1:0]     dcache_wdata_sel;

wire                 dcache_sram_wen;
wire [INDEX_LEN-1:0] dcache_sram_addr;
wire [`AXILEN-1:0]   dcache_sram_data;
wire [`AXILEN-1:0]   dcache_sram_rdata;
wire [`XLEN-1:0]     dcache_hit_data;
wire [`XLEN-1:0]     dcache_hit_data_nxt;
wire [`AXILEN-1:0]   read_miss_sram_data;
wire [`AXILEN-1:0]   write_hit_sram_data;
wire [`AXILEN-1:0]   write_miss_sram_data;

reg  [TAG_WIDTH+4:0] dcache_extend [CACHE_SIZE-1:0][CACHE_WAY-1:0];//TAG_WIDTH + VALID_BIT1 + LRU_BIT 4
// ================================================================================================================================================
// STATE CONTROL
// ================================================================================================================================================
always @(*) begin
  case(state_wr)
    STATEW_IDE:state_wnxt = {
    (aw_sh & w_sh),
    (aw_sh & ~w_sh),
    (~aw_sh & w_sh),
    (dcache_axi_awvalid & ~aw_sh & ~w_sh) | sync_valid,
    (~dcache_axi_awvalid & ~sync_valid)};
    STATEW_AWW:state_wnxt = {
    (aw_sh & w_sh),
    (aw_sh & ~w_sh),
    (~aw_sh & w_sh),
    (~aw_sh & ~w_sh),
    1'b0};
    STATEW_AW :state_wnxt = {
    aw_sh,
    1'b0,
    ~aw_sh,
    2'b0};
    STATEW_W  :state_wnxt = {
    w_sh,
    ~w_sh,
    3'b0};
    STATEW_B  :state_wnxt = {
    ~b_sh | (dcache_req_sh & aw_sh & w_sh),
    dcache_req_sh & aw_sh & ~w_sh,
    dcache_req_sh & ~aw_sh & w_sh,
    dcache_req_sh & dcache_axi_awvalid & ~aw_sh & ~w_sh,
    (b_sh & ~dcache_req_sh) | (dcache_req_sh & ~dcache_axi_awvalid)};
    default   :state_wnxt = STATEW_IDE;
  endcase
  case(state_rr)
    STATER_IDE:state_rnxt = {
    ar_sh,
    ~ar_sh & dcache_axi_arvalid,
    ~dcache_axi_arvalid
    };
    STATER_AR :state_rnxt = {
    ar_sh,
    ~ar_sh,
    1'b0
    };
    STATER_R  :state_rnxt = {
    ~r_sh | (dcache_req_sh & ar_sh),
    dcache_req_sh & ~ar_sh,
    r_sh & ~dcache_req_sh
    };
    default:state_rnxt = STATER_IDE;
  endcase
  case(state_r)
    STATE_IDLE:state_nxt = {
    dcache_req_sh & dcache_req_axi_idle,
    dcache_req_sh & ~dcache_req_axi_idle,
    ~dcache_req_sh
    };
    STATE_BUSY:state_nxt = {
    (dcache_rsp_valid & ~dcache_rsp_ready) | (dcache_req_sh & dcache_req_axi_idle),
    ~dcache_rsp_valid | (dcache_req_sh & ~dcache_req_axi_idle),
    dcache_rsp_sh & ~dcache_req_sh
    };
    STATE_VALD:state_nxt = {
    ~dcache_rsp_ready | (dcache_req_sh & dcache_req_axi_idle),
    dcache_req_sh & ~dcache_req_axi_idle,
    dcache_rsp_sh & ~dcache_req_sh
    };
    default:state_nxt = STATE_IDLE;
  endcase
end
lieat_general_dffrd #(
  .DW(3),
  .DEFAULT(STATE_IDLE)
) dcache_state_dff(clock,reset,state_nxt,state_r);
lieat_general_dffrd #(
  .DW(3),
  .DEFAULT(STATER_IDE)
) dcache_stater_dff(clock,reset,state_rnxt,state_rr);
lieat_general_dffrd #(
  .DW(5),
  .DEFAULT(STATEW_IDE)
) dcache_statew_dff(clock,reset,state_wnxt,state_wr);

lieat_general_dfflr #(3)     dcache_flag_dff(clock,reset,dcache_req_sh,dcache_req_flag,dcache_flag);
lieat_general_dfflr #(`XLEN) dcache_addr_dff(clock,reset,dcache_req_sh,dcache_req_addr,dcache_addr);
lieat_general_dfflr #(`XLEN) dcache_wdata_dff(clock,reset,dcache_req_sh,dcache_req_wdata,dcache_wdata);
lieat_general_dfflr #(1)     dcache_hsel_dff(clock,reset,dcache_req_sh,dcache_req_hit_sel,dcache_hsel);
lieat_general_dfflr #(1)     dcache_msel_dff(clock,reset,dcache_req_sh,dcache_req_miss_sel,dcache_msel);
lieat_general_dfflr #(1)     dcache_inaddr_dff(clock,reset,dcache_req_sh,dcache_req_inaddr,dcache_inaddr);
lieat_general_dfflr #(1)     dcache_hit_or_miss_dff(clock,reset,dcache_req_sh,dcache_req_hit_or_miss,dcache_hit_or_miss);
lieat_general_dfflr #(1)     dcache_clean_or_dirty_dff(clock,reset,dcache_req_sh,dcache_req_clean_or_dirty,dcache_clean_or_dirty);
lieat_general_dfflr #(1)     dcache_ren_or_wen_dff(clock,reset,dcache_req_sh,dcache_req_ren,dcache_ren_or_wen);
lieat_general_dfflr #(1)     dcache_fencei_dff(clock,reset,lsu_req_sh | lsu_rsp_sh,lsu_req_fencei,dcache_fencei);
lieat_general_dfflr #(1)     dcache_vpu_dff(clock,reset,dcache_req_sh,vpu_req_valid,dcache_vpu);

`ifdef DPIC_VALID
  assign vpu_req_inaddr          = (vpu_req_addr[31:28] == 4'b1000);
  assign lsu_req_inaddr          = (lsu_req_addr[31:28] == 4'b1000);
`else
  assign vpu_req_inaddr          = (vpu_req_addr[31:28] == 4'b0011) | vpu_req_addr[31];
  assign lsu_req_inaddr          = (lsu_req_addr[31:28] == 4'b0011) | lsu_req_addr[31];
`endif

assign lsu_req_hit_or_miss     = (dcache_extend[lsu_req_index][0][TAG_WIDTH+4:5] == lsu_req_tag) | (dcache_extend[lsu_req_index][1][TAG_WIDTH+4:5] == lsu_req_tag);//1 hit 0 miss
assign lsu_req_hit_sel         = (dcache_extend[lsu_req_index][1][TAG_WIDTH+4:5] == lsu_req_tag);//1 sel1 0 sel0
assign lsu_req_miss_sel        = (dcache_extend[lsu_req_index][0][3:0] < dcache_extend[lsu_req_index][1][3:0]);//1 sel1 0 sel0
assign lsu_req_clean_or_dirty  = (~lsu_req_miss_sel & ~dcache_extend[lsu_req_index][0][4]) | (lsu_req_miss_sel & ~dcache_extend[lsu_req_index][1][4]);//1 clean 0 dirty
assign lsu_req_tag             = lsu_req_addr[`XLEN-1:OFFSET_LEN+INDEX_LEN];
assign lsu_req_index           = lsu_req_addr[OFFSET_LEN+INDEX_LEN-1:OFFSET_LEN];
assign lsu_req_read_outaddr    = lsu_req_ren & ~lsu_req_inaddr & ~lsu_req_fencei;
assign lsu_req_read_hit        = lsu_req_ren & lsu_req_inaddr & lsu_req_hit_or_miss;
assign lsu_req_read_miss       = lsu_req_ren & lsu_req_inaddr & ~lsu_req_hit_or_miss & lsu_req_clean_or_dirty;
assign lsu_req_read_miss_wb    = lsu_req_ren & lsu_req_inaddr & ~lsu_req_hit_or_miss & ~lsu_req_clean_or_dirty;
assign lsu_req_write_outaddr   = lsu_req_wen & ~lsu_req_inaddr & ~lsu_req_fencei;
assign lsu_req_write_hit       = lsu_req_wen & lsu_req_inaddr & lsu_req_hit_or_miss;
assign lsu_req_write_miss      = lsu_req_wen & lsu_req_inaddr & ~lsu_req_hit_or_miss & lsu_req_clean_or_dirty & lsu_req_flag[1];
assign lsu_req_write_miss_wb   = lsu_req_wen & lsu_req_inaddr & ~lsu_req_hit_or_miss & ~lsu_req_clean_or_dirty & lsu_req_flag[1];
assign lsu_req_write_miss_rd   = lsu_req_wen & lsu_req_inaddr & ~lsu_req_hit_or_miss & lsu_req_clean_or_dirty & ~lsu_req_flag[1];
assign lsu_req_write_miss_wbrd = lsu_req_wen & lsu_req_inaddr & ~lsu_req_hit_or_miss & ~lsu_req_clean_or_dirty & ~lsu_req_flag[1];
assign lsu_req_axi_idle        = lsu_req_write_hit | lsu_req_read_hit | lsu_req_write_miss;
assign lsu_req_axi_read        = lsu_req_read_outaddr | lsu_req_read_miss | lsu_req_write_miss_rd;
assign lsu_req_axi_write       = lsu_req_write_outaddr | lsu_req_write_miss_wb;
assign lsu_req_axi_wbrd        = lsu_req_read_miss_wb | lsu_req_write_miss_wbrd;

assign vpu_req_hit_or_miss     = (dcache_extend[vpu_req_index][0][TAG_WIDTH+4:5] == vpu_req_tag) | (dcache_extend[vpu_req_index][1][TAG_WIDTH+4:5] == vpu_req_tag);//1 hit 0 miss
assign vpu_req_hit_sel         = (dcache_extend[vpu_req_index][1][TAG_WIDTH+4:5] == vpu_req_tag);//1 sel1 0 sel0
assign vpu_req_miss_sel        = (dcache_extend[vpu_req_index][0][3:0] < dcache_extend[vpu_req_index][1][3:0]);//1 sel1 0 sel0
assign vpu_req_clean_or_dirty  = (~vpu_req_miss_sel & ~dcache_extend[vpu_req_index][0][4]) | (vpu_req_miss_sel & ~dcache_extend[vpu_req_index][1][4]);//1 clean 0 dirty
assign vpu_req_tag             = vpu_req_addr[`XLEN-1:OFFSET_LEN+INDEX_LEN];
assign vpu_req_index           = vpu_req_addr[OFFSET_LEN+INDEX_LEN-1:OFFSET_LEN];
assign vpu_req_read_outaddr    = vpu_req_ren & ~vpu_req_inaddr;
assign vpu_req_read_hit        = vpu_req_ren & vpu_req_inaddr & vpu_req_hit_or_miss;
assign vpu_req_read_miss       = vpu_req_ren & vpu_req_inaddr & ~vpu_req_hit_or_miss & vpu_req_clean_or_dirty;
assign vpu_req_read_miss_wb    = vpu_req_ren & vpu_req_inaddr & ~vpu_req_hit_or_miss & ~vpu_req_clean_or_dirty;
assign vpu_req_write_outaddr   = vpu_req_wen & ~vpu_req_inaddr;
assign vpu_req_write_hit       = vpu_req_wen & vpu_req_inaddr & vpu_req_hit_or_miss;
assign vpu_req_write_miss      = vpu_req_wen & vpu_req_inaddr & ~vpu_req_hit_or_miss & vpu_req_clean_or_dirty & vpu_req_flag[1];
assign vpu_req_write_miss_wb   = vpu_req_wen & vpu_req_inaddr & ~vpu_req_hit_or_miss & ~vpu_req_clean_or_dirty & vpu_req_flag[1];
assign vpu_req_write_miss_rd   = vpu_req_wen & vpu_req_inaddr & ~vpu_req_hit_or_miss & vpu_req_clean_or_dirty & ~vpu_req_flag[1];
assign vpu_req_write_miss_wbrd = vpu_req_wen & vpu_req_inaddr & ~vpu_req_hit_or_miss & ~vpu_req_clean_or_dirty & ~vpu_req_flag[1];
assign vpu_req_axi_idle        = vpu_req_write_hit | vpu_req_read_hit | vpu_req_write_miss;
assign vpu_req_axi_read        = vpu_req_read_outaddr | vpu_req_read_miss | vpu_req_write_miss_rd;
assign vpu_req_axi_write       = vpu_req_write_outaddr | vpu_req_write_miss_wb;
assign vpu_req_axi_wbrd        = vpu_req_read_miss_wb | vpu_req_write_miss_wbrd;

assign dcache_req_inaddr          = vpu_req_valid ? vpu_req_inaddr          : lsu_req_inaddr;
assign dcache_req_flag            = vpu_req_valid ? vpu_req_flag            : lsu_req_flag;
assign dcache_req_addr            = vpu_req_valid ? vpu_req_addr            : lsu_req_addr;
assign dcache_req_wdata           = vpu_req_valid ? vpu_req_wdata           : lsu_req_wdata;
assign dcache_req_ren             = vpu_req_valid ? vpu_req_ren             : lsu_req_ren;
assign dcache_req_index           = vpu_req_valid ? vpu_req_index           : lsu_req_index;
assign dcache_req_hit_or_miss     = vpu_req_valid ? vpu_req_hit_or_miss     : lsu_req_hit_or_miss;
assign dcache_req_hit_sel         = vpu_req_valid ? vpu_req_hit_sel         : lsu_req_hit_sel;
assign dcache_req_miss_sel        = vpu_req_valid ? vpu_req_miss_sel        : lsu_req_miss_sel;
assign dcache_req_clean_or_dirty  = vpu_req_valid ? vpu_req_clean_or_dirty  : lsu_req_clean_or_dirty;
assign dcache_req_read_outaddr    = vpu_req_valid ? vpu_req_read_outaddr    : lsu_req_read_outaddr;
assign dcache_req_write_outaddr   = vpu_req_valid ? vpu_req_write_outaddr   : lsu_req_write_outaddr;
assign dcache_req_axi_idle        = vpu_req_valid ? vpu_req_axi_idle        : lsu_req_axi_idle;
assign dcache_req_axi_read        = vpu_req_valid ? vpu_req_axi_read        : lsu_req_axi_read;
assign dcache_req_axi_write       = vpu_req_valid ? vpu_req_axi_write       : lsu_req_axi_write;
assign dcache_req_axi_wbrd        = vpu_req_valid ? vpu_req_axi_wbrd        : lsu_req_axi_wbrd;

assign dcache_len1             = ~dcache_flag[1] & ~dcache_flag[0];
assign dcache_len2             = dcache_flag[0];
assign dcache_len4             = dcache_flag[1];
assign dcache_bytesel          = dcache_addr[OFFSET_LEN-1:0];
assign dcache_tag              = dcache_addr[`XLEN-1:OFFSET_LEN+INDEX_LEN];
assign dcache_index            = dcache_addr[OFFSET_LEN+INDEX_LEN-1:OFFSET_LEN];
assign dcache_read_outaddr     = dcache_ren_or_wen & ~dcache_inaddr & ~dcache_fencei;
assign dcache_read_hit         = dcache_ren_or_wen & dcache_inaddr & dcache_hit_or_miss;
assign dcache_read_miss        = dcache_ren_or_wen & dcache_inaddr & ~dcache_hit_or_miss & dcache_clean_or_dirty;
assign dcache_read_miss_wb     = dcache_ren_or_wen & dcache_inaddr & ~dcache_hit_or_miss & ~dcache_clean_or_dirty;
assign dcache_write_outaddr    = ~dcache_ren_or_wen & ~dcache_inaddr & ~dcache_fencei;
assign dcache_write_hit        = ~dcache_ren_or_wen & dcache_inaddr & dcache_hit_or_miss;
assign dcache_write_miss       = ~dcache_ren_or_wen & dcache_inaddr & ~dcache_hit_or_miss & dcache_clean_or_dirty & dcache_len4;
assign dcache_write_miss_wb    = ~dcache_ren_or_wen & dcache_inaddr & ~dcache_hit_or_miss & ~dcache_clean_or_dirty & dcache_len4;
assign dcache_write_miss_rd    = ~dcache_ren_or_wen & dcache_inaddr & ~dcache_hit_or_miss & dcache_clean_or_dirty & ~dcache_len4;
assign dcache_write_miss_wbrd  = ~dcache_ren_or_wen & dcache_inaddr & ~dcache_hit_or_miss & ~dcache_clean_or_dirty & ~dcache_len4;
assign dcache_axi_read         = dcache_read_outaddr | dcache_read_miss | dcache_write_miss_rd;
assign dcache_axi_write        = dcache_write_outaddr | dcache_write_miss_wb;
assign dcache_axi_wbrd         = dcache_read_miss_wb | dcache_write_miss_wbrd;
assign dcache_axi_sync         = dcache_fencei;

wire dcache_bytesel_00 = ~dcache_bytesel[0] & ~dcache_bytesel[1];
wire dcache_bytesel_01 =  dcache_bytesel[0] & ~dcache_bytesel[1];
wire dcache_bytesel_10 = ~dcache_bytesel[0] &  dcache_bytesel[1];
wire dcache_bytesel_11 =  dcache_bytesel[0] &  dcache_bytesel[1];
wire dcache_flag_000   = ~dcache_flag[0] & ~dcache_flag[1] & ~dcache_flag[2];
wire dcache_flag_001   =  dcache_flag[0] & ~dcache_flag[1] & ~dcache_flag[2];
wire dcache_flag_010   = ~dcache_flag[0] &  dcache_flag[1] & ~dcache_flag[2];
wire dcache_flag_100   = ~dcache_flag[0] & ~dcache_flag[1] &  dcache_flag[2];
wire dcache_flag_101   =  dcache_flag[0] & ~dcache_flag[1] &  dcache_flag[2];
wire dcache_awaddr_000 = ~dcache_axi_awaddr[0] & ~dcache_axi_awaddr[1] & ~dcache_axi_awaddr[2];
wire dcache_awaddr_001 =  dcache_axi_awaddr[0] & ~dcache_axi_awaddr[1] & ~dcache_axi_awaddr[2];
wire dcache_awaddr_010 = ~dcache_axi_awaddr[0] &  dcache_axi_awaddr[1] & ~dcache_axi_awaddr[2];
wire dcache_awaddr_011 =  dcache_axi_awaddr[0] &  dcache_axi_awaddr[1] & ~dcache_axi_awaddr[2];
wire dcache_awaddr_100 = ~dcache_axi_awaddr[0] & ~dcache_axi_awaddr[1] &  dcache_axi_awaddr[2];
wire dcache_awaddr_101 =  dcache_axi_awaddr[0] & ~dcache_axi_awaddr[1] &  dcache_axi_awaddr[2];
wire dcache_awaddr_110 = ~dcache_axi_awaddr[0] &  dcache_axi_awaddr[1] &  dcache_axi_awaddr[2];
wire dcache_awaddr_111 =  dcache_axi_awaddr[0] &  dcache_axi_awaddr[1] &  dcache_axi_awaddr[2];
wire dcache_awsize_000 = ~dcache_axi_awsize[0] & ~dcache_axi_awsize[1] & ~dcache_axi_awsize[2];
wire dcache_awsize_001 =  dcache_axi_awsize[0] & ~dcache_axi_awsize[1] & ~dcache_axi_awsize[2];
wire dcache_awsize_010 = ~dcache_axi_awsize[0] &  dcache_axi_awsize[1] & ~dcache_axi_awsize[2];
assign dcache_rdata_sel = //READ CHANNEL:SEL CACHE OR AXI ---> LSU
({`XLEN{dcache_inaddr & dcache_hit_or_miss }} & dcache_hit_data         ) |
({`XLEN{dcache_axi_rvalid &  dcache_addr[2]}} & dcache_axi_rdata[63:32] ) |
({`XLEN{dcache_axi_rvalid & ~dcache_addr[2]}} & dcache_axi_rdata[31:0]  ) ;
assign dcache_wdata_sel = (state_wr[STATEW_AWW_BIT] | state_wr[STATEW_AW_BIT] | state_wr[STATEW_W_BIT]) ? 
(dcache_write_outaddr     ? dcache_wdata     : dcache_hit_data):
(dcache_req_write_outaddr ? dcache_req_wdata : (~dcache_req_miss_sel ? dcache_sram_rdata[31:0] : dcache_sram_rdata[63:32]));
// ================================================================================================================================================
// READ CHANNEL
// ================================================================================================================================================
assign dcache_axi_arvalid = state_rr[STATER_AR_BIT] | (dcache_req_sh & (dcache_req_axi_read | dcache_req_axi_wbrd));
assign dcache_axi_araddr  = state_rr[STATER_AR_BIT] ? 
(dcache_read_outaddr     ? dcache_addr     : {dcache_addr[31:2] ,2'b0}):
(dcache_req_read_outaddr ? dcache_req_addr : {dcache_req_addr[31:2],2'b0});
assign dcache_axi_arsize  = state_rr[STATER_AR_BIT] ? (dcache_read_outaddr ? {1'b0, dcache_flag[1:0]}: 3'b010): (dcache_req_read_outaddr ? {1'b0,dcache_req_flag[1:0]} : 3'b010);
assign dcache_axi_rready  = lsu_rsp_ready & (~dcache_axi_wbrd | (dcache_axi_bvalid));
// ================================================================================================================================================
// WRITE CHANNEL
// ================================================================================================================================================
assign dcache_axi_awvalid = (state_wr[STATEW_AWW_BIT] | state_wr[STATEW_AW_BIT]) | (dcache_req_sh & (dcache_req_axi_write | dcache_req_axi_wbrd));
assign dcache_axi_wvalid  = (state_wr[STATEW_AWW_BIT] | state_wr[STATEW_W_BIT]) | (dcache_req_sh & (dcache_req_axi_write | dcache_req_axi_wbrd));
assign dcache_axi_bready  = lsu_rsp_ready & (~dcache_axi_wbrd | (dcache_axi_rvalid));

assign dcache_axi_awsize  = (state_wr[STATEW_AWW_BIT] | state_wr[STATEW_AW_BIT] | state_wr[STATEW_W_BIT]) ?
(dcache_write_outaddr     ? {1'b0,dcache_flag[1:0]}     : 3'b010):
(dcache_req_write_outaddr ? {1'b0,dcache_req_flag[1:0]} : 3'b010);
assign dcache_axi_awaddr = dcache_axi_sync ? {dcache_extend[count[INDEX_LEN:1]][count[0]][TAG_WIDTH+4:5],count[INDEX_LEN:1],2'b0} : 
(state_wr[STATEW_AWW_BIT] | state_wr[STATEW_AW_BIT] | state_wr[STATEW_W_BIT]) ? 
(dcache_write_outaddr     ? dcache_addr     : {dcache_extend[dcache_index ][dcache_msel][TAG_WIDTH+4:5],dcache_index,2'b0}):
(dcache_req_write_outaddr ? dcache_req_addr : {dcache_extend[dcache_req_index][dcache_req_miss_sel][TAG_WIDTH+4:5],dcache_req_index,2'b0});

assign dcache_axi_wstrb  = dcache_axi_sync ? {{4{count[1]}},{4{~count[1]}}} : 
({8{dcache_awsize_000 & dcache_awaddr_000}} & 8'b00000001) |
({8{dcache_awsize_000 & dcache_awaddr_001}} & 8'b00000010) |
({8{dcache_awsize_000 & dcache_awaddr_010}} & 8'b00000100) |
({8{dcache_awsize_000 & dcache_awaddr_011}} & 8'b00001000) |
({8{dcache_awsize_000 & dcache_awaddr_100}} & 8'b00010000) |
({8{dcache_awsize_000 & dcache_awaddr_101}} & 8'b00100000) |
({8{dcache_awsize_000 & dcache_awaddr_110}} & 8'b01000000) |
({8{dcache_awsize_000 & dcache_awaddr_111}} & 8'b10000000) |
({8{dcache_awsize_001 & dcache_awaddr_000}} & 8'b00000011) |
({8{dcache_awsize_001 & dcache_awaddr_010}} & 8'b00001100) |
({8{dcache_awsize_001 & dcache_awaddr_100}} & 8'b00110000) |
({8{dcache_awsize_001 & dcache_awaddr_110}} & 8'b11000000) |
({8{dcache_awsize_010 & dcache_awaddr_000}} & 8'b00001111) |
({8{dcache_awsize_010 & dcache_awaddr_100}} & 8'b11110000) ;
assign dcache_axi_wdata  = dcache_axi_sync ? {
{`XLEN{ count[1]}} & (count[0] ? dcache_sram_rdata[63:32] : dcache_sram_rdata[31:0]),
{`XLEN{~count[1]}} & (count[0] ? dcache_sram_rdata[63:32] : dcache_sram_rdata[31:0])}   : 
({64{dcache_awsize_000 & dcache_awaddr_000}} & {56'h0,{dcache_wdata_sel[ 7: 0]}})       |
({64{dcache_awsize_000 & dcache_awaddr_001}} & {48'h0,{dcache_wdata_sel[ 7: 0]}, 8'h0}) |
({64{dcache_awsize_000 & dcache_awaddr_010}} & {40'h0,{dcache_wdata_sel[ 7: 0]},16'h0}) |
({64{dcache_awsize_000 & dcache_awaddr_011}} & {32'h0,{dcache_wdata_sel[ 7: 0]},24'h0}) |
({64{dcache_awsize_000 & dcache_awaddr_100}} & {24'h0,{dcache_wdata_sel[ 7: 0]},32'h0}) |
({64{dcache_awsize_000 & dcache_awaddr_101}} & {16'h0,{dcache_wdata_sel[ 7: 0]},40'h0}) |
({64{dcache_awsize_000 & dcache_awaddr_110}} & { 8'h0,{dcache_wdata_sel[ 7: 0]},48'h0}) |
({64{dcache_awsize_000 & dcache_awaddr_111}} & {      {dcache_wdata_sel[ 7: 0]},56'h0}) |
({64{dcache_awsize_001 & dcache_awaddr_000}} & {48'h0,{dcache_wdata_sel[15: 0]}      }) |
({64{dcache_awsize_001 & dcache_awaddr_010}} & {32'h0,{dcache_wdata_sel[15: 0]},16'h0}) |
({64{dcache_awsize_001 & dcache_awaddr_100}} & {16'h0,{dcache_wdata_sel[15: 0]},32'h0}) |
({64{dcache_awsize_001 & dcache_awaddr_110}} & {      {dcache_wdata_sel[15: 0]},48'h0}) |
({64{dcache_awsize_010 & dcache_awaddr_000}} & {32'h0,{dcache_wdata_sel[31: 0]}      }) |
({64{dcache_awsize_010 & dcache_awaddr_100}} & {      {dcache_wdata_sel[31: 0]},32'h0}) ;

assign count_nxt = count_over ? 9'b0 : (count+1);
assign count_ena = dcache_axi_sync & (dcache_axi_bvalid | sync_clean);
assign count_over = (count == 9'b111111111) & count_ena;

assign sync_clean   = ~dcache_extend[count[INDEX_LEN:1]][count[0]][4];
assign sync_valid   = dcache_axi_sync & ~sync_clean;
lieat_general_dfflr #(SYNC_SIZE) sync_count_dff(clock,reset,count_ena,count_nxt,count);
lieat_general_dfflr #(1)         sync_finish_dff(clock,reset,(count_over & (dcache_axi_bvalid | sync_clean)) | lsu_rsp_sh,(count_over & (dcache_axi_bvalid | sync_clean)),sync_finish);
// ================================================================================================================================================
// CACHE MODULE
// ================================================================================================================================================
assign dcache_hit_data_nxt = dcache_req_hit_sel ? dcache_sram_rdata[63:32] : dcache_sram_rdata[31:0];
lieat_general_dfflr #(`XLEN) dcache_hit_data_dff(clock,reset,dcache_req_sh,dcache_hit_data_nxt,dcache_hit_data);
lieat_general_256x64_sram dcache_sram(clock,reset,dcache_sram_wen,dcache_sram_addr,dcache_sram_data,dcache_sram_rdata);

assign dcache_sram_wen = 
(dcache_read_miss       & dcache_axi_rvalid      ) |
(dcache_read_miss_wb    & dcache_axi_rvalid      ) |
(dcache_write_hit       & state_r[STATE_VALD_BIT]) |
(dcache_write_miss      & state_r[STATE_VALD_BIT]) |
(dcache_write_miss_rd   & dcache_axi_rvalid      ) |
(dcache_write_miss_wb   & dcache_axi_bvalid      ) |
(dcache_write_miss_wbrd & dcache_axi_rvalid      ) ;

assign dcache_sram_addr = dcache_axi_sync ? count[INDEX_LEN:1] : dcache_sram_wen ? dcache_index : dcache_req_index;
assign dcache_sram_data = 
({64{(dcache_read_miss       & dcache_axi_rvalid)}} & read_miss_sram_data) |
({64{(dcache_read_miss_wb    & dcache_axi_rvalid)}} & read_miss_sram_data) |
({64{(dcache_write_hit                          )}} & write_hit_sram_data) |
({64{(dcache_write_miss                         )}} & write_miss_sram_data)|
({64{(dcache_write_miss_rd   & dcache_axi_rvalid)}} & write_miss_sram_data)|
({64{(dcache_write_miss_wb                      )}} & write_miss_sram_data)|
({64{(dcache_write_miss_wbrd & dcache_axi_rvalid)}} & write_miss_sram_data);

assign read_miss_sram_data = ~dcache_msel ? {dcache_sram_rdata[63:32],dcache_rdata_sel} : {dcache_rdata_sel,dcache_sram_rdata[31:0]};
assign write_hit_sram_data = 
({64{(dcache_len1 & dcache_bytesel_00 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63: 8],dcache_wdata[7:0]                         }) |
({64{(dcache_len1 & dcache_bytesel_01 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63:16],dcache_wdata[7:0],dcache_sram_rdata[ 7:0] }) |
({64{(dcache_len1 & dcache_bytesel_10 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63:24],dcache_wdata[7:0],dcache_sram_rdata[15:0] }) |
({64{(dcache_len1 & dcache_bytesel_11 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63:32],dcache_wdata[7:0],dcache_sram_rdata[23:0] }) |
({64{(dcache_len1 & dcache_bytesel_00 & dcache_hit_or_miss &  dcache_hsel)}} & {dcache_sram_rdata[63:40],dcache_wdata[7:0],dcache_sram_rdata[31:0] }) |
({64{(dcache_len1 & dcache_bytesel_01 & dcache_hit_or_miss &  dcache_hsel)}} & {dcache_sram_rdata[63:48],dcache_wdata[7:0],dcache_sram_rdata[39:0] }) |
({64{(dcache_len1 & dcache_bytesel_10 & dcache_hit_or_miss &  dcache_hsel)}} & {dcache_sram_rdata[63:56],dcache_wdata[7:0],dcache_sram_rdata[47:0] }) |
({64{(dcache_len1 & dcache_bytesel_11 & dcache_hit_or_miss &  dcache_hsel)}} & {                         dcache_wdata[7:0],dcache_sram_rdata[55:0] }) |
({64{(dcache_len2 & dcache_bytesel_00 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63:16],dcache_wdata[15:0]                        }) |
({64{(dcache_len2 & dcache_bytesel_10 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63:32],dcache_wdata[15:0],dcache_sram_rdata[15:0]}) |
({64{(dcache_len2 & dcache_bytesel_00 & dcache_hit_or_miss &  dcache_hsel)}} & {dcache_sram_rdata[63:48],dcache_wdata[15:0],dcache_sram_rdata[31:0]}) |
({64{(dcache_len2 & dcache_bytesel_10 & dcache_hit_or_miss &  dcache_hsel)}} & {                         dcache_wdata[15:0],dcache_sram_rdata[47:0]}) |
({64{(dcache_len4 & dcache_bytesel_00 & dcache_hit_or_miss & ~dcache_hsel)}} & {dcache_sram_rdata[63:32],dcache_wdata[31:0]                        }) |
({64{(dcache_len4 & dcache_bytesel_00 & dcache_hit_or_miss &  dcache_hsel)}} & {                         dcache_wdata[31:0],dcache_sram_rdata[31:0]}) ;
assign write_miss_sram_data = 
({64{(dcache_len1 & dcache_bytesel_00 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],dcache_rdata_sel[31: 8],dcache_wdata[7:0]                }) |
({64{(dcache_len1 & dcache_bytesel_01 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],dcache_rdata_sel[31:16],dcache_wdata[7:0],dcache_rdata_sel[ 7:0]}) |
({64{(dcache_len1 & dcache_bytesel_10 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],dcache_rdata_sel[31:24],dcache_wdata[7:0],dcache_rdata_sel[15:0]}) |
({64{(dcache_len1 & dcache_bytesel_11 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],                 dcache_wdata[7:0],dcache_rdata_sel[23:0]}) |
({64{(dcache_len1 & dcache_bytesel_00 &  dcache_msel)}} & {dcache_rdata_sel[31: 8],dcache_wdata[7:0],                dcache_sram_rdata[31: 0]}) |
({64{(dcache_len1 & dcache_bytesel_01 &  dcache_msel)}} & {dcache_rdata_sel[31:16],dcache_wdata[7:0],dcache_rdata_sel[7:0] ,dcache_sram_rdata[31: 0]}) |
({64{(dcache_len1 & dcache_bytesel_10 &  dcache_msel)}} & {dcache_rdata_sel[31:24],dcache_wdata[7:0],dcache_rdata_sel[15:0],dcache_sram_rdata[31: 0]}) |
({64{(dcache_len1 & dcache_bytesel_11 &  dcache_msel)}} & {                 dcache_wdata[7:0],dcache_rdata_sel[23:0],dcache_sram_rdata[31: 0]}) |
({64{(dcache_len2 & dcache_bytesel_00 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],dcache_rdata_sel[31:16],dcache_wdata[15:0]               }) |
({64{(dcache_len2 & dcache_bytesel_10 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],                dcache_wdata[15:0],dcache_rdata_sel[15:0]}) |
({64{(dcache_len2 & dcache_bytesel_00 &  dcache_msel)}} & {                dcache_rdata_sel[31:16],dcache_wdata[15:0],dcache_sram_rdata[31:0]}) |
({64{(dcache_len2 & dcache_bytesel_10 &  dcache_msel)}} & {                dcache_wdata[15: 0],dcache_rdata_sel[15:0],dcache_sram_rdata[31:0]}) |
({64{(dcache_len4 & dcache_bytesel_00 & ~dcache_msel)}} & {dcache_sram_rdata[63:32],dcache_wdata[31:0]}                                ) |
({64{(dcache_len4 & dcache_bytesel_00 &  dcache_msel)}} & {dcache_wdata[31:0],dcache_sram_rdata[31:0]});

reg dcache_reset_sync1;
reg dcache_reset_sync2;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    dcache_reset_sync1 <= 1'b1;
    dcache_reset_sync2 <= 1'b1;
  end else begin
    dcache_reset_sync1 <= 1'b0;
    dcache_reset_sync2 <= dcache_reset_sync1;
  end
end

always@(posedge clock) begin
  if(dcache_reset_sync2)begin
    for(int i = 0;i < CACHE_SIZE; i = i + 1)begin
      for(int j = 0; j < CACHE_WAY; j = j + 1)begin
        dcache_extend[i][j] <= 0;
      end
    end
  end
  else if(dcache_read_hit & state_r[STATE_VALD_BIT]) begin
      dcache_extend[dcache_index][dcache_hsel][3:0] <= 4'b0;
      dcache_extend[dcache_index][~dcache_hsel][3:0] <= (dcache_extend[dcache_index][~dcache_hsel][3:0] == 4'b1111) ? 4'b1111 : (dcache_extend[dcache_index][~dcache_hsel][3:0] + 1);
  end
  else if(dcache_write_hit & state_r[STATE_VALD_BIT]) begin
      dcache_extend[dcache_index][dcache_hsel] <= {dcache_tag,5'b10000};
      dcache_extend[dcache_index][~dcache_hsel][3:0] <= dcache_extend[dcache_index][~dcache_hsel][3:0]+1;
  end
  else if(dcache_write_miss & state_r[STATE_VALD_BIT]) begin
    dcache_extend[dcache_index][dcache_msel] <= {dcache_tag,5'b10000};
    dcache_extend[dcache_index][~dcache_msel][3:0] <= dcache_extend[dcache_index][~dcache_msel][3:0]+1;
  end
  else if(dcache_write_miss_wb & dcache_axi_bvalid) begin
    dcache_extend[dcache_index][dcache_msel] <= {dcache_tag,5'b10000};
    dcache_extend[dcache_index][~dcache_msel][3:0] <= dcache_extend[dcache_index][~dcache_msel][3:0]+1;
  end
  else if(dcache_axi_rvalid & (dcache_write_miss_rd | dcache_write_miss_wbrd)) begin
    dcache_extend[dcache_index][dcache_msel] <= {dcache_tag,5'b10000};
    dcache_extend[dcache_index][~dcache_msel][3:0] <= dcache_extend[dcache_index][~dcache_msel][3:0]+1;
  end
  else if(dcache_axi_rvalid & (dcache_read_miss | dcache_read_miss_wb)) begin
    dcache_extend[dcache_index][dcache_msel] <= {dcache_tag,5'b00000};
    dcache_extend[dcache_index][~dcache_msel][3:0] <= dcache_extend[dcache_index][~dcache_msel][3:0]+1;
  end
end

// ================================================================================================================================================
// REQ/RSP CHANNEL
// ================================================================================================================================================
assign lsu_rsp_mmio = (dcache_addr[31:28] != 4'b1000);//DPI-C
assign lsu_rsp_fencei_over = lsu_rsp_valid & dcache_fencei;

assign dcache_req_ready = state_r[STATE_IDLE_BIT];
assign dcache_rsp_valid = state_r[STATE_VALD_BIT]| 
(state_r[STATE_BUSY_BIT] & (
(dcache_axi_read  & (state_rr[STATER_R_BIT] & dcache_axi_rvalid)) |
(dcache_axi_write & (state_wr[STATEW_B_BIT] & dcache_axi_bvalid)) |
(dcache_axi_wbrd  & (state_rr[STATER_R_BIT] & dcache_axi_rvalid)  & (state_wr[STATEW_B_BIT] & dcache_axi_bvalid)) |
(dcache_axi_sync  & sync_finish)));
assign dcache_rsp_rdata = 
({`XLEN{dcache_flag_010                    }} & dcache_rdata_sel               )                      |
({`XLEN{dcache_flag_101 & dcache_bytesel_00}} & {16'b0,dcache_rdata_sel[15: 0]})                      |
({`XLEN{dcache_flag_101 & dcache_bytesel_10}} & {16'b0,dcache_rdata_sel[31:16]})                      |
({`XLEN{dcache_flag_001 & dcache_bytesel_00}} & {{16{dcache_rdata_sel[15]}},dcache_rdata_sel[15: 0]}) |
({`XLEN{dcache_flag_001 & dcache_bytesel_10}} & {{16{dcache_rdata_sel[31]}},dcache_rdata_sel[31:16]}) |
({`XLEN{dcache_flag_100 & dcache_bytesel_00}} & {24'b0,dcache_rdata_sel[ 7: 0]})                      |
({`XLEN{dcache_flag_100 & dcache_bytesel_01}} & {24'b0,dcache_rdata_sel[15: 8]})                      |
({`XLEN{dcache_flag_100 & dcache_bytesel_10}} & {24'b0,dcache_rdata_sel[23:16]})                      |
({`XLEN{dcache_flag_100 & dcache_bytesel_11}} & {24'b0,dcache_rdata_sel[31:24]})                      |
({`XLEN{dcache_flag_000 & dcache_bytesel_00}} & {{24{dcache_rdata_sel[7 ]}},dcache_rdata_sel[ 7: 0]}) |
({`XLEN{dcache_flag_000 & dcache_bytesel_01}} & {{24{dcache_rdata_sel[15]}},dcache_rdata_sel[15: 8]}) |
({`XLEN{dcache_flag_000 & dcache_bytesel_10}} & {{24{dcache_rdata_sel[23]}},dcache_rdata_sel[23:16]}) |
({`XLEN{dcache_flag_000 & dcache_bytesel_11}} & {{24{dcache_rdata_sel[31]}},dcache_rdata_sel[31:24]}) ;

assign dcache_rsp_ready = dcache_vpu ? vpu_rsp_ready : lsu_rsp_ready;
assign lsu_rsp_valid = dcache_rsp_valid & ~dcache_vpu;
assign vpu_rsp_valid = dcache_rsp_valid &  dcache_vpu;
assign lsu_req_ready = dcache_req_ready;
assign vpu_req_ready = dcache_req_ready & ~lsu_req_valid;
assign lsu_rsp_rdata = dcache_rsp_rdata;
assign vpu_rsp_rdata = dcache_rsp_rdata;
wire unused_ok = &{dcache_axi_bresp};
// ================================================================================================================================================
// DCACHE DPIC_COUNT
// ================================================================================================================================================
`ifdef DPIC_VALID
  wire unused_ok = &{dcache_axi_rdata[63:32]};
  wire [`XLEN-1:0] hit_count;
  wire [`XLEN-1:0] miss_count;
  wire hit_ena  = lsu_req_sh & lsu_req_hit_or_miss;
  wire miss_ena = lsu_req_sh & ~lsu_req_hit_or_miss;
  lieat_general_dfflr #(`XLEN) hit_count_dff(clock,reset,hit_ena,hit_count+1'b1,hit_count);
  lieat_general_dfflr #(`XLEN) miss_count_dff(clock,reset,miss_ena,miss_count+1'b1,miss_count);
  import "DPI-C" function void dcache_dpic(input int hit_count,input int miss_count);
  always @(posedge clock or posedge reset) dcache_dpic(hit_count,miss_count);
`endif
endmodule
