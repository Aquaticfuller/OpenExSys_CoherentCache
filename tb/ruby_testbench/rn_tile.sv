module rn_tile
  import rvh_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_noc_pkg::*;
  import uop_encoding_pkg::*;
  import riscv_pkg::*;
`ifdef RUBY
  import ruby_pkg::*;
`endif
  #(
    parameter CHANNEL_NUM = 5,
    parameter CORE_ID = 0
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
    input  logic                [NodeID_X_Width-1:0]                                      node_id_x_i,
    input  logic                [NodeID_Y_Width-1:0]                                      node_id_y_i,

    input  logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               ls_pipe_l1d_ld_req_vld,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               ls_pipe_l1d_ld_req_io_region,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0]                       ls_pipe_l1d_ld_req_rob_tag,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0]                       ls_pipe_l1d_ld_req_prd,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][      LDU_OP_WIDTH-1:0]                       ls_pipe_l1d_ld_req_opcode,
`ifdef RUBY
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]                       ls_pipe_l1d_ld_req_lsu_tag,
`endif    
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][       L1D_INDEX_WIDTH-1:0]                   ls_pipe_l1d_ld_req_idx,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][      L1D_OFFSET_WIDTH-1:0]                   ls_pipe_l1d_ld_req_offset,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][     L1D_TAG_WIDTH-1:0]                       ls_pipe_l1d_ld_req_vtag,                                                       
    output logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               ls_pipe_l1d_ld_req_rdy,
`ifdef RUBY
    output logic  [LSU_ADDR_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0]                ls_pipe_l1d_ld_req_hit_bank_id,
    output logic  [LSU_DATA_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0]                ls_pipe_l1d_st_req_hit_bank_id,
`endif
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               dtlb_l1d_resp_vld,                           
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0][         PPN_WIDTH-1:0]                       dtlb_l1d_resp_ppn,                   
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               dtlb_l1d_resp_excp_vld,
    input  logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               dtlb_l1d_resp_hit,
    input  logic  [LSU_DATA_PIPE_COUNT-1:0]                                               ls_pipe_l1d_st_req_vld,  
    input  logic  [LSU_DATA_PIPE_COUNT-1:0]                                               ls_pipe_l1d_st_req_io_region,    
    input  logic  [LSU_DATA_PIPE_COUNT-1:0]                                               ls_pipe_l1d_st_req_is_fence,    
    input  logic  [LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0]                       ls_pipe_l1d_st_req_rob_tag,                              
    input  logic  [LSU_DATA_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0]                       ls_pipe_l1d_st_req_prd,                        
    input  logic  [LSU_DATA_PIPE_COUNT-1:0][      STU_OP_WIDTH-1:0]                       ls_pipe_l1d_st_req_opcode, 
`ifdef RUBY
    input  logic  [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]                       ls_pipe_l1d_st_req_lsu_tag,                         
`endif
    input  logic  [LSU_DATA_PIPE_COUNT-1:0][       PADDR_WIDTH-1:0]                       ls_pipe_l1d_st_req_paddr,
    input  logic  [LSU_DATA_PIPE_COUNT-1:0][              XLEN-1:0]                       ls_pipe_l1d_st_req_data,                                                                  
    output logic  [LSU_DATA_PIPE_COUNT-1:0]                                               ls_pipe_l1d_st_req_rdy,
`ifdef RUBY
    output logic  [LSU_DATA_PIPE_COUNT-1:0]                                               l1d_lsu_st_lsu_tag_vld_per_input_port,
    output logic  [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]                       l1d_lsu_st_lsu_tag_per_input_port,
    input  logic  [LSU_DATA_PIPE_COUNT-1:0]                                               l1d_lsu_st_lsu_tag_rdy_per_input_port,                               
`endif
    output logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               l1d_ls_pipe_replay_vld, 
`ifdef RUBY                                                                                                                                                   
    output logic  [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]                       l1d_ls_pipe_replay_lsu_tag,                                                                                        
`endif
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                                                ls_pipe_l1d_kill_resp,
    output logic  [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0]                           l1d_rob_wb_vld,
    output logic  [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0]   l1d_rob_wb_rob_tag,                                            
    output logic  [LSU_ADDR_PIPE_COUNT-1:0]                                               l1d_int_prf_wb_vld,                               
    output logic  [LSU_ADDR_PIPE_COUNT-1:0][INT_PREG_TAG_WIDTH-1:0]                       l1d_int_prf_wb_tag,   
    output logic  [LSU_ADDR_PIPE_COUNT-1:0][              XLEN-1:0]                       l1d_int_prf_wb_data,
`ifdef RUBY
    output logic  [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]                       l1d_lsu_lsu_tag,                             
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

cache_scu_cc_req_t   [OUTPUT_PORT_NUM-1:0]                                 rt_all_flit_channel_0; // req
cache_scu_cc_resp_t  [OUTPUT_PORT_NUM-1:0]                                 rt_all_flit_channel_1; // resp
cache_scu_cc_req_t   [OUTPUT_PORT_NUM-1:0]                                 rt_all_flit_channel_2; // evict
cache_scu_cc_data_t  [OUTPUT_PORT_NUM-1:0]                                 rt_all_flit_channel_3; // data
cache_scu_cc_snp_t   [OUTPUT_PORT_NUM-1:0]                                 rt_all_flit_channel_4; // snp


logic                          ptw_walk_req_rdy_o;
logic                          ptw_walk_resp_vld_o;
logic [      PTW_ID_WIDTH-1:0] ptw_walk_resp_id_o;
logic [         PTE_WIDTH-1:0] ptw_walk_resp_pte_o;

// scu rx port, private cache -> scu
    // req
logic                 pc_cc_arb_req_vld;
cache_scu_cc_req_t    pc_cc_arb_req;
logic                 pc_cc_arb_req_rdy;

  // resp
logic                 pc_cc_arb_resp_vld;
cache_scu_cc_resp_t   pc_cc_arb_resp;
logic                 pc_cc_arb_resp_rdy;

  // evict/wb
logic                 pc_cc_arb_evict_vld;
cache_scu_cc_req_t    pc_cc_arb_evict;
logic                 pc_cc_arb_evict_rdy;

  // data
logic                 pc_cc_arb_data_vld;
cache_scu_cc_data_t   pc_cc_arb_data;
logic                 pc_cc_arb_data_rdy;

// scu tx port, scu -> private cache
  // resp
logic                 cc_arb_pc_resp_vld;
cache_scu_cc_resp_t   cc_arb_pc_resp;
logic                 cc_arb_pc_resp_rdy;

  // snp
logic                 cc_arb_pc_snp_vld;
cache_scu_cc_snp_t    cc_arb_pc_snp;
logic                 cc_arb_pc_snp_rdy;

  // data
logic                 cc_arb_pc_data_vld;
cache_scu_cc_data_t   cc_arb_pc_data;
logic                 cc_arb_pc_data_rdy;

logic                 snp_req_buf_order_fifo_dq_vld;


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

logic [L1D_BANK_ID_NUM-1:0]  snp_req_head_buf_valid_clr;

rvh_l1d
#(
  .CORE_ID(CORE_ID)
)
rvh_l1d_u
(
    // LS Pipe -> D$ : Load request
    .ls_pipe_l1d_ld_req_vld_i                     (ls_pipe_l1d_ld_req_vld          ),
    .ls_pipe_l1d_ld_req_io_i                      (ls_pipe_l1d_ld_req_io_region    ),
    .ls_pipe_l1d_ld_req_rob_tag_i                 (ls_pipe_l1d_ld_req_rob_tag      ), 
    .ls_pipe_l1d_ld_req_prd_i                     (ls_pipe_l1d_ld_req_prd          ), 
    .ls_pipe_l1d_ld_req_opcode_i                  (ls_pipe_l1d_ld_req_opcode       ),        
`ifdef RUBY                      
    .ls_pipe_l1d_ld_req_lsu_tag_i                 (ls_pipe_l1d_ld_req_lsu_tag      ),
`endif
    .ls_pipe_l1d_ld_req_index_i                   (ls_pipe_l1d_ld_req_idx          ),
    .ls_pipe_l1d_ld_req_offset_i                  (ls_pipe_l1d_ld_req_offset       ),
    .ls_pipe_l1d_ld_req_vtag_i                    (ls_pipe_l1d_ld_req_vtag         ),                                                            
    .ls_pipe_l1d_ld_req_rdy_o                     (ls_pipe_l1d_ld_req_rdy          ), 
`ifdef RUBY
    .ls_pipe_l1d_ld_req_hit_bank_id_o             (ls_pipe_l1d_ld_req_hit_bank_id  ),
    .ls_pipe_l1d_st_req_hit_bank_id_o             (ls_pipe_l1d_st_req_hit_bank_id  ),
`endif                                                  
    // LS Pipe -> D$ : DTLB response
    .ls_pipe_l1d_dtlb_resp_vld_i                   (dtlb_l1d_resp_vld            ),                              
    .ls_pipe_l1d_dtlb_resp_ppn_i                   (dtlb_l1d_resp_ppn            ), // VIPT, get at s1 if tlb hit                   
    .ls_pipe_l1d_dtlb_resp_excp_vld_i              (dtlb_l1d_resp_excp_vld       ), // s1 kill
    .ls_pipe_l1d_dtlb_resp_hit_i                   (dtlb_l1d_resp_hit            ),      // s1 kill 
    .ls_pipe_l1d_dtlb_resp_miss_i                  (~dtlb_l1d_resp_hit            ),                              
    // LS Pipe -> D$ : Store request
    .ls_pipe_l1d_st_req_vld_i                      (ls_pipe_l1d_st_req_vld       ),  
    .ls_pipe_l1d_st_req_io_i                       (ls_pipe_l1d_st_req_io_region  ),                                  
    .ls_pipe_l1d_st_req_is_fence_i                 (ls_pipe_l1d_st_req_is_fence   ),
    .ls_pipe_l1d_st_req_rob_tag_i                  (ls_pipe_l1d_st_req_rob_tag   ),                                   
    .ls_pipe_l1d_st_req_prd_i                      (ls_pipe_l1d_st_req_prd       ),                                   
    .ls_pipe_l1d_st_req_opcode_i                   (ls_pipe_l1d_st_req_opcode    ), 
`ifdef RUBY                      
    .ls_pipe_l1d_st_req_lsu_tag_i                  (ls_pipe_l1d_st_req_lsu_tag      ),
`endif                                  
    // .ls_pipe_l1d_st_req_index_i                    (ls_pipe_l1d_st_req_paddr[L1D_INDEX_WIDTH-1:0]     ),                                                                 
    // .ls_pipe_l1d_st_req_tag_i                      (ls_pipe_l1d_st_req_paddr[PADDR_WIDTH-1:L1D_INDEX_WIDTH]     ),                                    
    .ls_pipe_l1d_st_req_paddr_i                    (ls_pipe_l1d_st_req_paddr     ),
    .ls_pipe_l1d_st_req_data_i                     (ls_pipe_l1d_st_req_data      ), // data from stb                                                                  
    .ls_pipe_l1d_st_req_rdy_o                      (ls_pipe_l1d_st_req_rdy       ),    
    
`ifdef RUBY
    .l1d_lsu_st_lsu_tag_vld_per_input_port_o       (l1d_lsu_st_lsu_tag_vld_per_input_port ),
    .l1d_lsu_st_lsu_tag_per_input_port_o           (l1d_lsu_st_lsu_tag_per_input_port     ),
    .l1d_lsu_st_lsu_tag_rdy_per_input_port_i       (l1d_lsu_st_lsu_tag_rdy_per_input_port ),
`endif
    // L1D -> LS Pipe : D-Cache MSHR Full, Replay load                                     
    .l1d_ls_pipe_ld_replay_valid_o                (l1d_ls_pipe_replay_vld       ),                               
`ifdef RUBY                                                                                                                                      
    .l1d_ls_pipe_replay_lsu_tag_o                  (l1d_ls_pipe_replay_lsu_tag   ),                                                                                                
`endif                                             
    // LS Pipe -> L1D : Kill D-Cache Response
    .ls_pipe_l1d_kill_resp_i                       (ls_pipe_l1d_kill_resp   ), // TODO:
    // D$ -> ROB : Write Back
    .l1d_rob_wb_vld_o                              (l1d_rob_wb_vld               ), // TODO:
    .l1d_rob_wb_rob_tag_o                          (l1d_rob_wb_rob_tag           ), // TODO:
    // D$ -> Int PRF : Write Back                                                
    .l1d_int_prf_wb_vld_o                          (l1d_int_prf_wb_vld           ),                              
    .l1d_int_prf_wb_tag_o                          (l1d_int_prf_wb_tag           ),
    .l1d_int_prf_wb_data_o                         (l1d_int_prf_wb_data          ),
`ifdef RUBY                                        
    .l1d_lsu_lsu_tag_o                             (l1d_lsu_lsu_tag              ),                              
`endif                                             
    // PTW -> D$ : Request
    .ptw_walk_req_vld_i ('0   ),
    .ptw_walk_req_id_i ('0   ),
    .ptw_walk_req_addr_i ('0   ),
    .ptw_walk_req_rdy_o (ptw_walk_req_rdy_o  ),
    // PTW -> D$ : Response
        // ptw walk response port
    .ptw_walk_resp_vld_o (ptw_walk_resp_vld_o  ),
    .ptw_walk_resp_id_o (ptw_walk_resp_id_o  ),
    .ptw_walk_resp_pte_o (ptw_walk_resp_pte_o  ),
    .ptw_walk_resp_rdy_i ('0   ),
    // cache tx port, private cache -> scu
      // req
    .pc_scu_req_vld_o           (pc_cc_arb_req_vld  ),//0
    .pc_scu_req_o               (pc_cc_arb_req  ),
    .pc_scu_req_rdy_i           (pc_cc_arb_req_rdy  ),
  
      // resp
    .pc_scu_resp_vld_o          (pc_cc_arb_resp_vld  ),//1
    .pc_scu_resp_o              (pc_cc_arb_resp  ),
    .pc_scu_resp_rdy_i          (pc_cc_arb_resp_rdy  ),
  
      // evict/wb
    .pc_scu_evict_vld_o         (pc_cc_arb_evict_vld  ),//2
    .pc_scu_evict_o             (pc_cc_arb_evict  ),
    .pc_scu_evict_rdy_i         (pc_cc_arb_evict_rdy  ),
  
      // data
    .pc_scu_data_vld_o          (pc_cc_arb_data_vld  ),//3
    .pc_scu_data_o              (pc_cc_arb_data  ),
    .pc_scu_data_rdy_i          (pc_cc_arb_data_rdy  ),
  
    // cache rx port, scu -> private cache
      // resp
    .scu_pc_resp_vld_i          (cc_arb_pc_resp_vld  ),//1
    .scu_pc_resp_i              (cc_arb_pc_resp  ),
    .scu_pc_resp_rdy_o          (cc_arb_pc_resp_rdy  ),
  
      // snp
    .scu_pc_snp_vld_i           (cc_arb_pc_snp_vld  ),//4
    .scu_pc_snp_i               (cc_arb_pc_snp  ),
    .scu_pc_snp_rdy_o           (cc_arb_pc_snp_rdy  ),
  
      // data
    .scu_pc_data_vld_i          (cc_arb_pc_data_vld  ),//3
    .scu_pc_data_i              (cc_arb_pc_data  ),
    .scu_pc_data_rdy_o          (cc_arb_pc_data_rdy  ),
    .snp_req_head_buf_valid_clr_o (snp_req_head_buf_valid_clr),
    .rob_flush_i                          (1'b0   ),
    .fencei_flush_vld_i                   (1'b0   ),
    .fencei_flush_grant_o                 (       ),
    .clk                              (clk                ),
    .rst                              (rst_n              ) 
);

flit_dec_t  [CHANNEL_NUM-1:0][LOCAL_PORT_NUMBER-1:0]  rx_flit_dec;

// channel 0, send req, no receive
cache_scu_cc_req_t  all_rt_flit_channel_0_without_xy;

assign all_rt_flit_pend   [0][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [0][ROUTER_PORT_NUMBER] = pc_cc_arb_req_vld & pc_cc_arb_req_rdy;
assign all_rt_flit_channel_0_without_xy           = pc_cc_arb_req;
assign rt_all_lcrd_v      [0][ROUTER_PORT_NUMBER] = '0;
assign rt_all_lcrd_id     [0][ROUTER_PORT_NUMBER] = '0;

rn_router_sam
#(
  .flit_payload_t   (cache_scu_cc_req_t)
)
channel_0_decode
(
  .flit_v_i     (all_rt_flit_v      [0][ROUTER_PORT_NUMBER]  ),
  .flit_i       (all_rt_flit_channel_0_without_xy            ),
  .flit_look_ahead_routing_i  ('0 ),

  .node_id_x_i  (node_id_x_i),
  .node_id_y_i  (node_id_y_i),

  .flit_dec_o   (rx_flit_dec[0][0]  ),
  .flit_o       (all_rt_flit_channel_0 [ROUTER_PORT_NUMBER])
);

local_port_couple_module
#(
  .VC_NUM_OUTPORT  (VC_NUM_INPUT_L ),
  .VC_DEPTH_OUTPORT(VC_DEPTH_INPUT_L ),
  .OUTPUT_TO_L     (1 )
)
channel_0_couple (
.node_id_x_tgt_i  (rx_flit_dec[0][0].tgt_id.x_position),
.node_id_y_tgt_i  (rx_flit_dec[0][0].tgt_id.y_position ),

.node_id_x_src_i  (rx_flit_dec[0][0].src_id.x_position ),
.node_id_y_src_i  (rx_flit_dec[0][0].src_id.y_position ),

.look_ahead_routing_o (all_rt_flit_look_ahead_routing [0][ROUTER_PORT_NUMBER] ),

.tx_lcrd_v_i          (all_rt_lcrd_v                  [0][ROUTER_PORT_NUMBER] ),
.tx_lcrd_id_i         (all_rt_lcrd_id                 [0][ROUTER_PORT_NUMBER] ),

.flit_vld_i           (all_rt_flit_v                  [0][ROUTER_PORT_NUMBER] ),
.flit_qos_value_i     (rx_flit_dec[0][0].qos_value ),

.free_credit_vld_o    (pc_cc_arb_req_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [0][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);

// channel 1 , send response, reveive response
  // send
cache_scu_cc_resp_t  all_rt_flit_channel_1_without_xy;

assign all_rt_flit_pend   [1][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [1][ROUTER_PORT_NUMBER] = pc_cc_arb_resp_vld & pc_cc_arb_resp_rdy;
assign all_rt_flit_channel_1_without_xy           = pc_cc_arb_resp;

rn_router_sam
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

  .flit_dec_o   (rx_flit_dec[1][0]  ),
  .flit_o       (all_rt_flit_channel_1 [ROUTER_PORT_NUMBER])
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
.flit_qos_value_i     (rx_flit_dec[1][0].qos_value ),

.free_credit_vld_o    (pc_cc_arb_resp_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [1][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);

  // receive
assign cc_arb_pc_resp_vld = rt_all_flit_v      [1][ROUTER_PORT_NUMBER];
assign cc_arb_pc_resp     = rt_all_flit_channel_1 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [1][ROUTER_PORT_NUMBER]  = cc_arb_pc_resp_vld & cc_arb_pc_resp_rdy;
assign rt_all_lcrd_id   [1][ROUTER_PORT_NUMBER]  = '0;



//channel 2, send evict, no receive
  // send
cache_scu_cc_req_t  all_rt_flit_channel_2_without_xy;

assign all_rt_flit_pend   [2][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [2][ROUTER_PORT_NUMBER] = pc_cc_arb_evict_vld & pc_cc_arb_evict_rdy;
assign all_rt_flit_channel_2_without_xy           = pc_cc_arb_evict;
assign rt_all_lcrd_v      [2][ROUTER_PORT_NUMBER] = '0;
assign rt_all_lcrd_id     [2][ROUTER_PORT_NUMBER] = '0;

rn_router_sam
#(
  .flit_payload_t   (cache_scu_cc_req_t)
)
channel_2_decode
(
  .flit_v_i     (all_rt_flit_v      [2][ROUTER_PORT_NUMBER]  ),
  .flit_i       (all_rt_flit_channel_2_without_xy            ),
  .flit_look_ahead_routing_i  ('0 ),

  .node_id_x_i  (node_id_x_i),
  .node_id_y_i  (node_id_y_i),

  .flit_dec_o   (rx_flit_dec[2][0]  ),
  .flit_o       (all_rt_flit_channel_2 [ROUTER_PORT_NUMBER])
);

local_port_couple_module
#(
  .VC_NUM_OUTPORT  (VC_NUM_INPUT_L ),
  .VC_DEPTH_OUTPORT(VC_DEPTH_INPUT_L ),
  .OUTPUT_TO_L     (1 )
)
channel_2_couple (
.node_id_x_tgt_i  (rx_flit_dec[2][0].tgt_id.x_position),
.node_id_y_tgt_i  (rx_flit_dec[2][0].tgt_id.y_position ),

.node_id_x_src_i  (rx_flit_dec[2][0].src_id.x_position ),
.node_id_y_src_i  (rx_flit_dec[2][0].src_id.y_position ),

.look_ahead_routing_o (all_rt_flit_look_ahead_routing [2][ROUTER_PORT_NUMBER] ),

.tx_lcrd_v_i          (all_rt_lcrd_v                  [2][ROUTER_PORT_NUMBER] ),
.tx_lcrd_id_i         (all_rt_lcrd_id                 [2][ROUTER_PORT_NUMBER] ),

.flit_vld_i           (all_rt_flit_v                  [2][ROUTER_PORT_NUMBER] ),
.flit_qos_value_i     (rx_flit_dec[2][0].qos_value ),

.free_credit_vld_o    (pc_cc_arb_evict_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [2][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);





//channel 3, send data, receive data
  // send
cache_scu_cc_data_t  all_rt_flit_channel_3_without_xy;

assign all_rt_flit_pend   [3][ROUTER_PORT_NUMBER] = 1'b1;
assign all_rt_flit_v      [3][ROUTER_PORT_NUMBER] = pc_cc_arb_data_vld & pc_cc_arb_data_rdy;
assign all_rt_flit_channel_3_without_xy           = pc_cc_arb_data;

rn_router_sam
#(
  .flit_payload_t   (cache_scu_cc_data_t)
)
channel_3_decode
(
  .flit_v_i     (all_rt_flit_v      [3][ROUTER_PORT_NUMBER]  ),
  .flit_i       (all_rt_flit_channel_3_without_xy            ),
  .flit_look_ahead_routing_i  ('0 ),

  .node_id_x_i  (node_id_x_i),
  .node_id_y_i  (node_id_y_i),

  .flit_dec_o   (rx_flit_dec[3][0]  ),
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
.flit_qos_value_i     (rx_flit_dec[3][0].qos_value ),

.free_credit_vld_o    (pc_cc_arb_data_rdy), 
.free_credit_vc_id_o  (all_rt_flit_vc_id              [3][ROUTER_PORT_NUMBER]),

.clk   (clk),
.rstn  (rst_n)
);

  // receive
assign cc_arb_pc_data_vld = rt_all_flit_v      [3][ROUTER_PORT_NUMBER];
assign cc_arb_pc_data     = rt_all_flit_channel_3 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [3][ROUTER_PORT_NUMBER]  = cc_arb_pc_data_vld & cc_arb_pc_data_rdy;
assign rt_all_lcrd_id   [3][ROUTER_PORT_NUMBER]  = '0;


//channel 4, no send ,receive snoop
logic [L1D_BANK_ID_INDEX_WIDTH-1+1:0] snp_req_head_buf_valid_clr_num;
logic [L1D_BANK_ID_NUM-1:0] snp_req_head_buf_valid_clr_num_vector;
logic snp_req_head_buf_valid_clr_from_buf_vld;
logic snp_req_head_buf_valid_clr_from_buf_re;

  // send
assign all_rt_flit_pend               [4][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_v                  [4][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_channel_4             [ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_vc_id              [4][ROUTER_PORT_NUMBER] = '0;
assign all_rt_flit_look_ahead_routing [4][ROUTER_PORT_NUMBER] = '0;
  // receive
assign cc_arb_pc_snp_vld  = rt_all_flit_v      [4][ROUTER_PORT_NUMBER];
assign cc_arb_pc_snp      = rt_all_flit_channel_4 [ROUTER_PORT_NUMBER];
assign rt_all_lcrd_v    [4][ROUTER_PORT_NUMBER]  = (|snp_req_head_buf_valid_clr) | snp_req_head_buf_valid_clr_from_buf_vld;
assign rt_all_lcrd_id   [4][ROUTER_PORT_NUMBER]  = '0;

assign snp_req_head_buf_valid_clr_num_vector  = (snp_req_head_buf_valid_clr_num > 1) ? L1D_BANK_ID_NUM'((1 << (snp_req_head_buf_valid_clr_num-1)) - 1)
                                                                                     : '0;
assign snp_req_head_buf_valid_clr_from_buf_re = snp_req_head_buf_valid_clr_from_buf_vld & ~(|snp_req_head_buf_valid_clr);
one_counter
#(
  .DATA_WIDTH(L1D_BANK_ID_NUM)
)
snp_req_head_buf_valid_clr_counter_u
(
    .data_i(snp_req_head_buf_valid_clr),
    .cnt_o(snp_req_head_buf_valid_clr_num)
);

mp_fifo
#(
  .payload_t          (logic  ),
  .ENQUEUE_WIDTH      (L1D_BANK_ID_NUM        ),
  .DEQUEUE_WIDTH      (1        ),
  .DEPTH              (VC_DEPTH_MAX * L1D_BANK_ID_NUM ),
  .MUST_TAKEN_ALL     (0                      )
)
snp_req_head_buf_valid_clr_overflow_fifo_u
(
  // Enqueue
  .enqueue_vld_i          (snp_req_head_buf_valid_clr_num_vector),
  .enqueue_payload_i      ('1),
  .enqueue_rdy_o          (),
  // Dequeue
  .dequeue_vld_o          (snp_req_head_buf_valid_clr_from_buf_vld),
  .dequeue_payload_o      (),
  .dequeue_rdy_i          (snp_req_head_buf_valid_clr_from_buf_re),
  
  .flush_i                (1'b0                          ),
  
  .clk                    (clk                           ),
  .rst                    (~rst_n                        )
);



endmodule
