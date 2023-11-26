
  typedef enum logic [RRV64_LSU_OPCODE_WIDTH - 1 : 0] {
    RRV64_LSU_LOAD       = 'h00,
    RRV64_LSU_STORE      = 'h01,
    RRV64_LSU_FLUSH      = 'h02,
    RRV64_LSU_FLUSH_ALL  = 'h03
  } rrv64_lsu_opcode_t;
  
  typedef enum logic [RRV64_LSU_SIZE_WIDTH - 1 : 0] {
    RRV64_LSU_SZ_1B  = 'h00,
    RRV64_LSU_SZ_2B  = 'h01,
    RRV64_LSU_SZ_4B  = 'h02,
    RRV64_LSU_SZ_8B  = 'h03
  } rrv64_lsu_size_t;
  
  typedef struct packed {
    rrv64_lsu_opcode_t opcode;
    logic[RRV64_LSU_TRANS_ID_WIDTH - 1:0] trans_id;
    rrv64_vaddr_t addr;
    rrv64_lsu_size_t size;
    logic[RRV64_LSU_REQ_D_WIDTH - 1:0] data;
  } rrv64_lsu_req_t;
  
  typedef struct packed {
    rrv64_lsu_opcode_t opcode;
    logic[RRV64_LSU_TRANS_ID_WIDTH - 1:0] trans_id;
    rrv64_paddr_t addr;
    rrv64_lsu_size_t size;
  } rrv64_lsu_ptw_req_t;

  typedef struct packed {
    logic[RRV64_LSU_TRANS_ID_WIDTH - 1:0] trans_id;
    logic[RRV64_LSU_RESP_D_WIDTH - 1:0] data;
    logic[RRV64_LSU_ERROR_WIDTH - 1:0] error;
  } rrv64_lsu_resp_t;

  typedef struct packed {
    rrv64_vpn_t req_vpn;
    rrv64_access_type_t req_access_type;
    logic va_excp_valid;
    logic pa_excp_valid;
  } rrv64_cache_tlb_if_req_t;

 typedef struct packed {
   logic resp_excp_valid;
   rrv64_excp_cause_t resp_excp_cause;
   rrv64_ppn_t resp_ppn;
 } rrv64_cache_tlb_if_resp_t;

  typedef enum logic [1:0] {
    RRV64_SFENCE_ASID       = 2'b00,
    RRV64_SFENCE_VPN        = 2'b01,
    RRV64_SFENCE_ASID_VPN   = 2'b10,
    RRV64_SFENCE_ALL        = 2'b11
  } rrv64_sfence_type_t;

  typedef struct packed {
    rrv64_sfence_type_t req_sfence_type;
    rrv64_asid_t req_flush_asid;
    rrv64_vpn_t req_flush_vpn;
  } rrv64_tlb_flush_if_req_t;

  typedef struct packed {
    logic valid;
    rrv64_vaddr_t             vaddr;
    rrv64_access_type_t       access_type;
    logic                     need_tlb;
    logic [RRV64_LSU_QID_WIDTH - 1 : 0] qid;
    logic va_excp_valid;
    logic pa_excp_valid;
  } lsu_missq_data_t;

  typedef struct packed {
    logic valid;
    rrv64_paddr_t                        pa;
    rrv64_access_type_t                  access_type;
    logic[RRV64_EXE_SUB_OP_W-1:0]        sub_op;
    logic [RRV64_LSU_SIZE_WIDTH - 1 : 0] size;
    logic [RRV64_ROB_ADDR_W-1:0]         rob_idx;
    logic [RRV64_INT_PHY_REG_ADDR_W-1:0] prd;
    logic                                ready_issue;
    logic [RRV64_LSU_QID_WIDTH - 1 : 0]      qid;
    logic                                pa_resolved;
    logic                                sent;
    logic [RRV64_INT_REG_DATA_W-1:0]     data;
    rrv64_excp_valid_t                   excp;
  } lsu_lsq_data_t;
  
  typedef struct packed {
    logic                             valid;
    logic [RRV64_LSU_QID_WIDTH - 1 : 0]  qid;
    logic [RRV64_INT_REG_DATA_W-1:0]  data;
  } lsu_st_dataq_data_t;

  //cache flush
  typedef enum logic [RRV64_LSU_CACHE_FLUSH_OPCODE_WIDTH - 1 : 0] {
    RRV64_CACHE_FLUSH_ALL      = 'h00,
    RRV64_CACHE_FLUSH_VA       = 'h01,
    RRV64_CACHE_FLUSH_PA       = 'h02,
    RRV64_CACHE_FLUSH_WAY      = 'h03,
    RRV64_CACHE_FLUSH_SET      = 'h04,
    RRV64_CACHE_FLUSH_WAY_SET  = 'h05,
    RRV64_CACHE_INV_ALL        = 'h06,
    RRV64_CACHE_INV_VA         = 'h07,
    RRV64_CACHE_INV_PA         = 'h08,
    RRV64_CACHE_INV_WAY        = 'h09,
    RRV64_CACHE_INV_SET        = 'h0a,
    RRV64_CACHE_INV_WAY_SET    = 'h0b,
    RRV64_CACHE_CLEAN_ALL      = 'h0c,
    RRV64_CACHE_CLEAN_VA       = 'h0d,
    RRV64_CACHE_CLEAN_PA       = 'h0e,
    RRV64_CACHE_CLEAN_WAY      = 'h0f,
    RRV64_CACHE_CLEAN_SET      = 'h10,
    RRV64_CACHE_CLEAN_WAY_SET  = 'h11
  } rrv64_lsu_cache_flush_opcode_t;
  typedef struct packed {
    rrv64_lsu_cache_flush_opcode_t      opcode;
    logic [RRV64_INT_REG_DATA_W-1:0]    addr;
  } lsu_st_lsu_cache_flush_reg_t;

  typedef enum logic [2:0] {
    LSU_REQ_ST_IDLE             = 3'h0,
    LSU_REQ_ST_FENCE_I_L1D      = 3'h1,
    LSU_REQ_ST_FENCE_I_L2       = 3'h2,
    LSU_REQ_ST_FENCE_I_L1I      = 3'h3,
    LSU_REQ_ST_SFENCE_VMA_DTLB  = 3'h4,
    LSU_REQ_ST_SFENCE_VMA_ITLB  = 3'h5,
    LSU_REQ_ST_SFENCE_VMA_L2TLB = 3'h6,
    LSU_REQ_ST_SFENCE_VMA_L1I   = 3'h7
  } lsu_req_state_t;

  typedef enum logic [2:0] {
    LSU_CMO_ST_IDLE = 3'h0,
    LSU_CMO_ST_L1I  = 3'h1,
    LSU_CMO_ST_L1D  = 3'h2,
    LSU_CMO_ST_L2   = 3'h3,  
    LSU_CMO_ST_L3   = 3'h4
  } lsu_cmo_state_t;

  //functions
  function automatic logic func_lsu_sub_op_is_load(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_is_load =
      (sub_op == LSU_LB  ) |
      (sub_op == LSU_LBU ) |
      (sub_op == LSU_LH  ) |
      (sub_op == LSU_LHU ) |
      (sub_op == LSU_LW  ) |
      (sub_op == LSU_LWU ) |
      (sub_op == LSU_LD  ) |
      (sub_op == LSU_FLW ) |
      (sub_op == LSU_FLD );
  endfunction

  function automatic logic func_lsu_sub_op_is_store(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_is_store =
      (sub_op == LSU_SB  ) |
      (sub_op == LSU_SH  ) |
      (sub_op == LSU_SW  ) |
      (sub_op == LSU_SD  ) |
      (sub_op == LSU_FSW ) |
      (sub_op == LSU_FSD );
  endfunction

  function automatic logic func_lsu_sub_op_is_amo(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_is_amo =
      (sub_op == LSU_LRW  ) |
      (sub_op == LSU_LRD  ) |
      (sub_op == LSU_SCW  ) |
      (sub_op == LSU_SCD  ) |
      (sub_op == LSU_AMOSWAPW  ) |
      (sub_op == LSU_AMOSWAPD  ) |
      (sub_op == LSU_AMOADDW   ) |
      (sub_op == LSU_AMOADDD   ) |
      (sub_op == LSU_AMOANDW   ) |
      (sub_op == LSU_AMOANDD   ) |
      (sub_op == LSU_AMOORW    ) |
      (sub_op == LSU_AMOORD    ) |
      (sub_op == LSU_AMOXORW   ) |
      (sub_op == LSU_AMOXORD   ) |
      (sub_op == LSU_AMOMAXW   ) |
      (sub_op == LSU_AMOMAXD   ) |
      (sub_op == LSU_AMOMAXUW  ) |
      (sub_op == LSU_AMOMAXUD  ) |
      (sub_op == LSU_AMOMINW   ) |
      (sub_op == LSU_AMOMIND   ) |
      (sub_op == LSU_AMOMINUW  ) |
      (sub_op == LSU_AMOMINUD  ) ;
  endfunction

  function automatic rrv64_access_type_t func_lsu_sub_op_access_type(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_access_type =
    func_lsu_sub_op_is_load(sub_op) ? RRV64_ACCESS_LOAD:
    func_lsu_sub_op_is_store(sub_op) ? RRV64_ACCESS_STORE:
    func_lsu_sub_op_is_amo(sub_op) ? RRV64_ACCESS_AMO:
    RRV64_ACCESS_LOAD;
  endfunction

  function automatic logic func_lsu_sub_op_write_rf(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_write_rf = func_lsu_sub_op_is_load(sub_op) | func_lsu_sub_op_is_amo(sub_op);
  endfunction

  function automatic logic func_lsu_sub_op_is_fp(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_is_fp =
      (sub_op == LSU_FLW ) |
      (sub_op == LSU_FLD ) |
      (sub_op == LSU_FSW ) |
      (sub_op == LSU_FSD );
  endfunction
  
  function automatic logic [RRV64_LSU_SIZE_WIDTH - 1 : 0] func_lsu_sub_op_size(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
    func_lsu_sub_op_size =
           ((sub_op == LSU_LB ) |
            (sub_op == LSU_LBU) |
            (sub_op == LSU_SB ))         ? 0:
           ((sub_op == LSU_LH ) |
            (sub_op == LSU_LHU) |
            (sub_op == LSU_SH ))         ? 1:
           ((sub_op == LSU_LW      ) |
            (sub_op == LSU_LWU     ) |
            (sub_op == LSU_SW      ) |
            (sub_op == LSU_FLW     ) |
            (sub_op == LSU_FSW     ) |
            (sub_op == LSU_LRW     ) |
            (sub_op == LSU_SCW     ) |
            (sub_op == LSU_AMOSWAPW) |
            (sub_op == LSU_AMOADDW ) |
            (sub_op == LSU_AMOANDW ) |
            (sub_op == LSU_AMOORW  ) |
            
            (sub_op == LSU_AMOXORW ) |
            (sub_op == LSU_AMOMAXW ) |
            (sub_op == LSU_AMOMAXUW) |
            (sub_op == LSU_AMOMINW ) |
            (sub_op == LSU_AMOMINUW))    ? 2:
           3;
  endfunction

  function automatic logic func_lsu_sub_op_need_tlb(logic[RRV64_EXE_SUB_OP_W-1:0] sub_op);
   func_lsu_sub_op_need_tlb =
     func_lsu_sub_op_is_load(sub_op) |
     func_lsu_sub_op_is_store(sub_op) |
     func_lsu_sub_op_is_amo(sub_op);
  endfunction