`timescale 1ns/1ps
module top_sliced_llc
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_cc_pkg::*;
    import rvh_l1d_pkg::*;
    import rvh_noc_pkg::*;
    import riscv_pkg::*;
`ifdef EBI
    import ebi_pkg::*;
`endif
`ifdef RUBY
    import ruby_pkg::*;
`endif
    import rvh_uncore_param_pkg::*;

();

  logic clk, rst_n, bus_clk;
  logic [10-1:0] counter;
  logic [64-1:0] cycle;
  genvar i;

// `ifdef RUBY
// //rubytop_l1d_adaptor
// parameter RUBY_TOP_L1D_PORT_NUM = 2;
// parameter RUBY_TOP_L1D_NUM = 2;
// `endif

//clock generate
  initial begin
    clk = 1'b0;
    forever #0.5 clk = ~clk;
  end
`ifdef EBI
  initial begin
    bus_clk = 1'b0;
    forever #1 bus_clk = ~bus_clk;
  end
`endif
  //reset generate
  initial begin
    rst_n = 1'b0;
    #20;
    rst_n = 1'b1;
  end
  
// `ifndef RUBY
//   initial begin
//     #10000;
//     $finish();
//   end
// `endif
  // always_ff @(posedge clk) begin
  //   if(cycle >= 50) begin
  //     $finish();
  //   end
  // end

  //wave dump
  initial begin
    int dumpon = 0;
    string log;
    string wav;
    string dump_name;
    $value$plusargs("dumpon=%d",dumpon);
    $value$plusargs("dumpon=%s",dump_name);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("!!!!!!!!!!wave_log= %s",log);
    end
    wav = {log,"/waves_",dump_name,".fsdb"};
    $display("!!!!!!wave_log= %s",wav);
    if(dumpon > 0) begin
      // $fsdbDumpfile(wav);
      $fsdbAutoSwitchDumpfile(1000,wav,0);
      $fsdbDumpvars(0,top_sliced_llc);
      $fsdbDumpvars("+struct");
      $fsdbDumpvars("+mda");
      $fsdbDumpvars("+all");
      $fsdbDumpMDA();
      $fsdbDumpon;
    end
  end


  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      counter <= '0;
      cycle   <= '0;
    end else begin
      counter <= counter + 1;
      cycle   <= cycle + 1;
    end
  end

  // always_comb begin
  //   if(counter[6:0] == 7'b0) begin
  //     $display("counter == %d", counter);
  //   end
  // end

  int debug_print= 0;
  int ebi_debug_print= 0;
`ifdef RUBY
  int rseed0 = RT_CHECK_GEN_ADDR_W'(1<<(RT_CHECK_GEN_ADDR_W-1));//?
  int rseed1 = $bits(lsu_op_e)'(1<<($bits(lsu_op_e)-1));//?
  int timeout_count= 20000;
  
  `ifdef RT_MODE_CLASSIC
  logic [RT_CID_DELTA_NUM_W-1:0]    _rt_cid_delta_seed = '0;
  logic [RT_CHECK_NUM_W-1:0]        _rt_cid_base_seed = '0;
  `else
  logic [RT_CHECK_GEN_ADDR_W-1:0]   _rt_info_addr_seed = RT_CHECK_GEN_ADDR_W'(1<<(RT_CHECK_GEN_ADDR_W-1));
  logic [$bits(lsu_op_e)-1:0]       _rt_info_opcode_seed = $bits(lsu_op_e)'(1<<($bits(lsu_op_e)-1));
  `endif 
  
  initial begin

    #1
    `ifdef RT_MODE_CLASSIC
        _rt_cid_delta_seed = rseed0;
        _rt_cid_base_seed  = rseed1;
    `else
        _rt_info_addr_seed = rseed0;
        _rt_info_opcode_seed = rseed1;
    `endif
    
  end
`endif


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
  
  // LS_PIPE -> D$ : LD Request
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_vld;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_io_region;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][ ROB_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_rob_tag;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][PREG_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_prd;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode;
`ifdef RUBY
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_ld_req_lsu_tag;
`endif

  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_INDEX_WIDTH-1:0 ] ls_pipe_l1d_ld_req_idx;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_ld_req_offset;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_TAG_WIDTH-1:0]    ls_pipe_l1d_ld_req_vtag;

  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_rdy;
`ifdef RUBY
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_hit_bank_id;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_hit_bank_id;
`endif
  // LS_PIPE -> D$ : ST Request
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_vld;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_io_region;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_is_fence;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_kill_resp;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_rob_tag;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_prd;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode;
`ifdef RUBY
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH -1:0]ls_pipe_l1d_st_req_lsu_tag;
`endif
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][       PADDR_WIDTH-1:0] ls_pipe_l1d_st_req_paddr;


  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][            XLEN  -1:0] ls_pipe_l1d_st_req_data; // data from lsu
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][  L1D_STB_DATA_WIDTH/8-1:0] ls_pipe_l1d_st_req_data_byte_mask; // data byte mask from stb
  
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_rdy;

`ifdef RUBY
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         l1d_lsu_st_lsu_tag_vld_per_input_port;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_lsu_st_lsu_tag_per_input_port;
  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         l1d_lsu_st_lsu_tag_rdy_per_input_port;
`endif

  // DTLB -> D$
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_vld;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_excp_vld; // s1 kill
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_hit;      // s1 kill
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][       PPN_WIDTH-1:0]   dtlb_l1d_resp_ppn;  // VIPT, get at s1 if tlb hit
  
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_rdy;

  // D$ -> LSQ, mshr full replay
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_replay_vld;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_mshr_full;
`ifdef RUBY
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_ls_pipe_replay_lsu_tag;
`endif

  // D$ -> ROB : Write Back
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0]                         l1d_rob_wb_vld;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag;
  // D$ -> Int PRF : Write Back
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         l1d_int_prf_wb_vld;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] l1d_int_prf_wb_tag;
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][              XLEN-1:0] l1d_int_prf_wb_data;
`ifdef RUBY
  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH -1:0]l1d_lsu_lsu_tag;
`endif
  
// L1D-> LSU : evict or snooped // move to lid, not in bank // TODO:
//  logic                          l1d_lsu_invld_vld;
//  logic [PADDR_WIDTH-1:0]        l1d_lsu_invld_tag; // tag+bankid



//NOC

  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                       tx_flit_pend;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                       tx_flit_v;
  cache_scu_cc_req_t      [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        tx_flit_channel_0;
  cache_scu_cc_resp_t     [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        tx_flit_channel_1;
  cache_scu_cc_req_t      [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        tx_flit_channel_2;
  cache_scu_cc_data_t     [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        tx_flit_channel_3;
  cache_scu_cc_snp_t      [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        tx_flit_channel_4;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]  tx_flit_vc_id;
  io_port_t               [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                       tx_flit_look_ahead_routing;

  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                       rx_flit_pend;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                       rx_flit_v;
  cache_scu_cc_req_t      [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        rx_flit_channel_0;
  cache_scu_cc_resp_t     [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        rx_flit_channel_1;
  cache_scu_cc_req_t      [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        rx_flit_channel_2;
  cache_scu_cc_data_t     [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        rx_flit_channel_3;
  cache_scu_cc_snp_t      [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0]                                        rx_flit_channel_4;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]  rx_flit_vc_id;
  io_port_t               [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                       rx_flit_look_ahead_routing;

  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                        tx_lcrd_v;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]   tx_lcrd_id;

  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0]                        rx_lcrd_v;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][ROUTER_PORT_NUMBER-1:0][VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id;


  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][NodeID_X_Width-1:0]                        node_id_x;
  logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][CHANNEL_NUM-1:0][NodeID_Y_Width-1:0]                        node_id_y;

logic [L1D_NUM - 1 : 0] snp_req_buf_order_fifo_dq_vld;
logic scu_evict_hsk;
logic scu_req_hsk;


`ifdef EBI
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                       tx_flit_pend_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                       tx_flit_v_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_flit_vc_id_e;
io_port_t               [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                       tx_flit_look_ahead_routing_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                       rx_flit_pend_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                       rx_flit_v_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  rx_flit_vc_id_e;
io_port_t               [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                       rx_flit_look_ahead_routing_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                        tx_lcrd_v_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   tx_lcrd_id_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0]                        rx_lcrd_v_e;
logic                   [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][ROUTER_PORT_NUMBER-1:0][CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id_e;

logic [NODE_NUM_X_DIMESION-2:0][NODE_NUM_Y_DIMESION-1:0][OFF_DIE_WD-1:0] x_inc_bus;
logic [NODE_NUM_X_DIMESION-2:0][NODE_NUM_Y_DIMESION-1:0][OFF_DIE_WD-1:0] x_dec_bus;
logic [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-2:0][OFF_DIE_WD-1:0] y_inc_bus;
logic [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-2:0][OFF_DIE_WD-1:0] y_dec_bus;
logic [NODE_NUM_X_DIMESION-2:0][NODE_NUM_Y_DIMESION-1:0] x_inc_credit;
logic [NODE_NUM_X_DIMESION-2:0][NODE_NUM_Y_DIMESION-1:0] x_dec_credit;
logic [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-2:0] y_inc_credit;
logic [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-2:0] y_dec_credit;
`endif

`ifdef RUBY
//rubytop_l1d_adaptor


parameter RT_LD_ST_PAIR_NUM  = L1D_NUM * (LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT)/2; // 2 load + 2 store ports

logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_req_valid;
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_req_ready;
rrv64_lsu_l1d_req_t  [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_req;
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_resp_valid;
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_resp_ready;
rrv64_lsu_l1d_resp_t [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_resp;

//l1dc
logic                [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_req_valid;
logic                [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_req_ready;
rrv64_lsu_l1d_req_t  [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_req;
logic                [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp_valid;
rrv64_lsu_l1d_resp_t [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp;

`ifdef RUBY
logic                [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] lsu_l1d_ld_req_bank_id;
logic                [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] lsu_l1d_st_req_bank_id;
`endif

logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][LDU_OP_WIDTH-1:0]         ls_pipe_l1d_ld_req_opcode_transed;
logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][STU_OP_WIDTH-1:0]         ls_pipe_l1d_st_req_opcode_transed;
logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][L1D_STB_DATA_WIDTH-1:0]       ls_pipe_l1d_st_req_data_transed; // data from stb
logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][L1D_STB_DATA_WIDTH/8-1:0]     ls_pipe_l1d_st_req_data_byte_mask_transed;


logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_sleep_valid;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]    l1d_lsu_sleep_ldq_id;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_sleep_cache_miss;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][RRV64_L1D_MSHR_IDX_W -1:0] l1d_lsu_sleep_mshr_id;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_sleep_mshr_full;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_wakeup_cache_refill_valid;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][RRV64_L1D_MSHR_IDX_W -1:0] l1d_lsu_wakeup_mshr_id;
logic[L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_wakeup_mshr_avail;

logic                [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_req_valid;
logic                [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_req_ready;
rrv64_lsu_l1d_req_t  [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_req;
logic                [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_resp_valid;
rrv64_lsu_l1d_resp_t [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_resp;


generate
  for(i = 0; i < RT_LD_ST_PAIR_NUM; i++) begin: gen_rubytop_l1d_adaptor
    rubytop_l1d_adaptor rubytop_l1d_adaptor_u
    (
    .clk                   (clk)
    ,.rst_n                 (rst_n)
    // ruby
    ,.top_l1d_req_valid_i   (lsu_l1d_req_valid  [i])
    ,.top_l1d_req_i         (lsu_l1d_req        [i])
    ,.top_l1d_req_ready_o   (lsu_l1d_req_ready  [i])
    ,.top_l1d_resp_valid_o  (lsu_l1d_resp_valid [i])
    ,.top_l1d_resp_o        (lsu_l1d_resp       [i])
    ,.top_l1d_resp_ready_i  (lsu_l1d_resp_ready [i])
    // l1dc
    ,.ld_l1d_req_valid_o    (lsu_l1d_ld_req_valid [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.ld_l1d_req_o          (lsu_l1d_ld_req       [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.ld_l1d_req_ready_i    (lsu_l1d_ld_req_ready [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.ld_l1d_resp_valid_i   (lsu_l1d_ld_resp_valid[i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.ld_l1d_resp_i         (lsu_l1d_ld_resp      [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])

    ,.st_l1d_req_valid_o    (lsu_l1d_st_req_valid [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.st_l1d_req_o          (lsu_l1d_st_req       [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.st_l1d_req_ready_i    (lsu_l1d_st_req_ready [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.st_l1d_resp_valid_i   (lsu_l1d_st_resp_valid[i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.st_l1d_resp_i         (lsu_l1d_st_resp      [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])

    ,.l1d_lsu_sleep_valid_i               (l1d_lsu_sleep_valid              [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_sleep_ldq_id_i              (l1d_lsu_sleep_ldq_id             [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_sleep_cache_miss_i          (l1d_lsu_sleep_cache_miss         [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_sleep_mshr_id_i             (l1d_lsu_sleep_mshr_id            [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_sleep_mshr_full_i           (l1d_lsu_sleep_mshr_full          [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_wakeup_cache_refill_valid_i (l1d_lsu_wakeup_cache_refill_valid[i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_wakeup_mshr_id_i            (l1d_lsu_wakeup_mshr_id           [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    ,.l1d_lsu_wakeup_mshr_avail_i         (l1d_lsu_wakeup_mshr_avail        [i/LSU_ADDR_PIPE_COUNT][i%LSU_ADDR_PIPE_COUNT])
    );
  end
endgenerate

rubytest_top rubytest_top_u
(
  .clk                       (clk),
  .rst_n                     (rst_n),
  .rt_l1d_req_valid_o        (lsu_l1d_req_valid),
  .rt_l1d_req_o              (lsu_l1d_req),
  .rt_l1d_req_ready_i        (lsu_l1d_req_ready),
  .rt_l1d_resp_valid_i       (lsu_l1d_resp_valid),
  .rt_l1d_resp_i             (lsu_l1d_resp),
  .rt_l1d_resp_ready_o       (lsu_l1d_resp_ready),
`ifdef RT_MODE_CLASSIC
  .rt_cid_delta_seed_i        (_rt_cid_delta_seed),
  .rt_cid_base_seed_i         (_rt_cid_base_seed),
`else
  .rt_info_addr_seed_i        (_rt_info_addr_seed),
  .rt_info_opcode_seed_i      (_rt_info_opcode_seed),
`endif
  .rt_debug_info              ()
);


generate
  for(genvar core_id = 0; core_id < L1D_NUM; core_id++) begin
    for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      rrv2rvh_ruby_reqtype_trans rrv2rvh_ruby_reqtype_trans_ld_req_u
      (
        .rrv64_ruby_req_type_i      (lsu_l1d_ld_req[core_id][i].req_type   ),
        .rvh_ld_req_type_o          (ls_pipe_l1d_ld_req_opcode_transed[core_id][i]),
        .rvh_st_req_type_o          (),
        .is_ld_o                    ()
      );
    end

    for(i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      rrv2rvh_ruby_reqtype_trans rrv2rvh_ruby_reqtype_trans_st_req_u
      (
        .rrv64_ruby_req_type_i      (lsu_l1d_st_req[core_id][i].req_type   ),
        .rvh_ld_req_type_o          (),
        .rvh_st_req_type_o          (ls_pipe_l1d_st_req_opcode_transed[core_id][i]),
        .is_ld_o                    ()
      );
    end
  end
endgenerate
`endif

`ifdef RUBY

typedef struct packed {
  logic [RRV64_LSU_ID_WIDTH -1:0] l1d_lsu_lsu_tag;  
  logic [     ROB_TAG_WIDTH-1:0 ] l1d_rob_wb_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0 ] l1d_int_prf_wb_tag;
  logic [              XLEN-1:0 ] l1d_int_prf_wb_data;
} lsu_l1d_ld_resp_valid_fifo_t;

lsu_l1d_ld_resp_valid_fifo_t [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp_fifo_din, lsu_l1d_ld_resp_fifo_dout;
logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp_fifo_din_vld,  lsu_l1d_ld_resp_fifo_din_rdy;
logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp_fifo_dout_vld, lsu_l1d_ld_resp_fifo_dout_rdy;

generate
  for(genvar core_id = 0; core_id < L1D_NUM; core_id++) begin
    always_comb begin
      // LS_PIPE -> D$ : LD Request
      for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
        ls_pipe_l1d_ld_req_vld       [core_id][i] = lsu_l1d_ld_req_valid[core_id][i];
        ls_pipe_l1d_ld_req_io_region [core_id][i] = 1'b0;
        ls_pipe_l1d_kill_resp        [core_id][i] = 1'b0;
        ls_pipe_l1d_ld_req_rob_tag   [core_id][i] = lsu_l1d_ld_req[core_id][i].rob_id;
        ls_pipe_l1d_ld_req_prd       [core_id][i] = lsu_l1d_ld_req[core_id][i].ld_rd_idx;
        ls_pipe_l1d_ld_req_opcode    [core_id][i] = ls_pipe_l1d_ld_req_opcode_transed[core_id][i];
    `ifdef RUBY
        ls_pipe_l1d_ld_req_lsu_tag   [core_id][i] = {i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0], lsu_l1d_ld_req[core_id][i].lsu_id[RRV64_LSU_ID_WIDTH-1-$clog2(LSU_ADDR_PIPE_COUNT):0]};
    `endif
        ls_pipe_l1d_ld_req_idx       [core_id][i] = lsu_l1d_ld_req[core_id][i].paddr[L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH-1:L1D_OFFSET_WIDTH];
        ls_pipe_l1d_ld_req_offset    [core_id][i] = lsu_l1d_ld_req[core_id][i].paddr[L1D_OFFSET_WIDTH-1:0];
        ls_pipe_l1d_ld_req_vtag      [core_id][i] = lsu_l1d_ld_req[core_id][i].paddr[PADDR_WIDTH-1:L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH];
        
        lsu_l1d_ld_req_ready         [core_id][i] = ls_pipe_l1d_ld_req_rdy[core_id][i];
    `ifdef RUBY
        lsu_l1d_ld_req_bank_id       [core_id][i] = ls_pipe_l1d_ld_req_hit_bank_id[core_id][i];
    `endif  
      end

      // LS_PIPE -> D$ : ST Request
      for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
        ls_pipe_l1d_st_req_vld       [core_id][i] = lsu_l1d_st_req_valid[core_id][i];
        ls_pipe_l1d_st_req_io_region [core_id][i] = 1'b0;
        ls_pipe_l1d_st_req_is_fence  [core_id][i] = 1'b0;
        ls_pipe_l1d_st_req_rob_tag   [core_id][i] = lsu_l1d_st_req[core_id][i].rob_id;
        ls_pipe_l1d_st_req_prd       [core_id][i] = lsu_l1d_st_req[core_id][i].ld_rd_idx;
        ls_pipe_l1d_st_req_opcode    [core_id][i] = ls_pipe_l1d_st_req_opcode_transed[core_id][i];
    `ifdef RUBY
        ls_pipe_l1d_st_req_lsu_tag   [core_id][i] = {i[$clog2(LSU_DATA_PIPE_COUNT)-1:0], lsu_l1d_st_req[core_id][i].lsu_id[RRV64_LSU_ID_WIDTH-1-$clog2(LSU_DATA_PIPE_COUNT):0]};
        // ls_pipe_l1d_st_req_lsu_tag   [core_id][i] = lsu_l1d_st_req[core_id][i].lsu_id;
    `endif
        ls_pipe_l1d_st_req_paddr     [core_id][i] = lsu_l1d_st_req[core_id][i].paddr;
        ls_pipe_l1d_st_req_data      [core_id][i] = lsu_l1d_st_req[core_id][i].st_dat;
        ls_pipe_l1d_st_req_data_byte_mask[core_id][i] = ls_pipe_l1d_st_req_data_byte_mask_transed[core_id][i]; // data byte mask from stb

        // lsu_l1d_st_req_ready          = (counter[5:0] == 6'b000010) & ls_pipe_l1d_st_req_rdy;
        lsu_l1d_st_req_ready         [core_id][i] = ls_pipe_l1d_st_req_rdy[core_id][i];
    `ifdef RUBY
        lsu_l1d_st_req_bank_id       [core_id][i] = ls_pipe_l1d_st_req_hit_bank_id[core_id][i];
    `endif  
      end

      // D$ -> LSQ, mshr full replay
      for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
        l1d_lsu_sleep_valid  [core_id][i]  =  l1d_ls_pipe_replay_vld[core_id][i];
    `ifdef RUBY
        l1d_lsu_sleep_ldq_id [core_id][i]  = l1d_ls_pipe_replay_lsu_tag[core_id][i];
    `endif
        l1d_ls_pipe_mshr_full[core_id][i] = l1d_ls_pipe_replay_vld[core_id][i];
        l1d_lsu_sleep_mshr_full[core_id][i] = l1d_ls_pipe_mshr_full[core_id][i];
        l1d_lsu_wakeup_mshr_avail[core_id][i] = ~l1d_ls_pipe_mshr_full[core_id][i];
      end

        // D$ -> ROB : Write Back
        // D$ -> Int PRF : Write Back


    `ifdef RUBY
      lsu_l1d_ld_resp_valid[core_id] = '0;
      for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin

        lsu_l1d_ld_resp_fifo_din_vld [core_id][i] = '0;
        lsu_l1d_ld_resp_fifo_din     [core_id][i] = '0;

        for(int j = 0; j < LSU_ADDR_PIPE_COUNT; j++) begin
          if((l1d_lsu_lsu_tag[core_id][j][RRV64_LSU_ID_WIDTH-1-:$clog2(LSU_ADDR_PIPE_COUNT)] ==  i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0])
          && l1d_int_prf_wb_vld[core_id][j]) begin

            if(lsu_l1d_ld_resp_valid [core_id][i] == 1'b1) begin // if this resp channel is already be occupies, push one of them into a fifo
              lsu_l1d_ld_resp_fifo_din_vld[core_id][i] = 1'b1;
              lsu_l1d_ld_resp_fifo_din    [core_id][i].l1d_lsu_lsu_tag     = lsu_l1d_ld_resp[core_id][i].lsu_id;
              lsu_l1d_ld_resp_fifo_din    [core_id][i].l1d_rob_wb_rob_tag  = lsu_l1d_ld_resp[core_id][i].rob_id;
              lsu_l1d_ld_resp_fifo_din    [core_id][i].l1d_int_prf_wb_data = lsu_l1d_ld_resp[core_id][i].ld_data;
              lsu_l1d_ld_resp_fifo_din    [core_id][i].l1d_int_prf_wb_tag  = lsu_l1d_ld_resp[core_id][i].ld_rd_idx;
            end

            lsu_l1d_ld_resp_valid    [core_id][i] = l1d_int_prf_wb_vld[core_id][j];
            lsu_l1d_ld_resp[core_id][i].lsu_id    = {{$clog2(LSU_ADDR_PIPE_COUNT){1'b0}}, l1d_lsu_lsu_tag[core_id][j][RRV64_LSU_ID_WIDTH-1-$clog2(LSU_ADDR_PIPE_COUNT):0]};
            lsu_l1d_ld_resp[core_id][i].rob_id    = l1d_rob_wb_rob_tag[core_id][j];
            lsu_l1d_ld_resp[core_id][i].req_type  = LSU_LB; // TODO: not precise
            lsu_l1d_ld_resp[core_id][i].ld_data   = l1d_int_prf_wb_data[core_id][j];
            lsu_l1d_ld_resp[core_id][i].ld_rd_idx = l1d_int_prf_wb_tag[core_id][j];
            lsu_l1d_ld_resp[core_id][i].err       = 1'b0;
          end
        end
      end

           
      for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
        lsu_l1d_ld_resp_fifo_dout_rdy[core_id][i] = '0;
        if(~lsu_l1d_ld_resp_valid[core_id][i]) begin
          if(lsu_l1d_ld_resp_fifo_dout_vld[core_id][i]) begin
            lsu_l1d_ld_resp_valid    [core_id][i] = lsu_l1d_ld_resp_fifo_dout_vld [core_id][i];
            lsu_l1d_ld_resp[core_id][i].lsu_id    = lsu_l1d_ld_resp_fifo_dout     [core_id][i].l1d_lsu_lsu_tag;
            lsu_l1d_ld_resp[core_id][i].rob_id    = lsu_l1d_ld_resp_fifo_dout     [core_id][i].l1d_rob_wb_rob_tag;
            lsu_l1d_ld_resp[core_id][i].ld_data   = lsu_l1d_ld_resp_fifo_dout     [core_id][i].l1d_int_prf_wb_data;
            lsu_l1d_ld_resp[core_id][i].ld_rd_idx = lsu_l1d_ld_resp_fifo_dout     [core_id][i].l1d_int_prf_wb_tag;

            lsu_l1d_ld_resp_fifo_dout_rdy[core_id][i] = 1'b1;
          end
        end
      end



    `endif


      // TODO: add st resp for ruby
      for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
        lsu_l1d_st_resp_valid    [core_id][i] = l1d_lsu_st_lsu_tag_vld_per_input_port[core_id][i];
        lsu_l1d_st_resp[core_id][i].lsu_id    = {{$clog2(LSU_DATA_PIPE_COUNT){1'b0}}, l1d_lsu_st_lsu_tag_per_input_port[core_id][i][RRV64_LSU_ID_WIDTH-1-$clog2(LSU_DATA_PIPE_COUNT):0]};
        lsu_l1d_st_resp[core_id][i].rob_id    = '0; // not used
        lsu_l1d_st_resp[core_id][i].req_type  = LSU_SB; // not used
        lsu_l1d_st_resp[core_id][i].ld_data   = '0; // not used for st resp
        lsu_l1d_st_resp[core_id][i].ld_rd_idx = '0; // not used for st resp
        lsu_l1d_st_resp[core_id][i].err       = 1'b0; // not used

        l1d_lsu_st_lsu_tag_rdy_per_input_port[core_id][i] = '1;
        // lsu_l1d_st_resp_valid    [core_id][i] = ls_pipe_l1d_st_req_vld[core_id][i] & ls_pipe_l1d_st_req_rdy[core_id][i];
        // lsu_l1d_st_resp[core_id][i].lsu_id    = lsu_l1d_st_req[core_id][i].lsu_id;
        // lsu_l1d_st_resp[core_id][i].rob_id    = lsu_l1d_st_req[core_id][i].rob_id;
        // lsu_l1d_st_resp[core_id][i].req_type  = lsu_l1d_st_req[core_id][i].req_type;
        // lsu_l1d_st_resp[core_id][i].ld_data   = '0;
        // lsu_l1d_st_resp[core_id][i].ld_rd_idx = '0;
        // lsu_l1d_st_resp[core_id][i].err       = 1'b0;
      end
    end


    `ifdef RUBY
      for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin: gen_lsu_l1d_ld_resp_fifo_u
        mp_fifo
        #(
          .payload_t          (lsu_l1d_ld_resp_valid_fifo_t  ),
          .ENQUEUE_WIDTH      (1        ),
          .DEQUEUE_WIDTH      (1        ),
          .DEPTH              (L1D_NUM*L1D_MSHR_NUM   ),
          .MUST_TAKEN_ALL     (0                      )
        )
        lsu_l1d_ld_resp_fifo_u
        (
          // Enqueue
          .enqueue_vld_i          (lsu_l1d_ld_resp_fifo_din_vld     [core_id][i]),
          .enqueue_payload_i      (lsu_l1d_ld_resp_fifo_din         [core_id][i]),
          .enqueue_rdy_o          (lsu_l1d_ld_resp_fifo_din_rdy     [core_id][i]),
          // Dequeue
          .dequeue_vld_o          (lsu_l1d_ld_resp_fifo_dout_vld    [core_id][i]),
          .dequeue_payload_o      (lsu_l1d_ld_resp_fifo_dout        [core_id][i]),
          .dequeue_rdy_i          (lsu_l1d_ld_resp_fifo_dout_rdy    [core_id][i]),
          
          .flush_i                (1'b0                          ),
          
          .clk                    (clk                           ),
          .rst                    (~rst_n                        )
        );
      end
    `endif
  end
endgenerate
  
  // for load, use vipt, tlb resp valid at s1 stage
  // DTLB -> D$
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      dtlb_l1d_resp_vld            <= '0;
      dtlb_l1d_resp_excp_vld       <= '0;
      dtlb_l1d_resp_hit            <= '0;
      dtlb_l1d_resp_ppn            <= '0;
    end
      dtlb_l1d_resp_vld            <= ls_pipe_l1d_ld_req_vld;
      dtlb_l1d_resp_excp_vld       <= 1'b0;
      dtlb_l1d_resp_hit            <= ls_pipe_l1d_ld_req_vld;
      for(int core_id = 0; core_id < L1D_NUM; core_id++) begin
        for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
          dtlb_l1d_resp_ppn[core_id][i]            <= lsu_l1d_ld_req[core_id][i].paddr[PADDR_WIDTH-1:PAGE_OFFSET_WIDTH];
        end
      end
    end

`else

  `ifdef TRACE_INPUT
generate
  for(genvar core_id = 0; core_id < L1D_NUM; core_id++) begin
    always_comb begin
      for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
        ls_pipe_l1d_kill_resp        [core_id][i] = 1'b0;
      end
      for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
        ls_pipe_l1d_st_req_is_fence  [core_id][i] = 1'b0;
      end
    end
  end
endgenerate

  trace_input
  #(
    .CORE_NUM(L1D_NUM)
  ) trace_input_u
  (
    // load interface
    .ls_pipe_l1d_ld_req_vld       (ls_pipe_l1d_ld_req_vld),
    .ls_pipe_l1d_ld_req_io_region (ls_pipe_l1d_ld_req_io_region),
    .ls_pipe_l1d_ld_req_rob_tag   (ls_pipe_l1d_ld_req_rob_tag),
    .ls_pipe_l1d_ld_req_prd       (ls_pipe_l1d_ld_req_prd),
    .ls_pipe_l1d_ld_req_opcode    (ls_pipe_l1d_ld_req_opcode),

    .ls_pipe_l1d_ld_req_idx       (ls_pipe_l1d_ld_req_idx),
    .ls_pipe_l1d_ld_req_offset    (ls_pipe_l1d_ld_req_offset),
    .ls_pipe_l1d_ld_req_vtag      (ls_pipe_l1d_ld_req_vtag),
    .ls_pipe_l1d_ld_req_rdy       (ls_pipe_l1d_ld_req_rdy),

    // DTLB -> D$
    .dtlb_l1d_resp_vld            (dtlb_l1d_resp_vld),
    .dtlb_l1d_resp_ppn            (dtlb_l1d_resp_ppn),
    .dtlb_l1d_resp_excp_vld       (dtlb_l1d_resp_excp_vld),
    .dtlb_l1d_resp_hit            (dtlb_l1d_resp_hit),

    // store interface
    .ls_pipe_l1d_st_req_vld       (ls_pipe_l1d_st_req_vld),
    .ls_pipe_l1d_st_req_io_region (ls_pipe_l1d_st_req_io_region),
    .ls_pipe_l1d_st_req_rob_tag   (ls_pipe_l1d_st_req_rob_tag),
    .ls_pipe_l1d_st_req_prd       (ls_pipe_l1d_st_req_prd),
    .ls_pipe_l1d_st_req_opcode    (ls_pipe_l1d_st_req_opcode),
    .ls_pipe_l1d_st_req_paddr     (ls_pipe_l1d_st_req_paddr),
    .ls_pipe_l1d_st_req_data      (ls_pipe_l1d_st_req_data),
    .ls_pipe_l1d_st_req_rdy       (ls_pipe_l1d_st_req_rdy),

    // D$ -> LSQ, mshr full replay
    .l1d_ls_pipe_replay_vld       (l1d_ls_pipe_replay_vld),
    .l1d_ls_pipe_mshr_full        (l1d_ls_pipe_mshr_full ),
    
    // D$ -> ROB : Write Back
    .l1d_rob_wb_vld               (l1d_rob_wb_vld    ),
    .l1d_rob_wb_rob_tag           (l1d_rob_wb_rob_tag),
    
    // D$ -> Int PRF : Write Back
    .l1d_int_prf_wb_vld           (l1d_int_prf_wb_vld  ),
    .l1d_int_prf_wb_tag           (l1d_int_prf_wb_tag  ),
    .l1d_int_prf_wb_data          (l1d_int_prf_wb_data ),

    .clk                          (clk                         ),
    .rstn                         (rst_n                       )
  );

  `else
  always_comb begin
    // LS_PIPE -> D$ : LD Request
    ls_pipe_l1d_ld_req_vld        = 1'b0;
    ls_pipe_l1d_ld_req_rob_tag    = 'h1;
    ls_pipe_l1d_ld_req_prd        = 'h2;
    ls_pipe_l1d_ld_req_opcode     = LDU_LB;
    ls_pipe_l1d_ld_req_idx        = '0;
    ls_pipe_l1d_ld_req_offset     = counter[L1D_OFFSET_WIDTH-1:0];
    
    // LS_PIPE -> D$ : ST Request
    ls_pipe_l1d_st_req_vld        = 1'b0;
    ls_pipe_l1d_st_req_io_region  = 1'b0;
    ls_pipe_l1d_st_req_rob_tag    = 'h10;
    ls_pipe_l1d_st_req_prd        = 'h11;
    ls_pipe_l1d_st_req_opcode     = STU_SB;
    ls_pipe_l1d_st_req_paddr      = {{(PADDR_WIDTH-$bits(counter)){1'b0}}, counter};
    ls_pipe_l1d_st_req_data       = 'h1234; // data from stb
    ls_pipe_l1d_st_req_data_byte_mask = '1; // data byte mask from stb

    // DTLB -> D$
    dtlb_l1d_resp_vld             = 1'b0;
    dtlb_l1d_resp_excp_vld        = 1'b0;
    dtlb_l1d_resp_hit             = 1'b0;
    dtlb_l1d_resp_ppn             = '0;
    
      
    // LS_PIPE -> D$ : ST Request
    if(counter[6:0] == 50) begin
      ls_pipe_l1d_st_req_vld = 1'b1;
      ls_pipe_l1d_st_req_paddr = 'h123f000;
    end

    // LS_PIPE -> D$ : LD Request
    if(counter[6:0] == 100) begin
      ls_pipe_l1d_ld_req_vld = 1'b1;
      ls_pipe_l1d_ld_req_idx = '0;
      ls_pipe_l1d_ld_req_offset = '0;
    end
    
    if(counter[6:0] == 101) begin
      dtlb_l1d_resp_vld = 1'b1; 
      dtlb_l1d_resp_hit = 1'b1;
      // dtlb_l1d_resp_ppn = {{(PPN_WIDTH-(10-7)){1'b0}}, counter[10-1:7]};
      dtlb_l1d_resp_ppn = 'h123f;
    end
  end
  `endif
`endif







//
generate
  for(genvar core_id = 0; core_id < L1D_NUM; core_id++) begin: gen_rn_tile
    mixed_tile
    #(
      .CHANNEL_NUM(CHANNEL_NUM),
      .CORE_ID (core_id)
    ) mixed_tile_u
    (
        .ls_pipe_l1d_ld_req_vld (ls_pipe_l1d_ld_req_vld[core_id]),
        .ls_pipe_l1d_ld_req_io_region (ls_pipe_l1d_ld_req_io_region[core_id]),
        .ls_pipe_l1d_ld_req_rob_tag (ls_pipe_l1d_ld_req_rob_tag[core_id]),
        .ls_pipe_l1d_ld_req_prd (ls_pipe_l1d_ld_req_prd[core_id]),
        .ls_pipe_l1d_ld_req_opcode (ls_pipe_l1d_ld_req_opcode[core_id]),
        `ifdef RUBY
        .ls_pipe_l1d_ld_req_lsu_tag (ls_pipe_l1d_ld_req_lsu_tag[core_id]),
        `endif
        .ls_pipe_l1d_ld_req_idx (ls_pipe_l1d_ld_req_idx[core_id]),
        .ls_pipe_l1d_ld_req_offset (ls_pipe_l1d_ld_req_offset[core_id]),
        .ls_pipe_l1d_ld_req_vtag (ls_pipe_l1d_ld_req_vtag[core_id]),
        .ls_pipe_l1d_ld_req_rdy (ls_pipe_l1d_ld_req_rdy[core_id]),
        `ifdef RUBY
        .ls_pipe_l1d_ld_req_hit_bank_id (ls_pipe_l1d_ld_req_hit_bank_id[core_id]),
        .ls_pipe_l1d_st_req_hit_bank_id (ls_pipe_l1d_st_req_hit_bank_id[core_id]),
        `endif
        .dtlb_l1d_resp_vld (dtlb_l1d_resp_vld[core_id]),
        .dtlb_l1d_resp_ppn (dtlb_l1d_resp_ppn[core_id]),
        .dtlb_l1d_resp_excp_vld (dtlb_l1d_resp_excp_vld[core_id]),
        .dtlb_l1d_resp_hit (dtlb_l1d_resp_hit[core_id]),
        .ls_pipe_l1d_st_req_vld (ls_pipe_l1d_st_req_vld[core_id]),
        .ls_pipe_l1d_st_req_io_region (ls_pipe_l1d_st_req_io_region[core_id]),
        .ls_pipe_l1d_st_req_is_fence (ls_pipe_l1d_st_req_is_fence[core_id]),
        .ls_pipe_l1d_st_req_rob_tag (ls_pipe_l1d_st_req_rob_tag[core_id]),
        .ls_pipe_l1d_st_req_prd (ls_pipe_l1d_st_req_prd[core_id]),
        .ls_pipe_l1d_st_req_opcode (ls_pipe_l1d_st_req_opcode[core_id]),
        `ifdef RUBY
        .ls_pipe_l1d_st_req_lsu_tag (ls_pipe_l1d_st_req_lsu_tag[core_id]),
        `endif
        .ls_pipe_l1d_st_req_paddr (ls_pipe_l1d_st_req_paddr[core_id]),
        .ls_pipe_l1d_st_req_data (ls_pipe_l1d_st_req_data[core_id]),
        .ls_pipe_l1d_st_req_rdy (ls_pipe_l1d_st_req_rdy[core_id]),
        `ifdef RUBY
        .l1d_lsu_st_lsu_tag_vld_per_input_port (l1d_lsu_st_lsu_tag_vld_per_input_port[core_id]),
        .l1d_lsu_st_lsu_tag_per_input_port (l1d_lsu_st_lsu_tag_per_input_port[core_id]),
        .l1d_lsu_st_lsu_tag_rdy_per_input_port (l1d_lsu_st_lsu_tag_rdy_per_input_port[core_id]),
        `endif
        .l1d_ls_pipe_replay_vld (l1d_ls_pipe_replay_vld[core_id]),
        `ifdef RUBY
        .l1d_ls_pipe_replay_lsu_tag (l1d_ls_pipe_replay_lsu_tag[core_id]),
        `endif
        .ls_pipe_l1d_kill_resp(ls_pipe_l1d_kill_resp),
        .l1d_rob_wb_vld (l1d_rob_wb_vld[core_id]),
        .l1d_rob_wb_rob_tag (l1d_rob_wb_rob_tag[core_id]),
        .l1d_int_prf_wb_vld (l1d_int_prf_wb_vld[core_id]),
        .l1d_int_prf_wb_tag (l1d_int_prf_wb_tag[core_id]),
        .l1d_int_prf_wb_data (l1d_int_prf_wb_data[core_id]),
        `ifdef RUBY
        .l1d_lsu_lsu_tag (l1d_lsu_lsu_tag[core_id]),
        `endif

        .tx_flit_pend_o (tx_flit_pend[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_v_o (tx_flit_v[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_vc_id_o (tx_flit_vc_id[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_look_ahead_routing_o (tx_flit_look_ahead_routing[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_pend_i (rx_flit_pend[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_v_i (rx_flit_v[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_vc_id_i (rx_flit_vc_id[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_lcrd_v_i (tx_lcrd_v[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_lcrd_id_i (tx_lcrd_id[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_lcrd_v_o (rx_lcrd_v[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_lcrd_id_o (rx_lcrd_id[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_channel_0_o (tx_flit_channel_0[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_channel_1_o (tx_flit_channel_1[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_channel_2_o (tx_flit_channel_2[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_channel_3_o (tx_flit_channel_3[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .tx_flit_channel_4_o (tx_flit_channel_4[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_channel_0_i (rx_flit_channel_0[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_channel_1_i (rx_flit_channel_1[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_channel_2_i (rx_flit_channel_2[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_channel_3_i (rx_flit_channel_3[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),
        .rx_flit_channel_4_i (rx_flit_channel_4[(core_id + 1) % NODE_NUM_X_DIMESION][(core_id + 1) / NODE_NUM_X_DIMESION]),

        .node_id_x_i ((core_id) % NODE_NUM_X_DIMESION),
        .node_id_y_i ((core_id) / NODE_NUM_X_DIMESION),

        .clk (clk),
        .rst_n (rst_n)

    );
  end

endgenerate



`ifndef EBI
  // // connect each router together
  genvar j, z;
  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_connect_routers_ns_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION-1; j++) begin: gen_connect_routers_ns_y_dimesion
        assign rx_flit_channel_0                    [i][j][0]   = tx_flit_channel_0                     [i][j+1][1];
        assign rx_flit_channel_0                    [i][j+1][1] = tx_flit_channel_0                     [i][j][0];
        assign rx_flit_channel_1                    [i][j][0]   = tx_flit_channel_1                     [i][j+1][1];
        assign rx_flit_channel_1                    [i][j+1][1] = tx_flit_channel_1                     [i][j][0];
        assign rx_flit_channel_2                    [i][j][0]   = tx_flit_channel_2                     [i][j+1][1];
        assign rx_flit_channel_2                    [i][j+1][1] = tx_flit_channel_2                     [i][j][0];
        assign rx_flit_channel_3                    [i][j][0]   = tx_flit_channel_3                     [i][j+1][1];
        assign rx_flit_channel_3                    [i][j+1][1] = tx_flit_channel_3                     [i][j][0];
        assign rx_flit_channel_4                    [i][j][0]   = tx_flit_channel_4                     [i][j+1][1];
        assign rx_flit_channel_4                    [i][j+1][1] = tx_flit_channel_4                     [i][j][0];
        for(z = 0; z < CHANNEL_NUM; z++) begin: gen_channel
            // connect N inport to S outport
            assign rx_flit_pend               [i][j][z][0]   = tx_flit_pend                [i][j+1][z][1];
            assign rx_flit_v                  [i][j][z][0]   = tx_flit_v                   [i][j+1][z][1];
            assign rx_flit_vc_id              [i][j][z][0]   = tx_flit_vc_id               [i][j+1][z][1];
            assign rx_flit_look_ahead_routing [i][j][z][0]   = tx_flit_look_ahead_routing  [i][j+1][z][1];

            assign tx_lcrd_v                  [i][j][z][0]   = rx_lcrd_v                   [i][j+1][z][1];
            assign tx_lcrd_id                 [i][j][z][0]   = rx_lcrd_id                  [i][j+1][z][1];

            // connect S inport to N outport
            assign rx_flit_pend               [i][j+1][z][1] = tx_flit_pend                [i][j][z][0];
            assign rx_flit_v                  [i][j+1][z][1] = tx_flit_v                   [i][j][z][0];
            assign rx_flit_vc_id              [i][j+1][z][1] = tx_flit_vc_id               [i][j][z][0];
            assign rx_flit_look_ahead_routing [i][j+1][z][1] = tx_flit_look_ahead_routing  [i][j][z][0];

            assign tx_lcrd_v                  [i][j+1][z][1] = rx_lcrd_v                   [i][j][z][0];
            assign tx_lcrd_id                 [i][j+1][z][1] = rx_lcrd_id                  [i][j][z][0];
        end
      end
    end
  endgenerate

  generate
    for(i = 0; i < NODE_NUM_Y_DIMESION; i++) begin: gen_connect_routers_ew_x_dimesion
      for(j = 0; j < NODE_NUM_X_DIMESION-1; j++) begin: gen_connect_routers_ew_y_dimesion
        assign rx_flit_channel_0                    [j][i][2]   = tx_flit_channel_0                     [j+1][i][3];
        assign rx_flit_channel_0                    [j+1][i][3] = tx_flit_channel_0                     [j][i][2];
        assign rx_flit_channel_1                    [j][i][2]   = tx_flit_channel_1                     [j+1][i][3];
        assign rx_flit_channel_1                    [j+1][i][3] = tx_flit_channel_1                     [j][i][2];
        assign rx_flit_channel_2                    [j][i][2]   = tx_flit_channel_2                     [j+1][i][3];
        assign rx_flit_channel_2                    [j+1][i][3] = tx_flit_channel_2                     [j][i][2];
        assign rx_flit_channel_3                    [j][i][2]   = tx_flit_channel_3                     [j+1][i][3];
        assign rx_flit_channel_3                    [j+1][i][3] = tx_flit_channel_3                     [j][i][2];
        assign rx_flit_channel_4                    [j][i][2]   = tx_flit_channel_4                     [j+1][i][3];
        assign rx_flit_channel_4                    [j+1][i][3] = tx_flit_channel_4                     [j][i][2];
        for(z = 0; z < CHANNEL_NUM; z++) begin: gen_channel
            // connect E inport to W outport
            assign rx_flit_pend               [j][i][z][2]   = tx_flit_pend                [j+1][i][z][3];
            assign rx_flit_v                  [j][i][z][2]   = tx_flit_v                   [j+1][i][z][3];
            assign rx_flit_vc_id              [j][i][z][2]   = tx_flit_vc_id               [j+1][i][z][3];
            assign rx_flit_look_ahead_routing [j][i][z][2]   = tx_flit_look_ahead_routing  [j+1][i][z][3];

            assign tx_lcrd_v                  [j][i][z][2]   = rx_lcrd_v                   [j+1][i][z][3];
            assign tx_lcrd_id                 [j][i][z][2]   = rx_lcrd_id                  [j+1][i][z][3];

            // connect W inport to E outport
            assign rx_flit_pend               [j+1][i][z][3] = tx_flit_pend                [j][i][z][2];
            assign rx_flit_v                  [j+1][i][z][3] = tx_flit_v                   [j][i][z][2];        
            assign rx_flit_vc_id              [j+1][i][z][3] = tx_flit_vc_id               [j][i][z][2];
            assign rx_flit_look_ahead_routing [j+1][i][z][3] = tx_flit_look_ahead_routing  [j][i][z][2];

            assign tx_lcrd_v                  [j+1][i][z][3] = rx_lcrd_v                   [j][i][z][2];
            assign tx_lcrd_id                 [j+1][i][z][3] = rx_lcrd_id                  [j][i][z][2];
        end
      end
    end
  endgenerate


`else

// connected routers with ebi
genvar j, z, k;

generate
  for(i = 0; i < NODE_NUM_X_DIMESION-1; i++) begin: gen_x_dimension_router
    for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin
      m1_ebi  ebi_X_u1(
      .m1_clk(clk),
      .bus_clk(bus_clk),
      .rst(~rst_n),
    // control signals
      .tx_flit_pend_i(tx_flit_pend_e[i][j][2]),
      .tx_flit_v_i(tx_flit_v_e[i][j][2]),
      .tx_flit_vc_id_i(tx_flit_vc_id_e[i][j][2]),
      .tx_flit_look_ahead_routing_i(tx_flit_look_ahead_routing_e[i][j][2]),

      .rx_flit_pend_o(rx_flit_pend_e[i][j][2]),
      .rx_flit_v_o(rx_flit_v_e[i][j][2]),
      .rx_flit_vc_id_o(rx_flit_vc_id_e[i][j][2]),
      .rx_flit_look_ahead_routing_o(rx_flit_look_ahead_routing_e[i][j][2]),

      .tx_lcrd_v_o(tx_lcrd_v_e[i][j][2]),
      .tx_lcrd_id_o(tx_lcrd_id_e[i][j][2]),

      .rx_lcrd_v_i(rx_lcrd_v_e[i][j][2]),
      .rx_lcrd_id_i(rx_lcrd_id_e[i][j][2]),

      .tx_flit_channel_0_i(tx_flit_channel_0[i][j][2]), // req
      .tx_flit_channel_1_i(tx_flit_channel_1[i][j][2]), // resp
      .tx_flit_channel_2_i(tx_flit_channel_2[i][j][2]), // evict
      .tx_flit_channel_3_i(tx_flit_channel_3[i][j][2]), // data
      .tx_flit_channel_4_i(tx_flit_channel_4[i][j][2]), // snp
      .rx_flit_channel_0_o(rx_flit_channel_0[i][j][2]), // req
      .rx_flit_channel_1_o(rx_flit_channel_1[i][j][2]), // resp
      .rx_flit_channel_2_o(rx_flit_channel_2[i][j][2]), // evict
      .rx_flit_channel_3_o(rx_flit_channel_3[i][j][2]), // data
      .rx_flit_channel_4_o(rx_flit_channel_4[i][j][2]), // snp

          //external interface
      .m1_m2_bus_o(x_inc_bus[i][j]),
      .m2_m1_credit_i(x_inc_credit[i][j]),
      .m2_m1_bus_i(x_dec_bus[i][j]),
      .m1_m2_credit_o(x_dec_credit[i][j])
    );
    m1_ebi  ebi_X_u2(
      .m1_clk(clk),
      .bus_clk(bus_clk),
      .rst(~rst_n),
    // control signals
      .tx_flit_pend_i(tx_flit_pend_e[i+1][j][3]),
      .tx_flit_v_i(tx_flit_v_e[i+1][j][3]),
      .tx_flit_vc_id_i(tx_flit_vc_id_e[i+1][j][3]),
      .tx_flit_look_ahead_routing_i(tx_flit_look_ahead_routing_e[i+1][j][3]),

      .rx_flit_pend_o(rx_flit_pend_e[i+1][j][3]),
      .rx_flit_v_o(rx_flit_v_e[i+1][j][3]),
      .rx_flit_vc_id_o(rx_flit_vc_id_e[i+1][j][3]),
      .rx_flit_look_ahead_routing_o(rx_flit_look_ahead_routing_e[i+1][j][3]),

      .tx_lcrd_v_o(tx_lcrd_v_e[i+1][j][3]),
      .tx_lcrd_id_o(tx_lcrd_id_e[i+1][j][3]),

      .rx_lcrd_v_i(rx_lcrd_v_e[i+1][j][3]),
      .rx_lcrd_id_i(rx_lcrd_id_e[i+1][j][3]),

      .tx_flit_channel_0_i(tx_flit_channel_0[i+1][j][3]), // req
      .tx_flit_channel_1_i(tx_flit_channel_1[i+1][j][3]), // resp
      .tx_flit_channel_2_i(tx_flit_channel_2[i+1][j][3]), // evict
      .tx_flit_channel_3_i(tx_flit_channel_3[i+1][j][3]), // data
      .tx_flit_channel_4_i(tx_flit_channel_4[i+1][j][3]), // snp
      .rx_flit_channel_0_o(rx_flit_channel_0[i+1][j][3]), // req
      .rx_flit_channel_1_o(rx_flit_channel_1[i+1][j][3]), // resp
      .rx_flit_channel_2_o(rx_flit_channel_2[i+1][j][3]), // evict
      .rx_flit_channel_3_o(rx_flit_channel_3[i+1][j][3]), // data
      .rx_flit_channel_4_o(rx_flit_channel_4[i+1][j][3]), // snp

          //external interface
      .m1_m2_bus_o(x_dec_bus[i][j]),
      .m2_m1_credit_i(x_dec_credit[i][j]),
      .m2_m1_bus_i(x_inc_bus[i][j]),
      .m1_m2_credit_o(x_inc_credit[i][j])
    );
    end
  end
endgenerate

generate
  for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_y_dimension_router
    for(j = 0; j < NODE_NUM_Y_DIMESION-1; j++) begin
      m1_ebi  ebi_Y_u1(
      .m1_clk(clk),
      .bus_clk(bus_clk),
      .rst(~rst_n),
    // control signals
      .tx_flit_pend_i(tx_flit_pend_e[i][j][0]),
      .tx_flit_v_i(tx_flit_v_e[i][j][0]),
      .tx_flit_vc_id_i(tx_flit_vc_id_e[i][j][0]),
      .tx_flit_look_ahead_routing_i(tx_flit_look_ahead_routing_e[i][j][0]),

      .rx_flit_pend_o(rx_flit_pend_e[i][j][0]),
      .rx_flit_v_o(rx_flit_v_e[i][j][0]),
      .rx_flit_vc_id_o(rx_flit_vc_id_e[i][j][0]),
      .rx_flit_look_ahead_routing_o(rx_flit_look_ahead_routing_e[i][j][0]),

      .tx_lcrd_v_o(tx_lcrd_v_e[i][j][0]),
      .tx_lcrd_id_o(tx_lcrd_id_e[i][j][0]),

      .rx_lcrd_v_i(rx_lcrd_v_e[i][j][0]),
      .rx_lcrd_id_i(rx_lcrd_id_e[i][j][0]),

      .tx_flit_channel_0_i(tx_flit_channel_0[i][j][0]), // req
      .tx_flit_channel_1_i(tx_flit_channel_1[i][j][0]), // resp
      .tx_flit_channel_2_i(tx_flit_channel_2[i][j][0]), // evict
      .tx_flit_channel_3_i(tx_flit_channel_3[i][j][0]), // data
      .tx_flit_channel_4_i(tx_flit_channel_4[i][j][0]), // snp
      .rx_flit_channel_0_o(rx_flit_channel_0[i][j][0]), // req
      .rx_flit_channel_1_o(rx_flit_channel_1[i][j][0]), // resp
      .rx_flit_channel_2_o(rx_flit_channel_2[i][j][0]), // evict
      .rx_flit_channel_3_o(rx_flit_channel_3[i][j][0]), // data
      .rx_flit_channel_4_o(rx_flit_channel_4[i][j][0]), // snp

          //external interface
      .m1_m2_bus_o(y_inc_bus[i][j]),
      .m2_m1_credit_i(y_inc_credit[i][j]),
      .m2_m1_bus_i(y_dec_bus[i][j]),
      .m1_m2_credit_o(y_dec_credit[i][j])
    );
    m1_ebi  ebi_Y_u2(
      .m1_clk(clk),
      .bus_clk(bus_clk),
      .rst(~rst_n),
    // control signals
      .tx_flit_pend_i(tx_flit_pend_e[i][j+1][1]),
      .tx_flit_v_i(tx_flit_v_e[i][j+1][1]),
      .tx_flit_vc_id_i(tx_flit_vc_id_e[i][j+1][1]),
      .tx_flit_look_ahead_routing_i(tx_flit_look_ahead_routing_e[i][j+1][1]),

      .rx_flit_pend_o(rx_flit_pend_e[i][j+1][1]),
      .rx_flit_v_o(rx_flit_v_e[i][j+1][1]),
      .rx_flit_vc_id_o(rx_flit_vc_id_e[i][j+1][1]),
      .rx_flit_look_ahead_routing_o(rx_flit_look_ahead_routing_e[i][j+1][1]),

      .tx_lcrd_v_o(tx_lcrd_v_e[i][j+1][1]),
      .tx_lcrd_id_o(tx_lcrd_id_e[i][j+1][1]),

      .rx_lcrd_v_i(rx_lcrd_v_e[i][j+1][1]),
      .rx_lcrd_id_i(rx_lcrd_id_e[i][j+1][1]),

      .tx_flit_channel_0_i(tx_flit_channel_0[i][j+1][1]), // req
      .tx_flit_channel_1_i(tx_flit_channel_1[i][j+1][1]), // resp
      .tx_flit_channel_2_i(tx_flit_channel_2[i][j+1][1]), // evict
      .tx_flit_channel_3_i(tx_flit_channel_3[i][j+1][1]), // data
      .tx_flit_channel_4_i(tx_flit_channel_4[i][j+1][1]), // snp
      .rx_flit_channel_0_o(rx_flit_channel_0[i][j+1][1]), // req
      .rx_flit_channel_1_o(rx_flit_channel_1[i][j+1][1]), // resp
      .rx_flit_channel_2_o(rx_flit_channel_2[i][j+1][1]), // evict
      .rx_flit_channel_3_o(rx_flit_channel_3[i][j+1][1]), // data
      .rx_flit_channel_4_o(rx_flit_channel_4[i][j+1][1]), // snp

          //external interface
      .m1_m2_bus_o(y_dec_bus[i][j]),
      .m2_m1_credit_i(y_dec_credit[i][j]),
      .m2_m1_bus_i(y_inc_bus[i][j]),
      .m1_m2_credit_o(y_inc_credit[i][j])
    );
    end
  end
endgenerate


generate 
  for (i = 0; i < NODE_NUM_X_DIMESION; i++) begin
    for ( j = 0; j < NODE_NUM_Y_DIMESION; j++) begin
      for ( z = 0; z < ROUTER_PORT_NUMBER; z++) begin
        for (k = 0; k < CHANNEL_NUM; k++) begin
          if ((!((i == 0) && (z == 3))) && (!((i == NODE_NUM_X_DIMESION-1) && (z == 2))) && (!((j == 0) && (z == 1))) && (!((j == NODE_NUM_Y_DIMESION-1) && (z == 0)))) begin
            assign tx_flit_pend_e[i][j][z][k] = tx_flit_pend[i][j][k][z];
            assign tx_flit_v_e[i][j][z][k] = tx_flit_v[i][j][k][z];
            assign tx_flit_vc_id_e[i][j][z][k] = tx_flit_vc_id[i][j][k][z];
            assign tx_flit_look_ahead_routing_e[i][j][z][k] = tx_flit_look_ahead_routing[i][j][k][z];
            assign rx_lcrd_v_e[i][j][z][k] = rx_lcrd_v[i][j][k][z];
            assign rx_lcrd_id_e[i][j][z][k] = rx_lcrd_id[i][j][k][z];

            assign rx_flit_pend[i][j][k][z] = rx_flit_pend_e[i][j][z][k];
            assign rx_flit_v[i][j][k][z] = rx_flit_v_e[i][j][z][k];
            assign rx_flit_vc_id[i][j][k][z] = rx_flit_vc_id_e[i][j][z][k];
            assign rx_flit_look_ahead_routing[i][j][k][z] = rx_flit_look_ahead_routing_e[i][j][z][k];
            assign tx_lcrd_v[i][j][k][z] = tx_lcrd_v_e[i][j][z][k];
            assign tx_lcrd_id[i][j][k][z] = tx_lcrd_id_e[i][j][z][k];
          end
        end
      end
    end
  end
endgenerate

//debug print
always_ff @(negedge clk) begin
  if(ebi_debug_print) begin
    for (int i = 0; i < NODE_NUM_X_DIMESION; i++) begin: ebi_debug_log
      for (int j = 0; j < NODE_NUM_Y_DIMESION; j++) begin
        for (int z = 0; z < ROUTER_PORT_NUMBER; z++) begin
          for (int k = 0; k < CHANNEL_NUM; k++) begin
            if(tx_flit_v_e[i][j][z][k]) begin
              $write("[%16d] info: flit_sender: (%0d, %0d); target: ", $time(), i, j);
              case (z)
                0: $write("(%0d, %0d)", i, j+1);
                1: $write("(%0d, %0d)", i, j-1);
                2: $write("(%0d, %0d)", i+1, j);
                3: $write("(%0d, %0d)", i-1, j);
                4: $write("local? wrong!");
              endcase              
              $write("vc_id: %1d; look_ahead_routing: %1d, channel: %1d, flit:", tx_flit_vc_id_e[i][j][z][k], tx_flit_look_ahead_routing_e[i][j][z][k], k);
              case (k)
                0: $write("%0h", tx_flit_channel_0[i][j][z]);
                1: $write("%0h", tx_flit_channel_1[i][j][z]);
                2: $write("%0h", tx_flit_channel_2[i][j][z]);
                3: $write("%0h", tx_flit_channel_3[i][j][z]);
                4: $write("%0h", tx_flit_channel_4[i][j][z]);
                default: $write("wrong channel %0d", k);
              endcase
              $write("                         \n");
            end
            if(rx_flit_v_e[i][j][z][k]) begin
              $write("[%16d] info: flit_receiver: (%0d, %0d); source: ", $time(), i, j);
              case (z)
                0: $write("(%0d, %0d)", i, j+1);
                1: $write("(%0d, %0d)", i, j-1);
                2: $write("(%0d, %0d)", i+1, j);
                3: $write("(%0d, %0d)", i-1, j);
                4: $write("local? wrong!");
              endcase              
              $write("vc_id: %1d; look_ahead_routing: %1d, channel: %1d, flit:", rx_flit_vc_id_e[i][j][z][k], rx_flit_look_ahead_routing_e[i][j][z][k], k);
              case (k)
                0: $write("%0h", rx_flit_channel_0[i][j][z]);
                1: $write("%0h", rx_flit_channel_1[i][j][z]);
                2: $write("%0h", rx_flit_channel_2[i][j][z]);
                3: $write("%0h", rx_flit_channel_3[i][j][z]);
                4: $write("%0h", rx_flit_channel_4[i][j][z]);
                default: $write("wrong channel %0d", k);
              endcase
              $write("                         \n");
            end
            if(tx_lcrd_v_e[i][j][z][k]) begin
              $write("[%16d] info credit: crd_receiver: (%0d, %0d); source: ", $time(), i, j);
              case (z)
                0: $write("(%0d, %0d)", i, j+1);
                1: $write("(%0d, %0d)", i, j-1);
                2: $write("(%0d, %0d)", i+1, j);
                3: $write("(%0d, %0d)", i-1, j);
                4: $write("local? wrong!");
              endcase              
              $write(" credit id: %0d, channel: %0d", tx_lcrd_id_e[i][j][z][k], k);
              $write("                         \n");
            end
            if(rx_lcrd_v_e[i][j][z][k]) begin
              $write("[%16d] info credit: crd_sender: (%0d, %0d); target: ", $time(), i, j);
              case (z)
                0: $write("(%0d, %0d)", i, j+1);
                1: $write("(%0d, %0d)", i, j-1);
                2: $write("(%0d, %0d)", i+1, j);
                3: $write("(%0d, %0d)", i-1, j);
                4: $write("local? wrong!");
              endcase              
              $write(" credit id: %0d, channel: %0d", rx_lcrd_id_e[i][j][z][k], k);
              $write("                         \n");
            end
          end
        end
      end
    end
  end
end

`endif

  // other unused non-local ports, assign router rx to 0
  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_unused_non_local_ports_x_dimesion
        assign rx_flit_channel_0                    [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
        assign rx_flit_channel_1                    [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
        assign rx_flit_channel_2                    [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
        assign rx_flit_channel_3                    [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
        assign rx_flit_channel_4                    [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
        assign rx_flit_channel_0                    [i][0][1]                       = '0;
        assign rx_flit_channel_1                    [i][0][1]                       = '0;
        assign rx_flit_channel_2                    [i][0][1]                       = '0;
        assign rx_flit_channel_3                    [i][0][1]                       = '0;
        assign rx_flit_channel_4                    [i][0][1]                       = '0;
        for(z = 0; z < CHANNEL_NUM; z++) begin: gen_channel
            assign rx_flit_pend               [i][NODE_NUM_Y_DIMESION-1][z][0]   = '0;
            assign rx_flit_v                  [i][NODE_NUM_Y_DIMESION-1][z][0]   = '0;
           
            assign rx_flit_vc_id              [i][NODE_NUM_Y_DIMESION-1][z][0]   = '0;
            assign rx_flit_look_ahead_routing [i][NODE_NUM_Y_DIMESION-1][z][0]   = '0;

            assign tx_lcrd_v                  [i][NODE_NUM_Y_DIMESION-1][z][0]   = '0;
            assign tx_lcrd_id                 [i][NODE_NUM_Y_DIMESION-1][z][0]   = '0;


            assign rx_flit_pend               [i][0][z][1]                       = '0;
            assign rx_flit_v                  [i][0][z][1]                       = '0;
            
            assign rx_flit_vc_id              [i][0][z][1]                       = '0;
            assign rx_flit_look_ahead_routing [i][0][z][1]                       = '0;

            assign tx_lcrd_v                  [i][0][z][1]                       = '0;
            assign tx_lcrd_id                 [i][0][z][1]                       = '0;
      end
    end

    for(i = 0; i < NODE_NUM_Y_DIMESION; i++) begin: gen_unused_non_local_ports_y_dimesion
        assign rx_flit_channel_0                    [NODE_NUM_X_DIMESION-1][i][2]   = '0;
        assign rx_flit_channel_1                    [NODE_NUM_X_DIMESION-1][i][2]   = '0;
        assign rx_flit_channel_2                    [NODE_NUM_X_DIMESION-1][i][2]   = '0;
        assign rx_flit_channel_3                    [NODE_NUM_X_DIMESION-1][i][2]   = '0;
        assign rx_flit_channel_4                    [NODE_NUM_X_DIMESION-1][i][2]   = '0;
        assign rx_flit_channel_0                    [0][i][3]                       = '0;
        assign rx_flit_channel_1                    [0][i][3]                       = '0;
        assign rx_flit_channel_2                    [0][i][3]                       = '0;
        assign rx_flit_channel_3                    [0][i][3]                       = '0;
        assign rx_flit_channel_4                    [0][i][3]                       = '0;
        for(z = 0; z < CHANNEL_NUM; z++) begin: gen_channel

            // connect E inport to W outport
            assign rx_flit_pend               [NODE_NUM_X_DIMESION-1][i][z][2]   = '0;
            assign rx_flit_v                  [NODE_NUM_X_DIMESION-1][i][z][2]   = '0;
            assign rx_flit_vc_id              [NODE_NUM_X_DIMESION-1][i][z][2]   = '0;
            assign rx_flit_look_ahead_routing [NODE_NUM_X_DIMESION-1][i][z][2]   = '0;

            assign tx_lcrd_v                  [NODE_NUM_X_DIMESION-1][i][z][2]   = '0;
            assign tx_lcrd_id                 [NODE_NUM_X_DIMESION-1][i][z][2]   = '0;

            // connect W inport to E outport
            assign rx_flit_pend               [0][i][z][3]                       = '0;
            assign rx_flit_v                  [0][i][z][3]                       = '0;
            
            assign rx_flit_vc_id              [0][i][z][3]                       = '0;
            assign rx_flit_look_ahead_routing [0][i][z][3]                       = '0;

            assign tx_lcrd_v                  [0][i][z][3]                       = '0;
            assign tx_lcrd_id                 [0][i][z][3]                       = '0;
      end
    end
  endgenerate

// debug print
logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] ls_pipe_l1d_ld_req_hsk;
logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] ls_pipe_l1d_st_req_hsk;
logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0] ls_pipe_l1d_ld_resp_hsk;
`ifdef RUBY
logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0] ls_pipe_l1d_st_resp_hsk;
`endif
logic scu_mem_aw_req_hsk;
logic scu_mem_w_req_hsk;
logic scu_mem_ar_req_hsk;
logic scu_mem_r_resp_hsk;

generate
  for(genvar core_id = 0; core_id < L1D_NUM; core_id++) begin
    for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      assign ls_pipe_l1d_ld_req_hsk [core_id][i] = ls_pipe_l1d_ld_req_vld[core_id][i] & ls_pipe_l1d_ld_req_rdy[core_id][i];
`ifdef RUBY
      assign ls_pipe_l1d_ld_resp_hsk[core_id][i] = lsu_l1d_ld_resp_valid[core_id][i];
`else
      assign ls_pipe_l1d_ld_resp_hsk[core_id][i] = l1d_int_prf_wb_vld[core_id][i];
`endif
    end
    for(i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      assign ls_pipe_l1d_st_req_hsk[core_id][i] = ls_pipe_l1d_st_req_vld[core_id][i] & ls_pipe_l1d_st_req_rdy[core_id][i];
`ifdef RUBY
      assign ls_pipe_l1d_st_resp_hsk[core_id][i] = l1d_lsu_st_lsu_tag_vld_per_input_port[core_id][i];
`endif
    end
  
    `ifndef SYNTHESIS
    assert property(@(posedge clk)disable iff(~rst_n)(l1d_rob_wb_vld[core_id][LSU_ADDR_PIPE_COUNT+:LSU_DATA_PIPE_COUNT] == ls_pipe_l1d_st_req_hsk[core_id])) 
            else $fatal("l1d st req hsk not right");
    `endif
  end
endgenerate


assign scu_mem_aw_req_hsk = scu_mem_awvalid & scu_mem_awready;
assign scu_mem_w_req_hsk  = scu_mem_wvalid & scu_mem_wready;
assign scu_mem_ar_req_hsk = scu_mem_arvalid & scu_mem_arready;
assign scu_mem_r_resp_hsk = scu_mem_rvalid & scu_mem_rready;

`ifdef RUBY
`ifdef RT_MODE_CLASSIC
logic [RT_CHECK_NUM-1:0]                                       rt_err_resp_data_mismatch_ent_q;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_data_q_q;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_port_update_resp_data_q;

always_ff @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rt_err_resp_data_mismatch_ent_q <= '0;
    check_data_q_q                  <= '0;
    check_port_update_resp_data_q   <= '0;
  end else if(top_sliced_llc.rubytest_top_u.rubytest_check_table_u.rt_err_resp_data_mismatch_d) begin
    rt_err_resp_data_mismatch_ent_q <= top_sliced_llc.rubytest_top_u.rubytest_check_table_u.rt_err_resp_data_mismatch_ent;
    check_data_q_q                  <= top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_data_q;
    check_port_update_resp_data_q   <= top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_port_update_resp_data;
  end
end
`endif
`endif

generate
  for(genvar core_id = 0; core_id < L1D_NUM; core_id++) begin
    always_ff @(posedge clk) begin
      if(debug_print) begin
        for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
          if(ls_pipe_l1d_ld_req_hsk[core_id][i]) begin
            $display("\n\n====================");
`ifdef RUBY
            $display("11@ cycle = %d, load req[core %2d][port %d, l1d bank %d] handshake", cycle, core_id, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0], lsu_l1d_ld_req_bank_id[core_id][i]);
`else
            $display("11@ cycle = %d, load req[core %2d][port %d] handshake", cycle, core_id, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0]);
`endif
`ifdef RUBY
            $display("lsu_id    = 0x%x", lsu_l1d_ld_req[core_id][i].lsu_id);
`endif
            $display("rob_id    = 0x%x", ls_pipe_l1d_ld_req_rob_tag[core_id][i]);
`ifdef RUBY
            $display("req_type  = %s", lsu_l1d_ld_req[core_id][i].req_type.name());
`else
            $display("req_type  = %d", ls_pipe_l1d_ld_req_opcode[core_id][i]);
`endif
            $display("paddr     = 0x%x", {ls_pipe_l1d_ld_req_vtag[core_id][i],ls_pipe_l1d_ld_req_idx[core_id][i],ls_pipe_l1d_ld_req_offset[core_id][i]});
            $display("ld_rd_idx = 0x%x", ls_pipe_l1d_ld_req_prd[core_id][i]);
            $display("====================");
          end
        end

        for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
          if(ls_pipe_l1d_st_req_hsk[core_id][i]) begin
            $display("\n\n====================");
`ifdef RUBY
            $display("11@ cycle = %d, store req[core %2d][port %d, l1d bank %d] handshake", cycle, core_id, i[$clog2(LSU_DATA_PIPE_COUNT)-1:0], lsu_l1d_st_req_bank_id[core_id][i]);
`else
            $display("11@ cycle = %d, store req[core %2d][port %d] handshake", cycle, core_id, i[$clog2(LSU_DATA_PIPE_COUNT)-1:0]);
`endif
`ifdef RUBY
            $display("lsu_id    = 0x%x", lsu_l1d_st_req[core_id][i].lsu_id);
`endif
            $display("rob_id    = 0x%x", ls_pipe_l1d_st_req_rob_tag[core_id][i]);
`ifdef RUBY
            $display("req_type  = %s", lsu_l1d_st_req[core_id][i].req_type.name());
`else
            $display("req_type  = %d", ls_pipe_l1d_st_req_opcode[core_id][i]);
`endif
            $display("paddr     = 0x%x", ls_pipe_l1d_st_req_paddr[core_id][i]);
            $display("ld_rd_idx = 0x%x", ls_pipe_l1d_st_req_prd[core_id][i]);
            $write("st_dat    = 0x");
            for(int j = XLEN/64-1; j >=0; j--) begin
              $write("%h", ls_pipe_l1d_st_req_data[core_id][i][j*64+:64]);
            end
            $display("\n====================");
          end
        end

        for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
          if(ls_pipe_l1d_ld_resp_hsk[core_id][i]) begin
            $display("\n\n====================");
            $display("11@ cycle = %d, load resp[core %2d][port %d] handshake", cycle, core_id, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0]);
`ifdef RUBY
            $display("lsu_id    = 0x%x", lsu_l1d_ld_resp[core_id][i].lsu_id);
            $display("rob_id    = 0x%x", lsu_l1d_ld_resp[core_id][i].rob_id);
            $display("req_type  = %s", lsu_l1d_ld_resp[core_id][i].req_type.name());
            $display("ld_rd_idx = 0x%x", lsu_l1d_ld_resp[core_id][i].ld_rd_idx);
            $write("ld_data   = 0x");
            for(int j = XLEN/64-1; j >=0; j--) begin
              $write("%h", lsu_l1d_ld_resp[core_id][i].ld_data[j*64+:64]);
            end
`endif
            $display("\n====================");
          end

          if(l1d_ls_pipe_replay_vld[core_id][i]) begin
            $display("\n\n====================");
            $display("11@ cycle = %d, load replay[core %2d][port %d] handshake", cycle, core_id, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0]);
`ifdef RUBY
            $display("lsu_id    = 0x%x", l1d_ls_pipe_replay_lsu_tag[core_id][i]);
`endif
            $display("====================");
          end
        end

`ifdef RUBY
        for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
          if(ls_pipe_l1d_st_resp_hsk[core_id][i]) begin
            $display("\n\n====================");
            $display("11@ cycle = %d, store resp[core %2d][port %d] handshake", cycle, core_id, i[$clog2(LSU_DATA_PIPE_COUNT)-1:0]);
            $display("lsu_id    = 0x%x", lsu_l1d_st_resp[core_id][i].lsu_id);
            $display("\n====================");
          end
        end
`endif
      end
    end
  end
endgenerate

always_ff @(posedge clk) begin
  if(cycle[16:0] == 'h1) begin
    $display("11@ cycle = %d", cycle);
  end
end

always_ff @(posedge clk) begin
  if(debug_print) begin
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      if(scu_mem_aw_req_hsk) begin
        $display("\n\n====================");
        $display("@ cycle = %d, write back aw req handshake", cycle);
        $display("awaddr    = 0x%x", scu_mem_aw.awaddr);
        $display("awlen     = 0x%x", scu_mem_aw.awlen);
        $display("awsize    = 0x%x", scu_mem_aw.awsize);
        $display("awid      = 0x%x", scu_mem_aw.awid);
        $display("awburst   = 0x%x", scu_mem_aw.awburst);
        $display("====================");
      end
      if(scu_mem_w_req_hsk) begin
        $display("\n\n====================");
        $display("@ cycle = %d, write back w req handshake", cycle);
        $display("wlast     = 0x%x", scu_mem_w.wlast);
        $display("wid       = 0x%x", scu_mem_w.wid);
        $write("wdata     = 0x");
        for(int i = MEM_DATA_WIDTH/64-1; i >=0; i--) begin
          $write("%h", scu_mem_w.wdata[i*64+:64]);
        end
        $display("\n====================");
      end
      if(scu_mem_ar_req_hsk) begin
        $display("\n\n====================");
        $display("@ cycle = %d, llc miss ar req handshake", cycle);
        $display("araddr    = 0x%x", scu_mem_ar.araddr);
        $display("arlen     = 0x%x", scu_mem_ar.arlen);
        $display("arsize    = 0x%x", scu_mem_ar.arsize);
        $display("arid      = 0x%x", scu_mem_ar.arid);
        $display("arburst   = 0x%x", scu_mem_ar.arburst);
        $display("====================");
      end
      if(scu_mem_r_resp_hsk) begin
        $display("\n\n====================");
        $display("@ cycle = %d, llc miss r resp handshake", cycle);
        $display("mesi_sta  = 0x%x", scu_mem_r.mesi_sta);
        $display("rresp     = 0x%x", scu_mem_r.rresp);
        $display("rlast     = 0x%x", scu_mem_r.rlast);
        $display("rid       = 0x%x", scu_mem_r.rid);
        $write("rdata     = 0x");
        for(int i = MEM_DATA_WIDTH/64-1; i >=0; i--) begin
          $write("%h", scu_mem_r.dat[i*64+:64]);
        end
        $display("\n====================");
      end
    end
  end

`ifdef RUBY
  `ifdef RT_MODE_CLASSIC
  if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_resp_data_mismatch) begin
    $display("CHECK NUM: %d, cycle:%d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err resp data mismatch-------");
    for(int i = 0; i < RT_CHECK_NUM; i++) begin
      if(rt_err_resp_data_mismatch_ent_q[i]) begin
        $display("right data = 0x%x", check_data_q_q[i][0+:RT_CHECK_DATA_CLASSIC_W]);
        $display("wrong data = 0x%x", check_port_update_resp_data_q[i][0+:RT_CHECK_DATA_CLASSIC_W]);
      end
    end
    $finish();
  end
  `endif
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_resp_timeout) begin
    $display("CHECK NUM: %d, cycle:%d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err resp timeout");
    for(int cc = 0; cc < RT_CHECK_NUM; cc++) begin
      if(top_sliced_llc.rubytest_top_u.rubytest_check_table_u.rt_err_resp_timeout_ent[cc]) begin
        $display("[core %2d, read port %2d](for each core, port 0-3 = port r0 w0 r1 w0)", top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_req_core_id_q[cc]/2, top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_req_core_id_q[cc]%2);
        $display("check_state_q = %s", top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_state_q[cc].name());
        $display("req sent cycle = %d", top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_req_cycle_q[cc]);
        $display("check_id       = 0x%x", cc);
        $display("paddr     = 0x%x", top_sliced_llc.rubytest_top_u.rubytest_check_table_u.check_addr_q[cc]);
      end
    end
    $finish();
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_put_by_invalid_trans_id) begin
    $display("CHECK NUM: %d, cycle:%d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err put by invalid trans id----------");
    $finish();
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_poll_by_invalid_trans_id) begin
    $display("CHECK NUM: %d, cycle:%d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err poll by invalid trans id---------");
    $finish();
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_resp_in_invalid_state) begin
    $display("CHECK NUM: %d, cycle:%d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err resp in invalid state-----");
    $finish();
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_ready_in_invalid_state) begin
    $display("CHECK NUM: %d, cycle:%d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err ready in invalid state-----");
    $finish();
  end
`endif
end

initial begin
  if ($value$plusargs("debug_print=%d", debug_print)) begin
    $display("TOP: debug_print_in=%d", debug_print);
  end
  if ($value$plusargs("ebi_debug_print=%d", ebi_debug_print)) begin
    $display("TOP: debug_print_ebi_in=%d", ebi_debug_print);
  end
end

`ifdef RUBY
function banner(int is_start);
  $display("\n-----------------");
  if (is_start)
      $display("------START RUBYTEST RTL TOP SIM-----------");
  else
      $display("------EXIT RUBYTEST RTL TOP SIM--------");
  $display("--------------------\n");
  if (0 == is_start)
      $finish();
endfunction : banner

initial begin
  banner(1);
end

initial begin
  if ($value$plusargs("timeout_count=%d", timeout_count)) begin
    $display("TOP: timeout_count_in=%d", timeout_count);
  end
  
  repeat(timeout_count) @(posedge clk);
  $display("TIMEOUT SIM %d times ....", timeout_count);
  $display("CHECK NUM: %d ....", top_sliced_llc.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0]);
  if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_resp_data_mismatch) begin
    $display("---------- ERROR: err resp data mismatch-------");
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_resp_timeout) begin
    $display("---------- ERROR: err resp timeout");
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_put_by_invalid_trans_id) begin
    $display("---------- ERROR: err put by invalid trans id----------");
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_poll_by_invalid_trans_id) begin
    $display("---------- ERROR: err poll by invalid trans id---------");
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_resp_in_invalid_state) begin
    $display("---------- ERROR: err resp in invalid state-----");
  end
  else if(top_sliced_llc.rubytest_top_u.rt_debug_info.err_ready_in_invalid_state) begin
    $display("---------- ERROR: err ready in invalid state-----");
  end
  else begin
    $display("RubyTest Result [SUCCESS]");
  end
  banner(0);
end

initial begin

  if ($value$plusargs("rseed0=%d", rseed0)) begin
      $display("TOP: user set rseed0=%d",rseed0);
  end else begin
      $display("TOP: default rseed0=%d",rseed0);
  end
  if ($value$plusargs("rseed1=%d", rseed1)) begin
      $display("TOP: rseed1=%d", rseed1);
  end else begin
    $display("TOP: default rseed1=%d",rseed1);
  end
end
`endif


endmodule
