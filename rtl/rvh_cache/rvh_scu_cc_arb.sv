module rvh_scu_cc_arb
  import rvh_pkg::*;
  import uop_encoding_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
#(
  parameter INPUT_PORT_NUM = L1D_BANK_ID_NUM,
  parameter INPUT_PORT_NUM_INDEX_WIDTH = $clog2(INPUT_PORT_NUM) > 0 ? $clog2(INPUT_PORT_NUM) : 1,
  parameter RESP_PORT_SELECT_BID_LSB = 0
)
(
    // L1D banks -> cc arb
      // private cache -> scu
        // req
    input  logic               [INPUT_PORT_NUM-1:0]  pc_scu_req_vld_i,
    input  cache_scu_cc_req_t  [INPUT_PORT_NUM-1:0]  pc_scu_req_i,
    output logic               [INPUT_PORT_NUM-1:0]  pc_scu_req_rdy_o,
  
        // resp
    input  logic               [INPUT_PORT_NUM-1:0]  pc_scu_resp_vld_i,
    input  cache_scu_cc_resp_t [INPUT_PORT_NUM-1:0]  pc_scu_resp_i,
    output logic               [INPUT_PORT_NUM-1:0]  pc_scu_resp_rdy_o,

        // evict/wb
    input  logic               [INPUT_PORT_NUM-1:0]  pc_scu_evict_vld_i,
    input  cache_scu_cc_req_t  [INPUT_PORT_NUM-1:0]  pc_scu_evict_i,
    output logic               [INPUT_PORT_NUM-1:0]  pc_scu_evict_rdy_o,
  
        // data
    input  logic               [INPUT_PORT_NUM-1:0]  pc_scu_data_vld_i,
    input  cache_scu_cc_data_t [INPUT_PORT_NUM-1:0]  pc_scu_data_i,
    output logic               [INPUT_PORT_NUM-1:0]  pc_scu_data_rdy_o,
  
      // scu -> private cache
        // resp
    output logic               [INPUT_PORT_NUM-1:0]  scu_pc_resp_vld_o,
    output cache_scu_cc_resp_t [INPUT_PORT_NUM-1:0]  scu_pc_resp_o,
    input  logic               [INPUT_PORT_NUM-1:0]  scu_pc_resp_rdy_i,
  
        // snp
    output logic               [INPUT_PORT_NUM-1:0]  scu_pc_snp_vld_o,
    output cache_scu_cc_snp_t  [INPUT_PORT_NUM-1:0]  scu_pc_snp_o,
    input  logic               [INPUT_PORT_NUM-1:0]  scu_pc_snp_rdy_i,
  
        // data
    output logic               [INPUT_PORT_NUM-1:0]  scu_pc_data_vld_o,
    output cache_scu_cc_data_t [INPUT_PORT_NUM-1:0]  scu_pc_data_o,
    input  logic               [INPUT_PORT_NUM-1:0]  scu_pc_data_rdy_i,


    // cc arb -> scu
      // req
    output logic                        arb_pc_scu_req_vld_o,
    output cache_scu_cc_req_t           arb_pc_scu_req_o,
    input  logic                        arb_pc_scu_req_rdy_i,
  
      // resp
    output logic                        arb_pc_scu_resp_vld_o,
    output cache_scu_cc_resp_t          arb_pc_scu_resp_o,
    input  logic                        arb_pc_scu_resp_rdy_i,
  
      // evict/wb
    output logic                        arb_pc_scu_evict_vld_o,
    output cache_scu_cc_req_t           arb_pc_scu_evict_o,
    input  logic                        arb_pc_scu_evict_rdy_i,
  
      // data
    output logic                        arb_pc_scu_data_vld_o,
    output cache_scu_cc_data_t          arb_pc_scu_data_o,
    input  logic                        arb_pc_scu_data_rdy_i,
  
    // cache rx port, scu -> private cache
      // resp
    input  logic                        arb_scu_pc_resp_vld_i,
    input  cache_scu_cc_resp_t          arb_scu_pc_resp_i,
    output logic                        arb_scu_pc_resp_rdy_o,
  
      // snp
    input  logic                        arb_scu_pc_snp_vld_i,
    input  cache_scu_cc_snp_t           arb_scu_pc_snp_i,
    output logic                        arb_scu_pc_snp_rdy_o,
  
      // data
    input  logic                        arb_scu_pc_data_vld_i,
    input  cache_scu_cc_data_t          arb_scu_pc_data_i,
    output logic                        arb_scu_pc_data_rdy_o,



    input logic clk,
    input logic rst

);

genvar i;

logic [INPUT_PORT_NUM-1:0]              req_grt, resp_grt, evict_grt, data_grt;
logic [INPUT_PORT_NUM_INDEX_WIDTH-1:0]  req_grt_idx, resp_grt_idx, evict_grt_idx, data_grt_idx;

// 1. l1d bank master ports
// 1.1 req channel rr arb
  // req
one_hot_rr_arb #(
  .N_INPUT      (INPUT_PORT_NUM) 
) req_rr_arb_u (
  .req_i        (pc_scu_req_vld_i   ),
  .update_i     (|pc_scu_req_vld_i  ),
  .grt_o        (req_grt            ),
  .grt_idx_o    (req_grt_idx        ),
  .rstn         (rst                ),
  .clk          (clk                )
);

one_hot_rr_arb #(
  .N_INPUT      (INPUT_PORT_NUM) 
) resp_rr_arb_u (
  .req_i        (pc_scu_resp_vld_i  ),
  .update_i     (|pc_scu_resp_vld_i ),
  .grt_o        (resp_grt           ),
  .grt_idx_o    (resp_grt_idx       ),
  .rstn         (rst                ),
  .clk          (clk                )
);

one_hot_rr_arb #(
  .N_INPUT      (INPUT_PORT_NUM) 
) evict_rr_arb_u (
  .req_i        (pc_scu_evict_vld_i ),
  .update_i     (|pc_scu_evict_vld_i),
  .grt_o        (evict_grt          ),
  .grt_idx_o    (evict_grt_idx      ),
  .rstn         (rst                ),
  .clk          (clk                )
);

one_hot_rr_arb #(
  .N_INPUT      (INPUT_PORT_NUM) 
) data_rr_arb_u (
  .req_i        (pc_scu_data_vld_i  ),
  .update_i     (|pc_scu_data_vld_i ),
  .grt_o        (data_grt           ),
  .grt_idx_o    (data_grt_idx       ),
  .rstn         (rst                ),
  .clk          (clk                )
);


// 1.2 control signals
always_comb begin: req_master_control_signal
  pc_scu_req_rdy_o      = '0;
  arb_pc_scu_req_vld_o  = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(req_grt[i]) begin
      pc_scu_req_rdy_o[i] = arb_pc_scu_req_rdy_i;
      arb_pc_scu_req_vld_o = pc_scu_req_vld_i[i];
    end
  end
end

always_comb begin: resp_master_control_signal
  pc_scu_resp_rdy_o      = '0;
  arb_pc_scu_resp_vld_o  = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(resp_grt[i]) begin
      pc_scu_resp_rdy_o[i] = arb_pc_scu_resp_rdy_i;
      arb_pc_scu_resp_vld_o = pc_scu_resp_vld_i[i];
    end
  end
end

always_comb begin: evict_master_control_signal
  pc_scu_evict_rdy_o      = '0;
  arb_pc_scu_evict_vld_o  = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(evict_grt[i]) begin
      pc_scu_evict_rdy_o[i] = arb_pc_scu_evict_rdy_i;
      arb_pc_scu_evict_vld_o = pc_scu_evict_vld_i[i];
    end
  end
end

always_comb begin: data_master_control_signal
  pc_scu_data_rdy_o      = '0;
  arb_pc_scu_data_vld_o  = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(data_grt[i]) begin
      pc_scu_data_rdy_o[i] = arb_pc_scu_data_rdy_i;
      arb_pc_scu_data_vld_o = pc_scu_data_vld_i[i];
    end
  end
end


// 2. l1d bank slave ports
// 2.1 control signals

always_comb begin: resp_slave_control_signal
  arb_scu_pc_resp_rdy_o = '0;
  scu_pc_resp_vld_o     = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(arb_scu_pc_resp_i.id.cid[INPUT_PORT_NUM_INDEX_WIDTH-1:0] == i[INPUT_PORT_NUM_INDEX_WIDTH-1:0]) begin
      arb_scu_pc_resp_rdy_o = scu_pc_resp_rdy_i[i];
      scu_pc_resp_vld_o [i] = arb_scu_pc_resp_vld_i;
    end
  end
end

// snp is different, it is generated by scu rather than private cache, so it doesn't have a cid, need to parse it from send_list
assign arb_scu_pc_snp_rdy_o = &(
                                (({PRIVATE_CACHE_NUM{arb_scu_pc_snp_vld_i}} & arb_scu_pc_snp_i.send_list) & scu_pc_snp_rdy_i) | 
                                ({PRIVATE_CACHE_NUM{arb_scu_pc_snp_vld_i}} & (~arb_scu_pc_snp_i.send_list))
                                );

always_comb begin: snp_slave_control_signal
  scu_pc_snp_vld_o     = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(arb_scu_pc_snp_i.send_list[i]) begin
      scu_pc_snp_vld_o [i] = arb_scu_pc_snp_rdy_o & arb_scu_pc_snp_vld_i;
    end
  end
end

always_comb begin: data_slave_control_signal
  arb_scu_pc_data_rdy_o = '0;
  scu_pc_data_vld_o     = '0;
  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(arb_scu_pc_data_i.id.cid[INPUT_PORT_NUM_INDEX_WIDTH-1:0] == i[INPUT_PORT_NUM_INDEX_WIDTH-1:0]) begin
      arb_scu_pc_data_rdy_o = scu_pc_data_rdy_i[i];
      scu_pc_data_vld_o [i] = arb_scu_pc_data_vld_i;
    end
  end
end

// 3. data signals
generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    assign scu_pc_resp_o[i] = arb_scu_pc_resp_i;
    assign scu_pc_snp_o [i] = arb_scu_pc_snp_i;
    assign scu_pc_data_o[i] = arb_scu_pc_data_i;
  end
endgenerate


assign  arb_pc_scu_req_o    = pc_scu_req_i  [req_grt_idx  ];
assign  arb_pc_scu_resp_o   = pc_scu_resp_i [resp_grt_idx ];
assign  arb_pc_scu_evict_o  = pc_scu_evict_i[evict_grt_idx];
assign  arb_pc_scu_data_o   = pc_scu_data_i [data_grt_idx ];


endmodule
