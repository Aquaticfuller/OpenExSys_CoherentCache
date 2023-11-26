module rvh_l1d_bank_axi_arb
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
#(
  parameter INPUT_PORT_NUM = L1D_BANK_ID_NUM,
  parameter INPUT_PORT_NUM_INDEX_WIDTH = $clog2(INPUT_PORT_NUM),
  parameter RESP_PORT_SELECT_BID_LSB = 0
)
(
    // L1D banks -> axi arb
      // AR
    input  logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_arvalid,
    output logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_arready,
    input  cache_mem_if_ar_t [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_ar,
      // AW
    input  logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_awvalid,
    output logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_awready,
    input  cache_mem_if_aw_t [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_aw,
      // W
    input  logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_wvalid,
    output logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_wready,
    input  cache_mem_if_w_t  [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_w,
      // B
    output logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_bvalid,
    input  logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_bready,
    output cache_mem_if_b_t  [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_b,
      // R
    output logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_rvalid,
    input  logic             [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_rready,
    output cache_mem_if_r_t  [INPUT_PORT_NUM-1:0] l1d_bank_axi_arb_r,
    
    // axi arb -> L2
      // AR
    output logic              axi_arb_l2_arvalid,
    input  logic              axi_arb_l2_arready,
    output cache_mem_if_ar_t  axi_arb_l2_ar,
      // AW 
    output logic              axi_arb_l2_awvalid,
    input  logic              axi_arb_l2_awready,
    output cache_mem_if_aw_t  axi_arb_l2_aw,
      // W 
    output logic              axi_arb_l2_wvalid,
    input  logic              axi_arb_l2_wready,
    output cache_mem_if_w_t   axi_arb_l2_w,
      // B
    input  logic              axi_arb_l2_bvalid,
    output logic              axi_arb_l2_bready,
    input  cache_mem_if_b_t   axi_arb_l2_b,
      // R
    input  logic              axi_arb_l2_rvalid,
    output logic              axi_arb_l2_rready,
    input cache_mem_if_r_t    axi_arb_l2_r,
    
    input logic clk,
    input logic rst
    
);

genvar i;

logic [INPUT_PORT_NUM-1:0]            ar_grt, aw_grt, w_grt;
logic [INPUT_PORT_NUM_INDEX_WIDTH-1:0]  ar_grt_idx, aw_grt_idx, w_grt_idx;

// 1. l1d bank master ports
// 1.1 req channel rr arb
  // ar
one_hot_rr_arb #(
  .N_INPUT      (INPUT_PORT_NUM) 
) ar_rr_arb_u (
  .req_i        (l1d_bank_axi_arb_arvalid   ),
  .update_i     (|l1d_bank_axi_arb_arvalid  ),
  .grt_o        (ar_grt                     ),
  .grt_idx_o    (ar_grt_idx                 ),
  .rstn         (rst                        ),
  .clk          (clk                        )
);
  // aw
// one_hot_rr_arb #(
//   .N_INPUT      (INPUT_PORT_NUM) 
// ) aw_rr_arb_u (
//   .req_i        (l1d_bank_axi_arb_awvalid   ),
//   .update_i     (axi_arb_w_rr_update_en     ),
//   .grt_o        (aw_grt                     ),
//   .grt_idx_o    (aw_grt_idx                 ),
//   .rstn         (rst                        ),
//   .clk          (clk                        )
// );

  // w
typedef enum logic { W_IDLE, W_TRANSMIT } axi_arb_w_fsm_e;
axi_arb_w_fsm_e axi_arb_w_fsm_d, axi_arb_w_fsm_q;
logic axi_arb_w_fsm_d_ena;
logic axi_arb_l2_w_hsk;
logic [INPUT_PORT_NUM-1:0] w_grt_d, w_grt_q, w_grt_chosen;
logic w_grt_d_ena;
logic [INPUT_PORT_NUM_INDEX_WIDTH-1:0] w_grt_idx_d, w_grt_idx_q, w_grt_idx_chosen;
logic w_grt_idx_d_ena;
logic axi_arb_w_fsm_in_transmit;
logic axi_arb_w_rr_update_en;

assign axi_arb_l2_w_hsk = axi_arb_l2_wvalid & axi_arb_l2_wready;

always_comb begin
  axi_arb_w_fsm_d     = axi_arb_w_fsm_q;
  axi_arb_w_fsm_d_ena = 1'b0;
  w_grt_d         = w_grt_q;
  w_grt_d_ena     = 1'b0;
  w_grt_idx_d     = w_grt_idx_q;
  w_grt_idx_d_ena = 1'b0;
  axi_arb_w_fsm_in_transmit = 1'b0;
  axi_arb_w_rr_update_en = 1'b0;
  case (axi_arb_w_fsm_q)
    W_IDLE: begin
      if(axi_arb_l2_wvalid) begin
        w_grt_d     = w_grt;
        w_grt_d_ena = 1'b1;
        w_grt_idx_d = w_grt_idx;
        w_grt_idx_d_ena = 1'b1;
      end
      if(axi_arb_l2_w_hsk) begin
        axi_arb_w_fsm_d     = W_TRANSMIT;
        axi_arb_w_fsm_d_ena = 1'b1;
      end
    end
    W_TRANSMIT: begin
      axi_arb_w_fsm_in_transmit = 1'b1;
      if(axi_arb_l2_w_hsk & axi_arb_l2_w.wlast) begin
        axi_arb_w_fsm_d     = W_IDLE;
        axi_arb_w_fsm_d_ena = 1'b1;
        axi_arb_w_rr_update_en = 1'b1;
      end
    end
    default: begin
      axi_arb_w_fsm_d = W_IDLE;
      w_grt_d     = w_grt;
      w_grt_d_ena = 1'b1;
      w_grt_idx_d = w_grt_idx;
      w_grt_idx_d_ena = 1'b1;
    end
  endcase
end

assign w_grt_chosen     = axi_arb_w_fsm_in_transmit ? w_grt_q : w_grt;
assign w_grt_idx_chosen = axi_arb_w_fsm_in_transmit ? w_grt_idx_q : w_grt_idx;

std_dffrve
#(.WIDTH($bits(axi_arb_w_fsm_e)))
U_L1D_AXI_ARB_W_FSM_STATE_REG
(
  .clk(clk),
  .rstn(rst),
  .rst_val(W_IDLE),
  .en(axi_arb_w_fsm_d_ena),
  .d(axi_arb_w_fsm_d),
  .q(axi_arb_w_fsm_q)
);

std_dffre
#(.WIDTH(INPUT_PORT_NUM)) 
U_L1D_AXI_ARB_W_GRT_REG
(
  .clk(clk),
  .rstn(rst),
  .en(w_grt_d_ena),
  .d(w_grt_d),
  .q(w_grt_q)
);

std_dffre
#(.WIDTH(INPUT_PORT_NUM_INDEX_WIDTH)) 
U_L1D_AXI_ARB_W_GRT_IDX_REG
(
  .clk(clk),
  .rstn(rst),
  .en(w_grt_idx_d_ena),
  .d(w_grt_idx_d),
  .q(w_grt_idx_q)
);

one_hot_rr_arb #(
  .N_INPUT      (INPUT_PORT_NUM) 
) w_rr_arb_u (
  .req_i        (l1d_bank_axi_arb_wvalid   ),
  .update_i     (axi_arb_w_rr_update_en    ),
  .grt_o        (w_grt                     ),
  .grt_idx_o    (w_grt_idx                 ),
  .rstn         (rst                       ),
  .clk          (clk                       )
);

// 1.2 control signals
always_comb begin: ar_control_signal
  l1d_bank_axi_arb_arready = '0;
  axi_arb_l2_arvalid = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(ar_grt[i]) begin
      l1d_bank_axi_arb_arready[i] = axi_arb_l2_arready;
      axi_arb_l2_arvalid = l1d_bank_axi_arb_arvalid[i];
    end
  end
end

always_comb begin: aw_control_signal
  l1d_bank_axi_arb_awready = '0;
  axi_arb_l2_awvalid = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(w_grt_chosen[i]) begin
      l1d_bank_axi_arb_awready[i] = axi_arb_l2_awready;
      axi_arb_l2_awvalid = l1d_bank_axi_arb_awvalid[i];
    end
  end
end

always_comb begin: w_control_signal
  l1d_bank_axi_arb_wready = '0;
  axi_arb_l2_wvalid = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(w_grt_chosen[i]) begin
      l1d_bank_axi_arb_wready[i] = axi_arb_l2_wready;
      axi_arb_l2_wvalid = l1d_bank_axi_arb_wvalid[i];
    end
  end
end


// 2. l1d bank slave ports
// 2.1 control signals
always_comb begin: r_control_signal
  axi_arb_l2_rready = '0;
  l1d_bank_axi_arb_rvalid = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(axi_arb_l2_r.rid.bid[RESP_PORT_SELECT_BID_LSB+:INPUT_PORT_NUM_INDEX_WIDTH] == i[INPUT_PORT_NUM_INDEX_WIDTH-1:0]) begin
      axi_arb_l2_rready = l1d_bank_axi_arb_rready[i];
      l1d_bank_axi_arb_rvalid [i] = axi_arb_l2_rvalid;
    end
  end
end

always_comb begin: b_control_signal
  axi_arb_l2_bready = '0;
  l1d_bank_axi_arb_bvalid = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(axi_arb_l2_b.bid.bid[RESP_PORT_SELECT_BID_LSB+:INPUT_PORT_NUM_INDEX_WIDTH] == i[INPUT_PORT_NUM_INDEX_WIDTH-1:0]) begin
      axi_arb_l2_bready = l1d_bank_axi_arb_bready[i];
      l1d_bank_axi_arb_bvalid [i] = axi_arb_l2_bvalid;
    end
  end
end

// 3. data signals
assign axi_arb_l2_ar = l1d_bank_axi_arb_ar[ar_grt_idx];
assign axi_arb_l2_aw = l1d_bank_axi_arb_aw[w_grt_idx_chosen];
assign axi_arb_l2_w  = l1d_bank_axi_arb_w [w_grt_idx_chosen];

generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    assign l1d_bank_axi_arb_b[i] = axi_arb_l2_b;
    assign l1d_bank_axi_arb_r[i] = axi_arb_l2_r;
  end
endgenerate

endmodule