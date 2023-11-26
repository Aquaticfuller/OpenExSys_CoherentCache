module rvh_l1d_mlfb
  import rvh_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_noc_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
     parameter ENTRY_NUM=8
    ,parameter ENTRY_IDX=$clog2(ENTRY_NUM)
    ,parameter BANK_ID=0
    ,parameter CORE_ID=0

)(
     input logic clk
    ,input logic rstn
    ,input logic rob_flush_i

    // cache rx port, scu -> private cache
      // resp
    ,input  logic                        scu_pc_resp_vld_i
    ,input  cache_scu_cc_resp_t          scu_pc_resp_i
    ,output logic                        scu_pc_resp_rdy_o

      // data
    ,input  logic                        scu_pc_data_vld_i
    ,input  cache_scu_cc_data_t          scu_pc_data_i
    ,output logic                        scu_pc_data_rdy_o

    // cache tx port, private cache -> scu
      // resp
    ,output logic                        pc_scu_resp_vld_o
    ,output cache_scu_cc_resp_t          pc_scu_resp_o
    ,input  logic                        pc_scu_resp_rdy_i

    ,output logic mlfb_mshr_dealloc_valid
    ,input logic mlfb_mshr_dealloc_ready
    ,output logic[N_MSHR_W -1:0] mlfb_mshr_dealloc_idx
    
    ,output logic[N_MSHR_W -1:0]   mlfb_mshr_head_rd_idx
    ,input  mshr_t                  mlfb_mshr_head_rd_mshr_entry
    ,input  logic                   mlfb_mshr_head_rd_mshr_entry_no_resp
//    ,output logic[ENTRY_IDX-1:0]    mlfb_mshr_head_pending_rd_idx
//    ,input  mshr_t                  mlfb_mshr_head_pending_rd_mshr_entry
    
    ,output logic                           mlfb_lru_peek_valid
    ,output logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  mlfb_lru_peek_set_idx
    ,input  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]   mlfb_lru_peek_dat
    
    ,output logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  mlfb_lst_peek_set_idx
    ,input  rrv64_l1d_lst_t  mlfb_lst_peek_dat
    ,input  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] mlfb_lst_peek_avail_way_idx
    
    ,output logic mlfb_lst_check_valid
    ,output logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  mlfb_lst_check_set_idx
    ,output logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  mlfb_lst_check_way_idx
    ,input  logic mlfb_lst_check_ready

    // ,output mlfb_lst_lock_wr_en
    // ,output[L1D_BANK_SET_INDEX_WIDTH-1:0] mlfb_lst_lock_wr_set_idx
    // ,output[L1D_BANK_WAY_INDEX_WIDTH-1:0] mlfb_lst_lock_wr_way_idx
    // ,output[1:0] mlfb_lst_lock_wr_dat
    
    ,output logic  mlfb_cache_evict_req_valid
    ,output logic  mlfb_cache_writeback_req_valid
    ,input  logic  mlfb_cache_evict_req_ready
    ,output rrv64_l1d_evict_req_t mlfb_cache_evict_req
    
    ,output logic mlfb_cache_refill_req_valid
    ,input logic  mlfb_cache_refill_req_ready
    ,output rrv64_l1d_refill_req_t mlfb_cache_refill_req

//    ,output logic mlfb_stb_rd_resp_valid
//    ,output rrv64_l1d_cache_stb_rd_resp_t mlfb_stb_rd_resp
//    ,output[L1D_BANK_LINE_DATA_SIZE-1:0] mlfb_stb_rd_resp_line_dat
    
//    ,output logic l1d_scu_rnsd_coh_ack_valid
//    ,output rrv64_l1d_scu_coh_ack_t l1d_scu_rnsd_coh_ack
//    ,output logic mlfb_head_buf_valid
    ,input logic                    s1_valid
    ,input logic[PADDR_WIDTH-1:0]   s1_paddr
    ,input logic                    s2_valid
    ,input logic[PADDR_WIDTH-1:0]   s2_paddr

    // snoop req: stall mlfb refill transaction if no sent-out line addr hit in mshr(cond s0.3)
    ,input logic                    snoop_stall_refill_i
);
//mlfb tail update, wr side
logic[ENTRY_NUM-1:0]                       mlfb_mshr_info_set;
logic[ENTRY_NUM-1:0]                       mlfb_mshr_info_from_data_set;
logic[ENTRY_NUM-1:0]                       mlfb_mshr_info_from_resp_set;
logic[ENTRY_NUM-1:0][N_MSHR_W-1:0]         mlfb_mshr_idx_nxt;
logic[ENTRY_NUM-1:0][N_MSHR_W-1:0]         mlfb_mshr_idx;
logic[ENTRY_NUM-1:0]                       mlfb_err_nxt;
logic[ENTRY_NUM-1:0]                       mlfb_err;
logic[ENTRY_NUM-1:0][SCU_TID_W-1:0]        scu_tid_nxt;
logic[ENTRY_NUM-1:0][SCU_TID_W-1:0]        scu_tid;
logic[ENTRY_NUM-1:0][$bits(rrv64_mesi_type_e)-1:0] mlfb_mesi_sta_nxt;
logic[ENTRY_NUM-1:0][$bits(rrv64_mesi_type_e)-1:0] mlfb_mesi_sta;
logic[ENTRY_NUM-1:0][DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0] mlfb_data_nxt;
logic[ENTRY_NUM-1:0][DATA_BURST_NUM-1:0]                          mlfb_data_ena;
logic[ENTRY_NUM-1:0][DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0] mlfb_data;
logic[ENTRY_NUM-1:0]                               mlfb_data_valid_nxt;
logic[ENTRY_NUM-1:0]                               mlfb_data_valid;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
logic[ENTRY_NUM-1:0]                               mlfb_critical_received_wait_for_common_set, mlfb_critical_received_wait_for_common_clr;
logic[ENTRY_NUM-1:0]                               mlfb_critical_received_wait_for_common_nxt;
logic[ENTRY_NUM-1:0]                               mlfb_critical_received_wait_for_common;
logic[ENTRY_NUM-1:0]                               mlfb_common_received_wait_for_critical_set, mlfb_common_received_wait_for_critical_clr;
logic[ENTRY_NUM-1:0]                               mlfb_common_received_wait_for_critical_nxt;
logic[ENTRY_NUM-1:0]                               mlfb_common_received_wait_for_critical;
logic[ENTRY_NUM-1:0]                               mlfb_critical_part_resp_done_set, mlfb_critical_part_resp_done_clr;
logic[ENTRY_NUM-1:0]                               mlfb_critical_part_resp_done_ena;
logic[ENTRY_NUM-1:0]                               mlfb_critical_part_resp_done_nxt;
logic[ENTRY_NUM-1:0]                               mlfb_critical_part_resp_done;
logic[ENTRY_NUM-1:0]                               mlfb_has_another_part_nxt;
logic[ENTRY_NUM-1:0]                               mlfb_has_another_part;
`endif

//mlfb head read, rd side
logic[BURST_SIZE-1:0] fifo_head_valid;
logic[BURST_SIZE-1:0][MEM_DATA_WIDTH-1:0] head_seg_dat;
//mlfb fifo
rrv64_l1d_mlfb_t[ENTRY_NUM-1:0] mlfb_fifo;
logic           [ENTRY_NUM-1:0] mlfb_fifo_valid, mlfb_fifo_valid_nxt;
logic           [ENTRY_NUM-1:0] mlfb_fifo_valid_clr, mlfb_fifo_valid_set, mlfb_fifo_valid_ena;
logic[ENTRY_IDX-1:0]  head_idx;
logic                 head_idx_valid;
//mlfb head buf
rrv64_l1d_mlfb_head_buf_t head_buf;
//sta
logic head_buf_valid_set;
logic head_buf_valid_clr;
logic head_buf_valid_ena;
logic head_buf_valid_nxt;
logic head_buf_valid;
logic head_buf_peek_done_set;
logic head_buf_peek_done_clr;
logic head_buf_peek_done_ena;
logic head_buf_peek_done_nxt;
logic head_buf_peek_done;
logic head_buf_evict_done_set;
logic head_buf_evict_done_clr;
logic head_buf_evict_done_ena;
logic head_buf_evict_done_nxt;
logic head_buf_evict_done;
logic head_buf_check_done_set;
logic head_buf_check_done_clr;
logic head_buf_check_done_ena;
logic head_buf_check_done_nxt;
logic head_buf_check_done;
logic head_buf_refill_done_set;
logic head_buf_refill_done_clr;
logic head_buf_refill_done_ena;
logic head_buf_refill_done_nxt;
logic head_buf_refill_done;
logic [L1D_BANK_LINE_DATA_SIZE -1:0] mlfb_refill_dat_tmp;
logic [L1D_BANK_LINE_DATA_SIZE -1:0] mlfb_refill_dat_tmp_bit_mask;
logic head_buf_lsu_resp_done_set;
logic head_buf_lsu_resp_done_clr;
logic head_buf_lsu_resp_done_ena;
logic head_buf_lsu_resp_done_nxt;
logic head_buf_lsu_resp_done;
logic head_buf_stb_dat_done_set;
logic head_buf_stb_dat_done_clr;
logic head_buf_stb_dat_done_ena;
logic head_buf_stb_dat_done_nxt;
logic head_buf_stb_dat_done;
//dat
logic[L1D_BANK_LINE_DATA_SIZE-1:0] head_buf_line_dat_nxt;
logic                              head_buf_line_dat_vld_nxt;
logic[N_MSHR_W-1:0] head_buf_mshr_idx_nxt;
logic head_buf_err_nxt ;
logic[SCU_TID_W-1:0] head_buf_scu_tid_nxt ;
rrv64_mesi_type_e head_buf_mesi_sta_nxt ;
rrv64_l1d_req_type_dec_t head_buf_lsu_req_type_dec_nxt;
// logic[RRV64_SCU_SST_IDX_W-1:0] head_buf_sst_idx_nxt ;
logic head_buf_l2_hit_nxt ;
logic[PADDR_WIDTH-1:0]  head_buf_paddr_nxt ;
logic [ROB_TAG_WIDTH-1:0]       head_buf_rob_tag_nxt;
logic [PREG_TAG_WIDTH-1:0]      head_buf_prd_nxt;
`ifdef RUBY
logic [RRV64_LSU_ID_WIDTH -1:0] head_buf_lsu_tag_nxt;
`endif
logic[L1D_STB_DATA_WIDTH-1:0]  head_buf_st_dat_nxt ;
logic[L1D_STB_DATA_WIDTH/8-1:0] head_buf_st_data_byte_mask_nxt;
rrv64_l1d_req_type_dec_t head_buf_req_type_dec_nxt ;
logic head_buf_no_resp_nxt;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
logic head_buf_no_refill_nxt; // for critical word first, no refill needed, only resp
`endif
logic [XLEN-1:0] head_buf_amo_st_data_nxt;
logic head_buf_stb_alloc_nxt;
logic [L1D_BANK_WAY_NUM-1:0]  head_buf_tag_compare_data_hit_permission_miss_per_way_nxt;

logic[L1D_BANK_WAY_INDEX_WIDTH -1:0] head_buf_victim_way_idx_nxt;
logic[L1D_BANK_WAY_INDEX_WIDTH -1:0] head_buf_victim_way_idx;
logic head_buf_victim_set_full_nxt;
logic head_buf_victim_set_full;
logic head_buf_victim_way_clean_nxt;
logic head_buf_victim_way_clean;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] head_buf_avail_way_idx_nxt;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] head_buf_avail_way_idx;
logic[L1D_BANK_WAY_NUM-1:0] lst_peek_valid_way;
logic mlfb_cache_peek_valid;
logic mlfb_cache_peek_bypass;
logic mlfb_cache_check_valid;
logic mlfb_cache_check_bypass;
logic mlfb_cache_evict_valid ;
logic mlfb_cache_writeback_valid ;
logic mlfb_cache_evict_bypass ;
logic mlfb_cache_refill_valid ;

logic mlfb_cache_peek_req_hsk;
logic mlfb_cache_evict_req_hsk;
logic mlfb_cache_refill_req_hsk;
logic mlfb_cache_lsu_resp_hsk;

logic op_b,op_hw,op_w,op_dw,ld_u;
logic[L1D_BANK_OFFSET_WIDTH-1:0] line_offset;
// logic[BURST_SIZE-1:0][ENTRY_IDX:0]entry_cnt;

wire mlfb_pipe_same_addr_haz;

logic [PADDR_WIDTH-L1D_BANK_OFFSET_WIDTH-1:0] head_buf_paddr_lineaddr;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] head_buf_paddr_idx;
logic [L1D_BANK_PADDR_TAG_WIDTH-1:0] head_buf_paddr_tag;
logic [L1D_BANK_OFFSET_WIDTH-1:0] head_buf_paddr_offset;

assign head_buf_paddr_lineaddr = head_buf.paddr[PADDR_WIDTH-1:L1D_BANK_OFFSET_WIDTH];
assign head_buf_paddr_idx      = head_buf.paddr[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH];
assign head_buf_paddr_tag      = head_buf.paddr[PADDR_WIDTH-1-:L1D_BANK_PADDR_TAG_WIDTH];
assign head_buf_paddr_offset   = head_buf.paddr[L1D_BANK_OFFSET_WIDTH-1:0];

//main code
genvar jj;
generate
  for(jj=0; jj<ENTRY_NUM; jj++)begin:GEN_MLFB_ENTRY
    assign mlfb_mshr_info_from_data_set[jj] = scu_pc_data_vld_i & (scu_pc_data_i.id.pc_tid == jj);
    assign mlfb_mshr_info_from_resp_set[jj] = scu_pc_resp_vld_i & (scu_pc_resp_i.id.pc_tid == jj);

    assign mlfb_mshr_info_set[jj]   = mlfb_mshr_info_from_data_set[jj] | mlfb_mshr_info_from_resp_set[jj];
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    assign mlfb_fifo_valid_clr[jj]  = head_buf_valid_set & (head_idx == jj) & ~mlfb_fifo[jj].critical_received_wait_for_common;
`else
    assign mlfb_fifo_valid_clr[jj]  = head_buf_valid_set & (head_idx == jj);
`endif
    assign mlfb_fifo_valid_set[jj]  = mlfb_mshr_info_set[jj];
    assign mlfb_fifo_valid_nxt[jj]  = (mlfb_fifo_valid[jj] & ~mlfb_fifo_valid_clr[jj]) | mlfb_fifo_valid_set[jj];
    assign mlfb_fifo_valid_ena[jj]  = mlfb_fifo_valid_clr[jj] | mlfb_fifo_valid_set[jj];

    assign mlfb_mshr_idx_nxt[jj]    = jj;
    assign mlfb_err_nxt[jj]         = '0;
    assign scu_tid_nxt[jj]          = mlfb_mshr_info_from_resp_set[jj] ? scu_pc_resp_i.id.scu_tid :
                                                                         scu_pc_data_i.id.scu_tid;

    assign mlfb_mesi_sta_nxt[jj]    = mlfb_mshr_info_from_resp_set[jj]      ? MODIFIED :
                                      (scu_pc_data_i.rtype == CompData_I)   ? INVALID :
                                      (scu_pc_data_i.rtype == CompData_SC)  ? SHARED :
                                      (scu_pc_data_i.rtype == CompData_UC)  ? EXCLUSIVE :
                                                                              MODIFIED;

    for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
      assign mlfb_data_ena[jj][data_seg_id] = mlfb_mshr_info_from_data_set[jj] & scu_pc_data_i.data_valid[data_seg_id];
      assign mlfb_data_nxt[jj][data_seg_id] = scu_pc_data_i.data[data_seg_id];
    end

    assign mlfb_data_valid_nxt[jj]  = mlfb_mshr_info_from_data_set[jj];

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    assign mlfb_critical_received_wait_for_common_set[jj]  = ((mlfb_fifo_valid[jj] & ~mlfb_fifo[jj].data_valid) | ~mlfb_fifo_valid[jj]) & scu_pc_data_vld_i & scu_pc_data_i.is_critical & scu_pc_data_i.has_another_part;
    assign mlfb_critical_received_wait_for_common_clr[jj]  = mlfb_fifo_valid[jj] & mlfb_fifo[jj].data_valid & ~scu_pc_data_i.is_critical & scu_pc_data_i.has_another_part;
    assign mlfb_critical_received_wait_for_common_nxt[jj]  = (mlfb_critical_received_wait_for_common[jj] | mlfb_critical_received_wait_for_common_set[jj]) & ~mlfb_critical_received_wait_for_common_clr[jj];

    assign mlfb_common_received_wait_for_critical_set[jj]  = ((mlfb_fifo_valid[jj] & ~mlfb_fifo[jj].data_valid) | ~mlfb_fifo_valid[jj]) & scu_pc_data_vld_i & ~scu_pc_data_i.is_critical & scu_pc_data_i.has_another_part;
    assign mlfb_common_received_wait_for_critical_clr[jj]  = mlfb_fifo_valid[jj] & mlfb_fifo[jj].data_valid & scu_pc_data_i.is_critical & scu_pc_data_i.has_another_part;
    assign mlfb_common_received_wait_for_critical_nxt[jj]  = (mlfb_common_received_wait_for_critical[jj] | mlfb_common_received_wait_for_critical_set[jj]) & ~mlfb_common_received_wait_for_critical_clr[jj];

    assign mlfb_critical_part_resp_done_set[jj] = head_buf_valid_set & (head_idx == jj) & mlfb_fifo[jj].critical_received_wait_for_common;
    assign mlfb_critical_part_resp_done_clr[jj] = mlfb_fifo_valid_clr[jj];
    assign mlfb_critical_part_resp_done_ena[jj] = mlfb_critical_part_resp_done_set[jj] | mlfb_critical_part_resp_done_clr[jj];
    assign mlfb_critical_part_resp_done_nxt[jj] = (mlfb_critical_part_resp_done[jj] | mlfb_critical_part_resp_done_set[jj]) & ~mlfb_critical_part_resp_done_clr[jj];

    assign mlfb_has_another_part_nxt[jj] = mlfb_mshr_info_from_data_set[jj] & scu_pc_data_i.has_another_part;
`endif

    std_dffre #(.WIDTH(1)) U_DAT_REG_MLFB_FIFO_VALID (.clk(clk), .rstn(rstn), .en(mlfb_fifo_valid_ena[jj]), .d(mlfb_fifo_valid_nxt[jj]), .q((mlfb_fifo_valid[jj])));
    std_dffe #(.WIDTH(N_MSHR_W)) U_DAT_REG_MSHR_IDX (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_mshr_idx_nxt[jj]), .q((mlfb_mshr_idx[jj])));
    std_dffe #(.WIDTH(1)) U_DAT_REG_ERR (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_err_nxt[jj]), .q((mlfb_err[jj])));
    std_dffe #(.WIDTH(SCU_TID_W)) U_DAT_REG_SCU_ID (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(scu_tid_nxt[jj]), .q((scu_tid[jj])));
    std_dffe #(.WIDTH($bits(rrv64_mesi_type_e))) U_DAT_REG_MESI_STA (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_mesi_sta_nxt[jj]), .q(mlfb_mesi_sta[jj]));
    for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
      std_dffe #(.WIDTH(DATA_LENGTH_PER_PKG)) U_DAT_REG_DATA (.clk(clk), .en(mlfb_data_ena[jj][data_seg_id]), .d(mlfb_data_nxt[jj][data_seg_id]), .q(mlfb_data[jj][data_seg_id]));
    end
    std_dffe #(.WIDTH(1)) U_DAT_REG_DATA_VALID (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_data_valid_nxt[jj]), .q(mlfb_data_valid[jj]));
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    std_dffre #(.WIDTH(1)) U_DAT_REG_CRITICAL_RECEIVED_WAIT_FOR_COMMON (.clk(clk), .rstn(rstn), .en(mlfb_mshr_info_set[jj]), .d(mlfb_critical_received_wait_for_common_nxt[jj]), .q(mlfb_critical_received_wait_for_common[jj]));
    std_dffre #(.WIDTH(1)) U_DAT_REG_COMMON_RECEIVED_WAIT_FOR_CRITICAL (.clk(clk), .rstn(rstn), .en(mlfb_mshr_info_set[jj]), .d(mlfb_common_received_wait_for_critical_nxt[jj]), .q(mlfb_common_received_wait_for_critical[jj]));
    std_dffre #(.WIDTH(1)) U_DAT_REG_CRITICAL_PART_RESP_DONE (.clk(clk), .rstn(rstn), .en(mlfb_critical_part_resp_done_ena[jj]), .d(mlfb_critical_part_resp_done_nxt[jj]), .q(mlfb_critical_part_resp_done[jj]));
    std_dffre #(.WIDTH(1)) U_DAT_REG_HAS_ANOTHER_PART (.clk(clk), .rstn(rstn), .en(mlfb_mshr_info_set[jj]), .d(mlfb_has_another_part_nxt[jj]), .q(mlfb_has_another_part[jj]));
`endif

    assign mlfb_fifo[jj].mshr_idx   = mlfb_mshr_idx[jj];
    assign mlfb_fifo[jj].err        = mlfb_err[jj];
    assign mlfb_fifo[jj].scu_tid    = scu_tid[jj];
    assign mlfb_fifo[jj].mesi_sta   = rrv64_mesi_type_e'(mlfb_mesi_sta[jj]);
    assign mlfb_fifo[jj].data       = mlfb_data[jj];
    assign mlfb_fifo[jj].data_valid = mlfb_data_valid[jj];
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    assign mlfb_fifo[jj].critical_received_wait_for_common = mlfb_critical_received_wait_for_common[jj];
    assign mlfb_fifo[jj].common_received_wait_for_critical = mlfb_common_received_wait_for_critical[jj];
    assign mlfb_fifo[jj].critical_part_resp_done           = mlfb_critical_part_resp_done[jj];
    assign mlfb_fifo[jj].has_another_part                  = mlfb_has_another_part[jj];
`endif


  end
endgenerate


logic           [ENTRY_NUM-1:0] mlfb_fifo_all_seg_valid;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
generate
  for(jj=0; jj<ENTRY_NUM; jj++)begin:gen_mlfb_fifo_all_seg_valid
    assign mlfb_fifo_all_seg_valid[jj]  = mlfb_fifo_valid[jj] & 
                                          ~mlfb_fifo[jj].common_received_wait_for_critical &
                                          ~(mlfb_fifo[jj].critical_received_wait_for_common & mlfb_fifo[jj].critical_part_resp_done);
  end
endgenerate
`else
assign mlfb_fifo_all_seg_valid = mlfb_fifo_valid;
`endif

priority_encoder
#(
  .SEL_WIDTH(ENTRY_NUM)
)
head_idx_sel
(
  .sel_i      (mlfb_fifo_all_seg_valid    ),
  .id_vld_o   (head_idx_valid     ),
  .id_o       (head_idx           )
);


//head buf
//valid
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign head_buf_valid_set = head_idx_valid & (~head_buf_valid | head_buf_valid_clr) & ~rob_flush_i & 
                            ((mlfb_fifo[head_idx].critical_received_wait_for_common & ~mlfb_fifo[head_idx].critical_part_resp_done) |
                             ~mlfb_fifo[head_idx].critical_received_wait_for_common
                            );
assign head_buf_valid_clr = head_buf.valid & head_buf.refill_done & ((mlfb_mshr_dealloc_ready & pc_scu_resp_rdy_i) | head_buf.ld_no_refill);
`else
assign head_buf_valid_set = head_idx_valid & (~head_buf_valid | head_buf_valid_clr) & ~rob_flush_i;
assign head_buf_valid_clr = head_buf.valid & head_buf.refill_done & (mlfb_mshr_dealloc_ready & pc_scu_resp_rdy_i);
`endif
assign head_buf_valid_ena = head_buf_valid_set | head_buf_valid_clr;
assign head_buf_valid_nxt = head_buf_valid_set ? 1'b1 : (~head_buf_valid_clr);
std_dffre#(.WIDTH(1)) U_STA_REG_HEAD_BUF_VALID(.clk(clk), .rstn(rstn), .en(head_buf_valid_ena), .d(head_buf_valid_nxt), .q(head_buf_valid));
assign head_buf.valid = head_buf_valid;
//data
// assign head_buf_line_dat_nxt = mlfb_fifo[head_idx].data;
generate
  for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
    assign head_buf_line_dat_nxt[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG] = mlfb_fifo[head_idx].data[data_seg_id];
  end
endgenerate

assign head_buf_line_dat_vld_nxt = mlfb_fifo[head_idx].data_valid;
assign head_buf_mshr_idx_nxt = mlfb_fifo[head_idx].mshr_idx;
assign head_buf_err_nxt      = mlfb_fifo[head_idx].err;
assign head_buf_scu_tid_nxt  = mlfb_fifo[head_idx].scu_tid;
assign head_buf_mesi_sta_nxt = mlfb_fifo[head_idx].mesi_sta;
assign head_buf_paddr_nxt = {mlfb_mshr_head_rd_mshr_entry.new_tag, mlfb_mshr_head_rd_mshr_entry.bank_index, BANK_ID[L1D_BANK_ID_INDEX_WIDTH-1:0], mlfb_mshr_head_rd_mshr_entry.offset};
assign head_buf_rob_tag_nxt = mlfb_mshr_head_rd_mshr_entry.rob_tag;
assign head_buf_prd_nxt = mlfb_mshr_head_rd_mshr_entry.prd;
`ifdef RUBY
assign head_buf_lsu_tag_nxt = mlfb_mshr_head_rd_mshr_entry.lsu_tag;
`endif
assign head_buf_st_dat_nxt = mlfb_mshr_head_rd_mshr_entry.data;
assign head_buf_st_data_byte_mask_nxt = mlfb_mshr_head_rd_mshr_entry.data_byte_mask;
assign head_buf_req_type_dec_nxt   = mlfb_mshr_head_rd_mshr_entry.req_type_dec;

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign head_buf_no_resp_nxt   = mlfb_mshr_head_rd_mshr_entry_no_resp | rob_flush_i | mlfb_fifo[head_idx].critical_part_resp_done;
`else
assign head_buf_no_resp_nxt   = mlfb_mshr_head_rd_mshr_entry_no_resp | rob_flush_i;
`endif
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign head_buf_no_refill_nxt = mlfb_fifo[head_idx].critical_received_wait_for_common; // for critical word first, no refill needed, only resp
assign head_buf_has_another_part_nxt = mlfb_fifo[head_idx].has_another_part; // for critical word first, no refill needed, only resp
`endif

assign head_buf_amo_st_data_nxt = mlfb_mshr_head_rd_mshr_entry.amo_st_data;
assign head_buf_tag_compare_data_hit_permission_miss_per_way_nxt = mlfb_mshr_head_rd_mshr_entry.tag_compare_data_hit_permission_miss_per_way;

//assign mlfb_refill_dat_tmp_mask   = head_buf.req_type_dec.op_b  ? {{(XLEN/8-1){1'b0}}, 1'b1}  :
//                                    head_buf.req_type_dec.op_hw ? {{(XLEN/8-2){1'b0}}, 2'b11} :
//                                    head_buf.req_type_dec.op_w  ? {{(XLEN/8-4){1'b0}}, 4'b1111} :
//                                    head_buf.req_type_dec.op_dw ? {{(XLEN/8-8){1'b0}}, 8'b11111111} : '0;
generate
    for(genvar ii = 0; ii < L1D_BANK_LINE_DATA_SIZE/8; ii++) begin
        assign mlfb_refill_dat_tmp_bit_mask[ii*8 +: 8] = {8{head_buf.st_dat_byte_mask[ii]}};
    end
endgenerate
assign mlfb_refill_dat_tmp = head_buf.req_type_dec.is_st ? (head_buf.line_dat_vld ? ((head_buf.line_dat & ~mlfb_refill_dat_tmp_bit_mask) | head_buf.st_dat & mlfb_refill_dat_tmp_bit_mask) :
                                                                                    head_buf.st_dat
                                                            )
                                                         : head_buf.line_dat; 

std_dffe #(.WIDTH(L1D_BANK_LINE_DATA_SIZE)) U_DAT_REG_HEAD_BUF_LINE_DAT (.clk(clk), .en(head_buf_valid_set & head_buf_line_dat_vld_nxt),  .d(head_buf_line_dat_nxt), .q(head_buf.line_dat));
std_dffe #(.WIDTH(1)) U_DAT_REG_HEAD_BUF_LINE_DAT_VLD (.clk(clk), .en(head_buf_valid_set),  .d(head_buf_line_dat_vld_nxt), .q(head_buf.line_dat_vld));
std_dffe #(.WIDTH(N_MSHR_W))U_DAT_REG_HEAD_BUF_MSHR_IDX (.clk(clk), .en(head_buf_valid_set),  .d(head_buf_mshr_idx_nxt), .q(head_buf.mshr_idx));
std_dffe #(.WIDTH(1))U_DAT_REG_HEAD_BUF_LINE_ERR (.clk(clk), .en(head_buf_valid_set), .d(head_buf_err_nxt), .q(head_buf.err));
std_dffe #(.WIDTH(SCU_TID_W))U_DAT_REG_HEAD_BUF_LINE_SCU_TID (.clk(clk), .en(head_buf_valid_set), .d(head_buf_scu_tid_nxt), .q(head_buf.scu_tid));
std_dffe #(.WIDTH($bits(rrv64_mesi_type_e)))U_DAT_REG_MESI_STA(.clk(clk), .en(head_buf_valid_set), .d(head_buf_mesi_sta_nxt), .q(head_buf.mesi_sta));
std_dffe#(.WIDTH($bits(head_buf_paddr_nxt)))U_DAT_REG_HEAD_BUF_PADDR(.clk(clk),.en(head_buf_valid_set),.d(head_buf_paddr_nxt),.q(head_buf.paddr));
std_dffe#(.WIDTH($bits(head_buf_rob_tag_nxt)))U_DAT_REG_HEAD_BUF_ROB_TAG(.clk(clk),.en(head_buf_valid_set),.d(head_buf_rob_tag_nxt),.q(head_buf.rob_tag));
std_dffe#(.WIDTH($bits(head_buf_prd_nxt)))U_DAT_REG_HEAD_BUF_PRD(.clk(clk),.en(head_buf_valid_set),.d(head_buf_prd_nxt),.q(head_buf.prd));
`ifdef RUBY
std_dffe#(.WIDTH($bits(head_buf_lsu_tag_nxt)))U_DAT_REG_HEAD_BUF_LSU_TAG(.clk(clk),.en(head_buf_valid_set),.d(head_buf_lsu_tag_nxt),.q(head_buf.lsu_tag));
`endif
std_dffe#(.WIDTH(L1D_STB_DATA_WIDTH))U_DAT_REG_HEAD_BUF_ST_DATA(.clk(clk),.en(head_buf_valid_set & head_buf_req_type_dec_nxt.is_st),.d(head_buf_st_dat_nxt),.q(head_buf.st_dat));
std_dffre#(.WIDTH(L1D_STB_DATA_WIDTH/8))U_DAT_REG_HEAD_BUF_ST_DATA_BYTE_MASK(.clk(clk),.rstn(rstn),.en(head_buf_valid_set & head_buf_req_type_dec_nxt.is_st),.d(head_buf_st_data_byte_mask_nxt),.q(head_buf.st_dat_byte_mask));
std_dffe#(.WIDTH($bits(rrv64_l1d_req_type_dec_t)))U_DAT_REG_HEAD_BUF_REQ_TYPE(.clk(clk),.en(head_buf_valid_set),.d(head_buf_req_type_dec_nxt),.q(head_buf.req_type_dec));
std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_NO_RESP(.clk(clk),.en(head_buf_valid_set | rob_flush_i),.d(head_buf_no_resp_nxt),.q(head_buf.ld_no_resp));
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_NO_REFILL(.clk(clk),.en(head_buf_valid_set),.d(head_buf_no_refill_nxt),.q(head_buf.ld_no_refill));
std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_HAS_ANOTHER_PART(.clk(clk),.en(head_buf_valid_set),.d(head_buf_has_another_part_nxt),.q(head_buf.has_another_part));
`endif
std_dffe#(.WIDTH(XLEN))U_DAT_REG_HEAD_BUF_AMO_ST_DATA(.clk(clk),.en(head_buf_valid_set),.d(head_buf_amo_st_data_nxt),.q(head_buf.amo_st_data));
std_dffe#(.WIDTH(L1D_BANK_WAY_NUM))U_DAT_REG_HEAD_BUF_TAG_COMPARE_PER_WAY_DATA(.clk(clk),.en(head_buf_valid_set),.d(head_buf_tag_compare_data_hit_permission_miss_per_way_nxt),.q(head_buf.tag_compare_data_hit_permission_miss_per_way));

//line back operation: dat done/peek/evict/refill/response
assign mlfb_pipe_same_addr_haz = s1_valid & (s1_paddr[PADDR_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == head_buf_paddr_lineaddr) |
                                 s2_valid & (s2_paddr[PADDR_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == head_buf_paddr_lineaddr) ;
///peek
assign head_buf_peek_done_set = mlfb_cache_peek_valid | mlfb_cache_peek_bypass;
assign head_buf_peek_done_clr = head_buf_valid_clr;
assign head_buf_peek_done_ena = head_buf_peek_done_set | head_buf_peek_done_clr;
assign head_buf_peek_done_nxt = head_buf_peek_done_set & (~head_buf_peek_done_clr);
std_dffre#(.WIDTH(1))U_STA_REG_PEEK_DONE(.clk(clk), .rstn(rstn),.en(head_buf_peek_done_ena),.d(head_buf_peek_done_nxt),.q(head_buf_peek_done));
assign head_buf.peek_done = head_buf_peek_done;
//victim way
genvar kk;
generate
for(kk=0; kk<L1D_BANK_WAY_NUM; kk++) begin:GEN_MLFB_LST_PEEK_STA
    assign lst_peek_valid_way[kk] = (mlfb_lst_peek_dat.mesi_sta[kk]!=INVALID);
end
endgenerate
assign head_buf_avail_way_idx_nxt = mlfb_lst_peek_avail_way_idx;
assign head_buf_victim_way_idx_nxt = mlfb_lru_peek_dat;
assign head_buf_victim_set_full_nxt = &lst_peek_valid_way;
assign head_buf_victim_way_clean_nxt = (mlfb_lst_peek_dat.mesi_sta[mlfb_lru_peek_dat] != MODIFIED);
std_dffe#(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH))U_STA_REG_PEEK_AVAIL (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_avail_way_idx_nxt),.q(head_buf_avail_way_idx));
std_dffe#(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH))U_STA_REG_PEEK_VICTIM (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_victim_way_idx_nxt), .q(head_buf_victim_way_idx));
std_dffe#(.WIDTH(1)) U_STA_REG_PEEK_SET_FULL (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_victim_set_full_nxt),.q(head_buf_victim_set_full));
std_dffe#(.WIDTH(1)) U_STA_REG_PEEK_WAY_CLEAN (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_victim_way_clean_nxt),.q(head_buf_victim_way_clean));
assign head_buf.victim_set_full     = head_buf_victim_set_full;
assign head_buf.victim_way_idx      = head_buf_victim_way_idx;
assign head_buf.avail_way_idx       = head_buf_avail_way_idx;
assign head_buf.victim_way_clean    = head_buf_victim_way_clean;

///check
assign head_buf_check_done_set = (mlfb_cache_check_valid & (|mlfb_lst_check_ready)) | mlfb_cache_check_bypass;
assign head_buf_check_done_clr = head_buf_valid_clr;
assign head_buf_check_done_ena = head_buf_check_done_set | head_buf_check_done_clr;
assign head_buf_check_done_nxt = head_buf_check_done_set & (~head_buf_check_done_clr);
std_dffre #(.WIDTH(1)) U_STA_REG_CHECK_DONE (.clk(clk) ,.rstn(rstn) ,.en(head_buf_check_done_ena) ,.d(head_buf_check_done_nxt) ,.q(head_buf_check_done));
assign head_buf.check_done = head_buf_check_done;

//evict
assign head_buf_evict_done_set = mlfb_cache_evict_req_hsk |
                                 mlfb_cache_evict_bypass ;
assign head_buf_evict_done_clr = head_buf_valid_clr;
assign head_buf_evict_done_ena = head_buf_evict_done_set | head_buf_evict_done_clr;
assign head_buf_evict_done_nxt = head_buf_evict_done_set & (~head_buf_evict_done_clr);
std_dffre#(.WIDTH(1))U_STA_REG_EVICT_DONE(.clk(clk), .rstn(rstn), .en(head_buf_evict_done_ena), .d(head_buf_evict_done_nxt), .q(head_buf_evict_done));
assign head_buf.evict_done= head_buf_evict_done;

//refill
assign head_buf_refill_done_set = mlfb_cache_refill_req_hsk;
assign head_buf_refill_done_clr = head_buf_valid_clr;
assign head_buf_refill_done_ena = head_buf_refill_done_set | head_buf_refill_done_clr;
assign head_buf_refill_done_nxt = head_buf_refill_done_set & (~head_buf_refill_done_clr);
std_dffre#(.WIDTH(1))U_STA_REG_REFILL_DONE(.clk(clk), .rstn(rstn), .en(head_buf_refill_done_ena), .d(head_buf_refill_done_nxt),.q(head_buf_refill_done));
assign head_buf.refill_done= head_buf_refill_done;

// //response to lsu
// assign head_buf_lsu_resp_done_set = mlfb_cache_lsu_resp_hsk;
// assign head_buf_lsu_resp_done_clr = head_buf_valid_clr;
// assign head_buf_lsu_resp_done_ena = head_buf_lsu_resp_done_set | head_buf_lsu_resp_done_clr;
// assign head_buf_lsu_resp_done_nxt = head_buf_lsu_resp_done_set & (~head_buf_lsu_resp_done_clr);
// std_dffre#(.WIDTH(1))U_STA_REG_LSU_RESP_DONE(.clk(clk), .rstn(rstn), .en(head_buf_lsu_resp_done_ena), .d(head_buf_lsu_resp_done_nxt), .q(head_buf_lsu_resp_done));
// assign head_buf.lsu_resp_done= head_buf_lsu_resp_done;

// //srq dat
// assign head_buf_srq_dat_done_set = mlfb_srq_return_upd_valid;
// assign head_buf_srq_dat_done_clr = head_buf_valid_clr;
// assign head_buf_srq_dat_done_ena = head_buf_srq_dat_done_set | head_buf_srq_dat_done_clr;
// assign head_buf_srq_dat_done_nxt = head_buf_srq_dat_done_set & (~head_buf_srq_dat_done_clr);
// std_dffre#(.WIDTH(1))U_STA_REG_SRQ_DAT_DONE(.clk(clk), .rstn(rstn),.en(head_buf_srq_dat_done_ena),.d(head_buf_srq_dat_done_nxt),.q(head_buf_srq_dat_done));
// assign head_buf.srq_dat_done = head_buf_srq_dat_done;

//MSHR intf
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign mlfb_mshr_dealloc_valid = head_buf_valid_clr & ~head_buf.ld_no_refill;
`else
assign mlfb_mshr_dealloc_valid = head_buf_valid_clr;
`endif
assign mlfb_mshr_dealloc_idx = head_buf.mshr_idx;
assign mlfb_mshr_head_rd_idx = mlfb_fifo[head_idx].mshr_idx;
assign mlfb_mshr_head_pending_rd_idx = head_buf.mshr_idx;

//Cache intf
logic head_buf_tag_compare_without_state_hit;
assign head_buf_tag_compare_without_state_hit = (|head_buf.tag_compare_data_hit_permission_miss_per_way);

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST

assign mlfb_cache_peek_valid      = head_buf.valid & ~snoop_stall_refill_i & (~head_buf.peek_done) & ~head_buf.ld_no_refill;
assign mlfb_cache_peek_bypass     = head_buf.valid & ~snoop_stall_refill_i & (~head_buf.peek_done) & head_buf.ld_no_refill;
assign mlfb_cache_check_valid     = head_buf.valid & ~snoop_stall_refill_i & head_buf.peek_done & ~head_buf.check_done & ~head_buf.ld_no_refill;
assign mlfb_cache_check_bypass    = head_buf.valid & ~snoop_stall_refill_i & ~head_buf.check_done & head_buf.ld_no_refill;
assign mlfb_cache_evict_valid     = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & head_buf.victim_set_full & head_buf.victim_way_clean &
                                    ~head_buf_tag_compare_without_state_hit & ~head_buf.ld_no_refill;
assign mlfb_cache_writeback_valid = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & head_buf.victim_set_full & ~head_buf.victim_way_clean &
                                    ~head_buf_tag_compare_without_state_hit & ~head_buf.ld_no_refill;
assign mlfb_cache_evict_bypass    = head_buf.valid & ~snoop_stall_refill_i & (~head_buf.evict_done) & ((head_buf.check_done & (~head_buf.victim_set_full | head_buf_tag_compare_without_state_hit)) | head_buf.ld_no_refill);
assign mlfb_cache_refill_valid    = head_buf.valid & ~snoop_stall_refill_i & (~head_buf.refill_done) & ((head_buf.evict_done & ~mlfb_pipe_same_addr_haz) | head_buf.ld_no_refill);

`else

assign mlfb_cache_peek_valid      = head_buf.valid & ~snoop_stall_refill_i & (~head_buf.peek_done);
assign mlfb_cache_peek_bypass     = '0;
assign mlfb_cache_check_valid     = head_buf.valid & ~snoop_stall_refill_i & head_buf.peek_done & ~head_buf.check_done;
assign mlfb_cache_check_bypass    = '0;
assign mlfb_cache_evict_valid     = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & head_buf.victim_set_full & head_buf.victim_way_clean &
                                    ~head_buf_tag_compare_without_state_hit;
assign mlfb_cache_writeback_valid = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & head_buf.victim_set_full & ~head_buf.victim_way_clean &
                                    ~head_buf_tag_compare_without_state_hit;
assign mlfb_cache_evict_bypass    = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & (~head_buf.victim_set_full | head_buf_tag_compare_without_state_hit);
assign mlfb_cache_refill_valid    = head_buf.valid & ~snoop_stall_refill_i & head_buf.evict_done & (~head_buf.refill_done) & ~mlfb_pipe_same_addr_haz;

`endif


//peek req
logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] tag_compare_valid_without_state_way_idx;
always_comb begin
  tag_compare_valid_without_state_way_idx = '0;
  for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
    if(head_buf.tag_compare_data_hit_permission_miss_per_way[i]) begin
      tag_compare_valid_without_state_way_idx = i;
    end
  end
end

assign mlfb_lru_peek_set_idx = head_buf_paddr_idx;
assign mlfb_lst_peek_set_idx = head_buf_paddr_idx;
assign mlfb_lst_check_set_idx = head_buf_paddr_idx;
assign mlfb_lst_check_way_idx = head_buf_tag_compare_without_state_hit ? tag_compare_valid_without_state_way_idx :
                                head_buf.victim_set_full ? head_buf.victim_way_idx : head_buf.avail_way_idx;

//evict req
assign mlfb_cache_evict_req_hsk = (mlfb_cache_evict_req_valid | mlfb_cache_writeback_req_valid) & mlfb_cache_evict_req_ready;
assign mlfb_cache_evict_req.set_idx = head_buf_paddr_idx;
assign mlfb_cache_evict_req.way_idx = head_buf.victim_way_idx;
//refill req
assign mlfb_cache_refill_req_hsk = mlfb_cache_refill_req_valid & mlfb_cache_refill_req_ready;
assign mlfb_cache_refill_req.set_idx = head_buf_paddr_idx;
assign mlfb_cache_refill_req.way_idx = head_buf_tag_compare_without_state_hit ? tag_compare_valid_without_state_way_idx :
                                       head_buf.victim_set_full ? head_buf.victim_way_idx : head_buf.avail_way_idx;
assign mlfb_cache_refill_req.tag     = head_buf_paddr_tag;
assign mlfb_cache_refill_req.dat     = mlfb_refill_dat_tmp;
assign mlfb_cache_refill_req.dat_byte_mask = head_buf.line_dat_vld ? '1 : head_buf.st_dat_byte_mask;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
assign mlfb_cache_refill_req.dat_dirty_byte_mask = head_buf.st_dat_byte_mask;
`endif
assign mlfb_cache_refill_req.mesi_sta= head_buf.req_type_dec.is_st ? MODIFIED : head_buf.mesi_sta; // TODO: it is only for single core
assign mlfb_cache_refill_req.is_lr   = head_buf.req_type_dec.is_lr;
assign mlfb_cache_refill_req.is_ld   = head_buf.req_type_dec.is_ld;
assign mlfb_cache_refill_req.offset  = head_buf_paddr_offset;
assign mlfb_cache_refill_req.rob_tag = head_buf.rob_tag;
assign mlfb_cache_refill_req.prd     = head_buf.prd;
`ifdef RUBY
assign mlfb_cache_refill_req.lsu_tag = head_buf.lsu_tag;
`endif
assign mlfb_cache_refill_req.req_type_dec = head_buf.req_type_dec;
assign mlfb_cache_refill_req.ld_no_resp   = head_buf.ld_no_resp;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign mlfb_cache_refill_req.ld_no_refill = head_buf.ld_no_refill;
`endif
assign mlfb_cache_refill_req.amo_st_data  = head_buf.amo_st_data;
//assign mlfb_cache_refill_req.tag_ecc_ckbit = head_buf.tag_ecc_ckbit;
assign mlfb_lru_peek_valid = mlfb_cache_peek_valid;
assign mlfb_lst_check_valid = mlfb_cache_check_valid;
assign mlfb_cache_evict_req_valid = mlfb_cache_evict_valid;
assign mlfb_cache_writeback_req_valid = mlfb_cache_writeback_valid;
assign mlfb_cache_refill_req_valid = mlfb_cache_refill_valid;

//stb intf
//assign mlfb_stb_rd_resp_valid = head_buf_valid_clr;
//assign mlfb_stb_rd_resp.cache_hit_mesi = head_buf.mesi_sta;
//assign mlfb_stb_rd_resp.id = '0;
//assign mlfb_stb_rd_resp.cache_hit_way_idx = head_buf.victim_set_full ? head_buf.victim_way_idx : head_buf.avail_way_idx;
//assign mlfb_stb_rd_resp.paddr = head_buf.paddr;
//assign mlfb_stb_rd_resp_line_dat =  head_buf.line_dat;

//output ready
assign scu_pc_resp_rdy_o = '1;
assign scu_pc_data_rdy_o = '1;

//coherence resp
assign mlfb_head_buf_valid      = head_buf_valid;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign pc_scu_resp_vld_o        = head_buf.valid & head_buf.refill_done & mlfb_mshr_dealloc_ready & 
                                  (~head_buf.ld_no_refill | (head_buf.ld_no_refill & ~head_buf.has_another_part)); // corner case, only critical part transfer, no valid data for rest part.
`else
assign pc_scu_resp_vld_o        = head_buf.valid & head_buf.refill_done & mlfb_mshr_dealloc_ready;
`endif
assign pc_scu_resp_o.id.cid     = CORE_ID;
assign pc_scu_resp_o.id.bid     = BANK_ID;
assign pc_scu_resp_o.id.pc_tid  = head_buf.mshr_idx;
assign pc_scu_resp_o.id.scu_tid = head_buf.scu_tid;
assign pc_scu_resp_o.rtype      = FinishTrans_Ack;

assign pc_scu_resp_o.src_id     = '0;
assign pc_scu_resp_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign pc_scu_resp_o.txn_id     = TxnID_Width'(pc_scu_resp_o.id);
`endif

`ifdef USE_QOS_VALUE
  assign pc_scu_resp_o.qos_value  = '0;
`endif
endmodule