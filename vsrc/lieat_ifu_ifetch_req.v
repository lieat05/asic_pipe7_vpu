module lieat_ifu_ifetch_req(
  input              clock,
  input              reset,

  input              req_i_flush,
  input [`XLEN-1:0]  req_i_flush_pc,

  input              req_i_valid,//rsp always ready
  input [`XLEN-1:0]  req_i_pc,
  input              req_i_bxx,
  input              req_i_jal,
  input              req_i_rs1en,
  input              req_i_rs1dep,
  input              req_i_bxx_taken,
  input [`XLEN-1:0]  req_i_src1,
  input [`XLEN-1:0]  req_i_immb,
  input              req_i_fencei,
  input              req_i_nojump,
  input              req_i_fencei_over,

  input              req_o_ready,
  output             req_o_valid,
  output [`XLEN-1:0] req_o_pc
);
// ================================================================================================================================================
// SIGNAL LIST
// ================================================================================================================================================
wire             req_o_sh   = req_o_valid & req_o_ready;
wire             rst_req;
wire             rst_flag;
wire             flush_req;
wire             ifetch_req;

wire [`XLEN-1:0] ifetch_pc;
wire [`XLEN-1:0] pc_wait;
wire [`XLEN-1:0] pc_nowait;
wire [`XLEN-1:0] pc_wait_nxt;

wire             fencei_need_wait;
wire             fencei_need_wait_r;
// ================================================================================================================================================
// STATE CONTROL
// ================================================================================================================================================
localparam STATE_IDLE = 3'b001;
localparam STATE_WAIT = 3'b010;
localparam STATE_VALD = 3'b100;

wire      ifetch_nowait = req_i_valid & req_i_nojump;
reg [2:0] ifetch_state_r;
reg [2:0] ifetch_state_nxt;

always @(*) begin
  case(ifetch_state_r)
    STATE_IDLE: ifetch_state_nxt = {
    ~flush_req & req_i_valid & (req_i_bxx | req_i_jal | (req_i_rs1en & ~req_i_rs1dep)),
    ~flush_req & req_i_valid & req_i_rs1en & req_i_rs1dep,
    flush_req | ~req_i_valid | (req_i_valid & ~req_i_bxx & ~req_i_rs1en & ~req_i_jal)
    };
    STATE_WAIT: ifetch_state_nxt = {
    ~flush_req & ~req_i_rs1dep,
    ~flush_req &  req_i_rs1dep,
    flush_req
    };
    STATE_VALD: ifetch_state_nxt = 3'b001;
    default:ifetch_state_nxt = STATE_IDLE;
  endcase
end
lieat_general_dfflr #(3) ifetch_state_dff(clock,reset,1'b1,ifetch_state_nxt,ifetch_state_r);

lieat_general_dfflr  #(1) rst_req_dff(clock,reset,1'b1,1'b1,rst_req);
lieat_general_dfflrs #(1) rst_flag_dff(clock,reset,req_o_sh,1'b0,rst_flag);

assign flush_req    = req_i_flush;
assign ifetch_req   = (ifetch_nowait & ~fencei_need_wait) | ifetch_state_r[2] | req_i_fencei_over;
assign req_o_valid  = (ifetch_req | (rst_req & rst_flag) | flush_req);

wire fencei_need_wait_set = req_i_valid & req_i_fencei;
wire fencei_need_wait_clr = req_i_fencei_over | flush_req;//fencei finish
wire fencei_need_wait_ena = fencei_need_wait_set |  fencei_need_wait_clr;
wire fencei_need_wait_nxt = fencei_need_wait_set | ~fencei_need_wait_clr;
lieat_general_dfflr #(1) fencei_need_wait_r_dff(clock,reset,fencei_need_wait_ena,fencei_need_wait_nxt,fencei_need_wait_r);
assign fencei_need_wait = req_i_fencei | fencei_need_wait_r;
// ================================================================================================================================================
// AGU
// ================================================================================================================================================                               
lieat_general_dfflr #(32) pc_wait_dff(clock,reset,1'b1,pc_wait_nxt,pc_wait);
assign pc_nowait          = req_i_pc + 32'h4;
assign pc_wait_nxt        = (~req_i_bxx_taken & req_i_bxx) ? ((req_i_rs1en ? req_i_src1 : req_i_pc) + 32'h4) : (req_i_rs1en ? req_i_src1 : req_i_pc) + req_i_immb;
assign ifetch_pc          = ifetch_state_r[2] ? pc_wait : pc_nowait;
assign req_o_pc           = req_i_flush ? req_i_flush_pc : ifetch_req ? ifetch_pc : `PC_DEFAULT;
endmodule
