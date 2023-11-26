module rvh_l1d_ptw_replay_buffer
  import riscv_pkg::*;
  import rvh_pkg::*;
  import uop_encoding_pkg::*;
  import rvh_l1d_pkg::*;
#(
  parameter int unsigned REPLAY_LATENCY = 4
)
(
  input  logic                          ptw_walk_req_vld_i,
  input  logic [      PTW_ID_WIDTH-1:0] ptw_walk_req_id_i,
  input  logic [       PADDR_WIDTH-1:0] ptw_walk_req_addr_i,

  input  logic                          ptw_walk_resp_vld_i,
  input  logic                          ptw_walk_resp_rdy_i,

  input  logic                          stb_l1d_ptw_replay_vld_i,

  output logic                          ptw_walk_replay_req_vld_o,
  output logic [PTW_ID_WIDTH-1:0]       ptw_walk_replay_req_id_o,
  output logic [PADDR_WIDTH-1:0 ]       ptw_walk_replay_req_paddr_o,
  input  logic                          ptw_walk_replay_req_rdy_i,

  input  logic                          clk,
  input  logic                          rst
 );

// replay buffer for ptw req
// replay when the ptw req partial hit in the stb, and the stb needs to evict that stb entry to cache
ptw_req_buffer_t ptw_req_buffer, ptw_req_buffer_nxt;
logic            ptw_req_buffer_ena;
logic            ptw_req_buffer_valid, ptw_req_buffer_valid_nxt;
logic            ptw_req_buffer_valid_set, ptw_req_buffer_valid_clr, ptw_req_buffer_valid_ena;
logic            ptw_req_buffer_replay_pending, ptw_req_buffer_replay_pending_nxt;
logic            ptw_req_buffer_replay_pending_set, ptw_req_buffer_replay_pending_clr, ptw_req_buffer_replay_pending_ena;

logic [$clog2(REPLAY_LATENCY)-1:0] replay_counter, replay_counter_nxt;
logic                              replay_counter_ena;

// next states
assign ptw_req_buffer_valid_set = ptw_walk_req_vld_i; // alloc when new ptw req in
assign ptw_req_buffer_valid_clr = ptw_walk_resp_vld_i & ptw_walk_resp_rdy_i; // dealloc when the ptw resp
assign ptw_req_buffer_valid_ena = ptw_req_buffer_valid_set | ptw_req_buffer_valid_clr;

assign ptw_req_buffer_valid_nxt = ptw_req_buffer_valid_clr  ? 1'b0 : // dealloc when the ptw resp
                                  ptw_req_buffer_valid_set  ? 1'b1 : // alloc when new ptw req in
                                                              ptw_req_buffer_valid;

std_dffre
#(.WIDTH($bits(ptw_req_buffer_valid)))
U_PTW_REQ_BUFFER_VALID
(
  .clk(clk),
  .rstn(rst),
  .en(ptw_req_buffer_valid_ena),
  .d(ptw_req_buffer_valid_nxt),
  .q(ptw_req_buffer_valid)
);


assign ptw_req_buffer_replay_pending_set = stb_l1d_ptw_replay_vld_i; // set when replay req comes
assign ptw_req_buffer_replay_pending_clr = (ptw_walk_replay_req_vld_o & ptw_walk_replay_req_rdy_i) | ptw_req_buffer_valid_clr; // clr when replay issued or entry invalided
assign ptw_req_buffer_replay_pending_ena = ptw_req_buffer_replay_pending_set | ptw_req_buffer_replay_pending_clr;

assign ptw_req_buffer_replay_pending_nxt = ptw_req_buffer_replay_pending_set ? 1'b1 :
                                           ptw_req_buffer_replay_pending_clr ? 1'b0 :
                                                                               ptw_req_buffer_replay_pending;

std_dffre
#(.WIDTH($bits(ptw_req_buffer_replay_pending)))
U_PTW_REQ_BUFFER_REPLAY_PENDING
(
  .clk(clk),
  .rstn(rst),
  .en(ptw_req_buffer_replay_pending_ena),
  .d(ptw_req_buffer_replay_pending_nxt),
  .q(ptw_req_buffer_replay_pending)
);

assign ptw_req_buffer_nxt.id    = ptw_walk_req_id_i;
assign ptw_req_buffer_nxt.paddr = ptw_walk_req_addr_i;
assign ptw_req_buffer_ena       = ptw_req_buffer_valid_set;

std_dffe
#(.WIDTH($bits(ptw_req_buffer_t)))
U_PTW_REQ_BUFFER
(
  .clk(clk),
  .en(ptw_req_buffer_ena),
  .d(ptw_req_buffer_nxt),
  .q(ptw_req_buffer)
);


// replay output
assign replay_counter_nxt = replay_counter + 1;
assign replay_counter_ena = ptw_req_buffer_valid & ptw_req_buffer_replay_pending;

std_dffre
#(.WIDTH($clog2(REPLAY_LATENCY)))
U_REPLAY_COUNTER
(
  .clk(clk),
  .rstn(rst),
  .en(replay_counter_ena),
  .d(replay_counter_nxt),
  .q(replay_counter)
);

assign ptw_walk_replay_req_vld_o    = ptw_req_buffer_valid & ptw_req_buffer_replay_pending & (replay_counter == (REPLAY_LATENCY-1));
assign ptw_walk_replay_req_id_o     = ptw_req_buffer.id;
assign ptw_walk_replay_req_paddr_o  = ptw_req_buffer.paddr;

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) (stb_l1d_ptw_replay_vld_i)|-> ptw_req_buffer_valid)
    else $fatal("ptw buffer: set replay pending to a invalid buffer entry");
`endif

endmodule