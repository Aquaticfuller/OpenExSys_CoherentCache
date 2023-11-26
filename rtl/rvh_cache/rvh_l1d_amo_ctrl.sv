module rvh_l1d_amo_ctrl
import riscv_pkg::*;
import rvh_pkg::*;
import uop_encoding_pkg::*;
import rvh_l1d_pkg::*;
#(
  parameter int unsigned N_STB_ST_IN_PORT  = 2
)
(
  // input st req from lsu
  input  logic [N_STB_ST_IN_PORT-1:0]                         ls_pipe_amo_ctrl_st_req_vld_i,
  input  logic [N_STB_ST_IN_PORT-1:0]                         ls_pipe_amo_ctrl_st_req_is_fence_i,
  input  logic [N_STB_ST_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_amo_ctrl_st_req_rob_tag_i,
  input  logic [N_STB_ST_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_amo_ctrl_st_req_prd_i,
  input  logic [N_STB_ST_IN_PORT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_amo_ctrl_st_req_opcode_i,
  input  logic [N_STB_ST_IN_PORT-1:0][       PADDR_WIDTH-1:0] ls_pipe_amo_ctrl_st_req_paddr_i,
  input  logic [N_STB_ST_IN_PORT-1:0][              XLEN-1:0] ls_pipe_amo_ctrl_st_req_data_i,
`ifdef RUBY
  input  logic [N_STB_ST_IN_PORT-1:0][RRV64_LSU_ID_WIDTH-1:0] ls_pipe_amo_ctrl_st_req_lsu_tag_i,
`endif
  output logic [N_STB_ST_IN_PORT-1:0]                         ls_pipe_amo_ctrl_st_req_rdy_o,

  // output st req to stb
  output logic [N_STB_ST_IN_PORT-1:0]                         amo_ctrl_stb_st_req_vld_o,
  output logic [N_STB_ST_IN_PORT-1:0]                         amo_ctrl_stb_st_req_is_fence_o,
  output logic                                                amo_ctrl_stb_st_req_no_fence_wb_resp_o,
  output logic                                                amo_ctrl_stb_st_req_sc_rt_check_succ_o,
  output logic [N_STB_ST_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] amo_ctrl_stb_st_req_rob_tag_o,
  output logic [N_STB_ST_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] amo_ctrl_stb_st_req_prd_o,
  output logic [N_STB_ST_IN_PORT-1:0][      STU_OP_WIDTH-1:0] amo_ctrl_stb_st_req_opcode_o,
  output logic [N_STB_ST_IN_PORT-1:0][       PADDR_WIDTH-1:0] amo_ctrl_stb_st_req_paddr_o,
  output logic [N_STB_ST_IN_PORT-1:0][              XLEN-1:0] amo_ctrl_stb_st_req_data_o,
`ifdef RUBY
  output logic [N_STB_ST_IN_PORT-1:0][RRV64_LSU_ID_WIDTH-1:0] amo_ctrl_stb_st_req_lsu_tag_o,
`endif
  input  logic [N_STB_ST_IN_PORT-1:0]                         amo_ctrl_stb_st_req_rdy_i,

  // input resp to finish the amo fsm
  input  logic [LSU_DATA_PIPE_COUNT-1:0]                      l1d_rob_wb_vld_i,
  input  logic [LSU_DATA_PIPE_COUNT-1:0][ROB_TAG_WIDTH-1:0]   l1d_rob_wb_rob_tag_i,

  // output in amo state
  output logic                                                in_amo_state_o,

//   // output amo req to l1d bank
//   output  logic                             amo_ctrl_bank_amo_req_vld_o,
//   output  logic [     ROB_TAG_WIDTH-1:0]    amo_ctrl_bank_amo_req_rob_tag_o,
//   output  logic [    PREG_TAG_WIDTH-1:0]    amo_ctrl_bank_amo_req_prd_o,
//   output  logic [      STU_OP_WIDTH-1:0]    amo_ctrl_bank_amo_req_opcode_o,
//   output  logic [       PADDR_WIDTH-1:0]    amo_ctrl_bank_amo_req_paddr_o,
//   output  logic [L1D_STB_DATA_WIDTH-1:0]    amo_ctrl_bank_amo_req_data_o,
//   output  logic [L1D_STB_DATA_WIDTH/8-1:0]  amo_ctrl_bank_amo_req_data_byte_mask_o,
// `ifdef RUBY
//   output  logic [RRV64_LSU_ID_WIDTH-1:0]    amo_ctrl_bank_amo_req_lsu_tag_o,
// `endif
//   input   logic                             amo_ctrl_bank_amo_req_rdy_i

  input logic clk,
  input logic rst
);

genvar i;

typedef enum logic[2:0] {
  IDLE,
  FLUSH_STB_1,
  REQ_BANK_SEND,
  FLUSH_STB_2,
  REQ_BANK_WAIT
} l1d_amo_ctrl_fsm_t;

typedef struct packed {
  logic [     ROB_TAG_WIDTH-1:0]  rob_tag;
  logic [    PREG_TAG_WIDTH-1:0]  prd;
  logic [      STU_OP_WIDTH-1:0]  opcode;
  logic [       PADDR_WIDTH-1:0]  paddr;
  logic [              XLEN-1:0]  data;

  logic is_lr;
  logic is_sc;
} l1d_amo_req_t;

typedef struct packed {
  logic [PADDR_WIDTH-1:0]  paddr;
} l1d_amo_reservation_table_t;

logic[N_STB_ST_IN_PORT-1:0] st_req_is_amo_req;
logic receive_amo_req_hsk;
logic send_stb_req_hsk;
logic bank_amo_resp_vld;

logic send_stb_flush_req_vld;
logic send_amo_req_vld;
logic waiting_for_amo_resp;

l1d_amo_ctrl_fsm_t amo_ctrl_fsm_state_d, amo_ctrl_fsm_state_q;
logic amo_ctrl_fsm_state_ena;

l1d_amo_req_t amo_req_d, amo_req_q;
logic amo_req_ena;

logic reservation_table_valid_d, reservation_table_valid_q;
logic reservation_table_valid_clr, reservation_table_valid_set;
logic reservation_table_valid_ena;
l1d_amo_reservation_table_t reservation_table_d, reservation_table_q;
logic reservation_table_ena;

generate
  for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_is_amo_req
    assign st_req_is_amo_req[i] =
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_LRW      ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_LRD      ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_SCW      ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_SCD      ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOSWAPW ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOSWAPD ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOADDW  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOADDD  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOANDW  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOANDD  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOORW   ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOORD   ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOXORW  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOXORD  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMAXW  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMAXD  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMAXUW ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMAXUD ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMINW  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMIND  ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMINUW ) |
        (ls_pipe_amo_ctrl_st_req_opcode_i[i] == STU_AMOMINUD ) ;
  end
endgenerate

// 1 for common st req, forward to stb
// 2 for amo req, use amo_req_ena_q
assign amo_ctrl_stb_st_req_no_fence_wb_resp_o = in_amo_state_o; // amo flush no need resp rob
generate
  for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_amo_ctrl_stb_st_req
    if(i == 0) begin: gen_is_amo_req_first_port
      assign amo_ctrl_stb_st_req_is_fence_o [i]  = in_amo_state_o ? send_stb_flush_req_vld :
                                                                  ls_pipe_amo_ctrl_st_req_is_fence_i[i];
      assign amo_ctrl_stb_st_req_rob_tag_o  [i]  = in_amo_state_o ? amo_req_q.rob_tag :
                                                                  ls_pipe_amo_ctrl_st_req_rob_tag_i[i];
      assign amo_ctrl_stb_st_req_prd_o      [i]  = in_amo_state_o ? amo_req_q.prd :
                                                                  ls_pipe_amo_ctrl_st_req_prd_i[i];
      assign amo_ctrl_stb_st_req_opcode_o   [i]  = in_amo_state_o ? amo_req_q.opcode :
                                                                  ls_pipe_amo_ctrl_st_req_opcode_i[i];
      assign amo_ctrl_stb_st_req_paddr_o    [i]  = in_amo_state_o ? amo_req_q.paddr :
                                                                  ls_pipe_amo_ctrl_st_req_paddr_i[i];
      assign amo_ctrl_stb_st_req_data_o     [i]  = in_amo_state_o ? amo_req_q.data :
                                                                  ls_pipe_amo_ctrl_st_req_data_i[i];
`ifdef RUBY
      assign amo_ctrl_stb_st_req_lsu_tag_o  [i]  = ls_pipe_amo_ctrl_st_req_lsu_tag_i[i];
`endif
    end else begin: gen_is_amo_req_other_port
      assign amo_ctrl_stb_st_req_is_fence_o [i]  = ls_pipe_amo_ctrl_st_req_is_fence_i[i];
      assign amo_ctrl_stb_st_req_rob_tag_o  [i]  = ls_pipe_amo_ctrl_st_req_rob_tag_i [i];
      assign amo_ctrl_stb_st_req_prd_o      [i]  = ls_pipe_amo_ctrl_st_req_prd_i     [i];
      assign amo_ctrl_stb_st_req_opcode_o   [i]  = ls_pipe_amo_ctrl_st_req_opcode_i  [i];
      assign amo_ctrl_stb_st_req_paddr_o    [i]  = ls_pipe_amo_ctrl_st_req_paddr_i   [i];
      assign amo_ctrl_stb_st_req_data_o     [i]  = ls_pipe_amo_ctrl_st_req_data_i    [i];
`ifdef RUBY
      assign amo_ctrl_stb_st_req_lsu_tag_o  [i]  = ls_pipe_amo_ctrl_st_req_lsu_tag_i[i];
`endif
    end
  end
endgenerate

// TODO: only for 2 port
// output valid to stb
assign amo_ctrl_stb_st_req_vld_o [0]  = ls_pipe_amo_ctrl_st_req_vld_i[0] & ~st_req_is_amo_req[0] & ~in_amo_state_o | // common st req
                                        send_stb_flush_req_vld |  // send stb flush
                                        send_amo_req_vld;         // send amo req

assign amo_ctrl_stb_st_req_vld_o [1]  = ls_pipe_amo_ctrl_st_req_vld_i[1] & ~st_req_is_amo_req[0] & ~st_req_is_amo_req[1] & ~in_amo_state_o;

// output ready to lsu
assign ls_pipe_amo_ctrl_st_req_rdy_o[0] = ~in_amo_state_o & (
                                          amo_ctrl_stb_st_req_rdy_i[0]);
assign ls_pipe_amo_ctrl_st_req_rdy_o[1] = ~in_amo_state_o & (
                                          amo_ctrl_stb_st_req_rdy_i[1] & ~st_req_is_amo_req[0] & ~st_req_is_amo_req[1] // common st req
                                          );                                                    // don't take amo req by port 1

// hand shakes
assign receive_amo_req_hsk    = ls_pipe_amo_ctrl_st_req_vld_i[0] &
                                st_req_is_amo_req[0] &
                                ls_pipe_amo_ctrl_st_req_rdy_o[0];

assign send_stb_req_hsk = amo_ctrl_stb_st_req_vld_o[0] &
                          amo_ctrl_stb_st_req_rdy_i[0];

assign bank_amo_resp_vld = l1d_rob_wb_vld_i[0] & (l1d_rob_wb_rob_tag_i[0] == amo_req_q.rob_tag);

always_comb begin
  amo_ctrl_fsm_state_d    = amo_ctrl_fsm_state_q;
  amo_ctrl_fsm_state_ena  = 1'b0;
  amo_req_ena             = 1'b0;

  in_amo_state_o            = 1'b1;
  send_stb_flush_req_vld  = 1'b0;
  send_amo_req_vld        = 1'b0;
  waiting_for_amo_resp    = 1'b0;
  case(amo_ctrl_fsm_state_q)
    IDLE: begin
      in_amo_state_o  = 1'b0;
      if(receive_amo_req_hsk) begin // receive a amo req
        amo_ctrl_fsm_state_d    = FLUSH_STB_1;
        amo_ctrl_fsm_state_ena  = 1'b1;

        amo_req_ena             = 1'b1;
      end
    end
    FLUSH_STB_1: begin
      send_stb_flush_req_vld  = 1'b1;
      if(send_stb_req_hsk) begin // send stb flush req
        amo_ctrl_fsm_state_d    = REQ_BANK_SEND;
        amo_ctrl_fsm_state_ena  = 1'b1;
      end
    end
    REQ_BANK_SEND: begin
      send_amo_req_vld = 1'b1;
      if(send_stb_req_hsk) begin
        amo_ctrl_fsm_state_d    = FLUSH_STB_2;
        amo_ctrl_fsm_state_ena  = 1'b1;
      end
    end
    FLUSH_STB_2: begin
      send_stb_flush_req_vld  = 1'b1;
      if(send_stb_req_hsk) begin
        amo_ctrl_fsm_state_d    = REQ_BANK_WAIT;
        amo_ctrl_fsm_state_ena  = 1'b1;
      end
    end
    REQ_BANK_WAIT: begin
      waiting_for_amo_resp = 1'b1;
      if(bank_amo_resp_vld) begin
        amo_ctrl_fsm_state_d    = IDLE;
        amo_ctrl_fsm_state_ena  = 1'b1;
      end
    end
    default: begin
      amo_ctrl_fsm_state_d    = IDLE;
      amo_ctrl_fsm_state_ena  = 1'b1;
    end
  endcase
end

assign amo_req_d.rob_tag = ls_pipe_amo_ctrl_st_req_rob_tag_i[0];
assign amo_req_d.prd     = ls_pipe_amo_ctrl_st_req_prd_i    [0];
assign amo_req_d.opcode  = ls_pipe_amo_ctrl_st_req_opcode_i [0];
assign amo_req_d.paddr   = ls_pipe_amo_ctrl_st_req_paddr_i  [0];
assign amo_req_d.data    = ls_pipe_amo_ctrl_st_req_data_i   [0];

assign amo_req_d.is_lr = (ls_pipe_amo_ctrl_st_req_opcode_i [0] == STU_LRW) |
                         (ls_pipe_amo_ctrl_st_req_opcode_i [0] == STU_LRD);
assign amo_req_d.is_sc = (ls_pipe_amo_ctrl_st_req_opcode_i [0] == STU_SCW) |
                         (ls_pipe_amo_ctrl_st_req_opcode_i [0] == STU_SCD);

  // fsm registers
std_dffrve
#(.WIDTH($bits(l1d_amo_ctrl_fsm_t)))
U_STA_L1D_AMO_CTRL_STATE_REG
(
  .clk(clk),
  .rstn(rst),
  .rst_val(IDLE),
  .en(amo_ctrl_fsm_state_ena),
  .d(amo_ctrl_fsm_state_d),
  .q(amo_ctrl_fsm_state_q)
);

std_dffe
#(.WIDTH($bits(l1d_amo_req_t)))
U_DAT_L1D_AMO_CTRL_REQ_REG
(
  .clk(clk),
  .en(amo_req_ena),
  .d(amo_req_d),
  .q(amo_req_q)
);


// reservation table
logic [N_STB_ST_IN_PORT-1:0] st_req_hit_rt; // st req hit valid reservation table

  // lr is failed by: 1.other store to the same cache line; TODO: 2.snoop req to the same cache line; 3.cache evict the same cache line
  // lr is cleared by any following sc
logic lr_fail_by_st;    // lr is failed by 1.other store to the same cache line
logic lr_fail_by_snp;   // TODO: lr is failed by 2.snoop req to the same cache line
logic lr_fail_by_evict; // TODO: lr is failed by 3.cache evict the same cache line
logic lr_clr_by_sc;     // lr is cleared by any following sc

generate
  for(i = 0; i < N_STB_ST_IN_PORT; i++) begin
    assign st_req_hit_rt[i] = ls_pipe_amo_ctrl_st_req_vld_i[i] & ~ls_pipe_amo_ctrl_st_req_is_fence_i[i] &
                              (ls_pipe_amo_ctrl_st_req_paddr_i[i][(PADDR_WIDTH-1)-:L1D_STB_LINE_ADDR_SIZE] == reservation_table_q.paddr[(PADDR_WIDTH-1)-:L1D_STB_LINE_ADDR_SIZE]);
  end
endgenerate

assign lr_fail_by_st  = reservation_table_valid_q & (st_req_hit_rt[0] & ~amo_req_d.is_lr | st_req_hit_rt[1]);
assign lr_fail_by_snp = 1'b0; // TODO:
assign lr_fail_by_evict = 1'b0; // TODO:
assign lr_clr_by_sc   = reservation_table_valid_q & amo_req_q.is_sc & waiting_for_amo_resp & bank_amo_resp_vld;
assign reservation_table_valid_set = amo_req_q.is_lr & waiting_for_amo_resp & bank_amo_resp_vld;
assign reservation_table_valid_clr = lr_fail_by_st | lr_fail_by_snp | lr_fail_by_evict | lr_clr_by_sc;
assign reservation_table_valid_d   = reservation_table_valid_set & (~reservation_table_valid_clr);
assign reservation_table_valid_ena = reservation_table_valid_set | reservation_table_valid_clr;
`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) ((reservation_table_valid_set & reservation_table_valid_clr)== '0))
    else $fatal("l1d amo ctrl: reservation_table set and clr at the same time");
`endif

assign reservation_table_d.paddr = amo_req_q.paddr;
assign reservation_table_ena     = reservation_table_valid_set;

std_dffre
#(.WIDTH(1))
U_STA_L1D_AMO_CTRL_RT_VALID_REG
(
  .clk(clk),
  .rstn(rst),
  .en(reservation_table_valid_ena),
  .d(reservation_table_valid_d),
  .q(reservation_table_valid_q)
);

std_dffe
#(.WIDTH($bits(l1d_amo_reservation_table_t)))
U_DAT_L1D_AMO_CTRL_RT_REG
(
  .clk(clk),
  .en(reservation_table_ena),
  .d(reservation_table_d),
  .q(reservation_table_q)
);

// sc check reservation table
assign amo_ctrl_stb_st_req_sc_rt_check_succ_o = reservation_table_valid_q &                     // reservation table valid
                                                (amo_req_q.paddr == reservation_table_q.paddr);  // reservation table paddr match
endmodule
