module mesh_hn_top
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_cc_pkg::*;
    import rvh_l1d_pkg::*;
    import rvh_noc_pkg::*;
    import riscv_pkg::*;

(
`ifdef SYNTHESIS
    output logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_arvalid_o,
    input  logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_arready_i,
    output cache_mem_if_ar_t [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_ar_o,
     
    input  logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_rvalid_i ,
    output logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_rready_o ,
    input  cache_mem_if_r_t  [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_r_i,
     
    output logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_awvalid_o ,
    input  logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_awready_i ,
    output cache_mem_if_aw_t [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_aw_o ,
     
    output logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_wvalid_o ,
    input  logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_wready_i ,
    output cache_mem_if_w_t  [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_w_o ,
     
    input  logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_bvalid_i,
    output logic             [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_bready_o,
    input  cache_mem_if_b_t  [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0] scu_mem_b_i,
`endif

    input  logic clk,
    input  logic rst_n
);

  genvar i,j,z;

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




//hn
generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_hn_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_hn_y_dimesion
        hn_tile
        #(
          .CHANNEL_NUM(CHANNEL_NUM)
        ) hn_tile_u
        (
          .tx_flit_pend_o (tx_flit_pend[i][j]),
          .tx_flit_v_o (tx_flit_v[i][j]),
          .tx_flit_vc_id_o (tx_flit_vc_id[i][j]),
          .tx_flit_look_ahead_routing_o (tx_flit_look_ahead_routing[i][j]),
          .rx_flit_pend_i (rx_flit_pend[i][j]),
          .rx_flit_v_i (rx_flit_v[i][j]),
          .rx_flit_vc_id_i (rx_flit_vc_id[i][j]),
          .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing[i][j]),
          .tx_lcrd_v_i (tx_lcrd_v[i][j]),
          .tx_lcrd_id_i (tx_lcrd_id[i][j]),
          .rx_lcrd_v_o (rx_lcrd_v[i][j]),
          .rx_lcrd_id_o (rx_lcrd_id[i][j]),
          .tx_flit_channel_0_o (tx_flit_channel_0[i][j]),
          .tx_flit_channel_1_o (tx_flit_channel_1[i][j]),
          .tx_flit_channel_2_o (tx_flit_channel_2[i][j]),
          .tx_flit_channel_3_o (tx_flit_channel_3[i][j]),
          .tx_flit_channel_4_o (tx_flit_channel_4[i][j]),
          .rx_flit_channel_0_i (rx_flit_channel_0[i][j]),
          .rx_flit_channel_1_i (rx_flit_channel_1[i][j]),
          .rx_flit_channel_2_i (rx_flit_channel_2[i][j]),
          .rx_flit_channel_3_i (rx_flit_channel_3[i][j]),
          .rx_flit_channel_4_i (rx_flit_channel_4[i][j]),
  
          .node_id_x_i (i[NodeID_X_Width-1:0]),
          .node_id_y_i (j[NodeID_Y_Width-1:0]),

`ifdef SYNTHESIS
          .scu_mem_arvalid_o        (scu_mem_arvalid_o [i][j]),
          .scu_mem_arready_i        (scu_mem_arready_i [i][j]),
          .scu_mem_ar_o             (scu_mem_ar_o      [i][j]),

          .scu_mem_rvalid_i         (scu_mem_rvalid_i  [i][j]),
          .scu_mem_rready_o         (scu_mem_rready_o  [i][j]),
          .scu_mem_r_i              (scu_mem_r_i       [i][j]),

          .scu_mem_awvalid_o        (scu_mem_awvalid_o [i][j]),
          .scu_mem_awready_i        (scu_mem_awready_i [i][j]),
          .scu_mem_aw_o             (scu_mem_aw_o      [i][j]),
            
          .scu_mem_wvalid_o         (scu_mem_wvalid_o  [i][j]),
          .scu_mem_wready_i         (scu_mem_wready_i  [i][j]),
          .scu_mem_w_o              (scu_mem_w_o       [i][j]),
                
          .scu_mem_bvalid_i         (scu_mem_bvalid_i  [i][j]),
          .scu_mem_bready_o         (scu_mem_bready_o  [i][j]),
          .scu_mem_b_i              (scu_mem_b_i       [i][j]),
`endif
          
          .clk (clk),
          .rst_n (rst_n)
        );
      end
    end
endgenerate

  // connect each router together
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

endmodule
