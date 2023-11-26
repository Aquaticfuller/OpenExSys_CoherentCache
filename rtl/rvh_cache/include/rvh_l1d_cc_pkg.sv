`ifndef __RVH_L1D_CC_PKG_SV__
`define __RVH_L1D_CC_PKG_SV__

// `define LLC_DATA_RAM_MULTI_BANK   // LLC_DATA_RAM_BANK_NUM > 1
// `define LLC_TAG_RAM_MULTI_BANK    // LLC_TAG_RAM_BANK_NUM > 1

package rvh_l1d_cc_pkg;
import rvh_pkg::*;
import uop_encoding_pkg::*;
import rvh_noc_pkg::*;
import rvh_uncore_param_pkg::*;

  localparam SCU_REQ_BUFFER_DEPTH = VC_DEPTH_MAX;
  localparam SCU_REQ_BUFFER_DEPTH_W = $clog2(SCU_REQ_BUFFER_DEPTH) > 0 ? $clog2(SCU_REQ_BUFFER_DEPTH) : 1;
  localparam SCU_EVICT_BUFFER_DEPTH = VC_DEPTH_MAX;
  localparam SCU_EVICT_BUFFER_DEPTH_W = $clog2(SCU_EVICT_BUFFER_DEPTH) > 0 ? $clog2(SCU_EVICT_BUFFER_DEPTH) : 1;
  
  localparam L1D_BANK_ID_NUM_DUPL = 2; // need to be same as L1D_BANK_ID_NUM in rvh_l1d_pkg

  localparam CACHE_MASTERID_W  = $clog2(L1D_BANK_ID_NUM_DUPL) > 0 ? $clog2(L1D_BANK_ID_NUM_DUPL) : 1;
  localparam CACHE_TID_W       = L1D_MSHR_NUM > 1 ? $clog2(L1D_MSHR_NUM) : 1;
  localparam SCU_MASTERID_W    = 1;
  localparam SCU_TID_W         = $clog2(SCU_MSHR_NUM)+1;
  localparam PRIVATE_CACHE_NUM   = L1D_NUM; // 4 private cache / 4 core
  localparam PRIVATE_CACHE_NUM_W = $clog2(PRIVATE_CACHE_NUM) > 0 ? $clog2(PRIVATE_CACHE_NUM) : 1;



  `ifdef SYNTHESIS
  localparam LLC_SET_NUM    = 256; // sets
  localparam LLC_WAY_NUM    = 1;
  `else
  localparam LLC_SET_NUM    = 512; // sets
  localparam LLC_WAY_NUM    = 8;
  `endif
  localparam LLC_WAY_NUM_W  = $clog2(LLC_WAY_NUM) > 0 ? $clog2(LLC_WAY_NUM) : 1;
  localparam LLC_DATA_RAM_BANK_NUM  = 1;
  localparam LLC_TAG_RAM_BANK_NUM   = 1;

  localparam LLC_INDEX_WIDTH        = $clog2(LLC_SET_NUM);
  localparam LLC_OFFSET_WIDTH       = $clog2(DATA_LINE_W/8);
  localparam LLC_BIT_OFFSET_WIDTH   = $clog2(DATA_LINE_W);
  localparam LLC_TAG_WIDTH          = PADDR_WIDTH-LLC_INDEX_WIDTH-LLC_OFFSET_WIDTH;
  localparam LLC_LINE_ADDR_SIZE     = PADDR_WIDTH-LLC_OFFSET_WIDTH;

  // idx for each tag ram bank
  localparam LLC_PER_TAG_RAM_BANK_SET_NUM       = LLC_SET_NUM/LLC_TAG_RAM_BANK_NUM;
  localparam LLC_PER_TAG_RAM_BANK_INDEX_WIDTH   = $clog2(LLC_PER_TAG_RAM_BANK_SET_NUM);
  localparam LLC_TAG_RAM_BANK_NUM_WIDTH         = $clog2(LLC_TAG_RAM_BANK_NUM) > 0 ? $clog2(LLC_TAG_RAM_BANK_NUM) > 0 : 1;

  // idx for each data ram bank
  localparam LLC_PER_DATA_RAM_BANK_SET_NUM      = LLC_SET_NUM/LLC_DATA_RAM_BANK_NUM;
  localparam LLC_PER_DATA_RAM_BANK_INDEX_WIDTH  = $clog2(LLC_PER_DATA_RAM_BANK_SET_NUM);
  localparam LLC_DATA_RAM_BANK_NUM_WIDTH        = $clog2(LLC_DATA_RAM_BANK_NUM) > 0 ? $clog2(LLC_DATA_RAM_BANK_NUM) > 0 : 1;




  typedef struct packed {
    logic [PRIVATE_CACHE_NUM_W-1:0] cid;  // private cache id
    logic [CACHE_MASTERID_W:0]      bid;  // cache bank id, the highest used for distinguish i$/d$
    logic [CACHE_TID_W-1:0]         pc_tid;  // cache mshr id in req and req's resp
  } cache_cc_req_tid_t;
  
  typedef struct packed {
    logic [PRIVATE_CACHE_NUM_W-1:0] cid;  // private cache id
    logic [CACHE_MASTERID_W-1:0]    bid;  // cache bank id, the highest used for distinguish i$/d$
    logic [CACHE_TID_W-1:0]         pc_tid;  // cache mshr id in req and req's resp
    logic [SCU_TID_W-1:0]           scu_tid;  // scu mshr id in snp, msb to diff scu mshr / repl mshr
  } scu_cc_resp_tid_t;

  typedef struct packed {
    logic [PRIVATE_CACHE_NUM_W-1:0] cid;  // private cache id
    logic [SCU_TID_W-1:0]           scu_tid;  // scu mshr id in snp
  } scu_cc_snp_tid_t;

  typedef enum logic [2:0] {
    // requestor req
    ReadShared          = 3'b000, // I -> S/E
    ReadOnce            = 3'b001, // I -> I
    ReadUnique          = 3'b010, // I -> M
    CleanUnique         = 3'b011,  // S -> M
    // cache -> scu, evict req (act like a resp)
    Evict               = 3'b100,  // self: S/E -> I
    // cache -> scu, writeback
    WriteBackFull       = 3'b101,  // self: M -> I, return dirty data
    WriteBackPartial    = 3'b110   // self: M -> I, return dirty data, not whole line dirty, only return dirt part of the line
  } cache_scu_cc_req_type_e;

  typedef enum logic [0:0] {
    // snoop req
    SnpUnique           = 1'b0, // others: S/E/M -> I; leave snpee invalid line, only return dirty data
    SnpShared           = 1'b1  // others: E/M -> S; leave snpee sharedclean line, only return dirty data
  } cache_scu_cc_snp_type_e;

  typedef enum logic [2:0] {
    // cache -> scu (transaction resp ack)
    FinishTrans_Ack   = 3'b000,
    FinishTrans_Ack_I = 3'b001, // reqor: req a Cleanunique, but it was inv snped before it get Unique permission, so it kept to be invalid
    // cache -> scu, snp resp
    SnpAck_FoundI     = 3'b010,   // snpee: found I(the actual data must be on the evict/writeback transaction)
    SnpAck_FoundSorE  = 3'b011,   // snpee: found S/E, changed to I/S(based on the snp req type)
    // scu -> cache (writeback start data transfer ack)
    WriteBack_Ack     = 3'b100,
    // scu -> requestor cache, dataless resp
    Comp_UD           = 3'b101 // scu: give permission E to requestor, dataless, for CleanUnique 
    // RespSepData_I     = 4'b1000,   // scu: give permission I to requestor, data is not in this pkg. for ReadOnce
    // RespSepData_SC    = 4'b1001,   // scu: give permission S to requestor, data is not in this pkg. for ReadShared and already have sharer
    // RespSepData_UC    = 4'b1010,   // scu: give permission E to requestor, data is not in this pkg. for ReadShared without sharer and ReadUnique.
    // RespSepData_UD    = 4'b1011    // scu: give permission M to requestor, data is not in this pkg. for ReadUnique and llc doesn't keep dirty data copy, not used in this implementation
  } cache_scu_cc_resp_type_e;

  typedef enum logic [2:0] {
    // cache -> scu, writeback
    WriteBackFullData      = 3'b000,  // self: M -> I, return dirty data
    WriteBackPartialData   = 3'b001,  // self: M -> I, return dirty data, not whole line dirty, only return dirt part of the line
    // cache -> scu, snoop data resp
    SnpAck_FoundM          = 3'b010,  // snpee: found M, return dirty data
    // scu -> cache, data resp
    // DataSepResp         = 2'b11   // scu: send data to requestor before receive all snp resp
    CompData_I             = 3'b100,   // scu: give permission I to requestor, data is in this pkg. for ReadOnce
    CompData_SC            = 3'b101,   // scu: give permission S to requestor, data is in this pkg. for ReadShared and already have sharer
    CompData_UC            = 3'b110,   // scu: give permission E to requestor, data is in this pkg. for ReadShared without sharer and ReadUnique.`
    CompData_UD            = 3'b111    // scu: give permission M to requestor, data is in this pkg. for ReadUnique and llc doesn't keep dirty data copy, not used in this implementation
  } cache_scu_cc_data_type_e;

  // typedef enum logic [1:0] {
  //   // cache -> scu, evict req (act like a resp)
  //   Evict               = 2'b00,  // self: S/E -> I
  //   // cache -> scu, writeback
  //   WriteBackFull       = 2'b01,  // self: M -> I, return dirty data
  //   WriteBackPartial    = 2'b10   // self: M -> I, return dirty data, not whole line dirty, only return dirt part of the line
  // } cache_scu_cc_evict_type_e;



  // low bw channel definition
  typedef struct packed {
    cache_cc_req_tid_t        id;
    cache_scu_cc_req_type_e   rtype;
    logic [PADDR_WIDTH-1:0]   addr;

    node_id_t                   tgt_id; // target id
    node_id_t                   src_id; // source id
`ifdef ENABLE_TXN_ID
    logic [TxnID_Width-1:0]     txn_id; // transaction id
`endif

`ifdef SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY
    logic [DATA_BURST_NUM-1:0]  data_part_to_be_fully_write;
`endif

`ifdef USE_QOS_VALUE
    logic [QoS_Value_Width-1:0] qos_value;
`endif

  } cache_scu_cc_req_t;

  typedef struct packed {
    scu_cc_resp_tid_t         id;
    cache_scu_cc_resp_type_e  rtype;

    node_id_t                   tgt_id; // target id
    node_id_t                   src_id; // source id
`ifdef ENABLE_TXN_ID
    logic [TxnID_Width-1:0]     txn_id; // transaction id
`endif

`ifdef USE_QOS_VALUE
    logic [QoS_Value_Width-1:0] qos_value;
`endif
  } cache_scu_cc_resp_t;

  typedef struct packed {
    // logic [PRIVATE_CACHE_NUM-1:0] send_list;
    scu_cc_snp_tid_t          id;
    cache_scu_cc_snp_type_e   rtype;
    logic [PADDR_WIDTH-1:0]   addr;

    node_id_t                   tgt_id; // target id
    node_id_t                   src_id; // source id
`ifdef ENABLE_TXN_ID
    logic [TxnID_Width-1:0]     txn_id; // transaction id
`endif

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    logic                     data_resp_with_critical_word_first; // if there is a data resp, resp data with critical word first (for SCU_MSHR snp)
`endif

`ifdef USE_QOS_VALUE
    logic [QoS_Value_Width-1:0] qos_value;
`endif
  } cache_scu_cc_snp_t;

  // typedef struct packed {
  //   cache_cc_req_tid_t              id;
  //   logic [DATA_BURST_NUM_W-1:0]    data_id;
  //   logic [DATA_BURST_NUM_W-1:0]    total_data_num; // total data section number = total_data_num+1
  //   cache_scu_cc_data_type_e        rtype;
  //   logic [DATA_LENGTH_PER_PKG-1:0] data;
  // } cache_scu_cc_data_t;

  typedef struct packed {
    logic [DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0] data;
    logic [DATA_BURST_NUM-1:0]                          data_valid;
    logic [DATA_BURST_NUM-1:0]                          data_dirty;

    scu_cc_resp_tid_t                                   id;
    cache_scu_cc_data_type_e                            rtype;

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    logic                                               is_critical;      // it is common/critical part
    logic                                               has_another_part; // also has a critical/common part
`endif

    node_id_t                   tgt_id; // target id
    node_id_t                   src_id; // source id
`ifdef ENABLE_TXN_ID
    logic [TxnID_Width-1:0]     txn_id; // transaction id
`endif

`ifdef USE_QOS_VALUE
    logic [QoS_Value_Width-1:0] qos_value;
`endif
  } cache_scu_cc_data_t;


  // typedef struct packed {
  //   cache_cc_req_tid_t                  id;
  //   cache_scu_cc_evict_type_e        rtype;
  //   logic [PADDR_WIDTH-1:0]         addr;
  // } cache_scu_cc_evict_t;
  

  typedef struct packed {
    // owner bit
    logic                         has_owner;
    // sharer list
    logic [PRIVATE_CACHE_NUM-1:0] sharer_list;
  } scu_dir_entry_t;

  typedef struct packed {
    // valid bit
    logic                         valid;
    // dirty bit
    logic                         dirty;
  } scu_llc_line_state_t;

  // fusing the dir, owner, state bits with tag
  typedef struct packed {
    scu_dir_entry_t           dir;
    scu_llc_line_state_t      state;
    logic [LLC_TAG_WIDTH-1:0] tag;
  } scu_llc_fused_tag_entry_t;





  typedef struct packed {
    cache_scu_cc_req_t            req;
    logic                         no_need_alloc_new_mshr; // for evict/wb hit exist mshr/repl mshr
    logic                         is_evict_wb; // is a evict/wb req
  } scu_pipe_s0_t;

  typedef struct packed {
    cache_scu_cc_req_t            req;
    // scu_llc_line_state_t  [LLC_WAY_NUM-1:0] llc_line_state_for_chosen_set;
    // scu_dir_entry_t       [LLC_WAY_NUM-1:0] scu_dir_entry_for_chosen_set;
    logic                         no_need_alloc_new_mshr; // for evict/wb hit exist mshr/repl mshr
    logic                         is_evict_wb; // is a evict/wb req

  } scu_pipe_s1_t;

  // typedef struct packed {
  //   cache_scu_cc_req_t                      req;

  // } scu_pipe_s2_t;

  typedef struct packed {
    // stage 0
    scu_pipe_s0_t s0;
    // stage 1
    scu_pipe_s1_t s1;
    // // stage 2
    // scu_pipe_s2_t s2;
  } scu_pipe_reg_t;


  typedef struct packed {
    // mshr state bits
    logic                         llc_hit; // llc has valid and latest data
    logic                         dir_hit; // private cache(s) has valid and latest data

    // req from private cache
    cache_scu_cc_req_t            req;

    // wb req from private cache
    cache_cc_req_tid_t            wb_pc_id;
    cache_scu_cc_req_type_e       wb_rtype;
    
    // dir entry
    scu_dir_entry_t               dir_entry;

    // old line state
    scu_llc_line_state_t          state_entry;

    // tag compare result
    logic [LLC_WAY_NUM-1:0]       valid_tags_compare_result;

    // cache line data
    logic [DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0]   data;
    logic [DATA_BURST_NUM-1:0]                            data_valid;
    logic [DATA_BURST_NUM-1:0]                            data_dirty;
    logic [DATA_BURST_NUM_W-1:0]                          mem_resp_data_seg_wr_ptr;

    // snp resp receiving vector
    logic [PRIVATE_CACHE_NUM-1:0] snp_need_to_send_list;
    logic [PRIVATE_CACHE_NUM-1:0] snp_sent_list;
    logic [PRIVATE_CACHE_NUM-1:0] snp_resp_receiving_list; // all received snp resp
    logic [PRIVATE_CACHE_NUM-1:0] snp_data_receiving_list; // all received snp data
    logic [PRIVATE_CACHE_NUM-1:0] snp_resp_receiving_invalid_list; // received invalid snp resp. means it is evicted or writebacked
    logic [PRIVATE_CACHE_NUM-1:0] evict_resp_receiving_list; // received evict and wb req
    logic                         writeback_data_received;
    
    // control bits
    logic                         wait_for_wb_data_en;

    logic                         wait_for_mem_read_data_en;
    logic                         wait_for_llc_read_data_en;
    
    logic                         need_invalid_snp;
    logic                         need_shared_snp;

    logic                         final_update_enqueued; // before the mshr dealloc
    logic                         need_to_update_data; // before the mshr dealloc
    logic                         need_to_update_tag;  // before the mshr dealloc
    logic                         need_to_update_dir;  // before the mshr dealloc

    logic                         monitor_evict_before_update_dir;                  // for new dir sharer list
    logic                         monitor_evict_before_receiving_all_snp_resp;      // some snp resp may replaced by evict resp
    logic                         monitor_writeback_before_receiving_all_snp_resp;  // some snp resp may replaced by writeback data

    logic                         final_resp_enqueued;
    logic                         wait_for_resp_ack;
    logic                         the_permission_dropped; // the reqor dropped the permisson it got and remain invalid, used for CleanUnique but the clean data in reqor was invalidated

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    logic                         critical_received_wait_for_common; // only when critical part received and need to wait for common part, the mlfb should resp the critical word first transaction, other condition only need common refill transaction
    logic                         common_received_wait_for_critical; // rare: common part comes ahead of critical part, wait for critical part and do common refill transaction
    logic                         critical_part_resp_enqueued;
    logic                         critical_part_resp_done; // the critical part has been resp to core, no resp needed in common refill transaction
`endif

  } scu_mshr_t;

  typedef struct packed {
    // mshr state bits
    logic                         llc_hit; // llc has valid and latest data
    logic                         dir_hit; // private cache(s) has valid and latest data

    // req from private cache
    logic                         req;
    
    // wb req from private cache
    logic                         wb_pc_id;
    logic                         wb_rtype;

    // old dir entry
    logic                         dir_entry;

    // old line state
    logic                         state_entry;

    // tag compare result
    logic                         valid_tags_compare_result;

    // cache line data
    logic [DATA_BURST_NUM-1:0]    data;
    logic                         data_valid;
    logic                         data_dirty;
    logic                         mem_resp_data_seg_wr_ptr;


    // snp resp receiving vector
    logic                         snp_need_to_send_list;
    logic                         snp_sent_list;
    logic                         snp_resp_receiving_list;
    logic                         snp_data_receiving_list;
    logic                         snp_resp_receiving_invalid_list;
    logic                         evict_resp_receiving_list;
    logic                         writeback_data_received;
    
    // control bits
    logic                         wait_for_wb_data_en;

    logic                         wait_for_mem_read_data_en;
    logic                         wait_for_llc_read_data_en;
    
    logic                         need_invalid_snp;
    logic                         need_shared_snp;

    logic                         final_update_enqueued; // before the mshr dealloc
    logic                         need_to_update_data; // before the mshr dealloc
    logic                         need_to_update_tag; // before the mshr dealloc
    logic                         need_to_update_dir; // before the mshr dealloc

    logic                         monitor_evict_before_update_dir;                  // for new dir sharer list
    logic                         monitor_evict_before_receiving_all_snp_resp;      // some snp resp may replaced by evict resp
    logic                         monitor_writeback_before_receiving_all_snp_resp;  // some snp resp may replaced by writeback data

    logic                         final_resp_enqueued;
    logic                         wait_for_resp_ack;
    logic                         the_permission_dropped; // the reqor dropped the permisson it got and remain invalid, used for CleanUnique but the clean data in reqor was invalidated

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    logic                         critical_received_wait_for_common; // only when critical part received and need to wait for common part, the mlfb should resp the critical word first transaction, other condition only need common refill transaction
    logic                         common_received_wait_for_critical; // rare: common part comes ahead of critical part, wait for critical part and do common refill transaction
    logic                         critical_part_resp_enqueued;
    logic                         critical_part_resp_done; // the critical part has been resp to core, no resp needed in common refill transaction
`endif
  } scu_mshr_ena_t;


  typedef struct packed {
    // addr for the replaced line
    logic [PADDR_WIDTH-1:0]       addr;

    // wb req from private cache
    cache_cc_req_tid_t            wb_pc_id;
    cache_scu_cc_req_type_e       wb_rtype;
    
    // dir entry
    scu_dir_entry_t               dir_entry;

    // old line state
    scu_llc_line_state_t          state_entry;

    // tag compare result
    logic [LLC_WAY_NUM-1:0]       victim_way_chosen_result;

    // cache line data
    logic [DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0]   data;
    logic [DATA_BURST_NUM-1:0]                            data_valid;
    logic [DATA_BURST_NUM-1:0]                            data_dirty;
    // logic [DATA_BURST_NUM_W-1:0]                          mem_req_data_seg_wr_ptr;

    // snp resp receiving vector
    logic [PRIVATE_CACHE_NUM-1:0] snp_need_to_send_list;
    logic [PRIVATE_CACHE_NUM-1:0] snp_sent_list;
    logic [PRIVATE_CACHE_NUM-1:0] snp_resp_receiving_list; // all received snp resp
    logic [PRIVATE_CACHE_NUM-1:0] snp_data_receiving_list; // all received snp data
    logic [PRIVATE_CACHE_NUM-1:0] snp_resp_receiving_invalid_list; // received invalid snp resp. means it is evicted or writebacked
    logic [PRIVATE_CACHE_NUM-1:0] evict_resp_receiving_list; // received evict and wb req
    logic                         writeback_data_received;
    
    // control bits
    logic                         wait_for_wb_data_en;

    logic                         wait_for_llc_read_data_en;
    
    logic                         need_invalid_snp;

    logic                         final_update_enqueued; // before the mshr dealloc
    logic                         need_to_update_tag;  // before the mshr dealloc
    logic                         need_to_update_dir;  // before the mshr dealloc

    logic                         monitor_evict_before_update_dir;                  // for new dir sharer list
    logic                         monitor_evict_before_receiving_all_snp_resp;      // some snp resp may replaced by evict resp
    logic                         monitor_writeback_before_receiving_all_snp_resp;  // some snp resp may replaced by writeback data

    logic                         dirty_writeback_mem_enqueued; // dirty writeback to mem has enqueued or no need
    logic                         dirty_writeback_mem_done; // dirty writeback to mem has done or no need
  } scu_repl_mshr_t;

  typedef struct packed {
    // addr for the replaced line
    logic                         addr;

    // wb req from private cache
    logic                         wb_pc_id;
    logic                         wb_rtype;

    // old dir entry
    logic                         dir_entry;

    // old line state
    logic                         state_entry;

    // tag compare result
    logic                         victim_way_chosen_result;

    // cache line data
    logic [DATA_BURST_NUM-1:0]    data;
    logic                         data_valid;
    logic                         data_dirty;
    // logic                         mem_req_data_seg_wr_ptr;


    // snp resp receiving vector
    logic                         snp_need_to_send_list;
    logic                         snp_sent_list;
    logic                         snp_resp_receiving_list;
    logic                         snp_data_receiving_list;
    logic                         snp_resp_receiving_invalid_list;
    logic                         evict_resp_receiving_list;
    logic                         writeback_data_received;
    
    // control bits
    logic                         wait_for_wb_data_en;

    logic                         wait_for_llc_read_data_en;
    
    logic                         need_invalid_snp;

    logic                         final_update_enqueued; // before the mshr dealloc
    logic                         need_to_update_tag; // before the mshr dealloc
    logic                         need_to_update_dir; // before the mshr dealloc

    logic                         monitor_evict_before_update_dir;                  // for new dir sharer list
    logic                         monitor_evict_before_receiving_all_snp_resp;      // some snp resp may replaced by evict resp
    logic                         monitor_writeback_before_receiving_all_snp_resp;  // some snp resp may replaced by writeback data

    logic                         dirty_writeback_mem_enqueued; // dirty writeback to mem has enqueued or no need
    logic                         dirty_writeback_mem_done; // dirty writeback to mem has done or no need
  } scu_repl_mshr_ena_t;
endpackage

`endif