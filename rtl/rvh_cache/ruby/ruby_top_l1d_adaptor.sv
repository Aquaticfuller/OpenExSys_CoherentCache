import rrv64_top_macro_pkg::*;
import rrv64_top_param_pkg::*;
import rrv64_top_typedef_pkg::*;
import rrv64_core_param_pkg::*;
import rrv64_core_typedef_pkg::*;
import rrv64_uncore_param_pkg::*;
import rrv64_uncore_typedef_pkg::*;

// `define ST_HSK_DELAY_EN // delay store req hsk for servel cycles to give stb flush the entry into cache

`ifdef ST_HSK_DELAY_EN
parameter ST_HSK_LATENCY = 6;
`endif

parameter LDQ_ID_NUM = 32;
parameter LDQ_ID_NUM_W = $clog2(LDQ_ID_NUM);
parameter MSHR_ID_NUM = RRV64_L1D_MSHR_D;
parameter MSHR_ID_NUM_W = $clog2(RRV64_L1D_MSHR_D);
parameter LDQ_LD_CNT_W = 32;

//RRV64_ROB_ADDR_W
parameter LDQ_STATE_W = 3;
parameter LDQ_LSU_ID_W = 5;
parameter LDQ_PORT_NUM = 2;

typedef enum logic[LDQ_STATE_W-1:0] { 
    INIT_LDQ_STATE = 3'd0,
    PENDING_LDQ_STATE = 3'd1,
    SENT_LDQ_STATE = 3'd2,
    NORDY_SENT_LDQ_STATE = 3'd3,
    IDMISS_LDQ_STATE = 3'd4,
    FULLMISS_LDQ_STATE = 3'd5
}ldq_state_e;

module rubytop_l1d_adaptor
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;
(
 input  logic clk
,input  logic rst_n
,input  logic                 [LDQ_PORT_NUM-1:0] top_l1d_req_valid_i
,input  rrv64_lsu_l1d_req_t   [LDQ_PORT_NUM-1:0] top_l1d_req_i
,output logic                 [LDQ_PORT_NUM-1:0] top_l1d_req_ready_o
,output logic                 [LDQ_PORT_NUM-1:0] top_l1d_resp_valid_o
,output rrv64_lsu_l1d_resp_t  [LDQ_PORT_NUM-1:0] top_l1d_resp_o
,input  logic                 [LDQ_PORT_NUM-1:0] top_l1d_resp_ready_i

,output logic                                    ld_l1d_req_valid_o
,output rrv64_lsu_l1d_req_t                      ld_l1d_req_o
,input  logic                                    ld_l1d_req_ready_i
,input  logic                                    ld_l1d_resp_valid_i
,input  rrv64_lsu_l1d_resp_t                     ld_l1d_resp_i

,output logic                                    st_l1d_req_valid_o
,output rrv64_lsu_l1d_req_t                      st_l1d_req_o
,input  logic                                    st_l1d_req_ready_i
,input  logic                                    st_l1d_resp_valid_i
,input  rrv64_lsu_l1d_resp_t                     st_l1d_resp_i

// load miss signals
// used for mshr full
,input logic                                     l1d_lsu_sleep_valid_i
,input logic[LDQ_ID_NUM_W-1:0]                   l1d_lsu_sleep_ldq_id_i
,input logic                                     l1d_lsu_sleep_cache_miss_i
,input logic[MSHR_ID_NUM_W-1:0]                  l1d_lsu_sleep_mshr_id_i
,input logic                                     l1d_lsu_sleep_mshr_full_i
,input logic                                     l1d_lsu_wakeup_cache_refill_valid_i
,input logic[MSHR_ID_NUM_W-1:0]                  l1d_lsu_wakeup_mshr_id_i
,input logic                                     l1d_lsu_wakeup_mshr_avail_i
);

genvar ii;

// assume LDQ_PORT_NUM = 2 & port0 is for ldq while port1 is for stq.
logic has_state_pending;
logic has_state_init;
logic has_state_sent;
logic has_state_sent_no_change;
logic has_state_sent_no_ready;
logic [LDQ_ID_NUM_W-1:0] ldq_sent_nordy_id;
logic [LDQ_ID_NUM_W-1:0] ldq_init_id;
logic [LDQ_ID_NUM_W-1:0] ldq_oldest_pending_id;
logic [LDQ_LD_CNT_W-1:0] ld_count_var;
logic [LDQ_LD_CNT_W-1:0] ldq_gbl_ld_cnt_d;
logic [LDQ_LD_CNT_W-1:0] ldq_gbl_ld_cnt_q;
 
ldq_state_e [LDQ_ID_NUM-1:0] ldq_state_d;
ldq_state_e [LDQ_ID_NUM-1:0] ldq_state_q;
logic [LDQ_ID_NUM-1:0][LDQ_LD_CNT_W-1:0] ldq_ld_count_set;
logic [LDQ_ID_NUM-1:0][LDQ_LD_CNT_W-1:0] ldq_ld_count_d;
logic [LDQ_ID_NUM-1:0][LDQ_LD_CNT_W-1:0] ldq_ld_count_q;
logic [LDQ_ID_NUM-1:0][MSHR_ID_NUM_W-1:0] ldq_mshr_id_d;
logic [LDQ_ID_NUM-1:0][MSHR_ID_NUM_W-1:0] ldq_mshr_id_q;
logic [LDQ_ID_NUM-1:0][LDQ_LSU_ID_W-1:0] ldq_req_lsu_id_d;
logic [LDQ_ID_NUM-1:0][LDQ_LSU_ID_W-1:0] ldq_req_lsu_id_q;
logic [LDQ_ID_NUM-1:0][$bits(rrv64_l1d_addr_t)-1:0] ldq_req_addr_d;
logic [LDQ_ID_NUM-1:0][$bits(rrv64_l1d_addr_t)-1:0] ldq_req_addr_q;
logic [LDQ_ID_NUM-1:0][$bits(lsu_op_e)-1:0] ldq_req_type_d;
logic [LDQ_ID_NUM-1:0][$bits(lsu_op_e)-1:0] ldq_req_type_q;
logic [LDQ_ID_NUM-1:0] ldq_req_cacheable_d;
logic [LDQ_ID_NUM-1:0] ldq_req_cacheable_q;
logic [LDQ_ID_NUM-1:0] ldq_resp_set;
logic [LDQ_ID_NUM-1:0] ldq_sleep_set;
logic [LDQ_ID_NUM-1:0] ldq_sent_change_init_set;

//store : pass through
assign st_l1d_req_valid_o = top_l1d_req_valid_i[1];
assign st_l1d_req_o = top_l1d_req_i[1];
assign top_l1d_req_ready_o[1] = st_l1d_req_ready_i;

`ifdef ST_HSK_DELAY_EN
logic                [ST_HSK_LATENCY-1:0]  st_l1d_resp_valid_delay;
rrv64_lsu_l1d_resp_t [ST_HSK_LATENCY-1:0]  st_l1d_resp_delay;

always @(posedge clk or negedge rst_n) begin
  for(int i = 1; i < ST_HSK_LATENCY; i++) begin
     if(~rst_n) begin
      st_l1d_resp_valid_delay[i]    <= '0;
      st_l1d_resp_delay[i]          <= '0;
     end else begin
      st_l1d_resp_valid_delay [i]   <= st_l1d_resp_valid_delay[i-1];
      st_l1d_resp_delay       [i]   <= st_l1d_resp_delay      [i-1];
     end
  end
end
assign st_l1d_resp_valid_delay  [0] = st_l1d_resp_valid_i;
assign st_l1d_resp_delay        [0] = st_l1d_resp_i;
assign top_l1d_resp_valid_o [1] = st_l1d_resp_valid_delay [ST_HSK_LATENCY-1];
assign top_l1d_resp_o       [1] = st_l1d_resp_delay       [ST_HSK_LATENCY-1];

`else
assign top_l1d_resp_valid_o[1] = st_l1d_resp_valid_i;
assign top_l1d_resp_o[1] = st_l1d_resp_i;
`endif

//load :
assign top_l1d_req_ready_o[0] = has_state_init;
assign top_l1d_resp_o[0] = ld_l1d_resp_i;
assign top_l1d_resp_valid_o[0] = ld_l1d_resp_valid_i;

assign ld_l1d_req_valid_o = top_l1d_req_valid_i[0] | has_state_pending | has_state_sent_no_ready;
always_comb begin
    ld_l1d_req_o = '0;
    ld_l1d_req_o.lsu_id = top_l1d_req_i[0].lsu_id;
    ld_l1d_req_o.paddr = top_l1d_req_i[0].paddr;
    ld_l1d_req_o.req_type = top_l1d_req_i[0].req_type;
    ld_l1d_req_o.is_cacheable = top_l1d_req_i[0].is_cacheable;
    if (has_state_pending) begin
        ld_l1d_req_o.lsu_id = ldq_req_lsu_id_q[ldq_oldest_pending_id];
        ld_l1d_req_o.paddr = ldq_req_addr_q[ldq_oldest_pending_id];
        ld_l1d_req_o.req_type = ldq_req_type_q[ldq_oldest_pending_id];
        ld_l1d_req_o.is_cacheable = ldq_req_cacheable_q[ldq_oldest_pending_id];
    end
        if(has_state_sent_no_ready) begin
            ld_l1d_req_o.lsu_id = ldq_req_lsu_id_q[ldq_sent_nordy_id];
            ld_l1d_req_o.paddr  = ldq_req_addr_q[ldq_sent_nordy_id];
            ld_l1d_req_o.req_type = ldq_req_type_q[ldq_sent_nordy_id];
            ld_l1d_req_o.is_cacheable = ldq_req_cacheable_q[ldq_sent_nordy_id];
        end
end

always_comb begin
    has_state_sent_no_ready = '0;
    ldq_sent_nordy_id = '0;

    for (int i = 0; i < LDQ_ID_NUM ;i++) begin
        if (ldq_state_q[i] == NORDY_SENT_LDQ_STATE && has_state_sent_no_ready == '0) begin
            has_state_sent_no_ready = 1'b1;
            ldq_sent_nordy_id = i[LDQ_ID_NUM_W-1:0];
        end
    end
end

always_comb begin

    has_state_init = '0;
    ldq_init_id = '0;

    for(int i = 0; i < LDQ_ID_NUM;i++) begin
        if(has_state_init == '0 && ldq_state_q[i] == INIT_LDQ_STATE) begin
            has_state_init = 1'b1;
            ldq_init_id = i[LDQ_ID_NUM_W-1:0];
        end
    end
end

always_comb begin
    has_state_pending = '0;
    ldq_oldest_pending_id = '0;
    ld_count_var = '0;

    for(int i =0; i < LDQ_ID_NUM; i++) begin
        if(ldq_state_q[i] == PENDING_LDQ_STATE) begin
            if(ldq_ld_count_q[i] < ld_count_var) begin
                ldq_oldest_pending_id = i[LDQ_ID_NUM_W-1:0];
                ld_count_var = ldq_ld_count_q[i];
            end
            if (has_state_pending == '0) begin
                has_state_pending = 1'b1;
                ldq_oldest_pending_id = i[LDQ_ID_NUM_W-1:0];
                ld_count_var = ldq_ld_count_q[i];
            end
        end
    end
end
assign ldq_gbl_ld_cnt_d = (ldq_ld_count_set[ldq_init_id] == '0) ? ldq_gbl_ld_cnt_q : ldq_ld_count_set[ldq_init_id];
std_dffr #(LDQ_LD_CNT_W) FF_LDQ_GBL_LD_CNT (.clk(clk),.rstn(rst_n),.d(ldq_gbl_ld_cnt_d),.q(ldq_gbl_ld_cnt_q));

generate
for(ii=0;ii<LDQ_ID_NUM;ii++) begin : GEN_LDQ_ENTRY
assign ldq_resp_set[ii] = ld_l1d_resp_valid_i & (ld_l1d_resp_i.lsu_id == ldq_req_lsu_id_q[ii]) & ~(LSU_LRW <= ld_l1d_resp_i.req_type & ld_l1d_resp_i.req_type <= LSU_AMOMINUD);
assign ldq_sleep_set[ii] = l1d_lsu_sleep_valid_i & (l1d_lsu_sleep_ldq_id_i == ldq_req_lsu_id_q[ii]);
assign ldq_sent_change_init_set[ii] = (ldq_state_q[ii] == SENT_LDQ_STATE) & ldq_resp_set[ii];


always_comb begin
    ldq_ld_count_set[ii] = '0;
    ldq_state_d[ii] = ldq_state_q[ii];
    ldq_ld_count_d[ii] = ldq_ld_count_q[ii];
    ldq_mshr_id_d[ii] = ldq_mshr_id_q[ii];
    ldq_req_addr_d[ii] = ldq_req_addr_q[ii];
    ldq_req_lsu_id_d[ii] = ldq_req_lsu_id_q[ii];
    ldq_req_cacheable_d[ii] = ldq_req_cacheable_q[ii];
    ldq_req_type_d[ii] = ldq_req_type_q[ii];

    if (ldq_state_q[ii] == INIT_LDQ_STATE) begin
        if(ldq_init_id == ii && top_l1d_req_valid_i[0]) begin
            ldq_state_d[ii] = (has_state_pending || has_state_sent_no_ready) ? PENDING_LDQ_STATE : ld_l1d_req_ready_i ? SENT_LDQ_STATE : NORDY_SENT_LDQ_STATE;
            ldq_ld_count_set[ii] = ldq_gbl_ld_cnt_q + LDQ_LD_CNT_W'(1);
            ldq_ld_count_d[ii] = ldq_ld_count_set[ii];

            ldq_req_addr_d[ii] = top_l1d_req_i[0].paddr;
            ldq_req_lsu_id_d[ii] = top_l1d_req_i[0].lsu_id;
            ldq_req_cacheable_d[ii] = top_l1d_req_i[0].is_cacheable;
            ldq_req_type_d[ii] = top_l1d_req_i[0].req_type;
        end
    end else if (ldq_state_q[ii] == NORDY_SENT_LDQ_STATE) begin
        ldq_state_d[ii] = ld_l1d_req_ready_i ? SENT_LDQ_STATE : NORDY_SENT_LDQ_STATE;
    end else if (ldq_state_q[ii] == PENDING_LDQ_STATE) begin
        if (ldq_oldest_pending_id == ii && ~has_state_sent_no_ready) begin
            ldq_state_d[ii] = ld_l1d_req_ready_i ? SENT_LDQ_STATE : NORDY_SENT_LDQ_STATE;
        end
    end else if (ldq_state_q[ii] == SENT_LDQ_STATE) begin
    //     if(ldq_oldest_pending_id ==  ii && ~has_state_sent_no_ready) begin
    //         ldq_state_d[ii] = ld_l1d_req_ready_i ? SNET_LDQ_STATE : NORDY_SENT_LDQ_STATE;
    //     end
    // end else if (ldq_state_q[ii] == SENT_LDQ_STATE) begin
        if(ldq_resp_set[ii]) begin
            ldq_state_d[ii] = INIT_LDQ_STATE;
        end else if (ldq_sleep_set[ii]) begin
            if (l1d_lsu_sleep_mshr_full_i) begin
                ldq_state_d[ii] = FULLMISS_LDQ_STATE;
            end else begin
                ldq_state_d[ii] = IDMISS_LDQ_STATE;
                ldq_mshr_id_d[ii] = l1d_lsu_sleep_mshr_id_i;
            end
        end
    end else if (ldq_state_q[ii] == IDMISS_LDQ_STATE) begin
        if(l1d_lsu_wakeup_cache_refill_valid_i && l1d_lsu_wakeup_mshr_id_i == ldq_mshr_id_q[ii]) begin
           ldq_state_d[ii] = PENDING_LDQ_STATE;
        end
    end else if (ldq_state_q[ii] == FULLMISS_LDQ_STATE) begin
        if(l1d_lsu_wakeup_mshr_avail_i) begin
            ldq_state_d[ii] = PENDING_LDQ_STATE;
        end
    end
end

std_dffrve #(LDQ_STATE_W)   FF_LDQ_ENT_STATE (.clk(clk),.rstn(rst_n),.rst_val(INIT_LDQ_STATE),.en(1'b1),.d(ldq_state_d[ii]),.q(ldq_state_q[ii]));
std_dffr   #(MSHR_ID_NUM_W) FF_LDQ_ENT_MSHR_ID (.clk(clk),.rstn(rst_n) ,.d(ldq_mshr_id_d[ii]) ,.q(ldq_mshr_id_q[ii]));
std_dffr   #(LDQ_LD_CNT_W)  FF_LDQ_ENT_LD_CNT (.clk(clk) ,.rstn(rst_n) ,.d(ldq_ld_count_d[ii]) ,.q(ldq_ld_count_q[ii]));
std_dffr   #($bits(rrv64_l1d_addr_t)) FF_LDQ_ENT_REQ_ADDR (.clk(clk) ,.rstn(rst_n) ,.d(ldq_req_addr_d[ii]),.q(ldq_req_addr_q[ii]));
std_dffr   #(LDQ_LSU_ID_W) FF_LDQ_ENT_REQ_LSU_ID (.clk(clk) ,.rstn(rst_n) ,.d(ldq_req_lsu_id_d[ii]),.q(ldq_req_lsu_id_q[ii]));
std_dffr   #(1) FF_LDQ_ENT_REQ_CACHEABLE (.clk(clk) ,.rstn(rst_n) ,.d(ldq_req_cacheable_d[ii]),.q(ldq_req_cacheable_q[ii]));
std_dffr   #($bits(lsu_op_e)) FF_LDQ_ENT_REQ_TYPE (.clk(clk) ,.rstn(rst_n) ,.d(ldq_req_type_d[ii]),.q(ldq_req_type_q[ii]));

end
endgenerate
endmodule