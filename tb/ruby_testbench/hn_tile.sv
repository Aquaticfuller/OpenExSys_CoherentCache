module hn_tile
  import rvh_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_noc_pkg::*;
  import uop_encoding_pkg::*;
  import riscv_pkg::*;
`ifdef RUBY
  import ruby_pkg::*;
`endif
  import rvh_uncore_param_pkg::*;
  #(
    parameter CHANNEL_NUM = 5
  )
  (
  // control signals
    output logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      tx_flit_pend_o,
    output logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      tx_flit_v_o,
    output logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0] tx_flit_vc_id_o,
    output io_port_t       [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      tx_flit_look_ahead_routing_o,

    input  logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      rx_flit_pend_i,
    input  logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      rx_flit_v_i,
    input  logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0] rx_flit_vc_id_i,
    input  io_port_t       [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      rx_flit_look_ahead_routing_i,

    input  logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      tx_lcrd_v_i,
    input  logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0] tx_lcrd_id_i,

    output logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                      rx_lcrd_v_o,
    output logic           [CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0] rx_lcrd_id_o,

  // payload
    output cache_scu_cc_req_t   [ROUTER_PORT_NUMBER-1:0]                                  tx_flit_channel_0_o, // req
    output cache_scu_cc_resp_t  [ROUTER_PORT_NUMBER-1:0]                                  tx_flit_channel_1_o, // resp
    output cache_scu_cc_req_t   [ROUTER_PORT_NUMBER-1:0]                                  tx_flit_channel_2_o, // evict
    output cache_scu_cc_data_t  [ROUTER_PORT_NUMBER-1:0]                                  tx_flit_channel_3_o, // data
    output cache_scu_cc_snp_t   [ROUTER_PORT_NUMBER-1:0]                                  tx_flit_channel_4_o, // snp

    input  cache_scu_cc_req_t   [ROUTER_PORT_NUMBER-1:0]                                  rx_flit_channel_0_i, // req
    input  cache_scu_cc_resp_t  [ROUTER_PORT_NUMBER-1:0]                                  rx_flit_channel_1_i, // resp
    input  cache_scu_cc_req_t   [ROUTER_PORT_NUMBER-1:0]                                  rx_flit_channel_2_i, // evict
    input  cache_scu_cc_data_t  [ROUTER_PORT_NUMBER-1:0]                                  rx_flit_channel_3_i, // data
    input  cache_scu_cc_snp_t   [ROUTER_PORT_NUMBER-1:0]                                  rx_flit_channel_4_i, // snp

  // position
    input  logic                [NodeID_X_Width-1:0]                                   node_id_x_i,
    input  logic                [NodeID_Y_Width-1:0]                                   node_id_y_i,

`ifdef SYNTHESIS
    output logic              scu_mem_arvalid_o,
    input  logic              scu_mem_arready_i,
    output cache_mem_if_ar_t  scu_mem_ar_o,
     
    input  logic              scu_mem_rvalid_i ,
    output logic              scu_mem_rready_o ,
    input  cache_mem_if_r_t   scu_mem_r_i,
     
    output logic              scu_mem_awvalid_o ,
    input  logic              scu_mem_awready_i ,
    output cache_mem_if_aw_t  scu_mem_aw_o ,
     
    output logic              scu_mem_wvalid_o ,
    input  logic              scu_mem_wready_i ,
    output cache_mem_if_w_t   scu_mem_w_o ,
     
    input  logic              scu_mem_bvalid_i,
    output logic              scu_mem_bready_o,
    input  cache_mem_if_b_t   scu_mem_b_i,
`endif


  // clk, rst
    input  logic  clk,
    input  logic  rst_n
  );

logic              scu_mem_arvalid;
logic              scu_mem_arready;
cache_mem_if_ar_t  scu_mem_ar;

logic              scu_mem_rvalid ;
logic              scu_mem_rready ; 
cache_mem_if_r_t   scu_mem_r;

logic              scu_mem_awvalid ;
logic              scu_mem_awready ;
cache_mem_if_aw_t  scu_mem_aw ;

logic              scu_mem_wvalid ;
logic              scu_mem_wready ;
cache_mem_if_w_t   scu_mem_w ;

logic              scu_mem_bvalid;
logic              scu_mem_bready;
cache_mem_if_b_t   scu_mem_b;

`ifdef SYNTHESIS
assign scu_mem_arvalid_o     = scu_mem_arvalid;
assign scu_mem_arready       = scu_mem_arready_i;
assign scu_mem_ar_o          = scu_mem_ar;

assign scu_mem_rvalid        = scu_mem_rvalid_i;
assign scu_mem_rready_o      = scu_mem_rready;
assign scu_mem_r             = scu_mem_r_i;

assign scu_mem_awvalid_o       = scu_mem_awvalid;
assign scu_mem_awready         = scu_mem_awready_i;
assign scu_mem_aw_o            = scu_mem_aw;

assign scu_mem_wvalid_o       = scu_mem_wvalid;
assign scu_mem_wready         = scu_mem_wready_i;
assign scu_mem_w_o            = scu_mem_w;

assign scu_mem_bvalid        = scu_mem_bvalid_i;
assign scu_mem_bready_o      = scu_mem_bready;
assign scu_mem_b             = scu_mem_b_i;
// 😌😌😌

`endif

// router <-> {noc port, local port}
logic           [CHANNEL_NUM-1:0][INPUT_PORT_NUM-1:0]                      all_rt_flit_pend;
logic           [CHANNEL_NUM-1:0][INPUT_PORT_NUM-1:0]                      all_rt_flit_v;
logic           [CHANNEL_NUM-1:0][INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] all_rt_flit_vc_id;
io_port_t       [CHANNEL_NUM-1:0][INPUT_PORT_NUM-1:0]                      all_rt_flit_look_ahead_routing;

logic           [CHANNEL_NUM-1:0][OUTPUT_PORT_NUM-1:0]                       rt_all_flit_pend;
logic           [CHANNEL_NUM-1:0][OUTPUT_PORT_NUM-1:0]                       rt_all_flit_v;
logic           [CHANNEL_NUM-1:0][OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  rt_all_flit_vc_id;
io_port_t       [CHANNEL_NUM-1:0][OUTPUT_PORT_NUM-1:0]                       rt_all_flit_look_ahead_routing;

logic           [CHANNEL_NUM-1:0][INPUT_PORT_NUM-1:0]                      all_rt_lcrd_v;
logic           [CHANNEL_NUM-1:0][INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] all_rt_lcrd_id;

logic           [CHANNEL_NUM-1:0][OUTPUT_PORT_NUM-1:0]                       rt_all_lcrd_v;
logic           [CHANNEL_NUM-1:0][OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  rt_all_lcrd_id;

// router <-> {local port}
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       lp_rt_flit_pend;
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       lp_rt_flit_v;
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]  lp_rt_flit_vc_id;
io_port_t       [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       lp_rt_flit_look_ahead_routing;

logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       rt_lp_flit_pend;
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       rt_lp_flit_v;
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]  rt_lp_flit_vc_id;
io_port_t       [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       rt_lp_flit_look_ahead_routing;

logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       lp_rt_lcrd_v;
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]  lp_rt_lcrd_id;

logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]                       rt_lp_lcrd_v;
logic           [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]  rt_lp_lcrd_id;

cache_scu_cc_req_t   [INPUT_PORT_NUM-1:0]                                  all_rt_flit_channel_0; // req
cache_scu_cc_resp_t  [INPUT_PORT_NUM-1:0]                                  all_rt_flit_channel_1; // resp
cache_scu_cc_req_t   [INPUT_PORT_NUM-1:0]                                  all_rt_flit_channel_2; // evict
cache_scu_cc_data_t  [INPUT_PORT_NUM-1:0]                                  all_rt_flit_channel_3; // data
cache_scu_cc_snp_t   [INPUT_PORT_NUM-1:0]                                  all_rt_flit_channel_4; // snp

cache_scu_cc_req_t   [OUTPUT_PORT_NUM-1:0]                                   rt_all_flit_channel_0; // req
cache_scu_cc_resp_t  [OUTPUT_PORT_NUM-1:0]                                   rt_all_flit_channel_1; // resp
cache_scu_cc_req_t   [OUTPUT_PORT_NUM-1:0]                                   rt_all_flit_channel_2; // evict
cache_scu_cc_data_t  [OUTPUT_PORT_NUM-1:0]                                   rt_all_flit_channel_3; // data
cache_scu_cc_snp_t   [OUTPUT_PORT_NUM-1:0]                                   rt_all_flit_channel_4; // snp

logic scu_evict_hsk;
logic scu_req_hsk;

// scu rx port, private cache -> scu
  // req
logic                                       cc_arb_scu_req_vld;
cache_scu_cc_req_t                          cc_arb_scu_req;
logic                                       cc_arb_scu_req_rdy;

  // resp
logic                                       cc_arb_scu_resp_vld;
cache_scu_cc_resp_t                         cc_arb_scu_resp;
logic                                       cc_arb_scu_resp_rdy;

  // evict/wb
logic                                       cc_arb_scu_evict_vld;
cache_scu_cc_req_t                          cc_arb_scu_evict;
logic                                       cc_arb_scu_evict_rdy;

  // data
logic                                       cc_arb_scu_data_vld;
cache_scu_cc_data_t                         cc_arb_scu_data;
logic                                       cc_arb_scu_data_rdy;

// scu tx port, scu -> private cache
  // resp
logic                                       scu_cc_arb_resp_vld;
cache_scu_cc_resp_t                         scu_cc_arb_resp;
logic                                       scu_cc_arb_resp_rdy;

  // snp
logic                                       scu_cc_arb_snp_vld;
cache_scu_cc_snp_t                          scu_cc_arb_snp;
logic                                       scu_cc_arb_snp_rdy;

  // data
logic                                       scu_cc_arb_data_vld;
cache_scu_cc_data_t                         scu_cc_arb_data;
logic                                       scu_cc_arb_data_rdy;


generate 
  for(genvar i = 0; i < CHANNEL_NUM; i ++) begin
    for(genvar j = 0; j < ROUTER_PORT_NUMBER; j++) begin
      assign tx_flit_pend_o[i][j]                  = rt_all_flit_pend[i][j];
      assign tx_flit_v_o[i][j]                     = rt_all_flit_v[i][j];
      assign tx_flit_vc_id_o[i][j]                 = rt_all_flit_vc_id[i][j];
      assign tx_flit_look_ahead_routing_o[i][j]    = rt_all_flit_look_ahead_routing[i][j];
      assign all_rt_flit_pend[i][j]                = rx_flit_pend_i[i][j];
      assign all_rt_flit_v[i][j]                   = rx_flit_v_i[i][j];
      assign all_rt_flit_vc_id[i][j]               = rx_flit_vc_id_i[i][j];
      assign all_rt_flit_look_ahead_routing[i][j]  = rx_flit_look_ahead_routing_i[i][j];

      assign rt_all_lcrd_v[i][j]                   = tx_lcrd_v_i[i][j];
      assign rt_all_lcrd_id[i][j]                  = tx_lcrd_id_i[i][j];

      assign rx_lcrd_v_o  [i][j]                   = all_rt_lcrd_v[i][j];
      assign rx_lcrd_id_o [i][j]                   = all_rt_lcrd_id[i][j];
    end
  end
endgenerate

generate 
  for(genvar i = 0; i < ROUTER_PORT_NUMBER; i++) begin
      assign tx_flit_channel_0_o[i] = rt_all_flit_channel_0[i];
      assign tx_flit_channel_1_o[i] = rt_all_flit_channel_1[i];
      assign tx_flit_channel_2_o[i] = rt_all_flit_channel_2[i];
      assign tx_flit_channel_3_o[i] = rt_all_flit_channel_3[i];
      assign tx_flit_channel_4_o[i] = rt_all_flit_channel_4[i];
      assign all_rt_flit_channel_0[i] = rx_flit_channel_0_i[i];
      assign all_rt_flit_channel_1[i] = rx_flit_channel_1_i[i];
      assign all_rt_flit_channel_2[i] = rx_flit_channel_2_i[i];
      assign all_rt_flit_channel_3[i] = rx_flit_channel_3_i[i];
      assign all_rt_flit_channel_4[i] = rx_flit_channel_4_i[i];
  end
endgenerate


generate
  for(genvar i = 0; i < CHANNEL_NUM; i ++) begin
    for(genvar j = 0; j < LOCAL_PORT_NUMBER; j++) begin
      assign rt_lp_flit_pend               [i][j] = rt_all_flit_pend              [i][ROUTER_PORT_NUMBER+j];
      assign rt_lp_flit_v                  [i][j] = rt_all_flit_v                 [i][ROUTER_PORT_NUMBER+j];
      assign rt_lp_flit_vc_id              [i][j] = rt_all_flit_vc_id             [i][ROUTER_PORT_NUMBER+j];
      assign rt_lp_flit_look_ahead_routing [i][j] = rt_all_flit_look_ahead_routing[i][ROUTER_PORT_NUMBER+j];

      assign lp_rt_lcrd_v                  [i][j] = all_rt_lcrd_v                 [i][ROUTER_PORT_NUMBER+j];
      assign lp_rt_lcrd_id                 [i][j] = all_rt_lcrd_id                [i][ROUTER_PORT_NUMBER+j];
    end
  end
endgenerate

generate
  for(genvar i = 0; i < CHANNEL_NUM; i ++) begin
    for(genvar j = 0; j < LOCAL_PORT_NUMBER; j++) begin
      assign  lp_rt_flit_pend               [i][j] = all_rt_flit_pend              [i][ROUTER_PORT_NUMBER+j];
      assign  lp_rt_flit_v                  [i][j] = all_rt_flit_v                 [i][ROUTER_PORT_NUMBER+j];
      assign  lp_rt_flit_vc_id              [i][j] = all_rt_flit_vc_id             [i][ROUTER_PORT_NUMBER+j];
      assign  lp_rt_flit_look_ahead_routing [i][j] = all_rt_flit_look_ahead_routing[i][ROUTER_PORT_NUMBER+j];

      assign  rt_lp_lcrd_v                  [i][j] = rt_all_lcrd_v                 [i][ROUTER_PORT_NUMBER+j];
      assign  rt_lp_lcrd_id                 [i][j] = rt_all_lcrd_id                [i][ROUTER_PORT_NUMBER+j];
    end
  end
endgenerate


vnet_router
#(
  .INPUT_PORT_NUM(INPUT_PORT_NUM ),
  .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
  .flit_payload_t(cache_scu_cc_req_t),
  .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
  .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
  .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
  .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
  .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
  .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
  .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
  .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
  .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
  .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
  .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
  .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
  .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
  .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
  .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
  .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
  .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
  .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
  .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
  .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
  .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
)
vnet_router_req_dut (
  .rx_flit_pend_i               (all_rt_flit_pend               [0]    ),
  .rx_flit_v_i                  (all_rt_flit_v                  [0]    ),
  .rx_flit_i                    (all_rt_flit_channel_0                 ),
  .rx_flit_vc_id_i              (all_rt_flit_vc_id              [0]    ),
  .rx_flit_look_ahead_routing_i (all_rt_flit_look_ahead_routing [0]    ),

  .tx_flit_pend_o               (rt_all_flit_pend               [0]    ),
  .tx_flit_v_o                  (rt_all_flit_v                  [0]    ),
  .tx_flit_o                    (rt_all_flit_channel_0                 ),
  .tx_flit_vc_id_o              (rt_all_flit_vc_id              [0]    ),
  .tx_flit_look_ahead_routing_o (rt_all_flit_look_ahead_routing [0]    ),

  .rx_lcrd_v_o                  (all_rt_lcrd_v                  [0]    ),
  .rx_lcrd_id_o                 (all_rt_lcrd_id                 [0]    ),

  .tx_lcrd_v_i                  (rt_all_lcrd_v                  [0]    ),
  .tx_lcrd_id_i                 (rt_all_lcrd_id                 [0]    ),

  .node_id_x_ths_hop_i          (node_id_x_i                         ),
  .node_id_y_ths_hop_i          (node_id_y_i                         ),

  .clk    (clk ),
  .rstn   (rst_n)
);

  // assign rx_flit_pend_channel_0[i][j][4] = 1'b1;
  // assign rx_flit_v_channel_0[i][j][4] = '0;
  // assign rx_flit_channel_0[i][j][4] = '0;
  // assign rx_flit_vc_id_channel_0[i][j][4] = '0;
  // assign rx_flit_look_ahead_routing_channel_0[i][j][4] = '0;
  // assign cc_arb_scu_req_vld = tx_flit_v_channel_0[i][j][4];
  // assign cc_arb_scu_req = tx_flit_channel_0[i][j][4];
  // assign tx_lcrd_id_channel_0[i][j][4] = '0;
  // assign tx_lcrd_v_channel_0[i][j][4] = scu_req_hsk;

vnet_router
#(
  .INPUT_PORT_NUM(INPUT_PORT_NUM ),
  .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
  .flit_payload_t(cache_scu_cc_resp_t),
  .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
  .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
  .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
  .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
  .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
  .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
  .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
  .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
  .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
  .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
  .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
  .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
  .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
  .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
  .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
  .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
  .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
  .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
  .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
  .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
  .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
)
vnet_router_resp_dut (
  .rx_flit_pend_i               (all_rt_flit_pend               [1]    ),
  .rx_flit_v_i                  (all_rt_flit_v                  [1]    ),
  .rx_flit_i                    (all_rt_flit_channel_1                 ),
  .rx_flit_vc_id_i              (all_rt_flit_vc_id              [1]    ),
  .rx_flit_look_ahead_routing_i (all_rt_flit_look_ahead_routing [1]    ),

  .tx_flit_pend_o               (rt_all_flit_pend               [1]    ),
  .tx_flit_v_o                  (rt_all_flit_v                  [1]    ),
  .tx_flit_o                    (rt_all_flit_channel_1                 ),
  .tx_flit_vc_id_o              (rt_all_flit_vc_id              [1]    ),
  .tx_flit_look_ahead_routing_o (rt_all_flit_look_ahead_routing [1]    ),

  .rx_lcrd_v_o                  (all_rt_lcrd_v                  [1]    ),
  .rx_lcrd_id_o                 (all_rt_lcrd_id                 [1]    ),

  .tx_lcrd_v_i                  (rt_all_lcrd_v                  [1]    ),
  .tx_lcrd_id_i                 (rt_all_lcrd_id                 [1]    ),

  .node_id_x_ths_hop_i          (node_id_x_i                         ),
  .node_id_y_ths_hop_i          (node_id_y_i                         ),

  .clk    (clk ),
  .rstn   (rst_n)
);

vnet_router
#(
  .INPUT_PORT_NUM(INPUT_PORT_NUM ),
  .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
  .flit_payload_t(cache_scu_cc_req_t),
  .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
  .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
  .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
  .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
  .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
  .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
  .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
  .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
  .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
  .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
  .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
  .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
  .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
  .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
  .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
  .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
  .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
  .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
  .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
  .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
  .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
)
vnet_router_evict_dut (
  .rx_flit_pend_i               (all_rt_flit_pend               [2]    ),
  .rx_flit_v_i                  (all_rt_flit_v                  [2]    ),
  .rx_flit_i                    (all_rt_flit_channel_2                 ),
  .rx_flit_vc_id_i              (all_rt_flit_vc_id              [2]    ),
  .rx_flit_look_ahead_routing_i (all_rt_flit_look_ahead_routing [2]    ),

  .tx_flit_pend_o               (rt_all_flit_pend               [2]    ),
  .tx_flit_v_o                  (rt_all_flit_v                  [2]    ),
  .tx_flit_o                    (rt_all_flit_channel_2                 ),
  .tx_flit_vc_id_o              (rt_all_flit_vc_id              [2]    ),
  .tx_flit_look_ahead_routing_o (rt_all_flit_look_ahead_routing [2]    ),

  .rx_lcrd_v_o                  (all_rt_lcrd_v                  [2]    ),
  .rx_lcrd_id_o                 (all_rt_lcrd_id                 [2]    ),

  .tx_lcrd_v_i                  (rt_all_lcrd_v                  [2]    ),
  .tx_lcrd_id_i                 (rt_all_lcrd_id                 [2]    ),

  .node_id_x_ths_hop_i          (node_id_x_i                         ),
  .node_id_y_ths_hop_i          (node_id_y_i                         ),

  .clk    (clk ),
  .rstn   (rst_n)
);

vnet_router
#(
  .INPUT_PORT_NUM(INPUT_PORT_NUM ),
  .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
  .flit_payload_t(cache_scu_cc_data_t),
  .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
  .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
  .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
  .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
  .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
  .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
  .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
  .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
  .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
  .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
  .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
  .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
  .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
  .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
  .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
  .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
  .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
  .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
  .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
  .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
  .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
)
vnet_router_data_dut (
  .rx_flit_pend_i               (all_rt_flit_pend               [3]    ),
  .rx_flit_v_i                  (all_rt_flit_v                  [3]    ),
  .rx_flit_i                    (all_rt_flit_channel_3                 ),
  .rx_flit_vc_id_i              (all_rt_flit_vc_id              [3]    ),
  .rx_flit_look_ahead_routing_i (all_rt_flit_look_ahead_routing [3]    ),

  .tx_flit_pend_o               (rt_all_flit_pend               [3]    ),
  .tx_flit_v_o                  (rt_all_flit_v                  [3]    ),
  .tx_flit_o                    (rt_all_flit_channel_3                 ),
  .tx_flit_vc_id_o              (rt_all_flit_vc_id              [3]    ),
  .tx_flit_look_ahead_routing_o (rt_all_flit_look_ahead_routing [3]    ),

  .rx_lcrd_v_o                  (all_rt_lcrd_v                  [3]    ),
  .rx_lcrd_id_o                 (all_rt_lcrd_id                 [3]    ),

  .tx_lcrd_v_i                  (rt_all_lcrd_v                  [3]    ),
  .tx_lcrd_id_i                 (rt_all_lcrd_id                 [3]    ),

  .node_id_x_ths_hop_i          (node_id_x_i                         ),
  .node_id_y_ths_hop_i          (node_id_y_i                         ),

  .clk    (clk ),
  .rstn   (rst_n)
);

vnet_router
#(
  .INPUT_PORT_NUM(INPUT_PORT_NUM ),
  .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
  .flit_payload_t(cache_scu_cc_snp_t),
  .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
  .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
  .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
  .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
  .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
  .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
  .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
  .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
  .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
  .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
  .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
  .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
  .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
  .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
  .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
  .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
  .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
  .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
  .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
  .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
  .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
)
vnet_router_snp_dut (
  .rx_flit_pend_i               (all_rt_flit_pend               [4]    ),
  .rx_flit_v_i                  (all_rt_flit_v                  [4]    ),
  .rx_flit_i                    (all_rt_flit_channel_4                 ),
  .rx_flit_vc_id_i              (all_rt_flit_vc_id              [4]    ),
  .rx_flit_look_ahead_routing_i (all_rt_flit_look_ahead_routing [4]    ),

  .tx_flit_pend_o               (rt_all_flit_pend               [4]    ),
  .tx_flit_v_o                  (rt_all_flit_v                  [4]    ),
  .tx_flit_o                    (rt_all_flit_channel_4                 ),
  .tx_flit_vc_id_o              (rt_all_flit_vc_id              [4]    ),
  .tx_flit_look_ahead_routing_o (rt_all_flit_look_ahead_routing [4]    ),

  .rx_lcrd_v_o                  (all_rt_lcrd_v                  [4]    ),
  .rx_lcrd_id_o                 (all_rt_lcrd_id                 [4]    ),

  .tx_lcrd_v_i                  (rt_all_lcrd_v                  [4]    ),
  .tx_lcrd_id_i                 (rt_all_lcrd_id                 [4]    ),

  .node_id_x_ths_hop_i          (node_id_x_i                         ),
  .node_id_y_ths_hop_i          (node_id_y_i                         ),

  .clk    (clk ),
  .rstn   (rst_n)
);






rvh_scu 
#(
  .MSHR_NUM(SCU_MSHR_NUM ),
  .REPL_MSHR_NUM(SCU_REPL_MSHR_NUM )
)
rvh_scu_dut (
  // scu rx port, private cache -> scu
    // req
  .pc_scu_req_vld_i   (cc_arb_scu_req_vld ),//0
  .pc_scu_req_i       (cc_arb_scu_req ),
  .pc_scu_req_rdy_o   (cc_arb_scu_req_rdy ),
    // resp
  .pc_scu_resp_vld_i  (cc_arb_scu_resp_vld ),//1
  .pc_scu_resp_i      (cc_arb_scu_resp ),
  .pc_scu_resp_rdy_o  (cc_arb_scu_resp_rdy ),
    // evict/wb
  .pc_scu_evict_vld_i (cc_arb_scu_evict_vld ),//2
  .pc_scu_evict_i     (cc_arb_scu_evict ),
  .pc_scu_evict_rdy_o (cc_arb_scu_evict_rdy ),
    // data
  .pc_scu_data_vld_i  (cc_arb_scu_data_vld ),//3
  .pc_scu_data_i      (cc_arb_scu_data ),
  .pc_scu_data_rdy_o  (cc_arb_scu_data_rdy ),
  
  // scu tx port, scu -> private cache
    // resp
  .scu_pc_resp_vld_o  (scu_cc_arb_resp_vld ),//1
  .scu_pc_resp_o      (scu_cc_arb_resp ),
  .scu_pc_resp_rdy_i  (scu_cc_arb_resp_rdy ),
    // snp
  .scu_pc_snp_vld_o   (scu_cc_arb_snp_vld ),//4
  .scu_pc_snp_o       (scu_cc_arb_snp ),
  .scu_pc_snp_rdy_i   (scu_cc_arb_snp_rdy ),
    // data
  .scu_pc_data_vld_o  (scu_cc_arb_data_vld ),//3
  .scu_pc_data_o      (scu_cc_arb_data ),
  .scu_pc_data_rdy_i  (scu_cc_arb_data_rdy ),

  // mem intf
    // AR
  .mem_if_arvalid_o (scu_mem_arvalid ),
  .mem_if_arready_i (scu_mem_arready ),
  .mem_if_ar_o      (scu_mem_ar ),
    // R
  .mem_if_rvalid_i  (scu_mem_rvalid ),
  .mem_if_rready_o  (scu_mem_rready ),
  .mem_if_r_i       (scu_mem_r ),
    // AW 
  .mem_if_awvalid_o (scu_mem_awvalid ),
  .mem_if_awready_i (scu_mem_awready ),
  .mem_if_aw_o      (scu_mem_aw ),
    // W
  .mem_if_wvalid_o  (scu_mem_wvalid ),
  .mem_if_wready_i  (scu_mem_wready ),
  .mem_if_w_o       (scu_mem_w ),
    // B
  .mem_if_bvalid_i  (scu_mem_bvalid ),
  .mem_if_bready_o  (scu_mem_bready ),
  .mem_if_b_i       (scu_mem_b ),

  .scu_evict_buf_order_fifo_dq_hsk_o (scu_evict_hsk),
  .scu_req_buf_order_fifo_dq_hsk_o (scu_req_hsk),

  // clk, rst
  .clk_i    (clk ),
  .rstn_i   (rst_n)
);



flit_dec_t  [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]  rx_flit_dec;
// channel 0, receive req, no send
  // send
assign all_rt_flit_pend               [0][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_v                  [0][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_channel_0             [ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_vc_id              [0][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_look_ahead_routing [0][ROUTER_PORT_NUMBER] = '0;
  // receive
assign cc_arb_scu_req_vld = rt_all_flit_v      [0][ROUTER_PORT_NUMBER];
assign cc_arb_scu_req     = rt_all_flit_channel_0 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [0][ROUTER_PORT_NUMBER]  = scu_req_hsk;
assign rt_all_lcrd_id   [0][ROUTER_PORT_NUMBER]  = '0;


// channel 1, send and receive resp
  // send
cache_scu_cc_resp_t  all_rt_flit_channel_1_without_xy; // resp

assign all_rt_flit_pend   [1][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [1][ROUTER_PORT_NUMBER] = scu_cc_arb_resp_vld & scu_cc_arb_resp_rdy;
assign all_rt_flit_channel_1_without_xy           = scu_cc_arb_resp;

hn_router_sam
#(
  .flit_payload_t   (cache_scu_cc_resp_t)
)
channel_1_decode
(
  .flit_v_i     (all_rt_flit_v      [1][ROUTER_PORT_NUMBER]  ),
  .flit_i       (all_rt_flit_channel_1_without_xy            ),
  .flit_look_ahead_routing_i  ('0 ),

  .node_id_x_i  (node_id_x_i),
  .node_id_y_i  (node_id_y_i),

  .flit_dec_o   (rx_flit_dec        [1][0]  ),
  .flit_o       (all_rt_flit_channel_1 [ROUTER_PORT_NUMBER]  )
);

local_port_couple_module
#(
  .VC_NUM_OUTPORT  (VC_NUM_INPUT_L ),
  .VC_DEPTH_OUTPORT(VC_DEPTH_INPUT_L ),
  .OUTPUT_TO_L     (1 )
)
channel_1_couple (
.node_id_x_tgt_i  (rx_flit_dec[1][0].tgt_id.x_position),
.node_id_y_tgt_i  (rx_flit_dec[1][0].tgt_id.y_position ),

.node_id_x_src_i  (rx_flit_dec[1][0].src_id.x_position ),
.node_id_y_src_i  (rx_flit_dec[1][0].src_id.y_position ),

.look_ahead_routing_o (all_rt_flit_look_ahead_routing [1][ROUTER_PORT_NUMBER] ),

.tx_lcrd_v_i          (all_rt_lcrd_v                  [1][ROUTER_PORT_NUMBER] ),
.tx_lcrd_id_i         (all_rt_lcrd_id                 [1][ROUTER_PORT_NUMBER] ),

.flit_vld_i           (all_rt_flit_v                  [1][ROUTER_PORT_NUMBER] ),
.flit_qos_value_i     (rx_flit_dec                    [1][0].qos_value ),

.free_credit_vld_o    (scu_cc_arb_resp_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [1][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);

  // receive
assign cc_arb_scu_resp_vld = rt_all_flit_v      [1][ROUTER_PORT_NUMBER];
assign cc_arb_scu_resp     = rt_all_flit_channel_1 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [1][ROUTER_PORT_NUMBER]  = cc_arb_scu_resp_vld & cc_arb_scu_resp_rdy;
assign rt_all_lcrd_id   [1][ROUTER_PORT_NUMBER]  = '0;

// channel 2, receive evict, no send
  // send
assign all_rt_flit_pend               [2][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_v                  [2][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_channel_2             [ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_vc_id              [2][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_look_ahead_routing [2][ROUTER_PORT_NUMBER] = '0;
  // receive
assign cc_arb_scu_evict_vld = rt_all_flit_v      [2][ROUTER_PORT_NUMBER];
assign cc_arb_scu_evict     = rt_all_flit_channel_2 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [2][ROUTER_PORT_NUMBER]  = scu_evict_hsk;
assign rt_all_lcrd_id   [2][ROUTER_PORT_NUMBER]  = '0;


// channel 3, send and receive data
  // send
cache_scu_cc_data_t  all_rt_flit_channel_3_without_xy; // data

assign all_rt_flit_pend   [3][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [3][ROUTER_PORT_NUMBER] = scu_cc_arb_data_vld & scu_cc_arb_data_rdy;
assign all_rt_flit_channel_3_without_xy           = scu_cc_arb_data;

hn_router_sam
#(
  .flit_payload_t   (cache_scu_cc_data_t)
)
channel_4_decode
(
  .flit_v_i     (all_rt_flit_v      [3][ROUTER_PORT_NUMBER]  ),
  .flit_i       (all_rt_flit_channel_3_without_xy            ),
  .flit_look_ahead_routing_i  ('0 ),

  .node_id_x_i  (node_id_x_i),
  .node_id_y_i  (node_id_y_i),

  .flit_dec_o   (rx_flit_dec        [3][0]  ),
  .flit_o       (all_rt_flit_channel_3 [ROUTER_PORT_NUMBER])
);

local_port_couple_module
#(
  .VC_NUM_OUTPORT  (VC_NUM_INPUT_L ),
  .VC_DEPTH_OUTPORT(VC_DEPTH_INPUT_L ),
  .OUTPUT_TO_L     (1 )
)
channel_3_couple (
.node_id_x_tgt_i  (rx_flit_dec[3][0].tgt_id.x_position),
.node_id_y_tgt_i  (rx_flit_dec[3][0].tgt_id.y_position ),

.node_id_x_src_i  (rx_flit_dec[3][0].src_id.x_position ),
.node_id_y_src_i  (rx_flit_dec[3][0].src_id.y_position ),

.look_ahead_routing_o (all_rt_flit_look_ahead_routing [3][ROUTER_PORT_NUMBER] ),

.tx_lcrd_v_i          (all_rt_lcrd_v                  [3][ROUTER_PORT_NUMBER] ),
.tx_lcrd_id_i         (all_rt_lcrd_id                 [3][ROUTER_PORT_NUMBER] ),

.flit_vld_i           (all_rt_flit_v                  [3][ROUTER_PORT_NUMBER] ),
.flit_qos_value_i     (rx_flit_dec                    [3][0].qos_value ),

.free_credit_vld_o    (scu_cc_arb_data_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [3][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);

  // receive
assign cc_arb_scu_data_vld = rt_all_flit_v      [3][ROUTER_PORT_NUMBER];
assign cc_arb_scu_data     = rt_all_flit_channel_3 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [3][ROUTER_PORT_NUMBER]  = cc_arb_scu_data_vld & cc_arb_scu_data_rdy;
assign rt_all_lcrd_id   [3][ROUTER_PORT_NUMBER]  = '0;


// channel 4, send snp, no receive
  // send
cache_scu_cc_snp_t  all_rt_flit_channel_4_without_xy; // snp

assign all_rt_flit_pend   [4][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [4][ROUTER_PORT_NUMBER] = scu_cc_arb_snp_vld & scu_cc_arb_snp_rdy;
assign all_rt_flit_channel_4_without_xy           = scu_cc_arb_snp;
assign rt_all_lcrd_v      [4][ROUTER_PORT_NUMBER] = '0;
assign rt_all_lcrd_id     [4][ROUTER_PORT_NUMBER] = '0;

hn_router_sam
#(
  .flit_payload_t   (cache_scu_cc_snp_t)
)
channel_5_decode
(
  .flit_v_i     (all_rt_flit_v      [4][ROUTER_PORT_NUMBER]  ),
  .flit_i       (all_rt_flit_channel_4_without_xy  ),
  .flit_look_ahead_routing_i  ('0 ),

  .node_id_x_i  (node_id_x_i),
  .node_id_y_i  (node_id_y_i),

  .flit_dec_o   (rx_flit_dec        [4][0]  ),
  .flit_o       (all_rt_flit_channel_4 [ROUTER_PORT_NUMBER])
);

local_port_couple_module
#(
  .VC_NUM_OUTPORT  (VC_NUM_INPUT_L ),
  .VC_DEPTH_OUTPORT(VC_DEPTH_INPUT_L ),
  .OUTPUT_TO_L     (1 )
)
channel_5_couple (
.node_id_x_tgt_i  (rx_flit_dec[4][0].tgt_id.x_position),
.node_id_y_tgt_i  (rx_flit_dec[4][0].tgt_id.y_position ),

.node_id_x_src_i  (rx_flit_dec[4][0].src_id.x_position ),
.node_id_y_src_i  (rx_flit_dec[4][0].src_id.y_position ),

.look_ahead_routing_o (all_rt_flit_look_ahead_routing [4][ROUTER_PORT_NUMBER] ),

.tx_lcrd_v_i          (all_rt_lcrd_v                  [4][ROUTER_PORT_NUMBER] ),
.tx_lcrd_id_i         (all_rt_lcrd_id                 [4][ROUTER_PORT_NUMBER] ),

.flit_vld_i           (all_rt_flit_v                  [4][ROUTER_PORT_NUMBER] ),
.flit_qos_value_i     (rx_flit_dec                    [4][0].qos_value ),

.free_credit_vld_o    (scu_cc_arb_snp_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [4][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);

`ifndef SYNTHESIS

axi_mem
#(
  .ID_WIDTH($bits(mem_tid_t)),
  .MEM_SIZE(1<<29), // byte 512MB
  .mem_clear(1),
  .mem_simple_seq(0),
  .READ_DELAY_CYCLE(1<<7),
  .READ_DELAY_CYCLE_RANDOMIZE(1),
  .READ_DELAY_CYCLE_RANDOMIZE_UPDATE_CYCLE(1<<10),
  .AXI_DATA_WIDTH(MEM_DATA_WIDTH) // bit
) 
axi_mem_0(
  .clk   (clk)
 ,.rst_n (rst_n)
  //AW
 ,.i_awid (scu_mem_aw.awid)  
 ,.i_awaddr (scu_mem_aw.awaddr)
 ,.i_awlen (scu_mem_aw.awlen)
 ,.i_awsize (scu_mem_aw.awsize)
 ,.i_awburst (scu_mem_aw.awburst) // INCR mode
 ,.i_awvalid (scu_mem_awvalid)
 ,.o_awready (scu_mem_awready)
  //AR
 ,.i_arid (scu_mem_ar.arid)
 ,.i_araddr (scu_mem_ar.araddr)
 ,.i_arlen (scu_mem_ar.arlen)
 ,.i_arsize (scu_mem_ar.arsize)
 ,.i_arburst (scu_mem_ar.arburst)
 ,.i_arvalid (scu_mem_arvalid)
 ,.o_arready (scu_mem_arready)
  //W
 ,.i_wdata (scu_mem_w.wdata)
 ,.i_wstrb ('1)
 ,.i_wlast (scu_mem_w.wlast)
 ,.i_wvalid (scu_mem_wvalid)
 ,.o_wready (scu_mem_wready)
  //B
 ,.o_bid (scu_mem_b.bid)
 ,.o_bresp (scu_mem_b.bresp)
 ,.o_bvalid (scu_mem_bvalid)
 ,.i_bready (scu_mem_bready)
  //R
 ,.o_rid    (scu_mem_r.rid)
 ,.o_rdata  (scu_mem_r.dat)
 ,.o_rresp  (scu_mem_r.rresp)
 ,.o_rlast  (scu_mem_r.rlast)
 ,.o_rvalid (scu_mem_rvalid)
 ,.i_rready (scu_mem_rready)

);
assign scu_mem_r.mesi_sta  = EXCLUSIVE;
assign scu_mem_r.err       = 1'b0;

`endif

endmodule
