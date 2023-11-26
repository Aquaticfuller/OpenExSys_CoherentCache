import rrv64_top_macro_pkg::*;
import rrv64_top_param_pkg::*;
import rrv64_top_typedef_pkg::*;
import rrv64_core_param_pkg::*;
import rrv64_core_typedef_pkg::*;
import rrv64_uncore_param_pkg::*;
import rrv64_uncore_typedef_pkg::*;
import rvh_l1d_pkg::*;

`ifdef RT_RUBY_ENABLE_MULTICORE
    parameter RT_ENABLE_MULTICORE  = 1;
`else
    parameter RT_ENABLE_MULTICORE  = 0;
`endif
`ifdef RT_RUBY_ENABLE_IO
    parameter RT_ENABLE_IO         = 1;
`else
    parameter RT_ENABLE_IO         = 0;
`endif
`ifdef RT_RUBY_ENABLE_AMO
    parameter RT_ENABLE_AMO        = 1;
`else
    parameter RT_ENABLE_AMO        = 0;
`endif


`ifdef  RT_MODE_CLASSIC   
parameter RT_CHECK_NUM         = 256; //32;
`else 
parameter RT_CHECK_NUM         = 512;
// parameter RT_CHECK_NUM         = 8;
`endif
parameter RT_CHECK_SYS_ADDR_W  = 56;
parameter RT_CHECK_SYS_DATA_W  = 64;

parameter RT_CHECK_NUM_W       = $clog2(RT_CHECK_NUM);//5

parameter RT_CORE_NUM         = RUBY_TOP_L1D_NUM * RUBY_TOP_L1D_PORT_NUM;
parameter RT_CORE_NUM_W       = $clog2(RT_CORE_NUM);
parameter RT_L1D_PORT_NUM_PER_CORE = 2;
parameter RT_L1D_PORT_NUM     = RT_CORE_NUM * RT_L1D_PORT_NUM_PER_CORE;//4
parameter RT_L1D_PORT_NUM_W   = $clog2(RT_L1D_PORT_NUM);//3

parameter RT_TRANS_ID_NUM     = 32;
parameter RT_TRANS_ID_NUM_W   = $clog2(RT_TRANS_ID_NUM);//RRV64_LSU_ID_WIDTH;

parameter RT_CHECK_STATE_W    = 2;

parameter RT_CHECK_BYTE_COUNT_NUM = 4;// 4byte per check
parameter RT_CHECK_BYTE_COUNT_NUM_W = $clog2(RT_CHECK_BYTE_COUNT_NUM);
parameter RT_CHECK_DATA_CLASSIC_W = RT_CHECK_BYTE_COUNT_NUM*8;
parameter RT_CHECK_ADDR_CLASSIC_W = 32;

parameter RT_MEM_SIZE         = 32'(2 * 1024 * 1024 * 1024);//2GB is enough
parameter RT_CHECK_ADDR_BASE  = 32'h00000000;
parameter RT_CHECK_ADDR_END   = RT_MEM_SIZE + RT_CHECK_ADDR_BASE;
parameter RT_CHECK_ADDR_DELTA = RT_CHECK_NUM * RT_CHECK_BYTE_COUNT_NUM;//32 * 4
parameter RT_CHECK_ADDR_END_DELTA = RT_CHECK_ADDR_END - RT_CHECK_ADDR_DELTA;
parameter RT_CHECK_DATA_BASE  = 32'h13121110;

parameter RT_CHECK_TRANS_OK_CNT_W = 64;
parameter RT_CYCLE_CNT_W          = 64;
parameter RT_RESP_TIMEOUT_CYCLE_CNT_W = 200000;

parameter RT_CHECK_GEN_ADDR_W     = 32;

`ifdef RT_MODE_CLASSIC           
parameter RT_CID_DELTA_NUM       = RT_CHECK_NUM/RT_L1D_PORT_NUM;// 4
parameter RT_CID_DELTA_NUM_W     = $clog2(RT_CID_DELTA_NUM);//2

parameter RT_CHECK_ADDR_W        = RT_CHECK_ADDR_CLASSIC_W;//32
parameter RT_CHECK_DATA_W        = RT_CHECK_DATA_CLASSIC_W;//32bit
parameter RT_L1D_PORT_RESP_NUM   = RT_L1D_PORT_NUM;//4
parameter RT_RESP_NUM            = 1;
`else
parameter RT_RESP_NUM            = RT_L1D_PORT_NUM_PER_CORE;
// parameter RT_RESP_NUM            = 1;
parameter RT_L1D_PORT_RESP_NUM   = RT_CORE_NUM + RT_L1D_PORT_NUM;
// parameter RT_L1D_PORT_RESP_NUM   = RT_L1D_PORT_NUM;
parameter RT_CHECK_ADDR_W        = RT_CHECK_GEN_ADDR_W;
parameter RT_CHECK_DATA_W        = RT_CHECK_SYS_DATA_W;
`endif

parameter RT_CMO_ADDR_START      = 32'hff024000;
parameter RT_CMO_ADDR_END        = 32'hff024fff;

typedef struct packed{
    logic [RT_CHECK_ADDR_W-1:0] addr;
    logic [RT_CHECK_DATA_W-1:0] data;
    logic                       is_cacheable;
    lsu_op_e                    opcode;
    logic [RT_TRANS_ID_NUM_W-1:0] tid;
}rt_check_gen_t;

typedef struct packed{
    logic [RT_CHECK_GEN_ADDR_W-1:0] addr;
    logic                           is_cacheable;
    lsu_op_e                        opcode;  
} rt_check_gen_info_t;

typedef struct packed {
    logic [RT_CHECK_NUM_W-1:0] check_id;
} rt_check_update_req_ready_t;

typedef struct packed {
    logic [RT_CHECK_NUM_W-1:0] check_id;
    logic [RT_CHECK_DATA_W-1:0] data;
} rt_check_update_resp_t;

typedef struct packed {
    logic                          err_put_by_invalid_trans_id;
    logic                          err_poll_by_invalid_trans_id;
    logic                          err_resp_data_mismatch;
    logic                          err_ready_in_invalid_state;
    logic                          err_resp_in_invalid_state;
    logic                          err_resp_timeout;
    logic  [RT_CHECK_TRANS_OK_CNT_W-1:0] stats_trans_ok_cnt;
} rt_debug_info_t;


typedef enum logic[RT_CHECK_STATE_W-1:0] {
    CHECK_STATE_IDLE         = RT_CHECK_STATE_W'('d0) ,
    CHECK_STATE_ACTION_PENDING = RT_CHECK_STATE_W'('d1) ,
    CHECK_STATE_READY        = RT_CHECK_STATE_W'('d2) ,
    CHECK_STATE_CHECK_PENDING = RT_CHECK_STATE_W'('d3)
}check_state_e;

module rubytest_top
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
(
 input  logic      clk
,input  logic      rst_n
,output logic [RT_CORE_NUM-1:0][RT_L1D_PORT_NUM_PER_CORE-1:0] rt_l1d_req_valid_o
,output rrv64_lsu_l1d_req_t [RT_CORE_NUM-1:0][RT_L1D_PORT_NUM_PER_CORE-1:0] rt_l1d_req_o
,input  logic [RT_CORE_NUM-1:0][RT_L1D_PORT_NUM_PER_CORE-1:0] rt_l1d_req_ready_i
,input  logic [RT_CORE_NUM-1:0][RT_L1D_PORT_NUM_PER_CORE-1:0] rt_l1d_resp_valid_i
,input  rrv64_lsu_l1d_resp_t [RT_CORE_NUM-1:0][RT_L1D_PORT_NUM_PER_CORE-1:0] rt_l1d_resp_i
,output logic [RT_CORE_NUM-1:0][RT_L1D_PORT_NUM_PER_CORE-1:0] rt_l1d_resp_ready_o

`ifdef RT_MODE_CLASSIC
,input logic [RT_CID_DELTA_NUM_W-1:0] rt_cid_delta_seed_i//2
,input logic [RT_CHECK_NUM_W-1:0] rt_cid_base_seed_i//5
`else
,input logic [RT_CHECK_GEN_ADDR_W-1:0] rt_info_addr_seed_i
,input logic [$bits(lsu_op_e)-1:0]     rt_info_opcode_seed_i
`endif
,output rt_debug_info_t                rt_debug_info
);
genvar ii;
logic               [RT_L1D_PORT_NUM-1:0]  __rt_l1d_req_valid;
rrv64_lsu_l1d_req_t [RT_L1D_PORT_NUM-1:0]  __rt_l1d_req;
logic               [RT_L1D_PORT_NUM-1:0]  __rt_l1d_req_ready;
logic               [RT_CORE_NUM-1:0]      __rt_l1d_ld_resp_valid;
rrv64_lsu_l1d_resp_t[RT_CORE_NUM-1:0]      __rt_l1d_ld_resp;
logic               [RT_CORE_NUM-1:0][RT_RESP_NUM-1:0] __rt_l1d_st_resp_valid;
rrv64_lsu_l1d_resp_t[RT_CORE_NUM-1:0][RT_RESP_NUM-1:0] __rt_l1d_st_resp;

logic               [RT_L1D_PORT_NUM-1:0]  __rt_check_gen_valid;

rt_check_gen_t      [RT_L1D_PORT_NUM-1:0]  __rt_check_gen;
logic               [RT_L1D_PORT_NUM-1:0]  __rt_check_gen_ready;

logic               [RT_L1D_PORT_NUM-1:0]  __rt_check_update_req_ready_valid;
rt_check_update_req_ready_t [RT_L1D_PORT_NUM-1:0] __rt_check_update_req_ready;

logic               [RT_CORE_NUM-1:0]      __rt_check_ld_update_resp_valid;
rt_check_update_resp_t [RT_CORE_NUM-1:0]   __rt_check_ld_update_resp;
logic               [RT_CORE_NUM-1:0][RT_RESP_NUM-1:0] __rt_check_st_update_resp_valid;
rt_check_update_resp_t [RT_CORE_NUM-1:0][RT_RESP_NUM-1:0] __rt_check_st_update_resp;
logic               [RT_L1D_PORT_RESP_NUM-1:0] __rt_check_update_resp_valid;
rt_check_update_resp_t [RT_L1D_PORT_RESP_NUM-1:0] __rt_check_update_resp;

logic               [RT_L1D_PORT_NUM-1:0]  __rt_tid_poll_valid;
logic [RT_L1D_PORT_NUM-1:0][RT_TRANS_ID_NUM_W-1:0] __rt_tid_poll_trans_id;
logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0] __rt_tid_poll_check_id;
logic               [RT_L1D_PORT_NUM-1:0]  __rt_tid_poll_ready;

logic               [RT_CORE_NUM-1:0]  __rt_tid_ld_put_valid;
logic [RT_CORE_NUM-1:0][RT_TRANS_ID_NUM_W-1:0] __rt_tid_ld_put_trans_id;
logic [RT_CORE_NUM-1:0][RT_CHECK_NUM_W-1:0] __rt_tid_ld_put_check_id;
logic               [RT_CORE_NUM-1:0]  __rt_tid_ld_put_ready;

logic [RT_CORE_NUM-1:0][RT_RESP_NUM-1:0] __rt_tid_st_put_valid;
logic [RT_CORE_NUM-1:0][RT_TRANS_ID_NUM_W-1:0][RT_RESP_NUM-1:0] __rt_tid_st_put_trans_id;
logic [RT_CORE_NUM-1:0][RT_CHECK_NUM_W-1:0][RT_RESP_NUM-1:0] __rt_tid_st_put_check_id;
logic [RT_CORE_NUM-1:0][RT_RESP_NUM-1:0]                     __rt_tid_st_put_ready;

logic [RT_L1D_PORT_NUM-1:0]                __rt_tid_get_valid;
logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0] __rt_tid_get_check_id;
logic [RT_L1D_PORT_NUM-1:0][RT_TRANS_ID_NUM_W-1:0] __rt_tid_get_trans_id;
logic [RT_L1D_PORT_NUM-1:0]                __rt_tid_get_ready;

logic [RT_L1D_PORT_NUM-1:0]                __rt_port_gen_check_valid;
`ifdef RT_MODE_CLASSIC
logic [RT_L1D_PORT_NUM-1:0]                __rt_port_gen_check_ready;
logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0] __rt_port_gen_check_id;//5位的id
`else
rt_check_gen_info_t [RT_L1D_PORT_NUM-1:0]  __rt_port_gen_check_info;
logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_GEN_ADDR_W-1:0] __rt_gen_info_addr_seed;
logic [RT_L1D_PORT_NUM-1:0][$bits(lsu_op_e)-1:0] __rt_gen_info_opcode_seed;
`endif

logic                                      __rt_err_resp_data_mismatch;
logic                                      __rt_err_resp_timeout;
logic                                      __rt_err_resp_in_invalid_state;
logic                                      __rt_err_ready_in_invalid_state;
logic  [RT_CHECK_TRANS_OK_CNT_W-1:0]       __rt_stats_trans_ok_cnt;
logic  [RT_L1D_PORT_NUM-1:0]               __rt_err_port_poll_by_invalid_trans_id;
logic  [RT_L1D_PORT_NUM-1:0]               __rt_err_port_put_by_invalid_trans_id;
logic                                      __rt_err_poll_by_invalid_trans_id_d;
logic                                      __rt_err_put_by_invalid_trans_id_d;
logic                                      __rt_err_poll_by_invalid_trans_id_q;
logic                                      __rt_err_put_by_invalid_trans_id_q;

logic [RT_CORE_NUM-1:0]                    ld_port_amo_resp;
logic [RT_CORE_NUM-1:0]                    ld_port_amo_resp_vld;

assign __rt_err_poll_by_invalid_trans_id_d = |__rt_err_port_poll_by_invalid_trans_id;
assign __rt_err_put_by_invalid_trans_id_d = |__rt_err_port_put_by_invalid_trans_id;

assign rt_debug_info.err_put_by_invalid_trans_id  = __rt_err_put_by_invalid_trans_id_q;
assign rt_debug_info.err_poll_by_invalid_trans_id = __rt_err_poll_by_invalid_trans_id_q;
assign rt_debug_info.err_resp_data_mismatch       = __rt_err_resp_data_mismatch;
assign rt_debug_info.err_resp_timeout             = __rt_err_resp_timeout;
assign rt_debug_info.err_resp_in_invalid_state    = __rt_err_resp_in_invalid_state;
assign rt_debug_info.err_ready_in_invalid_state   = __rt_err_ready_in_invalid_state;
assign rt_debug_info.stats_trans_ok_cnt           = __rt_stats_trans_ok_cnt;

std_dffre #(1) FF_ERR_POLLBITI (.clk(clk),.rstn(rst_n),.en(__rt_err_poll_by_invalid_trans_id_d),.d(__rt_err_poll_by_invalid_trans_id_d),.q(__rt_err_poll_by_invalid_trans_id_q));
std_dffre #(1) FF_ERR_PUTBITI  (.clk(clk),.rstn(rst_n),.en(__rt_err_put_by_invalid_trans_id_d),.d(__rt_err_put_by_invalid_trans_id_d),.q(__rt_err_put_by_invalid_trans_id_q));

generate
for(ii=0;ii<RT_CORE_NUM;ii++) begin : GEN_DUT_PORT_INFO
    assign rt_l1d_req_valid_o[ii] = __rt_l1d_req_valid[ii*RT_L1D_PORT_NUM_PER_CORE+:RT_L1D_PORT_NUM_PER_CORE];
    assign rt_l1d_req_o[ii] = __rt_l1d_req[ii*RT_L1D_PORT_NUM_PER_CORE+:RT_L1D_PORT_NUM_PER_CORE];
    assign __rt_l1d_req_ready[ii*RT_L1D_PORT_NUM_PER_CORE+:RT_L1D_PORT_NUM_PER_CORE]  = rt_l1d_req_ready_i[ii];

    assign ld_port_amo_resp[ii] = (LSU_LRW <= rt_l1d_resp_i[ii][0].req_type) & (rt_l1d_resp_i[ii][0].req_type <= LSU_AMOMINUD);
    assign ld_port_amo_resp_vld[ii] = rt_l1d_resp_valid_i[ii][0] & ld_port_amo_resp[ii];
    assign __rt_l1d_ld_resp_valid[ii] = rt_l1d_resp_valid_i[ii][0] & ~ld_port_amo_resp[ii];
    assign __rt_l1d_ld_resp[ii] = rt_l1d_resp_i[ii][0];

    assign __rt_l1d_st_resp_valid[ii][0] = rt_l1d_resp_valid_i[ii][1];
    assign __rt_l1d_st_resp[ii][0]  =  rt_l1d_resp_i[ii][1];
    if (1 < RT_RESP_NUM) begin
        assign __rt_l1d_st_resp_valid[ii][1] = ld_port_amo_resp_vld[ii];
        assign __rt_l1d_st_resp[ii][1] = rt_l1d_resp_i[ii][0];
    end
    assign rt_l1d_resp_ready_o[ii] = {RT_L1D_PORT_NUM_PER_CORE{1'b1}};
end
endgenerate

`ifdef RT_MODE_CLASSIC
rubytest_port_check_gen_cid rubytest_port_check_gen_cid_u
(
    .clk                       (clk),
    .rst_n                     (rst_n),
    .rt_port_gen_check_valid_o (__rt_port_gen_check_valid),
    .rt_port_gen_check_id_o    (__rt_port_gen_check_id),
    .rt_port_gen_check_ready_i (__rt_port_gen_check_ready),
    .rt_cid_delta_seed_i       (rt_cid_delta_seed_i),//0
    .rt_cid_base_seed_i        (rt_cid_base_seed_i)//0
);
`else
generate
for(ii=0;ii<RT_L1D_PORT_NUM;ii++) begin : GEN_RT_PORT_CHECK_GEN_INFO
assign __rt_gen_info_addr_seed[ii] = rt_info_addr_seed_i + (ii+1) * ('h123456);
assign __rt_gen_info_opcode_seed[ii] = rt_info_opcode_seed_i + ii;

rubytest_port_check_gen_info #(ii%RT_L1D_PORT_NUM_PER_CORE) rubytest_port_check_gen_info_u
(
    .clk                        (clk)
    ,.rst_n                      (rst_n)
    ,.rt_port_gen_check_info_o   (__rt_port_gen_check_info[ii])
    ,.rt_gen_info_addr_seed_i    (__rt_gen_info_addr_seed[ii])
    ,.rt_gen_info_opcode_seed_i  (__rt_gen_info_opcode_seed[ii])
);
assign __rt_port_gen_check_valid[ii] = 1'b1;
end
endgenerate
`endif

generate
for(ii=0;ii<RT_L1D_PORT_NUM;ii++) begin : GEN_RT_TRANS_ID_POOL
    if (ii%RT_L1D_PORT_NUM_PER_CORE == 0) begin
    rubytest_trans_id_pool rubytest_trans_id_pool_u (
        .clk                         (clk),
        .rst_n                       (rst_n),

        .rt_tid_get_valid_i          (__rt_tid_get_valid[ii]),
        .rt_tid_get_check_id_i       (__rt_tid_get_check_id[ii]),
        .rt_tid_get_trans_id_o       (__rt_tid_get_trans_id[ii]),
        .rt_tid_get_ready_o          (__rt_tid_get_ready[ii]),

        .rt_tid_poll_valid_i         (__rt_tid_poll_valid[ii]),
        .rt_tid_poll_trans_id_i      (__rt_tid_poll_trans_id[ii]),
        .rt_tid_poll_check_id_o      (__rt_tid_poll_check_id[ii]),
        .rt_tid_poll_ready_o         (__rt_tid_poll_ready[ii]),

        .rt_tid_put_valid_i          (__rt_tid_ld_put_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_tid_put_trans_id_i       (__rt_tid_ld_put_trans_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_tid_put_check_id_o       (__rt_tid_ld_put_check_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_tid_put_ready_o          (__rt_tid_ld_put_ready[ii/RT_L1D_PORT_NUM_PER_CORE]),

        .rt_err_poll_by_invalid_trans_id_o (__rt_err_port_poll_by_invalid_trans_id[ii]),
        .rt_err_put_by_invalid_trans_id_o  (__rt_err_port_put_by_invalid_trans_id[ii])
    );
    end else begin
        rubytest_trans_id_pool
    `ifndef RT_MODE_CLASSIC
        #(RT_L1D_PORT_NUM_PER_CORE)
    `endif
        rubytest_trans_id_pool_u (
            .clk             (clk),
            .rst_n           (rst_n),
            .rt_tid_get_valid_i (__rt_tid_get_valid[ii]),
            .rt_tid_get_check_id_i (__rt_tid_get_check_id[ii]),
            .rt_tid_get_trans_id_o (__rt_tid_get_trans_id[ii]),
            .rt_tid_get_ready_o    (__rt_tid_get_ready[ii]),

            .rt_tid_poll_valid_i    (__rt_tid_poll_valid[ii]),
            .rt_tid_poll_trans_id_i (__rt_tid_poll_trans_id[ii]),
            .rt_tid_poll_check_id_o (__rt_tid_poll_check_id[ii]),
            .rt_tid_poll_ready_o    (__rt_tid_poll_ready[ii]),

            .rt_tid_put_valid_i     (__rt_tid_st_put_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_tid_put_trans_id_i  (__rt_tid_st_put_trans_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_tid_put_check_id_o  (__rt_tid_st_put_check_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_tid_put_ready_o     (__rt_tid_st_put_ready[ii/RT_L1D_PORT_NUM_PER_CORE]),

            .rt_err_poll_by_invalid_trans_id_o (__rt_err_port_poll_by_invalid_trans_id[ii]),
            .rt_err_put_by_invalid_trans_id_o  (__rt_err_port_put_by_invalid_trans_id[ii])
        );
    end
end
endgenerate

generate
for(ii=0;ii<RT_L1D_PORT_NUM;ii++) begin : GEN_RT_TRANS_CTRL//8
    if (ii%RT_L1D_PORT_NUM_PER_CORE == 0) begin
    rubytest_trans_control rubytest_trans_control_u (
        .clk                 (clk),
        .rst_n               (rst_n),
        .rt_l1d_req_valid_o  (__rt_l1d_req_valid[ii]),
        .rt_l1d_req_o        (__rt_l1d_req[ii]),
        .rt_l1d_req_ready_i  (__rt_l1d_req_ready[ii]),
        .rt_l1d_resp_valid_i (__rt_l1d_ld_resp_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_l1d_resp_i       (__rt_l1d_ld_resp[ii/RT_L1D_PORT_NUM_PER_CORE]),


        .rt_check_gen_valid_i(__rt_check_gen_valid[ii]),
        .rt_check_gen_i      (__rt_check_gen[ii]),
        .rt_check_gen_ready_o(__rt_check_gen_ready[ii]),

        .rt_check_update_req_ready_valid_o (__rt_check_update_req_ready_valid[ii]),
        .rt_check_update_req_ready_o       (__rt_check_update_req_ready[ii]),

        .rt_check_update_resp_valid_o      (__rt_check_ld_update_resp_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_check_update_resp_o            (__rt_check_ld_update_resp[ii/RT_L1D_PORT_NUM_PER_CORE]),

        .rt_tid_poll_valid_o               (__rt_tid_poll_valid[ii]),
        .rt_tid_poll_trans_id_o            (__rt_tid_poll_trans_id[ii]),
        .rt_tid_poll_check_id_i            (__rt_tid_poll_check_id[ii]),
        .rt_tid_poll_ready_i               (__rt_tid_poll_ready[ii]),
        .rt_tid_put_valid_o                (__rt_tid_ld_put_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_tid_put_trans_id_o             (__rt_tid_ld_put_trans_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_tid_put_check_id_i             (__rt_tid_ld_put_check_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
        .rt_tid_put_ready_i                (__rt_tid_ld_put_ready[ii/RT_L1D_PORT_NUM_PER_CORE])
    );
    end else begin
        rubytest_trans_control
    `ifndef RT_MODE_CLASSIC
        #(RT_L1D_PORT_NUM_PER_CORE)
    `endif
        rubytest_trans_control_u(
            .clk                            (clk),
            .rst_n                          (rst_n),
            //l1d
            .rt_l1d_req_valid_o             (__rt_l1d_req_valid[ii]),
            .rt_l1d_req_o                   (__rt_l1d_req[ii]),
            .rt_l1d_req_ready_i             (__rt_l1d_req_ready[ii]),
            .rt_l1d_resp_valid_i            (__rt_l1d_st_resp_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_l1d_resp_i                  (__rt_l1d_st_resp[ii/RT_L1D_PORT_NUM_PER_CORE]),
            //table
            .rt_check_gen_valid_i           (__rt_check_gen_valid[ii]),
            .rt_check_gen_i                 (__rt_check_gen[ii]),
            .rt_check_gen_ready_o           (__rt_check_gen_ready[ii]),
            .rt_check_update_req_ready_valid_o (__rt_check_update_req_ready_valid[ii]),
            .rt_check_update_req_ready_o    (__rt_check_update_req_ready[ii]),
            .rt_check_update_resp_valid_o   (__rt_check_st_update_resp_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_check_update_resp_o         (__rt_check_st_update_resp[ii/RT_L1D_PORT_NUM_PER_CORE]),
            //pool
            .rt_tid_poll_valid_o            (__rt_tid_poll_valid[ii]),
            .rt_tid_poll_trans_id_o         (__rt_tid_poll_trans_id[ii]),
            .rt_tid_poll_check_id_i         (__rt_tid_poll_check_id[ii]),
            .rt_tid_poll_ready_i            (__rt_tid_poll_ready[ii]),
            .rt_tid_put_valid_o             (__rt_tid_st_put_valid[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_tid_put_trans_id_o          (__rt_tid_st_put_trans_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_tid_put_check_id_i          (__rt_tid_st_put_check_id[ii/RT_L1D_PORT_NUM_PER_CORE]),
            .rt_tid_put_ready_i             (__rt_tid_st_put_ready[ii/RT_L1D_PORT_NUM_PER_CORE])
        );
    end
end
endgenerate

generate
for(ii=0;ii<RT_L1D_PORT_RESP_NUM;ii++) begin: GEN_RT_UPDATE_RESP
    if (ii%(RT_RESP_NUM+1) == 0) begin
        assign __rt_check_update_resp_valid[ii] = __rt_check_ld_update_resp_valid[ii/(RT_RESP_NUM+1)];
        assign __rt_check_update_resp[ii]       = __rt_check_ld_update_resp[ii/(RT_RESP_NUM+1)];
    end else if (ii%(RT_RESP_NUM+1) == 1) begin
        assign __rt_check_update_resp_valid[ii+:RT_RESP_NUM] = __rt_check_st_update_resp_valid[ii/(RT_RESP_NUM+1)];
        assign __rt_check_update_resp[ii+:RT_RESP_NUM] = __rt_check_st_update_resp[ii/(RT_RESP_NUM+1)];
    end
end
endgenerate
    

rubytest_check_table rubytest_check_table_u (
        .clk                               (clk),
        .rst_n                             (rst_n),

        .rt_tid_get_valid_o                (__rt_tid_get_valid),
        .rt_tid_get_check_id_o             (__rt_tid_get_check_id),
        .rt_tid_get_trans_id_i             (__rt_tid_get_trans_id),
        .rt_tid_get_ready_i                (__rt_tid_get_ready),

        .rt_check_gen_valid_o              (__rt_check_gen_valid),
        .rt_check_gen_o                    (__rt_check_gen),
        .rt_check_gen_ready_i              (__rt_check_gen_ready),

        .rt_check_update_req_ready_valid_i (__rt_check_update_req_ready_valid),
        .rt_check_update_req_ready_i       (__rt_check_update_req_ready),

        .rt_check_update_resp_valid_i      (__rt_check_update_resp_valid),
        .rt_check_update_resp_i            (__rt_check_update_resp),

        .rt_port_gen_check_valid_i         (__rt_port_gen_check_valid),
`ifdef RT_MODE_CLASSIC
        .rt_port_gen_check_ready_o         (__rt_port_gen_check_ready),
        .rt_port_gen_check_id_i            (__rt_port_gen_check_id),
`else
        .rt_port_gen_check_info_i          (__rt_port_gen_check_info),
`endif  
        .rt_err_resp_data_mismatch_o       (__rt_err_resp_data_mismatch),
        .rt_err_ready_in_invalid_state_o   (__rt_err_ready_in_invalid_state),
        .rt_err_resp_in_invalid_state_o    (__rt_err_resp_in_invalid_state),
        .rt_err_resp_timeout_o             (__rt_err_resp_timeout),
        .rt_stats_trans_ok_cnt_o           (__rt_stats_trans_ok_cnt)                                  
);

endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
`ifdef  RT_MODE_CLASSIC

module rubytest_port_check_gen_cid
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
(
    input logic                          clk
   ,input logic                          rst_n
   ,output logic [RT_L1D_PORT_NUM-1:0]   rt_port_gen_check_valid_o
   ,output logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0]   rt_port_gen_check_id_o//8 5
   ,input  logic [RT_L1D_PORT_NUM-1:0]   rt_port_gen_check_ready_i
   ,input  logic [RT_CID_DELTA_NUM_W-1:0]    rt_cid_delta_seed_i
   ,input  logic [RT_CHECK_NUM_W-1:0]    rt_cid_base_seed_i
);

logic [RT_CHECK_NUM_W-1:0] lfsr_cid_data;//5
logic [RT_CID_DELTA_NUM_W-1:0] lfsr_delta_data;//2
//generate check id delta
LFSR #(.NUM_BITS(RT_CID_DELTA_NUM_W)) LFSR_delta_u (//2
    .i_Clk                      (clk),
    .i_Enable                   (rst_n),
    .i_Seed_DV                  ('0),
    .i_Seed_Data                (rt_cid_delta_seed_i),
    .o_LFSR_Data                (lfsr_delta_data),
    .o_LFSR_Done                ()
);
//generate check id base
LFSR #(.NUM_BITS(RT_CHECK_NUM_W)) LFSR_check_id_u (//5
    .i_Clk                  (clk),
    .i_Enable               (rst_n),
    .i_Seed_DV              ('0),
    .i_Seed_Data            (rt_cid_base_seed_i),
    .o_LFSR_Data            (lfsr_cid_data),
    .o_LFSR_Done            ()
);

logic  port_gen_check_valid_q;

generate
    for(genvar ii=0; ii<RT_L1D_PORT_NUM; ii++) begin
        assign rt_port_gen_check_valid_o[ii] = port_gen_check_valid_q;
        assign rt_port_gen_check_id_o[ii] = lfsr_cid_data + ii * (lfsr_delta_data + 1);// overflow is fine, rollback
    end
endgenerate

std_dffr #(1) FF_GEN_CHECK_VALID (.clk(clk) ,.rstn(rst_n) ,.d(rst_n) ,.q(port_gen_check_valid_q));

endmodule

`else
module rubytest_port_check_gen_info
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
#(
    parameter L1D_PORT_STORE = 0
)
(
    input logic clk
   ,input logic rst_n
   ,output rt_check_gen_info_t rt_port_gen_check_info_o
   ,input logic [RT_CHECK_GEN_ADDR_W-1:0] rt_gen_info_addr_seed_i
   ,input logic [$bits(lsu_op_e)-1:0] rt_gen_info_opcode_seed_i
);

logic [31:0][5:0] opcode_st_table;
logic [15:0][5:0] opcode_ld_table;

logic [RT_CHECK_GEN_ADDR_W-1:0] addr_gen;
logic [RT_CHECK_GEN_ADDR_W-1:0] align_addr;
logic [4:0]                     opcode_idx_gen;
logic [$bits(lsu_op_e)-1:0]     opcode_gen;
logic [$bits(lsu_op_e)-1:0]     opcode_lsu_noamo;
logic [$bits(lsu_op_e)-1:0]     opcode;

// assign opcode_st_table = {6'd8,6'd9,6'd10,6'd11,6'd14,6'd15,6'd16,6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23,6'd24,6'd25,6'd26,6'd27,6'd28,6'd29,6'd30,6'd31,6'd32,6'd33,6'd35,6'd37,6'd8,6'd9,6'd10,6'd11,6'd12,6'd13};
assign opcode_st_table = {6'd8,6'd9,6'd10,6'd11,  6'd8,6'd9,6'd10,6'd11};
// assign opcode_ld_table = {6'd1,6'd2,6'd3,6'd4,6'd5,6'd6,6'd7,6'd2,6'd3,6'd34,6'd36,6'd4,6'd1,6'd6,6'd34,6'd7};
assign opcode_ld_table = {6'd1,6'd2,6'd3,6'd4,6'd5,6'd6,6'd7,  6'd1};

LFSR #(.NUM_BITS(RT_CHECK_GEN_ADDR_W)) LFSR_check_addr_u (
    .i_Clk             (clk),
    .i_Enable          (rst_n),
    .i_Seed_DV         ('0),
    .i_Seed_Data       (rt_gen_info_addr_seed_i),
    .o_LFSR_Data       (addr_gen),
    .o_LFSR_Done       ()
);

generate
if (L1D_PORT_STORE == 1) begin
// LFSR #(.NUM_BITS(5)) LFSR_check_opcode_u (
LFSR #(.NUM_BITS(3)) LFSR_check_opcode_u (
    .i_Clk                  (clk),
    .i_Enable               (rst_n),
    .i_Seed_DV              ('0),
    .i_Seed_Data            (rt_gen_info_opcode_seed_i),
    .o_LFSR_Data            (opcode_idx_gen),
    .o_LFSR_Done            ()
);
assign opcode_gen = opcode_st_table[opcode_idx_gen];
end else begin

// LFSR #(.NUM_BITS(4)) LFSR_check_opcode_u(
LFSR #(.NUM_BITS(3)) LFSR_check_opcode_u(
    .i_Clk         (clk),
    .i_Enable      (rst_n),
    .i_Seed_DV      ('0),
    .i_Seed_Data    (rt_gen_info_opcode_seed_i),
    .o_LFSR_Data    (opcode_idx_gen),
    .o_LFSR_Done    ()
);
assign opcode_gen = opcode_ld_table[opcode_idx_gen];
end
endgenerate

// do alignment
assign align_addr  = (opcode == LSU_LB || opcode == LSU_LBU || opcode == LSU_SB ) ? addr_gen :
                     (opcode == LSU_LH || opcode == LSU_LHU || opcode == LSU_SH ) ? {addr_gen[RT_CHECK_GEN_ADDR_W-1:1],1'b0}:
                     (opcode == LSU_LW || opcode == LSU_LWU || opcode == LSU_SW || opcode == LSU_LRW || 
                      opcode == LSU_SCW || opcode == LSU_AMOSWAPW || opcode == LSU_AMOADDW || opcode == LSU_AMOANDW || opcode == LSU_AMOXORW ||
                      opcode == LSU_AMOORW || opcode == LSU_AMOMAXW || opcode == LSU_AMOMAXUW || opcode == LSU_AMOMINW ||
                      opcode == LSU_AMOMINUW || opcode == LSU_FLW || opcode == LSU_FSW) ? {addr_gen[RT_CHECK_GEN_ADDR_W-1:2],2'b0} : 
                     {addr_gen[RT_CHECK_GEN_ADDR_W-1:3],3'b0};

// TODO: change cmo addr for store op
assign rt_port_gen_check_info_o.addr = ((L1D_PORT_STORE == 1) && (RT_CMO_ADDR_START <= align_addr && align_addr <= RT_CMO_ADDR_END)) ? (align_addr & RT_CHECK_GEN_ADDR_W'('hf0ffffff)) : align_addr;
assign opcode_lsu_noamo = (LSU_LRW <= opcode_gen && opcode_gen <= LSU_AMOMINUD) ? LSU_SD : opcode_gen;
// till now. support nc amo except lrsc
assign opcode = (RT_ENABLE_AMO) ? opcode_gen : opcode_lsu_noamo;
// till mow. dont support cmo store
assign rt_port_gen_check_info_o.opcode = opcode;
// half is 1, NOTICE nc space, AMO for cacheable
assign rt_port_gen_check_info_o.is_cacheable = ~RT_ENABLE_IO | (addr_gen < (1<<(RT_CHECK_GEN_ADDR_W-1)));
endmodule
`endif
//rubytest_check_table
module rubytest_check_table
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
(
    input logic                                               clk
   ,input logic                                               rst_n
   ,output logic [RT_L1D_PORT_NUM-1:0]                        rt_tid_get_valid_o
   ,output logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0]    rt_tid_get_check_id_o
   ,input logic  [RT_L1D_PORT_NUM-1:0][RT_TRANS_ID_NUM_W-1:0] rt_tid_get_trans_id_i
   ,input logic  [RT_L1D_PORT_NUM-1:0]                        rt_tid_get_ready_i
   ,output logic [RT_L1D_PORT_NUM-1:0]                        rt_check_gen_valid_o
   ,output rt_check_gen_t [RT_L1D_PORT_NUM-1:0]               rt_check_gen_o
   ,input  logic          [RT_L1D_PORT_NUM-1:0]               rt_check_gen_ready_i
   ,input  logic          [RT_L1D_PORT_NUM-1:0]               rt_check_update_req_ready_valid_i
   ,input  rt_check_update_req_ready_t [RT_L1D_PORT_NUM-1:0]  rt_check_update_req_ready_i 
   ,input  logic          [RT_L1D_PORT_RESP_NUM-1:0]               rt_check_update_resp_valid_i
   ,input  rt_check_update_resp_t  [RT_L1D_PORT_RESP_NUM-1:0]      rt_check_update_resp_i

   ,input logic    [RT_L1D_PORT_NUM-1:0]                      rt_port_gen_check_valid_i
   `ifdef RT_MODE_CLASSIC
   ,output logic   [RT_L1D_PORT_NUM-1:0]                      rt_port_gen_check_ready_o
   ,input  logic   [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0]  rt_port_gen_check_id_i       
   `else
   ,input rt_check_gen_info_t [RT_L1D_PORT_NUM-1:0]           rt_port_gen_check_info_i
   `endif
   ,output logic                                              rt_err_resp_data_mismatch_o
   ,output logic                                              rt_err_ready_in_invalid_state_o
   ,output logic                                              rt_err_resp_in_invalid_state_o
   ,output logic                                              rt_err_resp_timeout_o
   ,output logic [RT_CHECK_TRANS_OK_CNT_W-1:0]                rt_stats_trans_ok_cnt_o
);

genvar pp;
genvar cc;
genvar ii;

logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0]                port_check_id;
`ifdef RT_MODE_CLASSIC                                         
logic [RT_L1D_PORT_NUM-1:0]                                    ldst_port_vld;
logic [RT_CHECK_NUM-1:0][RT_CHECK_ADDR_W-1:0]                  check_addr_q;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_data_q;
logic [RT_CHECK_NUM-1:0]                                       check_opcode_q;
logic [RT_CHECK_NUM-1:0][RT_CHECK_BYTE_COUNT_NUM_W-1:0]        check_byte_count_q;

logic [RT_CHECK_NUM-1:0][RT_CHECK_ADDR_W-1:0]                  check_addr_d;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_data_d;
logic [RT_CHECK_NUM-1:0]                                       check_opcode_d;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_port_update_resp_data;

logic [RT_CHECK_NUM-1:0][RT_L1D_PORT_RESP_NUM-1:0][RT_CHECK_DATA_W-1:0] check_port_update_resp_data_tmp;
logic [RT_CHECK_NUM-1:0][RT_CHECK_BYTE_COUNT_NUM_W-1:0]        check_byte_count_d;
logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_BYTE_COUNT_NUM_W-1:0]     port_check_gen_byte_count;

logic [RT_CHECK_NUM-1:0]                                       rt_err_resp_data_mismatch_ent;
logic                                                          rt_err_resp_data_mismatch_d;
logic                                                          rt_err_resp_data_mismatch_q;
logic [RT_CHECK_NUM-1:0]                                       check_last_resp;
`endif

check_state_e [RT_CHECK_NUM-1:0]                               check_state_q;
check_state_e [RT_CHECK_NUM-1:0]                               check_state_d;
logic [RT_CHECK_NUM-1:0][RT_CYCLE_CNT_W-1:0]                   check_req_cycle_q;
logic [RT_CHECK_NUM-1:0]                                       check_pending_q;
logic [RT_CHECK_NUM-1:0]                                       check_pending_d;
logic [RT_CHECK_NUM-1:0][RT_CYCLE_CNT_W-1:0]                   check_req_cycle_d;

logic [RT_CHECK_NUM-1:0]                                       check_pending_en;

logic [RT_CHECK_NUM-1:0]                                       check_update_req_ready_set;
logic [RT_CHECK_NUM-1:0][RT_L1D_PORT_NUM-1:0]                  check_port_update_req_ready;
logic [RT_CHECK_NUM-1:0]                                       check_update_resp_set;
logic [RT_CHECK_NUM-1:0][RT_L1D_PORT_RESP_NUM-1:0]             check_port_update_resp;
logic [RT_CHECK_NUM-1:0][RT_L1D_PORT_NUM-1:0]                  check_port_gen_valid;
logic [RT_CHECK_NUM-1:0]                                       check_port_gen_valid_set;

logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0]                port_check_vld_check_id;
logic [RT_L1D_PORT_NUM-1:0]                                    port_check_gen_vld;
logic [RT_CHECK_NUM-1:0]                                       check_trans_done;

logic [RT_CHECK_NUM-1:0]                                       rt_err_resp_in_invalid_state_ent;
logic                                                          rt_err_resp_in_invalid_state_d;
logic                                                          rt_err_resp_in_invalid_state_q;

logic [RT_CHECK_NUM-1:0]                                       rt_err_ready_in_invalid_state_ent;
logic                                                          rt_err_ready_in_invalid_state_d;
logic                                                          rt_err_ready_in_invalid_state_q;

logic [RT_CHECK_NUM-1:0]                                       check_update_req_cycle_en;

logic [RT_CHECK_NUM-1:0]                                       rt_err_resp_timeout_ent;
logic                                                          rt_err_resp_timeout_d;
logic                                                          rt_err_resp_timeout_q;

logic [RT_CHECK_TRANS_OK_CNT_W-1:0]                            rt_stats_trans_ok_cnt_ttl_d;
logic [RT_CHECK_TRANS_OK_CNT_W-1:0]                            rt_stats_trans_ok_cnt_ttl_q;

logic [RT_CYCLE_CNT_W-1:0]                                     rt_cycle_cnt_d;
logic [RT_CYCLE_CNT_W-1:0]                                     rt_cycle_cnt_q;

logic [RT_CHECK_NUM-1:0]                                       check_prev_resp;

`ifdef RT_DEBUG_SHOW_REQ_CORE
logic [RT_CHECK_NUM-1:0][RT_CORE_NUM_W-1:0]                    check_req_core_id_d;
logic [RT_CHECK_NUM-1:0][RT_CORE_NUM_W-1:0]                    check_req_core_id_q;
`endif 

`ifndef RT_MODE_CLASSIC
logic [RT_L1D_PORT_NUM-1:0][RT_CHECK_NUM_W-1:0]                port_select_check_id;
logic [RT_L1D_PORT_NUM-1:0]                                    port_select_check_id_vld;
logic [RT_L1D_PORT_NUM_W:0]                                    port_select_id;
logic [RT_CHECK_NUM-1:0]                                       check_sent_vld;

always_comb begin
    port_select_check_id_vld = '0;
    port_select_check_id = '0;
    port_select_id = '0;
    for(int i=0; i<RT_CHECK_NUM;i++) begin
        if (port_select_id<RT_L1D_PORT_NUM && check_sent_vld[i]) begin
            port_select_check_id_vld[port_select_id]  = 1'b1;
            port_select_check_id[port_select_id] = i[RT_CHECK_NUM_W-1:0];
            port_select_id = port_select_id + (RT_L1D_PORT_NUM_W+1)'(1);
        end
    end
end
`endif
assign rt_tid_get_valid_o = rt_check_gen_ready_i & port_check_gen_vld & rt_port_gen_check_valid_i;
assign rt_tid_get_check_id_o = port_check_vld_check_id;
assign rt_check_gen_valid_o = rt_tid_get_ready_i & rt_tid_get_valid_o;
assign rt_port_gen_check_ready_o = 1'b1;

generate
for(pp=0;pp<RT_L1D_PORT_NUM;pp++) begin
    assign port_check_vld_check_id[pp] = port_check_id[pp];
`ifdef RT_MODE_CLASSIC
    assign port_check_id[pp] = rt_port_gen_check_id_i[pp/RT_L1D_PORT_NUM_PER_CORE];
    assign ldst_port_vld[pp] = check_opcode_d[port_check_id[pp]] ^ (pp%RT_L1D_PORT_NUM_PER_CORE);
    assign port_check_gen_vld[pp] = (RT_ENABLE_MULTICORE | (pp<RT_L1D_PORT_NUM_PER_CORE)) &
                                 ldst_port_vld[pp] &
                                 (~check_pending_q[port_check_id[pp]] | check_update_req_ready_set[port_check_id[pp]]) &
                                 (check_state_d[port_check_id[pp]] == CHECK_STATE_IDLE | check_state_d[port_check_id[pp]] == CHECK_STATE_READY);
    assign port_check_gen_byte_count[pp] = check_byte_count_d[port_check_id[pp]];
    assign rt_check_gen_o[pp].addr = {RT_CHECK_ADDR_W{rt_check_gen_valid_o[pp]}} & (check_addr_d[port_check_id[pp]] + RT_CHECK_ADDR_W'(port_check_gen_byte_count[pp]));
    assign rt_check_gen_o[pp].data = {RT_CHECK_DATA_W{rt_check_gen_valid_o[pp]}} & ((check_data_d[port_check_id[pp]] >> (RT_CHECK_DATA_W'(port_check_gen_byte_count[pp]) << 3)) & RT_CHECK_DATA_W'(8'hff));
    assign rt_check_gen_o[pp].opcode = {$bits(lsu_op_e){rt_check_gen_valid_o[pp]}} & (check_opcode_d[port_check_id[pp]] ? LSU_LW : LSU_SB);
    assign rt_check_gen_o[pp].is_cacheable = ~RT_ENABLE_IO | (rt_check_gen_valid_o[pp] & check_addr_d[port_check_id[pp]][2]);
    assign rt_check_gen_o[pp].tid = {RT_TRANS_ID_NUM_W{rt_check_gen_valid_o[pp]}} & rt_tid_get_trans_id_i[pp];
`else
    assign port_check_id[pp] = port_select_check_id[pp];
    assign port_check_gen_vld[pp] = (RT_ENABLE_MULTICORE | (pp<RT_L1D_PORT_NUM_PER_CORE)) & port_select_check_id_vld[pp];
    assign rt_check_gen_o[pp].data= {RT_CHECK_DATA_W{rt_check_gen_valid_o[pp]}} & (((pp+1) * RT_CHECK_DATA_W'('h9876543210abcdef)) ^
                                    rt_port_gen_check_info_i[pp].addr ^ 
                                    {rt_cycle_cnt_q[31:0],16'(rt_port_gen_check_info_i[pp].opcode), 16'b0});
    assign rt_check_gen_o[pp].addr = {RT_CHECK_ADDR_W{rt_check_gen_valid_o[pp]}} & (rt_port_gen_check_info_i[pp].addr);
    assign rt_check_gen_o[pp].opcode = {$bits(lsu_op_e){rt_check_gen_valid_o[pp]}} & (rt_port_gen_check_info_i[pp].opcode);
    assign rt_check_gen_o[pp].is_cacheable = rt_port_gen_check_info_i[pp].is_cacheable;
    assign rt_check_gen_o[pp].tid = {RT_TRANS_ID_NUM_W{rt_check_gen_valid_o[pp]}} & rt_tid_get_trans_id_i[pp];
`endif
end
for(cc=0;cc<RT_CHECK_NUM;cc++) begin
    for(pp=0;pp<RT_L1D_PORT_NUM;pp++) begin
        assign check_port_update_req_ready[cc][pp] = rt_check_update_req_ready_valid_i[pp] &(rt_check_update_req_ready_i[pp].check_id == cc);
        assign check_port_gen_valid[cc][pp] = rt_check_gen_valid_o[pp] & (port_check_id[pp] == cc);
    end

    for(pp=0;pp<RT_L1D_PORT_RESP_NUM;pp++) begin
        assign check_port_update_resp[cc][pp] = rt_check_update_resp_valid_i[pp] & (rt_check_update_resp_i[pp].check_id == cc);
`ifdef  RT_MODE_CLASSIC
        if(pp == 0) begin
            assign check_port_update_resp_data_tmp[cc][pp] = {RT_CHECK_DATA_W{check_port_update_resp[cc][pp]}} & rt_check_update_resp_i[pp].data;
        end else begin
            assign check_port_update_resp_data_tmp[cc][pp] = check_port_update_resp_data_tmp[cc][pp-1] | ({RT_CHECK_DATA_W{check_port_update_resp[cc][pp]}} & rt_check_update_resp_i[pp].data);
        end
`endif 
    end

`ifdef RT_DEBUG_SHOW_REQ_CORE
    always_comb begin
        check_req_core_id_d[cc] = '0;
        for(int i=0;i<RT_L1D_PORT_NUM;i++) begin
            if(check_port_gen_valid[cc][i]) begin
                check_req_core_id_d[cc] = i/RT_L1D_PORT_NUM_PER_CORE;
            end
        end
    end
`endif

  assign check_update_req_ready_set[cc] = |check_port_update_req_ready[cc];
  assign check_update_resp_set[cc] = |check_port_update_resp[cc];
  assign check_port_gen_valid_set[cc] = |check_port_gen_valid[cc];
  assign check_update_req_cycle_en[cc] = check_update_resp_set[cc] | check_port_gen_valid_set[cc];

  assign check_pending_en[cc] = check_update_req_ready_set[cc] | check_port_gen_valid_set[cc];
  assign check_pending_d[cc] = ~check_update_req_ready_set[cc] | check_port_gen_valid_set[cc];
  assign check_req_cycle_d[cc] = {RT_CYCLE_CNT_W{check_port_gen_valid_set[cc]}} & rt_cycle_cnt_d;
  assign rt_err_resp_timeout_ent[cc] = (check_req_cycle_q[cc] != '0) && ((check_req_cycle_q[cc] + RT_RESP_TIMEOUT_CYCLE_CNT_W) < rt_cycle_cnt_d);

  assign check_prev_resp[cc] = (check_state_q[cc] == CHECK_STATE_IDLE && check_update_req_ready_set[cc] && check_update_resp_set[cc]) || (check_state_q[cc] == CHECK_STATE_ACTION_PENDING && check_update_resp_set[cc]);

`ifdef RT_MODE_CLASSIC
  assign check_last_resp[cc] = (check_state_q[cc] == CHECK_STATE_READY && check_update_req_ready_set[cc] && check_update_resp_set[cc]) || (check_state_q[cc] == CHECK_STATE_CHECK_PENDING && check_update_resp_set[cc]);

  assign check_port_update_resp_data[cc] = check_port_update_resp_data_tmp[cc][RT_L1D_PORT_NUM-1];
  // check FSM
  always_comb begin
        check_state_d[cc] = check_state_q[cc];
        check_byte_count_d[cc] = check_byte_count_q[cc];
        check_opcode_d[cc] = check_opcode_q[cc];
        check_addr_d[cc] = check_addr_q[cc];
        check_data_d[cc] = check_data_q[cc];
        check_trans_done[cc] = '0;
        rt_err_ready_in_invalid_state_ent[cc] = '0;
        rt_err_resp_in_invalid_state_ent[cc] = '0;
        rt_err_resp_data_mismatch_ent[cc] = '0;
    
        if (check_prev_resp[cc]) begin//收到
            check_byte_count_d[cc] = check_byte_count_q[cc] + 1;
            if(check_byte_count_q[cc] < (RT_CHECK_BYTE_COUNT_NUM-1)) begin//4 byte 还没发完
                check_state_d[cc] = CHECK_STATE_IDLE;
            end else begin//4 byte 发完了
                check_state_d[cc] = CHECK_STATE_READY;
                check_opcode_d[cc] = 1'b1;
            end
        end else if (check_last_resp[cc]) begin//收到对方
            check_state_d[cc] = CHECK_STATE_IDLE;
            check_opcode_d[cc] = '0;
            check_byte_count_d[cc] = '0;
            check_addr_d[cc] = check_addr_q[cc] + RT_CHECK_ADDR_DELTA - ((check_addr_q[cc] < RT_CHECK_ADDR_END_DELTA) ? 0 : RT_MEM_SIZE);
            check_data_d[cc] = check_data_q[cc] + 32'h12345678;
            rt_err_resp_data_mismatch_ent[cc] = (check_data_q[cc][0+:RT_CHECK_DATA_CLASSIC_W] != check_port_update_resp_data[cc][0+:RT_CHECK_DATA_CLASSIC_W]);
            check_trans_done[cc] = 1'b1;
        end else if (check_update_req_ready_set[cc])  begin//收到对方的ready
            if (check_state_q[cc] == CHECK_STATE_IDLE) begin
                check_state_d[cc] = CHECK_STATE_ACTION_PENDING;
            end else if (check_state_q[cc] == CHECK_STATE_READY) begin
                check_state_d[cc] = CHECK_STATE_CHECK_PENDING;
            end else begin
                rt_err_ready_in_invalid_state_ent[cc] = 1'b1;
            end
        end else if (check_update_resp_set[cc]) begin
            rt_err_resp_in_invalid_state_ent[cc] = 1'b1;
        end
    end
`else
    assign check_sent_vld[cc] = (~check_pending_q[cc] | check_update_req_ready_set[cc]) & (check_state_d[cc] == CHECK_STATE_IDLE | check_state_d[cc] == CHECK_STATE_READY);
    always_comb begin
        check_state_d[cc] = check_state_q[cc];
        check_trans_done[cc] = '0;
        rt_err_ready_in_invalid_state_ent[cc] = '0;
        rt_err_resp_in_invalid_state_ent[cc] = '0;

        if (check_prev_resp[cc]) begin
            check_state_d[cc] = CHECK_STATE_IDLE;
            check_trans_done[cc] = 1'b1;
        end else if (check_update_req_ready_set[cc]) begin
            if (check_state_q[cc] == CHECK_STATE_IDLE) begin
                check_state_d[cc] = CHECK_STATE_ACTION_PENDING;
            end else begin
                rt_err_ready_in_invalid_state_ent[cc] = 1'b1;
            end
        end else if (check_update_resp_set[cc]) begin
            rt_err_resp_in_invalid_state_ent[cc] = 1'b1;
        end
    end
`endif
//save check elements
//configure initial addr and data
`ifdef RT_MODE_CLASSIC 
    std_dffrve #(RT_CHECK_ADDR_W) FF_ENT_ADDR (.clk(clk) ,.rstn(rst_n),.rst_val(RT_CHECK_ADDR_W'(cc*4+RT_CHECK_ADDR_BASE)) ,.en(1'b1),.d(check_addr_d[cc]),.q(check_addr_q[cc]));
    std_dffrve #(RT_CHECK_DATA_W) FF_ENT_DATA (.clk(clk) ,.rstn(rst_n),.rst_val(RT_CHECK_DATA_W'(cc*19820611+RT_CHECK_DATA_BASE)),.en(1'b1),.d(check_data_d[cc]),.q(check_data_q[cc]));
    std_dffr #(1) FF_ENT_OPCODE               (.clk(clk) ,.rstn(rst_n),.d(check_opcode_d[cc]),.q(check_opcode_q[cc]));
    std_dffr #(RT_CHECK_BYTE_COUNT_NUM_W) FF_ENT_BYTE_COUNT (.clk(clk) ,.rstn(rst_n) ,.d(check_byte_count_d[cc]),.q(check_byte_count_q[cc]));
`endif 
    std_dffrve #($bits(check_state_e)) FF_ENT_STATE (.clk(clk),.rstn(rst_n),.rst_val(CHECK_STATE_IDLE),.en(1'b1),.d(check_state_d[cc]),.q(check_state_q[cc]));
    std_dffre  #(RT_CYCLE_CNT_W) FF_REQ_CYCLE       (.clk(clk),.rstn(rst_n),.en(check_update_req_cycle_en[cc]),.d(check_req_cycle_d[cc]),.q(check_req_cycle_q[cc]));
    std_dffre  #(1) FF_ENT_PENDING                  (.clk(clk),.rstn(rst_n),.en(check_pending_en[cc]),.d(check_pending_d[cc]),.q(check_pending_q[cc]));
`ifdef RT_DEBUG_SHOW_REQ_CORE
    std_dffre  #(RT_CORE_NUM_W) FF_REQ_CORE_ID      (.clk(clk),.rstn(rst_n),.en(check_update_req_cycle_en[cc]),.d(check_req_core_id_d[cc]),.q(check_req_core_id_q[cc]));
`endif
end
endgenerate

always_comb begin
    rt_stats_trans_ok_cnt_ttl_d = '0;
    for(int i = 0; i < RT_CHECK_NUM; i++) begin
`ifdef RT_MODE_CLASSIC
        rt_stats_trans_ok_cnt_ttl_d = rt_stats_trans_ok_cnt_ttl_d + (RT_CHECK_TRANS_OK_CNT_W)'(~rt_err_resp_data_mismatch_ent[i] & check_trans_done[i]);
`else
        rt_stats_trans_ok_cnt_ttl_d = rt_stats_trans_ok_cnt_ttl_d + (RT_CHECK_TRANS_OK_CNT_W)'(check_trans_done[i]);
`endif
    end
    rt_stats_trans_ok_cnt_ttl_d = rt_stats_trans_ok_cnt_ttl_d + rt_stats_trans_ok_cnt_ttl_q;
end
// rt_err handler
assign rt_err_ready_in_invalid_state_d = |rt_err_ready_in_invalid_state_ent;
assign rt_err_resp_in_invalid_state_d = |rt_err_resp_in_invalid_state_ent;
assign rt_err_resp_timeout_d = |rt_err_resp_timeout_ent;

// show the 1st mismatch
std_dffre #(1) FF_ERR_RSPTO  (.clk(clk),.rstn(rst_n),.en(rt_err_resp_timeout_d),.d(rt_err_resp_timeout_d),.q(rt_err_resp_timeout_q));
std_dffre #(1) FF_ERR_RDYIIS (.clk(clk),.rstn(rst_n),.en(rt_err_ready_in_invalid_state_d),.d(rt_err_ready_in_invalid_state_d),.q(rt_err_ready_in_invalid_state_q));
std_dffre #(1) FF_ERR_RSPIIS (.clk(clk),.rstn(rst_n),.en(rt_err_resp_in_invalid_state_d),.d(rt_err_resp_in_invalid_state_d),.q(rt_err_resp_in_invalid_state_q));
std_dffr  #(RT_CHECK_TRANS_OK_CNT_W) FF_TTL_TOK_CNT (.clk(clk),.rstn(rst_n),.d(rt_stats_trans_ok_cnt_ttl_d),.q(rt_stats_trans_ok_cnt_ttl_q));

assign rt_cycle_cnt_d = rt_cycle_cnt_q + RT_CYCLE_CNT_W'(1);
std_dffr #(RT_CYCLE_CNT_W) FF_CYCLE_CNT (.clk(clk),.rstn(rst_n),.d(rt_cycle_cnt_d),.q(rt_cycle_cnt_q));

`ifdef RT_MODE_CLASSIC
assign rt_err_resp_data_mismatch_d = |rt_err_resp_data_mismatch_ent;
std_dffre #(1) FF_ERR_RDM (.clk(clk),.rstn(rst_n),.en(rt_err_resp_data_mismatch_d),.d(rt_err_resp_data_mismatch_d),.q(rt_err_resp_data_mismatch_q));
assign rt_err_resp_data_mismatch_o = rt_err_resp_data_mismatch_q;
`else
assign rt_err_resp_data_mismatch_o = '0;
`endif
assign rt_err_ready_in_invalid_state_o = rt_err_ready_in_invalid_state_q;
assign rt_err_resp_in_invalid_state_o = rt_err_resp_in_invalid_state_q;
assign rt_err_resp_timeout_o = rt_err_resp_timeout_q;
assign rt_stats_trans_ok_cnt_o = rt_stats_trans_ok_cnt_ttl_q;
endmodule


//rubytest_trans_control
module rubytest_trans_control
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
#(
    parameter RESP_NUM = 1
)
(
 input logic           clk
,input logic           rst_n
,output logic          rt_l1d_req_valid_o
,output rrv64_lsu_l1d_req_t rt_l1d_req_o
,input  logic          rt_l1d_req_ready_i
,input  logic   [RESP_NUM-1:0]       rt_l1d_resp_valid_i
,input  rrv64_lsu_l1d_resp_t [RESP_NUM-1:0] rt_l1d_resp_i

,input logic           rt_check_gen_valid_i
,input rt_check_gen_t  rt_check_gen_i
,output logic          rt_check_gen_ready_o

,output logic        rt_check_update_req_ready_valid_o
,output rt_check_update_req_ready_t rt_check_update_req_ready_o
,output logic [RESP_NUM-1:0] rt_check_update_resp_valid_o
,output rt_check_update_resp_t [RESP_NUM-1:0] rt_check_update_resp_o


,output logic                         rt_tid_poll_valid_o
,output logic [RT_TRANS_ID_NUM_W-1:0] rt_tid_poll_trans_id_o
,input  logic [RT_CHECK_NUM_W-1:0]    rt_tid_poll_check_id_i
,input  logic                         rt_tid_poll_ready_i

,output logic [RESP_NUM-1:0]          rt_tid_put_valid_o
,output logic [RESP_NUM-1:0][RT_TRANS_ID_NUM_W-1:0] rt_tid_put_trans_id_o
,input  logic [RESP_NUM-1:0][RT_CHECK_NUM_W-1:0]    rt_tid_put_check_id_i
,input  logic [RESP_NUM-1:0]                        rt_tid_put_ready_i

);

logic [RT_TRANS_ID_NUM_W-1:0]    port_pld_trans_id;
logic port_l1d_req_valid_d;
logic port_l1d_req_valid_q;
rrv64_lsu_l1d_req_t port_l1d_req_d;
rrv64_lsu_l1d_req_t port_l1d_req_q;

assign rt_check_gen_ready_o = rt_l1d_req_ready_i;
assign port_l1d_req_valid_d = rt_check_gen_valid_i;
assign rt_l1d_req_valid_o = port_l1d_req_valid_q;
assign rt_l1d_req_o = port_l1d_req_q;
always_comb begin
    port_l1d_req_d = '0;
    port_l1d_req_d.is_cacheable = rt_check_gen_i.is_cacheable;
    port_l1d_req_d.paddr = RT_CHECK_SYS_ADDR_W'(rt_check_gen_i.addr);
    port_l1d_req_d.req_type = rt_check_gen_i.opcode;
    port_l1d_req_d.st_dat = RT_CHECK_SYS_DATA_W'(rt_check_gen_i.data);
    port_l1d_req_d.lsu_id = rt_check_gen_i.tid;
end
assign port_pld_trans_id  = port_l1d_req_q.lsu_id;

std_dffre #(1) FF_PORT_L1D_REQ_VLD (.clk(clk),.rstn(rst_n),.en(rt_l1d_req_ready_i),.d(port_l1d_req_valid_d),.q(port_l1d_req_valid_q));
std_dffre #($bits(rrv64_lsu_l1d_req_t)) FF_PORT_L1D_REQ (.clk(clk),.rstn(rst_n),.en(rt_l1d_req_ready_i),.d(port_l1d_req_d),.q(port_l1d_req_q));

assign rt_tid_poll_valid_o = port_l1d_req_valid_q & rt_l1d_req_ready_i;

assign rt_tid_poll_trans_id_o = {RT_TRANS_ID_NUM_W{rt_tid_poll_valid_o}} & port_pld_trans_id;

assign rt_check_update_req_ready_valid_o = rt_tid_poll_ready_i & rt_tid_poll_valid_o;
assign rt_check_update_req_ready_o.check_id = {RT_CHECK_NUM_W{rt_check_update_req_ready_valid_o}} & rt_tid_poll_check_id_i;

assign rt_tid_put_valid_o = rt_l1d_resp_valid_i;
assign rt_check_update_resp_valid_o = rt_tid_put_ready_i & rt_tid_put_valid_o;

generate
for(genvar ii=0; ii<RESP_NUM; ii++) begin
    assign rt_tid_put_trans_id_o[ii] = {RT_TRANS_ID_NUM_W{rt_l1d_resp_valid_i[ii]}} & rt_l1d_resp_i[ii].lsu_id;
    assign rt_check_update_resp_o[ii].check_id = {RT_CHECK_NUM_W{rt_check_update_resp_valid_o[ii]}} & rt_tid_put_check_id_i[ii];
    assign rt_check_update_resp_o[ii].data = {RT_CHECK_DATA_W{rt_check_update_resp_valid_o[ii]}} & rt_l1d_resp_i[ii].ld_data[RT_CHECK_DATA_W-1:0];
end
endgenerate
endmodule

//per core
module rubytest_trans_id_pool
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
#(
    parameter TID_PUT_NUM = 1
)
(
    input logic              clk
   ,input logic              rst_n
   //get trans id by check id. and create their mapping
   ,input logic              rt_tid_get_valid_i
   ,input logic [RT_CHECK_NUM_W-1:0] rt_tid_get_check_id_i
   ,output logic [RT_TRANS_ID_NUM_W-1:0] rt_tid_get_trans_id_o
   ,output logic rt_tid_get_ready_o
   //get check id
   ,input logic                       rt_tid_poll_valid_i
   ,input logic [RT_TRANS_ID_NUM-1:0] rt_tid_poll_trans_id_i
   ,output logic [RT_CHECK_NUM_W-1:0] rt_tid_poll_check_id_o
   ,output logic                      rt_tid_poll_ready_o

   //remove mapping
   ,input logic [TID_PUT_NUM - 1 : 0] rt_tid_put_valid_i
   ,input logic [TID_PUT_NUM - 1 : 0][RT_TRANS_ID_NUM_W-1:0] rt_tid_put_trans_id_i
   ,output logic [TID_PUT_NUM - 1 : 0][RT_CHECK_NUM_W-1:0] rt_tid_put_check_id_o
   ,output logic [TID_PUT_NUM - 1 : 0] rt_tid_put_ready_o

   ,output logic                       rt_err_poll_by_invalid_trans_id_o
   ,output logic                       rt_err_put_by_invalid_trans_id_o
);

genvar ii;
genvar pp;
logic [RT_TRANS_ID_NUM-1:0] get_map_vld;
logic [RT_TRANS_ID_NUM-1:0][TID_PUT_NUM-1:0] put_map_vld_set;
logic [RT_TRANS_ID_NUM-1:0] put_map_vld;

logic [RT_TRANS_ID_NUM-1:0] tid_check_vld_en;
logic [RT_TRANS_ID_NUM-1:0] tid_check_vld_d;
logic [RT_TRANS_ID_NUM-1:0][RT_CHECK_NUM_W-1:0] tid_check_id_d;
logic [RT_TRANS_ID_NUM-1:0] tid_check_vld_q;
logic [RT_TRANS_ID_NUM-1:0][RT_CHECK_NUM_W-1:0] tid_check_id_q;

logic tid_pool_get_vld;
logic tid_pool_get_grt;
logic [RT_TRANS_ID_NUM_W-1:0] tid_pool_get_trans_id;
logic [TID_PUT_NUM -1:0]      tid_pool_put_vld;
logic [TID_PUT_NUM -1:0]      tid_pool_put_grt;
logic [TID_PUT_NUM -1:0][RT_TRANS_ID_NUM_W-1:0] tid_pool_put_trans_id;  

logic [TID_PUT_NUM -1:0]      port_tid_put_poll_ready;
logic [TID_PUT_NUM -1:0]      rt_err_put_by_invalid_trans_id_set;
logic [RT_TRANS_ID_NUM_W:0]   tid_pool_avail_tid_num;

// rt_err handler
assign rt_err_poll_by_invalid_trans_id_o = ~rt_tid_poll_ready_o & rt_tid_poll_valid_i;
assign rt_err_put_by_invalid_trans_id_set = ~port_tid_put_poll_ready & rt_tid_put_valid_i & tid_pool_put_vld;
assign rt_err_put_by_invalid_trans_id_o = |rt_err_put_by_invalid_trans_id_set;
assign rt_tid_get_ready_o = tid_pool_get_grt & tid_pool_get_vld;
assign rt_tid_put_ready_o = tid_pool_put_grt & tid_pool_put_vld & port_tid_put_poll_ready;
assign tid_pool_get_grt = rt_tid_get_valid_i;
assign tid_pool_put_grt = rt_tid_put_valid_i;
assign rt_tid_get_trans_id_o = {RT_TRANS_ID_NUM_W{rt_tid_get_ready_o}} & tid_pool_get_trans_id;

assign rt_tid_poll_check_id_o = tid_check_id_q[rt_tid_poll_trans_id_i] & {RT_CHECK_NUM_W{rt_tid_poll_valid_i & rt_tid_poll_ready_o}};
assign rt_tid_poll_ready_o = tid_check_vld_q[rt_tid_poll_trans_id_i];

id_pool_2w1r
#(
    .width (RT_TRANS_ID_NUM_W),
    .depth (RT_TRANS_ID_NUM)
)
trans_id_pool
(
    .clk (clk),
    .rst_n (rst_n),
    .c_srdy (tid_pool_put_grt),
    .c_drdy (tid_pool_put_vld),
    .c_data (tid_pool_put_trans_id),
    .p_srdy (tid_pool_get_vld),
    .p_drdy (tid_pool_get_grt),
    .p_data (tid_pool_get_trans_id),
    .usage  (tid_pool_avail_tid_num)
);

generate
for(ii=0;ii<TID_PUT_NUM;ii++) begin
    assign tid_pool_put_trans_id[ii] = rt_tid_put_trans_id_i[ii];
    assign rt_tid_put_check_id_o[ii] = tid_check_id_q[tid_pool_put_trans_id[ii]] & {RT_CHECK_NUM_W{rt_tid_put_ready_o[ii]}};
    assign port_tid_put_poll_ready[ii] = tid_check_vld_q[tid_pool_put_trans_id[ii]];
end
endgenerate

generate
for(ii=0;ii<RT_TRANS_ID_NUM;ii++) begin
assign get_map_vld[ii] = rt_tid_get_ready_o & (rt_tid_get_trans_id_o == ii);
assign put_map_vld[ii] = |put_map_vld_set[ii];

for(genvar jj=0;jj<TID_PUT_NUM;jj++) begin
    assign put_map_vld_set[ii][jj] = rt_tid_put_ready_o[jj] & (rt_tid_put_trans_id_i[jj] == ii);
end

assign tid_check_id_d[ii] = get_map_vld[ii] ? ({RT_CHECK_NUM_W{get_map_vld[ii]}} & rt_tid_get_check_id_i) : tid_check_id_q[ii];

assign tid_check_vld_en[ii] = get_map_vld[ii] | put_map_vld[ii];
assign tid_check_vld_d[ii]  = get_map_vld[ii] & ~put_map_vld[ii];

std_dffre #(1) FF_MAP_VLD (.clk(clk),.rstn(rst_n),.en(tid_check_vld_en[ii]),.d(tid_check_vld_d[ii]),.q(tid_check_vld_q[ii]));
std_dffr #(RT_CHECK_NUM_W) FF_MAP_CHECK_ID (.clk(clk),.rstn(rst_n),.d(tid_check_id_d[ii]),.q(tid_check_id_q[ii]));
end
endgenerate
endmodule





