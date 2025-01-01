module lieat_exu_vpu_vlsu(
  input                           clock,
  input                           reset,
  input                           flush_req,

  input                           vlsu_i_valid,
  output                          vlsu_i_ready,
  input  [`REG_IDX-1:0]           vlsu_i_rd,
  input  [`XLEN-1:0]              vlsu_i_src1,
  input  [`XLEN-1:0]              vlsu_i_pc,
  input  [`INFOBUS_VPU_WIDTH-1:0] vlsu_i_infobus,
  
  input  [      4:0]              vlsu_vl,
  input  [`XLEN-1:0]              vlsu_mask,//v0.t
  output [`REG_IDX-1:0]           vlsu_vs2,
  output [`REG_IDX-1:0]           vlsu_vs3,
  input  [`XLEN-1:0]              vlsu_vsrc2,
  input  [`XLEN-1:0]              vlsu_vsrc3,

  output                          vlsu_req_valid,
  input                           vlsu_req_ready,
  output                          vlsu_req_ren,
  output                          vlsu_req_wen,
  output [`XLEN-1:0]              vlsu_req_addr,
  output [2:0]                    vlsu_req_flag,
  output [`XLEN-1:0]              vlsu_req_wdata,
  input                           vlsu_rsp_valid,
  output                          vlsu_rsp_ready,
  input  [`XLEN-1:0]              vlsu_rsp_rdata,
  
  output                          vlsu_o_valid,
  input                           vlsu_o_ready,
  output                          vlsu_o_flush,
  output [`XLEN-1:0]              vlsu_o_pc,
  output                          vlsu_o_vwen,
  output [`REG_IDX-1:0]           vlsu_o_rd,
  output [`XLEN-1:0]              vlsu_o_data,
  output [      3:0]              vlsu_o_mask
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
localparam                    STATE_IDE = 5'b00001;
localparam                    STATE_PRE = 5'b00010;
localparam                    STATE_REQ = 5'b00100;
localparam                    STATE_RSP = 5'b01000;
localparam                    STATE_VLD = 5'b10000;
localparam                    STATE_IDE_BIT = 0;
localparam                    STATE_PRE_BIT = 1;
localparam                    STATE_REQ_BIT = 2;
localparam                    STATE_RSP_BIT = 3;
localparam                    STATE_VLD_BIT = 4;

wire                          vlsu_req_sh;
wire                          vlsu_rsp_sh;
wire                          vlsu_i_sh;
wire                          vlsu_o_sh;

reg [4:0]                     vlsu_state;
reg [4:0]                     vlsu_state_nxt;
reg [7:0]                     vlsu_cyclesel;//08 04 02 01
reg [7:0]                     vlsu_cyclesel_nxt;//08 04 02 01
wire                          vlsu_last_cycle;

wire                          vlsu_flush_ena;
wire [31:0]                   vlsu_pc;
wire [`INFOBUS_VPU_WIDTH-1:0] vlsu_infobus;
wire [4:0]                    vlsu_o_rd_nxt;
wire [31:0]                   vlsu_req_addr_nxt;

wire                          vlsu_load;
wire                          vlsu_store;
wire                          vlsu_unitstrd;
wire                          vlsu_consstrd;
wire                          vlsu_unoridx;
wire                          vlsu_orderidx;
wire                          vlsu_maskunit;
wire                          vlsu_fofload;
wire                          vlsu_wholereg;
wire                          vlsu_vm;
wire                          vlsu_noseg;
wire [2:0]                    vlsu_nf;

wire [2:0]                    vlsu_sizesel;//32 16 08
wire [31:0]                   vlsu_masksel;
wire                          vlsu_size_32;
wire                          vlsu_size_16;
wire                          vlsu_size_08;

wire unused_ok = &{vlsu_unitstrd,vlsu_consstrd,vlsu_unoridx,vlsu_orderidx,vlsu_maskunit,vlsu_fofload,vlsu_wholereg,vlsu_noseg,vlsu_nf,vlsu_vsrc2,vlsu_infobus,vlsu_i_src1};
// ================================================================================================================================================
// INPUT
// ================================================================================================================================================
assign vlsu_req_sh = vlsu_req_valid & vlsu_req_ready;
assign vlsu_rsp_sh = vlsu_rsp_valid & vlsu_rsp_ready;
assign vlsu_i_sh = vlsu_i_valid & vlsu_i_ready;
assign vlsu_o_sh = vlsu_o_valid & vlsu_o_ready;

lieat_general_dfflr #(1)        lsu_flush_ena_dff(clock,reset,1'b1,vlsu_i_sh,vlsu_flush_ena);
assign vlsu_o_flush = flush_req & vlsu_flush_ena;

lieat_general_dfflr #(`XLEN)    vlsu_pc_dff(clock,reset,vlsu_i_sh,vlsu_i_pc,vlsu_pc);
lieat_general_dfflr #(`INFOBUS_VPU_WIDTH) vlsu_infobus_dff(clock,reset,vlsu_i_sh,vlsu_i_infobus,vlsu_infobus);

always @(*) begin
  case(vlsu_state)
    STATE_IDE:vlsu_state_nxt = {
    3'b0,
    vlsu_i_sh,
    ~vlsu_i_sh
    };
    STATE_PRE:vlsu_state_nxt = {
    2'b0,
    ~vlsu_o_flush,
    1'b0,
    vlsu_o_flush
    };
    STATE_REQ:vlsu_state_nxt = {
    1'b0,
    vlsu_req_sh,
    ~vlsu_req_sh,
    2'b0
    };
    STATE_RSP:vlsu_state_nxt = {
    vlsu_req_sh & vlsu_last_cycle & ~vlsu_o_ready,
    ~vlsu_rsp_sh,
    vlsu_rsp_sh & ~vlsu_last_cycle,
    vlsu_rsp_sh & vlsu_o_sh &  vlsu_i_sh,
    vlsu_rsp_sh & vlsu_o_sh & ~vlsu_i_sh
    };
    STATE_VLD:vlsu_state_nxt = {
    ~vlsu_o_sh,
    2'b0,
    vlsu_o_sh & vlsu_i_sh,
    vlsu_o_sh & ~vlsu_i_sh
    };
    default:vlsu_state_nxt = STATE_IDE;
  endcase
end
assign vlsu_cyclesel_nxt = vlsu_state[STATE_PRE_BIT] ? {
(vlsu_size_32 & (vlsu_vl == 5'b00111)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0111)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b111)),
(vlsu_size_32 & (vlsu_vl == 5'b00110)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0110)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b110)),
(vlsu_size_32 & (vlsu_vl == 5'b00101)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0101)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b101)),
(vlsu_size_32 & (vlsu_vl == 5'b00100)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0100)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b100)),
(vlsu_size_32 & (vlsu_vl == 5'b00011)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0011)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b011)),
(vlsu_size_32 & (vlsu_vl == 5'b00010)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0010)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b010)),
(vlsu_size_32 & (vlsu_vl == 5'b00001)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0001)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b001)),
(vlsu_size_32 & (vlsu_vl == 5'b00000)) | (vlsu_size_16 & (vlsu_vl[4:1] == 4'b0000)) | (vlsu_size_08 & (vlsu_vl[4:2] == 3'b000))
}
 : {1'b0,vlsu_cyclesel[7:1]};
lieat_general_dffrd #(.DW(5),.DEFAULT(STATE_IDE)) vlsu_state_dff(clock,reset,vlsu_state_nxt,vlsu_state);
lieat_general_dfflr #(8) vlsu_cyclesel_dff(clock,reset,vlsu_state[STATE_PRE_BIT] | vlsu_rsp_sh,vlsu_cyclesel_nxt,vlsu_cyclesel);
assign vlsu_last_cycle = vlsu_cyclesel[0];
// ================================================================================================================================================

// MAIN
// ================================================================================================================================================
assign vlsu_load     = vlsu_infobus[`INFOBUS_VLSU_LOAD    ];
assign vlsu_store    = vlsu_infobus[`INFOBUS_VLSU_STORE   ];
assign vlsu_unitstrd = vlsu_infobus[`INFOBUS_VLSU_UNITSTRD];
assign vlsu_consstrd = vlsu_infobus[`INFOBUS_VLSU_CONSSTRD];
assign vlsu_unoridx  = vlsu_infobus[`INFOBUS_VLSU_UNORIDX ];
assign vlsu_orderidx = vlsu_infobus[`INFOBUS_VLSU_ORDERIDX];
assign vlsu_maskunit = vlsu_infobus[`INFOBUS_VLSU_MSKUNIT ];
assign vlsu_fofload  = vlsu_infobus[`INFOBUS_VLSU_FOFLOAD ];
assign vlsu_wholereg = vlsu_infobus[`INFOBUS_VLSU_WHOLEREG];
assign vlsu_vm       = vlsu_infobus[`INFOBUS_VLSU_VM      ];
assign vlsu_noseg    = vlsu_infobus[`INFOBUS_VLSU_NOSEG   ];
assign vlsu_nf       = vlsu_infobus[`INFOBUS_VLSU_NF      ];

assign vlsu_masksel = ({`XLEN{vlsu_vm}} | vlsu_mask) & (32'hFFFFFFFF >> (5'b11111 - vlsu_vl));
assign vlsu_sizesel = vlsu_infobus[`INFOBUS_VLSU_SIZE];
assign vlsu_size_32 = vlsu_sizesel[2];
assign vlsu_size_16 = vlsu_sizesel[1];
assign vlsu_size_08 = vlsu_sizesel[0];
// ================================================================================================================================================
// REQ OR RSP
// ================================================================================================================================================
assign vlsu_vs2 = 5'b0;
assign vlsu_vs3 = vlsu_o_rd;

assign vlsu_req_valid   = vlsu_state[STATE_REQ_BIT];
assign vlsu_req_addr_nxt= vlsu_i_sh ? vlsu_i_src1 : {vlsu_req_addr + 32'h4};
lieat_general_dfflr #(`XLEN) vlsu_req_addr_dff(clock,reset,vlsu_i_sh | vlsu_req_sh,vlsu_req_addr_nxt,vlsu_req_addr);
assign vlsu_req_ren     = vlsu_load;
assign vlsu_req_wen     = vlsu_store;
assign vlsu_req_flag    = 3'b010;
assign vlsu_req_wdata   = vlsu_vsrc3;
assign vlsu_rsp_ready   = vlsu_o_ready;
// ================================================================================================================================================
// OUTPUT SIGNAL
// ================================================================================================================================================
assign vlsu_i_ready     = vlsu_state[STATE_IDE_BIT] | vlsu_o_sh;

assign vlsu_o_valid = vlsu_state[STATE_VLD_BIT] | (vlsu_state[STATE_RSP_BIT] & vlsu_rsp_valid & vlsu_last_cycle);
assign vlsu_o_pc        = vlsu_pc;
assign vlsu_o_data      = vlsu_rsp_rdata;
assign vlsu_o_vwen      = vlsu_load & vlsu_rsp_valid;
assign vlsu_o_rd_nxt    = vlsu_i_sh ? vlsu_i_rd : {vlsu_o_rd + 5'b1};
lieat_general_dfflr #(5) vlsu_o_rd_dff(clock,reset,vlsu_i_sh | vlsu_rsp_sh,vlsu_o_rd_nxt,vlsu_o_rd);

assign vlsu_o_mask      = 
({4{vlsu_cyclesel[7]}} & (({4{vlsu_size_32 & vlsu_masksel[7]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[15],vlsu_masksel[15],vlsu_masksel[14],vlsu_masksel[14]}) | ({4{vlsu_size_08}} & {vlsu_masksel[31],vlsu_masksel[30],vlsu_masksel[29],vlsu_masksel[28]})))|
({4{vlsu_cyclesel[6]}} & (({4{vlsu_size_32 & vlsu_masksel[6]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[13],vlsu_masksel[13],vlsu_masksel[12],vlsu_masksel[12]}) | ({4{vlsu_size_08}} & {vlsu_masksel[27],vlsu_masksel[26],vlsu_masksel[25],vlsu_masksel[24]})))|
({4{vlsu_cyclesel[5]}} & (({4{vlsu_size_32 & vlsu_masksel[5]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[11],vlsu_masksel[11],vlsu_masksel[10],vlsu_masksel[10]}) | ({4{vlsu_size_08}} & {vlsu_masksel[23],vlsu_masksel[22],vlsu_masksel[21],vlsu_masksel[20]})))|
({4{vlsu_cyclesel[4]}} & (({4{vlsu_size_32 & vlsu_masksel[4]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[ 9],vlsu_masksel[ 9],vlsu_masksel[ 8],vlsu_masksel[ 8]}) | ({4{vlsu_size_08}} & {vlsu_masksel[19],vlsu_masksel[18],vlsu_masksel[17],vlsu_masksel[16]})))|
({4{vlsu_cyclesel[3]}} & (({4{vlsu_size_32 & vlsu_masksel[3]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[ 7],vlsu_masksel[ 7],vlsu_masksel[ 6],vlsu_masksel[ 6]}) | ({4{vlsu_size_08}} & {vlsu_masksel[15],vlsu_masksel[14],vlsu_masksel[13],vlsu_masksel[12]})))|
({4{vlsu_cyclesel[2]}} & (({4{vlsu_size_32 & vlsu_masksel[2]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[ 5],vlsu_masksel[ 5],vlsu_masksel[ 4],vlsu_masksel[ 4]}) | ({4{vlsu_size_08}} & {vlsu_masksel[11],vlsu_masksel[10],vlsu_masksel[ 9],vlsu_masksel[ 8]})))|
({4{vlsu_cyclesel[1]}} & (({4{vlsu_size_32 & vlsu_masksel[1]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[ 3],vlsu_masksel[ 3],vlsu_masksel[ 2],vlsu_masksel[ 2]}) | ({4{vlsu_size_08}} & {vlsu_masksel[ 7],vlsu_masksel[ 6],vlsu_masksel[ 5],vlsu_masksel[ 4]})))|
({4{vlsu_cyclesel[0]}} & (({4{vlsu_size_32 & vlsu_masksel[0]}}) | ({4{vlsu_size_16}} & {vlsu_masksel[ 1],vlsu_masksel[ 1],vlsu_masksel[ 0],vlsu_masksel[ 0]}) | ({4{vlsu_size_08}} & {vlsu_masksel[ 3],vlsu_masksel[ 2],vlsu_masksel[ 1],vlsu_masksel[ 0]})));

endmodule
