package rrv64_uncore_typedef_pkg;
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    
    /////////////////////////////////////coherence////////////////////////
    /////////////////////////////////////////////////////////////////////////////////// 
    typedef enum logic[1:0] {
        INVALID,
        SHARED,
        EXCLUSIVE,
        MODIFIED
    }rrv64_mesi_type_e;
    
    typedef enum logic[3:0]{
        READ_NSD,
        READ_UNIQ,
        CLEAN_UNIQ,
        WRITE_BACK,
        EVICT,
        WRITE_CLEAN,
        //acp
        READ_ONCE,
        WRITE_LUNIQ, //TODO: WRITE_UNIQ
        WRITE_UNIQ,
        //cache maintainence
        CLEAN_SHARED, //clean
        CLEAN_INV, //flush
        MAKE_INV //invalid
    }rrv64_ace_req_type_e;
    
    //CMO
    typedef enum logic[3:0]{
        RRV64_CMO_FLUSH_ALL,
        RRV64_CMO_FLUSH_VA,
        RRV64_CMO_FLUSH_WAY_SET,
        RRV64_CMO_INV_ALL,
        RRV64_CMO_INV_VA,
        RRV64_CMO_INV_WAY_SET,
        RRV64_CMO_CLEAN_ALL,
        RRV64_CMO_CLEAN_VA,
        RRV64_CMO_CLEAN_WAY_SET
    
    }rrv64_cmo_req_type_t;
    typedef struct packed{
       rrv64_cmo_req_type_t       opcode;
       logic[PHY_ADDR_WIDTH -1:0]  addr;
       logic[12:0]        set_idx;
       logic[2:0]         way_idx;
    }rrv64_cmo_req_t;
    
    
    //tcm intf
    typedef struct packed {
    logic valid;
    logic[OUT_UNCORE_AXI_S_TCM_RID_WIDTH -1:0] id;
    logic req_type;
    logic[OUT_UNCORE_AXI_S_TCM_RADDR_WIDTH -1:0] paddr;
    logic[2:0] user;
    logic[2:0] burst_cnt;
    logic[2:0] req_size;
    logic[64* 4-1:0] wr_all_mask;
    logic[64* 4-1:0] wr_all_data;
    logic[2:0] wcnt;
    logic write_done;
    logic[2:0] trans_burst_cnt;
    logic trans_burst_done;
    logic[2:0] trans_resp_burst_cnt;
    logic trans_resp_burst_done;
    logic[64* 4-1:0] rdata;
    logic rd_err;
    } rrv64_tcm_req_buf_t;
    
    typedef struct packed {
    logic[RRV64_TCM_IDX_W-1:0]  id;
    logic req_type;
    logic[2:0] req_size;
    logic[OUT_UNCORE_AXI_S_TCM_RADDR_WIDTH -1:0] paddr;
    logic[63:0] wr_data;
    logic[63:0] wr_mask;
    } rrv64_tcm_req_t;
    
    typedef struct packed{
    logic[RRV64_TCM_IDX_W -1:0] id;
    logic[63:0] rdata;
    logic err;
    } rrv64_tcm_resp_t;
    
    
    //acp intf
    typedef struct packed {
    logic  valid;
    logic[OUT_UNCORE_AXI_S_ACP_RID_WIDTH -1:0] id;
    rrv64_ace_req_type_e req_type;
    logic[OUT_UNCORE_AXI_S_ACP_RADDR_WIDTH -1:0] paddr;
    logic[RRV64_LINE_DATA_W-1:0] wr_line_mask;
    logic[RRV64_LINE_DATA_W-1:0] wr_line_data;
    logic[2:0] rcnt;
    logic[2:0] wcnt;
    logic write_done;
    logic trans_start;
    logic[2:0] trans_resp_burst_cnt;
    logic trans_done;
    logic[RRV64_LINE_DATA_W-1:0] rdata;
    logic rd_err;
    } rrv64_acp_req_buf_t;
    
    //scu
    typedef struct packed{
    logic[RRV64_SCU_SF_TAG_W -1:0] tag;
    logic[RRV64_SCU_SF_SET_IDX_W -1:0] set_idx;
    }rrv64_scu_line_addr_t;
    typedef struct packed{
    rrv64_scu_line_addr_t line_addr;
    logic[RRV64_LINE_OFFSET_W -1:0] offset;
    }rrv64_scu_paddr_t;
    
    typedef struct packed{
    logic[RRV64_ACP_IDX_W -1:0] acp_id;
    rrv64_ace_req_type_e req_type;
    rrv64_scu_paddr_t paddr;
    logic[RRV64_LINE_DATA_W-1:0] wr_line_data;
    logic[RRV64_LINE_DATA_W-1:0] wr_line_mask;
    } rrv64_acp_req_t;
    
    typedef struct packed {
    logic[RRV64_ACP_IDX_W -1:0] acp_id;
    logic[RRV64_LINE_DATA_W-1:0] rdata;
    logic err;
    } rrv64_acp_resp_t;
    typedef struct packed{
    logic[RRV64_L1D_STB_IDX_W-1:0] l1d_coh_id;
    rrv64_ace_req_type_e req_type;
    rrv64_scu_paddr_t paddr;
    }rrv64_l1d_scu_coh_req_t;
    
    typedef struct packed{ 
            logic[RRV64_L1D_STB_IDX_W-1:0] l1d_coh_id;
            // logic[SCU_SST_IDX_W-1:0] sst_id; TBD
           } rrv64_l1d_scu_coh_resp_t;
    
    typedef struct packed{
    logic[RRV64_SCU_SST_IDX_W -1:0] sst_idx;
    } rrv64_l1d_scu_coh_ack_t;
    
    typedef struct packed {
    logic[RRV64_CORE_IDX_W -1:0] core_idx;
    logic[RRV64_SCU_SST_IDX_W -1:0] sst_idx;
    }rrv64_scu_snp_id_t;
    
    typedef struct packed {
    logic[RRV64_CORE_N -1:0]        core_idx_oh;
    logic[RRV64_SCU_SST_IDX_W -1:0] sst_idx;
    logic[RRV64_L2_MSHR_IDX_W -1:0] l2_rd_id;
    }rrv64_scu_l3_rd_id_t;
    typedef struct packed{  
    rrv64_scu_snp_id_t scu_id;
    rrv64_ace_req_type_e req_type;
    rrv64_l1d_addr_t paddr;
    logic is_ovfl_ev;
    } rrv64_scu_snp_req_t;
    
    typedef struct packed {
    rrv64_scu_snp_id_t scu_id;
    logic is_dirty;
    logic has_dat;
    logic has_err;
    logic[RRV64_BUS_DATA_W-1:0] resp_data;
    logic is_cu;
    logic is_ovfl_ev;
    } rrv64_scu_snp_resp_seg_t;
    
    typedef struct packed{
    rrv64_scu_snp_id_t scu_id;
    logic is_dirty;
    logic has_dat;
    logic has_err;
    logic[RRV64_LINE_DATA_W-1:0] resp_data;
    rrv64_l1d_addr_t paddr;
    logic is_cu;
    logic is_ovfl_ev;
    } rrv64_scu_snp_resp_full_t;
    
    typedef struct packed {
    rrv64_scu_snp_id_t scu_id;
    logic is_dirty;
    logic has_dat;
    logic has_err;
    logic[RRV64_LINE_DATA_W-1:0] resp_data;
    logic is_cu;
    logic is_ovfl_ev;
    } rrv64_scu_snp_resp_t;
    
    typedef struct packed {
    logic[RRV64_SCU_SRQ_ID_W -1:0] scu_id;
    logic remote_miss;
    logic is_dirty;
    logic has_dat;
    logic has_err;
    logic inv_done;
    logic[RRV64_LINE_DATA_W-1:0] resp_data;
    rrv64_l1d_addr_t paddr;
    } rrv64_scu_l1d_snp_resp_t;
    
    typedef struct packed{ 
    logic[RRV64_SCU_SRQ_ID_W -1:0] scu_id;
    logic remote_miss;
    logic is_dirty;
    logic has_dat;
    logic has_err;
    logic inv_done;
    logic[RRV64_BUS_DATA_W -1:0] resp_data;
    } rrv64_scu_l1d_resp_t; 
    
    typedef struct packed{
    logic[RRV64_L1D_MSHR_IDX_W-1:0] id;
    logic[2:0] len;
    logic[2:0] size;
    logic[RRV64_LINE_ADDR_W -1:0] addr;
    logic is_st;
    }rrv64_l1d_l2_ar_t;
    
    typedef struct packed {
    logic[RRV64_L1D_MSHR_IDX_W-1:0] id;
    logic[RRV64_BUS_DATA_W -1:0] dat;
    logic err;
    rrv64_mesi_type_e mesi_sta;
    logic[RRV64_SCU_SST_IDX_W-1:0] sst_idx;
    logic l2_hit;
    }rrv64_l1d_l2_r_t;//l2 回给 l1 的数据
    
    typedef struct packed{
    logic[RRV64_L1D_MSHR_IDX_W-1:0] id;
    logic[2:0] len;
    logic[2:0] size;
    logic[RRV64_LINE_ADDR_W -1:0] addr;
    rrv64_mesi_type_e mesi_sta;
    }rrv64_l1d_l2_aw_t;
    
    typedef struct packed {
    logic[RRV64_L1D_MSHR_IDX_W-1:0]  id;
    logic[RRV64_BUS_DATA_W -1:0] dat;
    }rrv64_l1d_l2_w_t;
    
    
    //L2 coherence intf
    typedef struct packed {
    logic[RRV64_L2_MSHR_IDX_W-1:0] l2_rd_id;
    logic is_dc;
    rrv64_ace_req_type_e req_type;
    rrv64_scu_paddr_t paddr;
    } rrv64_l2_scu_rd_coh_req_t;
    
    typedef struct packed{
    logic[ RRV64_L2_MSHR_IDX_W -1:0] l2_rd_id;
    logic[RRV64_SCU_SST_IDX_W -1:0] sst_id;
    logic[RRV64_LINE_DATA_W -1:0] resp_data;
    logic err;
    rrv64_mesi_type_e             mesi_sta;
    } rrv64_l2_scu_rd_coh_resp_t;
    
    typedef struct packed{ 
    logic[RRV64_SCU_SST_IDX_W -1:0] sst_id;
    }rrv64_l2_scu_rd_coh_ack_t;
    
    typedef struct packed{  
    logic[RRV64_L2_EWRQ_IDX_W -1:0] l2_wr_id;
    rrv64_ace_req_type_e req_type;
    rrv64_scu_paddr_t paddr;
    logic[RRV64_LINE_DATA_W-1:0] wdata;
    }rrv64_l2_scu_wr_coh_req_t;
    
    //snoop intf
    ////////////////////////////// 
    //////////RRV64_L1D//////////////
    ///////////////////////
    typedef enum logic[2:0]{
        AMOSWAP, AMOADD, AMOAND, AMOOR, AMOXOR, AMOMAX, AMOMIN
    }l1d_amo_type_e;
    
    typedef struct packed {
    logic is_ld;
    logic is_st;
    logic is_amo;
    l1d_amo_type_e amo_type;
    logic is_lr;
    logic is_sc;
    logic op_b;
    logic op_hw;
    logic op_w;
    logic op_dw;
    logic ld_u;
    }rrv64_l1d_req_type_dec_t;
    
    // typedef struct packed{ 
    // logic[RRV64_L1D_TCM_BK_IDX_W-1:0] bnk_idx;
    // logic[RRV64_L1D_TCM_ENT_IDX_W-1:0] ent_idx;
    // logic[RRV64_L1D_TCM_DATA_IDX_W-1:0] seg_idx;
    // logic[ RRV64_L1D_TCM_OFFSET_W-1:0] offset;
    // }rrv64_l1d_tcm_addr_t;
    
    
    // typedef struct packed{ 
    // rrv64_l1d_tcm_addr_t paddr;
    // logic[63:0] st_dat;
    // rrv64_l1d_req_type_dec_t lsu_req_type_dec;
    // }rrv64_l1d_tcm_amo_req_t;
    
    typedef struct packed {
    logic[RRV64_L1D_TAG_W-1:0] tag;
    logic[ RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[ RRV64_L1D_WAY_IDX_W -1:0] way_idx;
    }rrv64_l1d_cmo_req_t;
    
    typedef struct packed {
    logic[RRV64_L1D_TAG_W-1:0] tag;
    logic[RRV64_LINE_DATA_W + RRV64_L1D_DATA_ECC_W * RRV64_L1D_WAY_N -1:0] dat;
    logic[RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L1D_WAY_IDX_W -1:0] way_idx;
    rrv64_mesi_type_e mesi_sta;
    logic[RRV64_L1D_DATA_ECC_W-1:0] dat_ecc_ckbit;
    logic [RRV64_L1D_TAG_ECC_W-1:0] tag_ecc_ckbit;
    }rrv64_l1d_refill_req_t;
    
   typedef struct packed {
    logic[RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L1D_WAY_IDX_W -1:0] way_idx;
   } rrv64_l1d_evict_req_t;

    typedef struct packed{
    rrv64_l1d_req_type_dec_t lsu_req_type_dec;
    rrv64_lsu_l1d_req_t lsu_req;
    }rrv64_lsu_io_req_t;
    
    typedef struct packed{
    rrv64_lsu_io_req_t io_req;
    logic trans_start;
    logic trans_done;
    logic valid;
    }rrv64_lsu_io_t;
    
    typedef struct packed {
    rrv64_mesi_type_e mesi_sta;
    }rrv64_l1d_lst_way_t;
    
    typedef struct packed{
        rrv64_l1d_lst_way_t[3:0] way_sta;
    }rrv64_l1d_lst_t;

    parameter LDQID_WIDTH = RRV64_LSU_ID_WIDTH;

   typedef struct packed {
    logic is_lsu_rd;
    logic is_lsu_ldq_rd;
    logic is_ptw_rd;
    logic is_prefetch;
    logic is_amo;
    logic [LDQID_WIDTH -1:0] lsu_rd_id;
    logic [RRV64_ROB_ADDR_W -1:0] lsu_rd_rob_id;
    logic [RRV64_INT_PHY_REG_ADDR_W-1:0] ld_rd_idx;
    lsu_op_e lsu_rd_req_type;
    rrv64_l1d_req_type_dec_t lsu_rd_req_type_dec;
    logic is_evict;
    logic is_snp_rd_1st;
    logic is_snp_rd_2nd;
    logic[RRV64_L1D_STB_IDX_W -1:0] stb_id;
    logic is_stb_rd;
    logic[RRV64_L1D_TAG_W -1:0] tag;
    logic[RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L1D_WAY_IDX_W -1:0] way_idx;
    logic[RRV64_LINE_OFFSET_W -1:0] offset;
    rrv64_l1d_lst_t   lst_sta;
   } rrv64_l1d_pipe_pkt_s1_t;
    

    typedef struct packed {
    logic is_lsu_rd;
    logic is_lsu_ldq_rd;
    logic is_ptw_rd;
    logic is_prefetch;
    logic is_amo;
    logic [LDQID_WIDTH -1:0] lsu_rd_id;
    logic [RRV64_ROB_ADDR_W -1:0] lsu_rd_rob_id;
    logic [RRV64_INT_PHY_REG_ADDR_W-1:0] ld_rd_idx;
    lsu_op_e lsu_rd_req_type;
    rrv64_l1d_req_type_dec_t lsu_rd_req_type_dec;
    logic is_evict;
    logic is_snp_rd_1st;
    logic is_snp_rd_2nd;
    logic[RRV64_L1D_STB_IDX_W -1:0] stb_id;
    logic is_stb_rd;
    logic[RRV64_L1D_TAG_W -1:0] tag;
    logic[RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L1D_WAY_IDX_W -1:0] way_idx;
    logic[RRV64_LINE_OFFSET_W -1:0] offset;
    logic[55:0] paddr;
    logic       cache_set_full;
    logic[(RRV64_L1D_TAG_W+RRV64_L1D_TAG_ECC_W) * RRV64_L1D_WAY_N-1:0] tram_rdat_all;
    logic[(RRV64_LINE_DATA_W+ RRV64_L1D_WAY_N* RRV64_L1D_DATA_ECC_W)-1:0] dram_rdat_all;
    rrv64_l1d_lst_t lst_sta;
    logic[RRV64_L1D_WAY_N -1:0] tag_ecc_1bit_err;
    logic[RRV64_L1D_WAY_N -1:0] tag_ecc_2bit_err;
    logic[RRV64_L1D_WAY_N -1:0] data_ecc_1bit_err;
    logic[RRV64_L1D_WAY_N -1:0] data_ecc_2bit_err;
    logic                       stb_full_hit_s1;
   } rrv64_l1d_pipe_pkt_s2_t;

    typedef struct packed {
    logic valid;
    rrv64_l1d_addr_t paddr;
    logic stb_alloc;
    logic dat_start;
    logic dat_done;
    } rrv64_l1d_mshr_t;

   typedef struct packed {
    rrv64_l1d_req_type_dec_t lsu_req_type_dec;
    rrv64_l1d_addr_t paddr;
    logic[63:0] st_dat;
   } rrv64_l1d_stb_req_t;

   typedef struct packed {
    logic[RRV64_L1D_STB_IDX_W -1:0] id;
    rrv64_l1d_addr_t paddr;
   } rrv64_l1d_stb_cache_rd_req_t;

  typedef struct packed {
    logic[RRV64_L1D_STB_IDX_W -1:0] id;
    logic cache_hit;
    logic[RRV64_L1D_WAY_IDX_W -1:0] cache_hit_way_idx;
    rrv64_mesi_type_e cache_hit_mesi;
    rrv64_l1d_addr_t paddr;
  } rrv64_l1d_cache_stb_rd_resp_t;

 typedef struct packed {
    logic[RRV64_LINE_DATA_W/RRV64_L1D_WAY_N + RRV64_L1D_DATA_ECC_W -1:0] dat;
    logic[RRV64_L1D_WAY_IDX_W -1:0] way_idx;
    logic[RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L1D_TAG_W + RRV64_L1D_TAG_ECC_W-1 :0] tag;
    logic[RRV64_LINE_OFFSET_W -1:0] offset;
    logic                           tag_wen;
 } rrv64_l1d_stb_cache_wr_req_t;

typedef struct packed {
    logic valid;
    rrv64_l1d_addr_t paddr;
    rrv64_l1d_req_type_dec_t lsu_req_type_dec;
    logic[63:0] st_dat;
    logic cache_rd_start;
    logic cache_rd_done;
    rrv64_l1d_cache_stb_rd_resp_t cache_rd_done_info;
    logic mshr_rd_start;
    logic mshr_rd_done;
    rrv64_l1d_cache_stb_rd_resp_t mshr_rd_done_info;
    logic line_dat_done;
    logic [RRV64_LINE_DATA_W/RRV64_L1D_WAY_N-1:0] line_dat;
    logic [RRV64_LINE_DATA_W/RRV64_L1D_WAY_N-1:0] line_dat_mask;
    logic merge_timeout;
    logic coh_start;
    logic coh_done;
    logic snp_change_i;
    logic cache_miss_real;   
}rrv64_l1d_stb_t ;

typedef struct packed {
    rrv64_mesi_type_e mesi_sta;
    logic[RRV64_LINE_ADDR_W -1:0] evict_addr;
    logic[RRV64_LINE_DATA_W -1:0] evict_dat;
} rrv64_l1d_ewrq_req_t;

typedef struct packed {
    logic                         valid;
    rrv64_l1d_ewrq_req_t              ewrq_req;
} rrv64_l1d_ewrq_t;

// typedef struct packed {
//     logic [RRV64_L1D_MSHR_IDX_W-1:0] mshr_idx;
//     logic                            err;
//     rrv64_mesi_type_e                mesi_sta;
//     logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
//     logic                            l2_hit;
//     logic                            merge_ld_valid;
// } rrv64_l1d_mlfb_t;

// typedef struct packed {
//     logic                             valid;
//     logic [RRV64_L1D_MSHR_IDX_W -1:0] mshr_idx;
//     logic                             err;
//     rrv64_mesi_type_e                 mesi_sta;
//     rrv64_l1d_addr_t                  paddr;
//     logic                             peek_done;
//     logic                             check_done;
//     logic                             evict_done;
//     logic                             refill_done;
//     logic                             stb_dat_done;
//     logic  [RRV64_LINE_DATA_W -1:0]   line_dat;
//     logic  [RRV64_L1D_DATA_ECC_W* RRV64_L1D_WAY_N -1:0] dat_ecc_ckbit;
//     logic  [RRV64_L1D_TAG_ECC_W -1:0] tag_ecc_ckbit;
//     logic  [RRV64_L1D_WAY_IDX_W -1:0] avail_way_idx;
//     logic  [RRV64_L1D_WAY_IDX_W -1:0] victim_way_idx;
//     logic                             victim_set_full;
//     logic  [RRV64_SCU_SST_IDX_W -1:0] sst_idx;
//     logic                             stb_alloc;
//     logic                             l2_hit;
// } rrv64_l1d_mlfb_head_buf_t;

typedef struct packed {
    logic[RRV64_L1D_WAY_IDX_W -1:0] way_idx;
    logic[RRV64_L1D_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L1D_TAG_W + RRV64_L1D_TAG_ECC_W-1 :0] tag;
    logic[RRV64_LINE_DATA_W/RRV64_L1D_WAY_N + RRV64_L1D_DATA_ECC_W -1:0] data;
    logic[RRV64_LINE_OFFSET_W-1:0] offset;
    logic                          tag_wen;
    logic                          data_wen;
} rrv64_l1d_ecc_wb_req_t;

typedef struct packed {
    logic is_ld;
    logic is_st;
    logic is_amo;
    l1d_amo_type_e amo_type;
    logic is_lr;
    logic is_sc;
    logic is_u;
    logic[2:0] size;
    logic is_nc;
    logic is_ns;
    logic [PHY_ADDR_WIDTH -1:0] addr;
    logic [RRV64_INT_REG_DATA_W-1:0] wdata;
    logic [RRV64_INT_REG_DATA_W/8 -1:0] wstrb;
} rrv64_l1d_io_req_t;

typedef struct packed {
    logic [RRV64_INT_REG_DATA_W -1:0] rdata;
    logic err;
    logic wr_done;
} rrv64_l1d_io_resp_t;

//L1D prefetch
typedef struct packed {
    logic valid;
    logic [(PF_ADDR_WIDTH -1):0] base;
    logic [(PF_TRACK_TABLE_OFFSET_WIDTH):0] offset;
} rrv64_prefetch_track_table_t;
typedef struct packed {
    logic [(PF_TRACK_TABLE_DEPTH-1):0][($clog2(PF_TRACK_TABLE_DEPTH) - 1):0] last_point;
    logic [(PF_TRACK_TABLE_DEPTH-1):0][($clog2(PF_TRACK_TABLE_DEPTH) - 1):0] next_point;
    logic [($clog2(PF_TRACK_TABLE_DEPTH) - 1):0] head;
    logic [($clog2(PF_TRACK_TABLE_DEPTH) - 1):0] tail;
} rrv64_prefetch_track_table_lru_t;

typedef struct packed {
    logic [RRV64_L3_TAG_W -1:0] tag;
    logic [RRV64_L3_SET_IDX_W -1:0] set_idx;
    logic                           bank_idx;
    logic [RRV64_L3_WAY_IDX_W -1:0] way_idx;
} rrv64_l3_cmo_req_t;

typedef struct packed {
    logic [RRV64_L3_TAG_W -1:0] tag;
    logic                       bank_idx;
    logic[RRV64_L3_SET_IDX_W -1:0] set_idx;
} rrv64_l3_line_addr_t;

typedef struct packed {
    rrv64_l3_line_addr_t        line_addr;
    logic[RRV64_LINE_OFFSET_W -1:0] offset;
} rrv64_l3_addr_t;

typedef struct packed {
    rrv64_scu_l3_rd_id_t scu_id;
    rrv64_l3_addr_t      paddr;
} rrv64_scu_l3_rd_req_t;

typedef struct packed {
    logic[RRV64_L3_WR_ID_W -1:0]  scu_id;
    rrv64_l3_addr_t               paddr;
    logic[RRV64_LINE_DATA_W -1:0] wr_dat;
} rrv64_scu_l3_wr_req_t; 

typedef struct packed {
    rrv64_scu_l3_rd_id_t  scu_id;
    logic[RRV64_LINE_DATA_W -1:0] rdata;
    logic                         err;
} rrv64_scu_l3_rd_resp_t;

    
    typedef struct packed {
        rrv64_scu_l3_rd_id_t scu_id;
    } rrv64_scu_l3_wr_resp_t;
    
    typedef struct packed {
        logic[RRV64_L3_MSHR_IDX_W-1:0] id;
        logic[7:0] len;
        logic[2:0] size;
        logic[RRV64_LINE_ADDR_W-1:0] addr;
    }rrv64_l3_out_ar_t;
    
    typedef struct packed{
    logic [RRV64_L3_MSHR_IDX_W-1:0] id;
    logic [RRV64_OUT_BUS_DATA_W-1:0] dat;
    logic err;
    logic last;
    }rrv64_l3_out_r_t;
    
    typedef struct packed {
        logic [7:0] len;
        logic[2:0] size;
        logic[RRV64_LINE_ADDR_W-1:0] addr;
    }rrv64_l3_out_aw_t;
    
    typedef struct packed{
        logic[RRV64_OUT_BUS_DATA_W-1:0] dat;
        logic wlast;
    }rrv64_l3_out_w_t;
    
    typedef struct packed {
        logic err;
    }rrv64_l3_out_b_t;
    //wr reg req
    typedef struct packed {
        rrv64_scu_l3_wr_req_t wr_req;
        logic wr_2nd;
        logic[RRV64_L3_WAY_IDX_W -1:0] wr_2nd_way_idx;
    }rrv64_scu_l3_wr_reg_req_t; 
    
    
    
    typedef struct packed{
        logic[RRV64_L3_SET_IDX_W-1:0] set_idx;
        logic bank_idx;
        logic[RRV64_L3_WAY_IDX_W-1:0] way_idx;
    }rrv64_l3_evict_req_t;
    
    typedef struct packed {
    logic[RRV64_L3_TAG_W-1:0] tag;
    logic[RRV64_LINE_DATA_W-1:0] dat;
    logic[RRV64_L3_SET_IDX_W -1:0] set_idx;
    logic[RRV64_L3_WAY_IDX_W -1:0] way_idx;
    logic[RRV64_L3_DATA_ECC_W -1:0] dat_ecc_ckbit;
    logic[RRV64_L3_TAG_ECC_W -1:0] tag_ecc_ckbit;
    } rrv64_l3_refill_req_t;
    
    
    typedef struct packed {
        logic dirty;
        logic valid;
    }rrv64_l3_lst_way_t;
    
    typedef struct packed{ 
        rrv64_l3_lst_way_t[RRV64_L3_WAY_N-1:0] way_sta;
    }rrv64_l3_lst_t; 
    
    typedef struct packed{
    logic is_scu_rd;
    logic is_scu_wr;
    logic is_evict;
    rrv64_l3_evict_req_t evict_req;
    rrv64_scu_l3_rd_req_t scu_rd_req;
    rrv64_scu_l3_wr_reg_req_t scu_wr_req;
    logic is_refill;
    rrv64_l3_refill_req_t refill_req;
    // logic is_flush;
    // logic is_flush_all;
    logic[RRV64_L3_WAY_IDX_W -1:0] scu_wr_avail_way_idx;
    logic[RRV64_L3_WAY_IDX_W -1:0] scu_wr_victim_way_idx;
    rrv64_l3_lst_t lst_sta;
    } rrv64_l3_pipe_pkt_s1_t;
    
    
    
    typedef struct packed {
    logic is_scu_rd;
    logic is_scu_wr;
    logic is_evict;
    rrv64_l3_evict_req_t evict_req;
    rrv64_scu_l3_rd_req_t scu_rd_req;
    rrv64_scu_l3_wr_reg_req_t scu_wr_req;
    logic is_refill;
    rrv64_l3_refill_req_t refill_req;
    
    logic[RRV64_L3_WAY_N-1:0] cache_hit_way;
    logic[RRV64_L3_WAY_IDX_W-1:0] cache_hit_way_idx;
    logic cache_hit;
    logic cache_miss;
    logic[RRV64_LINE_ADDR_W-1:0] evict_addr;
    logic cache_ecc_2bit_err;
    rrv64_l3_lst_way_t cache_hit_lst_sta;
    
    // logic[RRV64_L3_WAY_IDX_W-1:0] scu_wr_avail_way_idx;
    logic[RRV64_L3_WAY_IDX_W-1:0] scu_wr_victim_way_idx;
    logic scu_wr_victim_way_is_dirty;
    logic scu_wr_set_full;
    }rrv64_l3_pipe_pkt_s2_t;
    
    typedef struct packed {
    logic is_scu_rd;
    logic is_scu_wr;
    logic is_evict;
    rrv64_l3_evict_req_t evict_req;
    rrv64_scu_l3_rd_req_t scu_rd_req;
    rrv64_scu_l3_wr_reg_req_t scu_wr_req;
    
    // logic[RRV64_L3_WAY_IDX_W-1:0] cache_hit_way_idx;
    logic[RRV64_LINE_ADDR_W-1:0] evict_addr;
    logic cache_bk_sel;
    // logic[RRV64_LINE_DATA_W-1:0] cache_hit_dat_selected;
    logic cache_hit;
    //logic cache_miss;
    logic cache_ecc_2bit_err;
    }rrv64_l3_pipe_pkt_s3_t;
    
    typedef struct packed{
    rrv64_scu_l3_rd_req_t scu_req;
    } rrv64_l3_mshr_req_t;
    
    typedef struct packed {
    logic valid;
    rrv64_l3_mshr_req_t mshr_req;
    logic dat_start;
    logic[RRV64_L3_BK_N-1:0] scu_rd_same_addr;
    logic[RRV64_L3_BK_N-1:0] scu_wr_same_set_addr;
    } rrv64_l3_mshr_t;
    
    typedef struct packed {
    logic[RRV64_LINE_ADDR_W -1:0] evict_addr;
    logic[RRV64_LINE_DATA_W -1:0] evict_dat;
    } rrv64_l3_ewrq_req_t;
    
    typedef struct packed {
    logic valid;
    logic[RRV64_L3_BK_N -1:0] scu_rd_same_addr;
    logic[RRV64_L3_BK_N -1:0] scu_rd_same_addr_s1;
    logic[RRV64_L3_BK_N -1:0] scu_wr_same_addr;
    logic[RRV64_L3_BK_N -1:0] scu_wr_same_addr_s1;
    rrv64_l3_ewrq_req_t ewrq_req;
    }rrv64_l3_ewrq_t;
    
    typedef struct packed {
    logic[RRV64_L3_MSHR_IDX_W-1:0] mshr_idx;
    logic err;
    } rrv64_l3_mlfb_t;
    
    typedef struct packed{
    logic valid;
    logic peek_done;
    logic evict_done;
    logic refill_done;
    logic scu_resp_done;
    logic[RRV64_LINE_DATA_W-1:0] line_dat;
    rrv64_l3_line_addr_t line_addr;
    logic[RRV64_L3_MSHR_IDX_W-1:0] mshr_idx;
    logic err ;
    logic [RRV64_L3_DATA_ECC_W-1:0] dat_ecc_ckbit;
    logic [RRV64_L3_TAG_ECC_W -1:0] tag_ecc_ckbit;
    logic [RRV64_L3_WAY_IDX_W -1:0] avail_way_idx;
    logic [RRV64_L3_WAY_IDX_W -1:0] victim_way_idx;
    logic victim_way_dirty;
    logic victim_set_full;
    rrv64_scu_l3_rd_id_t scu_id ;
    }rrv64_l3_mlfb_head_buf_t;
    
    
    
    
    
    
    //SST pipeline packet
    typedef struct packed {
    logic is_rnsd;
    logic is_ru;
    logic is_cu;
    //logic is_ev; 
    logic is_sst_ovfl_ev;
    logic is_sst_access;
    rrv64_scu_paddr_t paddr;
    logic[RRV64_CORE_IDX_W-1:0] core_idx;
    logic[RRV64_CORE_N-1:0] core_idx_oh;
    logic[RRV64_L1D_STB_IDX_W-1:0] l1d_coh_id;
    logic[RRV64_L2_MSHR_IDX_W-1:0] l2_coh_id;
    }rrv64_sst_req_t;
    
    //RRV64_SCU_SF data
    typedef struct packed{
        logic[RRV64_SCU_SF_TAG_W-1:0] tag;
        logic[RRV64_CORE_N-1:0] core_dir;
    }rrv64_sf_dat_t;
    //RRV64_SCU_SF pipeline packet
    typedef struct packed
    {
    logic is_rd;
    logic is_wr;
    logic is_sst_ovfl_ev;
    //logic is_local_ev;
    logic[RRV64_CORE_N-1:0] core_idx_oh;
    logic[RRV64_SCU_SF_TAG_W-1:0] tag;
    logic[RRV64_SCU_SF_SET_IDX_W-1:0] set_idx;
    logic[RRV64_SCU_SF_WAY_IDX_W-1:0] way_idx;
    rrv64_sf_dat_t wdata;
    }rrv64_sf_req_t;
    
    typedef struct packed{
    logic[RRV64_CORE_N -1:0] core_idx_oh;
    logic[RRV64_SCU_SF_TAG_W-1:0] tag;
    logic[RRV64_SCU_SF_SET_IDX_W -1:0] set_idx;
    }rrv64_wr_sf_req_t;
    
    typedef struct packed {
        rrv64_sst_req_t sst_req;
        rrv64_sf_req_t sf_req;
    }rrv64_scu_pipe_pkt_s1_t;
    
    typedef struct packed {
        rrv64_sst_req_t sst_req;
    }rrv64_scu_pipe_pkt_s2_t;
    
    typedef struct packed {
        rrv64_sst_req_t sst_req;
    }rrv64_scu_pipe_pkt_s3_t;
    
    typedef struct packed {
        rrv64_scu_paddr_t paddr;
        logic[RRV64_CORE_N-1:0] core_dir_nxt;
        logic[RRV64_SCU_SF_WAY_IDX_W-1:0] way_idx;
    } rrv64_sst_upd_sf_req_t;
    
    typedef struct packed{
        rrv64_sf_req_t sf_req;  
        logic[RRV64_SCU_SF_WAY_N-1:0] tag_valid;
    }rrv64_scu_pipe_pkt_sf_rslt_t;
    
    typedef struct packed {
        rrv64_wr_sf_req_t sf_req;
        logic[RRV64_SCU_SF_WAY_N-1:0] tag_valid;
    }rrv64_scu_pipe_pkt_sf_wr_rslt_t;
    
    typedef struct packed {
        rrv64_sf_req_t sf_req;
        logic sf_hit;
        logic[RRV64_SCU_SF_WAY_N-1:0] sf_hit_way;
        logic[RRV64_SCU_SF_WAY_IDX_W -1:0] sf_hit_way_idx;
        rrv64_sf_dat_t sf_hit_dat;
        logic sf_miss;
        rrv64_sf_dat_t sst_ev_dat;
        rrv64_scu_paddr_t sst_ev_addr;
    }rrv64_scu_pipe_pkt_sf_out_t;
    typedef struct packed {
    rrv64_wr_sf_req_t sf_req;
    logic[RRV64_LINE_ADDR_W-1:0] paddr;
    logic sf_hit;
    logic[RRV64_SCU_SF_WAY_N-1:0] sf_hit_way;
    logic[RRV64_SCU_SF_WAY_IDX_W-1:0] sf_hit_way_idx;
    rrv64_sf_dat_t sf_hit_dat;
    logic sf_miss;
    }rrv64_scu_pipe_pkt_sf_wr_out_t; 
    //SRQ
    typedef struct packed {
    rrv64_sst_req_t sst_req;
    logic[RRV64_SCU_SST_IDX_W-1:0] sst_idx;
    rrv64_scu_paddr_t ovfl_ev_paddr;
    logic is_ovfl_ev;
    }rrv64_scu_srq_t;
    //SRDQ
    typedef struct packed {
    rrv64_scu_snp_id_t scu_id;
    logic[RRV64_L2_MSHR_IDX_W -1:0] l2_coh_id;
    rrv64_scu_paddr_t paddr;
    logic[RRV64_LINE_DATA_W-1:0] resp_data;
    logic is_dirty;
    logic has_err;
    }rrv64_scu_srdq_t;
    //SST
    typedef struct packed {
    logic is_l2_resp;
    logic[RRV64_CORE_IDX_W -1:0] resp_core_idx;
    logic has_dat;
    logic is_dirty;
    logic is_ovfl_ev;
    }rrv64_scu_sst_snp_resp_upd_t;
    
    typedef struct packed {
    rrv64_sst_req_t sst_req;
    logic l3_rd;
    logic single_s_cu;
    rrv64_scu_paddr_t paddr;
    logic sf_hit;
    logic[RRV64_SCU_SF_WAY_IDX_W-1:0] sf_hit_way_idx;
    logic[RRV64_CORE_N-1:0] snp_core_dir;
    logic[RRV64_CORE_N -1:0] snp_core_dir_ev;
    }rrv64_scu_sst_req_t;
    
    typedef struct packed{
    logic valid;
    rrv64_sst_req_t sst_req;
    rrv64_scu_paddr_t paddr;
    logic sf_hit;
    logic[RRV64_SCU_SF_WAY_IDX_W -1:0] sf_hit_way_idx;
    logic[RRV64_CORE_N -1:0] snp_core_dir;
    logic[RRV64_CORE_N -1:0] snp_core_dir_ev;
    logic[RRV64_CORE_N -1:0] snp_resp_done_l1;
    logic[RRV64_CORE_N -1:0] snp_resp_done_l2;
    logic snp_resp_data_done;
    logic snp_resp_data_is_dirty;
    logic is_l3_rd;
    logic l3_rd_done;
    logic local_rd_done;
    logic local_wr_done;
    // logic l3_wr_acked;
    logic sf_upd_prepared;
    logic sf_upd_done;
    logic cu_resp_done;
    // logic init_resp_ready;
    logic cu_resp_ready;
    logic rnsd_ru_resp_ready;
    logic l3_rd_ready;
    logic single_s_cu;
    logic snp_ovfl_ev_same_addr;
    }rrv64_scu_sst_t;
    
    //SST pipeline packet
    typedef struct packed {
    logic valid;
    rrv64_sst_req_t sst_req;
    rrv64_scu_paddr_t paddr;
    logic[RRV64_SCU_SST_D -1:0] sst_idx_oh;
    logic is_l3_rd;
    logic[RRV64_CORE_N-1:0] snp_core_dir;
    logic sf_peek_done;
    logic[RRV64_SCU_SF_WAY_IDX_W-1:0] sf_victim_way_idx;
    logic sf_victim_set_full;
    logic sf_evict_done;
    logic[RRV64_SCU_SF_WAY_IDX_W -1 :0] sf_hit_way_idx;
    logic sf_hit;
    }rrv64_sst_sf_upd_buf_t;
    
    
    typedef struct packed {
    logic[RRV64_SCU_SF_SET_IDX_W-1:0] set_idx;
    logic[RRV64_SCU_SF_WAY_IDX_W-1:0] way_idx;
    rrv64_sf_dat_t wdata;
    }rrv64_sf_upd_req_t;
    
    typedef struct packed{
    logic[RRV64_SCU_SF_SET_IDX_W-1:0] set_idx;
    logic[RRV64_SCU_SF_WAY_IDX_W-1:0] way_idx;
    }rrv64_sf_ovfl_evict_req_t;
    //wrq
    typedef struct packed {
    rrv64_scu_paddr_t paddr;
    logic[RRV64_LINE_DATA_W-1:0] wdata;
    }rrv64_wrq_req_t; 
    typedef struct packed{
    logic valid;
    logic[RRV64_CORE_N-1:0] rnsd_ru_wrq_same_addr;
    logic[RRV64_CORE_N-1:0] cu_wrq_same_addr;
    rrv64_wrq_req_t wrq_req;
    }rrv64_scu_wrq_array_t ;
    //rrq
    typedef struct packed {
    rrv64_scu_l3_rd_id_t scu_id;
    rrv64_scu_paddr_t paddr;
    }rrv64_rrq_req_t;
    typedef struct packed {
    logic valid;
    logic [RRV64_CORE_N-1:0] rnsd_ru_rrq_same_addr;
    logic [RRV64_CORE_N-1:0] cu_rrq_same_addr;
    rrv64_rrq_req_t rrq_req;
    }rrv64_scu_rrq_array_t ;
    ////////////////////////////////////////////////////////////////////////////////////7/////   
    ////////////////////////////722////////////////////////////////////////////////////////7771717/
    ////////////////707700////////////////////2////////////////////////////////7/////7
    //addr
    typedef logic[addr_width-1:0] addr_t;
    //axi length
    typedef logic[1:0] length_width_t;
    //axi data
    typedef logic[data_width_axi-1:0] rrv64_data_axi_t;
    //axi size
    typedef logic[2:0] rrv64_size_width_t;
    //snoop rd id
    //typedef logic [scu_srqcx_entry_width-1:0] scu_srqcx_entry_width_t;
    ////l1 i rd id
    typedef logic[RRV64_L1D_MSHR_IDX_W-1:0] l1i_rd_id_width_t;
    //l1 d rd id
    typedef logic [RRV64_L1D_MSHR_IDX_W-1:0] l1_mshr_entry_width_t;
    //l1 d wr id
    //typedef logic [l1_ewrq_entry_width-1:0] l1_ewrq_entry_width_t;
    

    //l2 rd id
    typedef logic [l2_mshr_entry_width-1:0] l2_mshr_entry_width_t;
    //l2 wr id
    typedef logic [l2_ewrq_entry_width-1:0] l2_ewrq_entry_width_t;
    //##############################SCU snoop intf###############
    // typedef struct packed{
    //     logic[3:0] arsnoop;
    //     addr_t arddr;
    //     scu_srqcx_entry_width_t arid;
    // }scu_l2_ace_req_t;
    
    // typedef struct packed{
    //   rrv64_data_axi_t rdata;
    //   scu_srqcx_entry_width_t rid;
    //   logic[3:0] resp;
    // }scu_l2_ace_resp_t;
    
    
    
    
    
    
    
    
    //#############################################################
    /*
    //###################l1d-l2 intf##############################
    typedef struct packed{
        addr_t arddr;
        l1_mshr_entry_width_t arid;
        length_width_t arlen;
        rrv64_size_width_t arsize; 
        logic rd_type; //ld/st
    }core_uncore_l1d_axi_ar_t;
    
    typedef struct packed{
        rrv64_data_t rdata;
        l1_mshr_entry_width_t rid;
        logic[1:0] rmesi;
        logic err;
    }core_uncore_l1d_axi_r_t;
    
    typedef struct packed{
        addr_t awddr;
        l1_ewrq_entry_width_t awid;
        length_width_t awlen;
        rrv64_size_width_t awsize;
        logic [1:0] wmesi;
    }core_uncore_l1d_axi_aw_t;
    
    typedef struct packed{
    rrv64_data_t wdata;
    
    }core_uncore_l1d_axi_w_t;
    
    
    
    */
    /*
    //###################l1i_l2 intf##########################
    typedef struct packed {
    logic[L1I_L2_AXI_RADDR_W-1:0] araddr;
    logic[L1I_L2_AXI_RID_W-1:0] arid;
    logic[3:0] arlen;
    logic[2:0] arsize;
    logic[1:0] arburst;
    logic[1:0] arlock;
    logic[3:0] arcache;
    logic[2:0] arprot;
    }core_uncore_l1i_axi_ar_t;
    
    typedef struct packed{
    logic[L1I_L2_AXI_RDATA_W-1:0] rdata;
    logic[L1I_L2_AXI_RID_W-1:0] rid;
    logic[1:0] rresp;
    logic rlast;
    }core_uncore_l1i_axi_r_t;
    */
    //##############l1_l2cross------->l2 cache
    typedef struct packed{
    logic[RRV64_LINE_ADDR_W-1:0] addr;
    // cacheline_width wr_data;
    // l1_ewrq_entry_width_t id;
    logic[1:0] mesi;
    // logic peeked;
    // logic valid;
    // logic wr_sent;
        logic[RRV64_L2_WAY_W-1:0] victim_way_id;
    }l1d_wr_req_t;
    
    
    //###########mshr id size_width
    
    
    
    //###########
    typedef struct packed{
    logic[RRV64_CACHELINE_W-1:0] cadata;
    logic l1id_rd;
    logic err;
    // logic valid;
    logic[l2_mshr_arid_width-1:0] id;
    logic [1:0] rmesi;
    }rhdq_t;
    
    
    
    //##############lfb--------->l1-l2cross###############
    typedef struct packed{
    logic[RRV64_CACHELINE_W-1:0] cadata;
    logic                      l1id_rd;
    // logic err;
    // logic valid;
    logic[l2_mshr_arid_width-1:0] id;
    // logic rmesi;
    }miss_lfb_o_t;
    
    //###############
    
    //############ req type
    typedef enum logic[3:0]{
    no_req = 'h00,
    l1i_rd = 'h01,
    l1d_rd = 'h02,
    l1d_wr = 'h03,
    evict_rd_l1d_wr =  'h04,
    linefill_wr = 'h05,
    evict_rd_linefill_wr = 'h06,
    snoop_rd = 'h07,
    l1d_wr_hit = 'h08
    }rrv64_wr_rd_req_t;
    
    
    // typedef enum logic[2:0]{
    // no_req = 3'b000,
    // l1i_rd = 3'b001,
    // l1d_rd = 3'b010,
    // l1d_wr = 3'b011,
    // evict_rd_l1d_wr = 3'b100,
    // linefill_wr = 3'b101,
    // evict_rd_linefill_wr = 3'b110,
    // snoop_rd = 3'b111
    // }rrv64_wr_rd_req_t;
    
    //#############snoop coherence intf#################
    typedef struct packed{
        rrv64_ace_req_type_e arsnoop;
        addr_t araddr;
        l2_mshr_entry_width_t arid;
        length_width_t arlen;
        rrv64_size_width_t arsize;
        logic is_dc;
    }l2_scu_ace_ar_t;
    
    typedef struct packed{
        rrv64_data_axi_t rdata;
        l2_mshr_entry_width_t rid;
        logic [3:0] rresp;
        //yzl
        logic[RRV64_SCU_SST_IDX_W-1:0] sst_idx;
    
    }l2_scu_ace_r_t;
    
    typedef struct packed{
    rrv64_ace_req_type_e awsnoop;
    addr_t awaddr;
    l2_ewrq_entry_width_t awid;
    length_width_t awlen;
    rrv64_size_width_t awsize;
    }l2_scu_ace_aw_t;
    
    typedef struct packed{
        rrv64_data_axi_t wdata;
        l2_ewrq_entry_width_t wid;
    }l2_scu_ace_w_t;
    
    //#############
    typedef struct packed{
    logic[RRV64_CACHELINE_W-1:0] lfb_data;
    logic is_dc;
    logic [3:0] resp;
    logic[l2_mshr_arid_width-1:0] id;
    logic[RRV64_SCU_SST_IDX_W-1:0] sst_idx;
    //z logic[1:0] mesi;
    }lfb_crossbar_t;
    
    //lst
    typedef struct packed{
    logic[1:0] mesi; //i=0; s=1;e=2; m =3;
    logic l1id_rd; //i=0; d=1;
    }lst_t;
    
    typedef struct packed{
    logic [RRV64_LINE_ADDR_W-1:0] addr;
    l1i_rd_id_width_t id;
    }l1i_rd_req_t;
    
    
    typedef struct packed{
    logic [RRV64_LINE_ADDR_W-1:0] addr;
    l1_mshr_entry_width_t     id;
    logic                       rd_type; // st/ld st =0; ld=1;
    }l1d_rd_req_t;
    
    
    //typedef struct packed{
    //logic[l2_way_width-1:0] victim_way_id;
    
    // logic peeked;
    // logic wr_sent;
    //}l1d_wr_req_o_t;
    
    
    typedef struct packed{
        logic[RRV64_CACHELINE_W-1:0] wr_data;
        logic[1:0] mshr_id;
        logic peeked;
        logic evicted;
        logic valid;
        logic l1i_lf_sent;
        logic l1_returned;
        logic l2_allocated;
        logic [RRV64_L2_WAY_W-1:0] victim_way_id;
    }lfb_req_t;
    typedef struct packed{
    // logic[cacheline_width-1:0] wr_data;
    logic peeked;
    logic evicted;
    logic[RRV64_L2_WAY_W-1:0] victim_way_id;
    logic l1i_lf_sent;
    logic l2_allocated;
    }lfb_req_o_t;
    
    typedef struct packed{
    logic [RRV64_LINE_ADDR_W-1:0] addr;
    // logic id;
    // rrv64_snoop_type_t snoop_type;
    }snoop_rd_req_t;
    
    //logic 1
    typedef logic[1:0] mesi_t;
    typedef logic inda_t;
    typedef struct packed{
        mesi_t  [RRV64_L2_WAY_N-1:0] mesi;
        inda_t  [RRV64_L2_WAY_N-1:0] inda; //0 instruction ;1 data;
    }l2_lst_set_t;
    typedef struct packed {
        mesi_t mesi;
        inda_t inda;
    }l2_lst_t;
    
    typedef logic [RRV64_L2_TAG_RAM_DATA_W-1:0] tag_ram_t;
    
    
    //output data
    //typedef struct packed{
    //  logic[cacheline_width-1:0] cadata;
    //}snoop_resp_t;
    
    //typedef struct packed{
    //      logic[cacheline_width-1:0] cadata;
    //      logic [1:0] lst;
    //}ewdq_t;
    
    
    
    //PLRU
    typedef logic[RRV64_L2_WAY_W-2:0] plru_t;
    
    typedef logic[l2_mshr_arid_width-1:0] l1_ar_id_width;
    
    typedef struct packed{
    logic valid;
    l1_ar_id_width l1_arid;
    logic sent;
    logic is_dc; // I$/D$
    logic is_l1d_ld; // l1d st/ld
    logic[RRV64_LINE_ADDR_W-1:0] addr;
    
    }mshr_t;
    
    //addz
    typedef struct packed{
        logic[data_width_axi-1:0] cadata;
        logic is_dc;
        logic[1:0] resp;
    // logic valid;
        logic [l2_mshr_arid_width-1:0] id;
        logic[1:0] rmesi;
    }return_arb_data_mux_t;
    
    //addz
    typedef struct packed{
    // logic[cacheline_width-1:0] data;
      l2_mshr_entry_width_t id;
      logic [3:0] resp;
    }scu_snoop_resp_reg_t;
    
    
    //addycy
    typedef struct packed{
    logic[1:0] op;
    logic valid;
    logic[1:0] is_dirty;
    logic is_dc;
    logic[RRV64_LINE_ADDR_W-1:0] lineaddr;
    }l2_ewrq_entry_t;
    typedef struct packed {
    logic valid_o;
    logic[1:0]id;
    rrv64_ace_req_type_e snoop;
    logic[RRV64_LINE_ADDR_W-1:0]addr;
    } l2_ewrq_reg_t;
    typedef struct packed {
    logic valid;
    logic[RRV64_CACHELINE_W-1:0] wdata;
    }l2_ewdq_entry_t;
    typedef struct packed {
    logic valid_o;
    logic[l2_ewrq_entry_width-1:0]id;
    logic[RRV64_CACHELINE_W-1:0] wdata;
    } l2_ewdq_reg_t;
    
    typedef struct packed {
    logic valid;
    logic [$clog2(l2_mshr_entry)-1:0] mshr_id;// scu return to l2
    logic [1:0]line_seg_received;
    logic line_ready;
    logic peeked;
    logic evicted;
    logic l1i_lf_sent;
    logic [1:0]line_seg_returned;
    logic l1_returned;
    logic l2_allocated;
    logic[RRV64_L2_WAY_W-1:0] evict_victim_way_id;//from_s2 ###############
    logic[RRV64_CACHELINE_W-1:0] rdata;
    logic [3:0]rresp;
    logic[RRV64_SCU_SST_IDX_W-1:0]sst_idx;
    } l2_lfb_t;
    
    
    //plic typedef
    //----------------------------------
    typedef enum logic[2:0]{
        REQ_READ =3'd0,
        REQ_WRITE=3'd1
    } cpu_req_type_t;
    typedef struct packed {
        logic[CPUNOC_TID_SRCID_SIZE-1:0] src;
        logic[CPUNOC_TID_TID_SIZE-1:0] tid;
    }cpu_tid_t;
    typedef struct packed {
    cpu_req_type_t req_type;
    cpu_tid_t req_tid;
    logic[MEM_ADDR_W-1:0] req_paddr;
    logic[MEM_BYTE_MASK_W-1:0] req_mask;
    logic[MEM_DATA_W-1:0] req_data;
    }mem_if_req_t;
    
    typedef struct packed {
    cpu_req_type_t resp_type;
    cpu_tid_t resp_tid;
    logic[MEM_DATA_W-1:0] resp_data;
    }mem_if_resp_t;
    
    typedef struct packed{
        logic [PLIC_INTR_ID_W-1:0] intr_id;
    }plic_intr_id_t;
    
    typedef logic[TIMER_WIDTH-1:0] timer_t;
    
    typedef enum logic[1:0]{
    LOCAL_SLAVE_TIMER = 2'd0,
    LOCAL_SLAVE_PLIC =2'd1,
    LOCAL_SLAVE_DM =2'd2
    }local_slave_e;
    

    typedef struct packed {
        rrv64_l1d_req_type_dec_t lsu_req_type_dec;
        rrv64_lsu_l1d_req_t      lsu_req;
        logic                    cache_hit;
        rrv64_mesi_type_e        mesi_sta;
      } rrv64_l1d_srq_req_t;

    typedef struct packed {
        rrv64_l1d_srq_req_t             srq_req;
        logic [RRV64_LINE_DATA_W-1:0]   clean_line_dat;
        logic [RRV64_L1D_WAY_IDX_W-1:0] st_way_idx;
        logic [RRV64_SCU_SST_IDX_W-1:0] sst_idx;
        logic                           tag_wen;
        logic                           sc_fail;

        logic[RRV64_ROB_ADDR_W-1:0]      srq_st_rob_idx;
        logic                            srq_st_rob_idx_valid;
        logic                            is_merged;
    } rrv64_l1d_real_st_req_raw_t;

    typedef struct packed {
        logic [RRV64_LINE_DATA_W-1:0]    dat;
        logic                            tag_wen;
        logic [RRV64_L1D_TAG_W-1:0]      tag;
        logic [RRV64_L1D_WAY_IDX_W-1:0]  way_idx;
        logic [RRV64_L1D_SET_IDX_W-1:0]  set_idx;
        logic                            is_sc;
        logic                            is_amo;
        logic [RRV64_INT_REG_DATA_W-1:0] amo_resp_dat;
        rrv64_mesi_type_e                mesi_sta;
        rrv64_lsu_l1d_req_t              lsu_req;
        logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
        logic                            sc_fail;

        logic[RRV64_ROB_ADDR_W-1:0]      rob_idx;
        logic                            rob_idx_valid;
        logic                            is_merged;
    } rrv64_l1d_real_st_req_t;
    
    endpackage 