package rrv64_core_typedef_pkg;
  import rrv64_top_param_pkg::*;
  import rrv64_core_param_pkg::*;

  typedef logic [RRV64_INSTR_WIDTH - 1 : 0] rrv64_instr_t;
  typedef logic [RRV64_VIR_ADDR_WIDTH - 1 : 0] rrv64_vaddr_t;
  typedef logic [RRV64_PHY_ADDR_WIDTH - 1 : 0] rrv64_paddr_t;
  typedef logic [RRV64_XLEN -1 : 0]             rrv64_xlen_t;
  typedef logic [RRV64_RS_FWD_SRC_NUM -1:0]     rrv64_fwd_src_t;
  typedef logic [RRV64_L1C_LINE_BYTE_W:0]      rrv64_cpu_byte_size_t;
  typedef logic[RRV64_XLEN-1:0]                 csr_mtval_t;
  typedef logic[RRV64_XLEN-1:0]                 rrv64_dpc_t;


  typedef enum logic [3:0] {
    RRV64_EXCP_CAUSE_INST_ADDR_MISALIGNED = 4'('d0),
    RRV64_EXCP_CAUSE_INST_ACCESS_FAULT = 4'('d1),
    RRV64_EXCP_CAUSE_ILLEGAL_INST = 4'('d2),
    RRV64_EXCP_CAUSE_BREAKPOINT = 4'('d3),
    RRV64_EXCP_CAUSE_LOAD_ADDR_MISALIGNED = 4'('d4),
    RRV64_EXCP_CAUSE_LOAD_ACCESS_FAULT = 4'('d5),
    RRV64_EXCP_CAUSE_STORE_ADDR_MISALIGNED = 4'('d6),
    RRV64_EXCP_CAUSE_STORE_ACCESS_FAULT = 4'('d7),
    RRV64_EXCP_CAUSE_ECALL_FROM_U = 4'('d8),
    RRV64_EXCP_CAUSE_ECALL_FROM_S = 4'('d9),
    RRV64_EXCP_CAUSE_ECALL_FROM_M = 4'('d11),
    RRV64_EXCP_CAUSE_INST_PAGE_FAULT = 4'('d12),
    RRV64_EXCP_CAUSE_LOAD_PAGE_FAULT = 4'('d13),
    RRV64_EXCP_CAUSE_STORE_PAGE_FAULT = 4'('d15),
    RRV64_EXCP_CAUSE_NONE = 4'('d10)

  } rrv64_excp_cause_t;


  //core <> l1 icache interface
  typedef enum logic [RRV64_L1IC_OPCODE_WIDTH - 1 : 0] {
    RRV64_L1IC_FETCH      = 'h00,
    RRV64_L1IC_FLUSH      = 'h01,
    RRV64_L1IC_FLUSH_ALL  = 'h02
  } rrv64_l1ic_opcode_t;

  typedef struct packed {
    rrv64_l1ic_opcode_t opcode;
    logic[RRV64_L1IC_TRANS_ID_WIDTH - 1:0] trans_id;
    rrv64_vaddr_t addr;  
  } rrv64_l1ic_req_t;

  typedef struct packed {
    logic [RRV64_L1IC_TRANS_ID_WIDTH -1 :0] trans_id;
    logic [RRV64_L1IC_FETCH_WIDTH -1 :0] data;
    logic [RRV64_L1IC_ERROR_WIDTH -1 :0] error;
    logic replay;
    rrv64_vaddr_t addr;
    logic excp_valid;
    rrv64_excp_cause_t excp_cause;
  } rrv64_l1ic_resp_t;


typedef struct packed {
    logic  valid;
    logic  [RRV64_MSHR_CNT_WIDTH -1:0] cnt;
    logic  [RRV64_ICACHE_RAM_TAG_WIDTH-1 :0] addr;  
}rrv64_l1ic_mshr_entry;

typedef logic [RRV64_L1C_LINE_WIDTH-1:0]  cache_line_t  ;

  typedef struct packed {
    logic                             valid;
    logic [RRV64_ICACHE_RAM_TAG_WIDTH-1:0] tag;  
  } rrv64_ic_tag_entry_t;
 typedef struct packed {
   logic [RRV64_PHY_ADDR_WIDTH -RRV64_L1IC_ADDR_IDX_W : 0] tag;  
 } rrv64_l1ic_tag_t;


  //
  //core <> l1 dcache interface
  typedef enum logic [RRV64_L1DC_OPCODE_WIDTH -1 : 0] {
    RRV64_L1DC_LOAD       = 'h00,
    RRV64_L1DC_STORE      = 'h01,
    RRV64_L1DC_FLUSH      = 'h02,
    RRV64_L1DC_FLUSH_ALL  = 'h03
  } rrv64_l1dc_opcode_t;
  
  typedef enum logic [RRV64_L1DC_SIZE_WIDTH -1 : 0]{
    RRV64_L1DC_SZ_1B = 'h00,
    RRV64_L1DC_SZ_2B = 'h01,
    RRV64_L1DC_SZ_4B = 'h02,
    RRV64_L1DC_SZ_8B = 'h03
  } rrv64_l1dc_size_t;

  typedef struct packed {
    rrv64_l1dc_opcode_t opcode;
    logic[RRV64_L1DC_TRANS_ID_WIDTH - 1:0] trans_id;
    rrv64_vaddr_t addr;
    rrv64_l1dc_size_t size;
    logic[RRV64_L1DC_REQ_D_WIDTH - 1:0] data;  
  } rrv64_l1dc_req_t;


  typedef struct packed {
    rrv64_l1dc_opcode_t opcode;
    logic[RRV64_L1DC_TRANS_ID_WIDTH - 1:0] trans_id;
    rrv64_paddr_t addr;
    rrv64_l1dc_size_t size;
    logic[RRV64_L1DC_ERROR_WIDTH - 1:0] error;
    logic[RRV64_L1DC_REQ_D_WIDTH - 1:0] data;  
  } rrv64_l1dc_req_pa_t;

  typedef struct packed {
    logic[RRV64_L1DC_TRANS_ID_WIDTH - 1:0] trans_id;
    logic[RRV64_L1DC_RESP_D_WIDTH - 1:0] data;
    logic[RRV64_L1DC_ERROR_WIDTH - 1:0] error;
  } rrv64_l1dc_resp_t;

  //
  //instruction predecode
  typedef struct packed {
    logic is_rvc;
    logic is_b;
    logic is_jal;
    logic is_jalr;
    logic is_call;
    logic is_ret;
    rrv64_vaddr_t offset;
  } rrv64_precode_t;
  //block_buffer
  typedef struct packed {
        logic is_rvc;
        logic [15:0] inst;
  }rrv64_block_buf_t;
  //
  typedef struct packed {
        logic         hw;
    logic         taken;
    rrv64_vaddr_t pc;
        logic [7:0]   offset;
        logic [7:0]   num;
        logic [7:0]   bytes;
        logic [2:0]   jumptype;
        rrv64_vaddr_t target;
        logic [15:0]  bpb_idx; 
  } rrv64_fetch_target_queue_t;


  typedef logic[4:0] rrv64_isa_reg_t;
  typedef logic[$clog2(RRV64_PHY_REG_NUM)-1:0] rrv64_phy_reg_t;
  typedef logic[$clog2(RRV64_ROB_ENTRY_NUM)-1:0] rrv64_rob_idx_t;

//
//
//
//
//
//  
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

  // typedef struct packed {
  //     logic ubtb_taken;
  //     logic gs_taken;
  //     logic lh_taken;
  //     logic [RRV64_BPU_BHT_CNT_W - 1 : 0]  ubtb_bht_cnt;
  //     logic [RRV64_BPU_BHT_CNT_W - 1 : 0]  gs_bht_cnt;
  //     logic [RRV64_BPU_BHT_CNT_W - 1 : 0]  lh_bht_cnt;
  //     logic [RRV64_BPU_SLT_CNT_W - 1 : 0]  slt_cnt;  
  //     //logic [RRV64_BPU_GHR_SIZE - 1 : 0]  ghr;  
  //     logic [RRV64_BPU_LHR_SIZE - 1 : 0]  lhr;  
  // } rrv64_bpu_state_info_t;
  
  // typedef struct packed {
  //     logic valid;                              // same value as valid outside
  //     logic taken;                              // indicate in the branch is taken
  //     logic [RRV64_BPU_OFFSET_W -1 :0] offset;  // indicate redirect pc offset in 16Bytes cache line (per 2Bytes)
  //     //
  //     rrv64_vaddr_t target;                     // branch target
  //     //
  //     logic branch_redirect;                    // not used in uBTB
  //     logic [RRV64_BPU_OFFSET_W -1 :0] branch_redirect_offset;  // not used in uBTB
  //     rrv64_bpu_state_info_t bp_state;          // indicate ALL BHT entry state. Only need to update related state.
  // } rrv64_branch_predict_t;

  // ----------------------
  // Exception Casuse Code
  // ----------------------
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
  
  typedef struct packed {
      logic                   valid;
      rrv64_excp_cause_t      cause;
      csr_mtval_t             tval;   
  } rrv64_exception_t;
  typedef struct packed {
      logic                  valid;
      rrv64_excp_cause_t     cause;
  } rrv64_excp_valid_t;
  //
  //page table walk
  typedef enum logic [1:0] {
    RRV64_ACCESS_FETCH = 2'b00,
    RRV64_ACCESS_LOAD  = 2'b01,
    RRV64_ACCESS_STORE = 2'b10,
    RRV64_ACCESS_AMO   = 2'b11
  } rrv64_access_type_t;

  typedef logic [RRV64_VPN_WIDTH-1:0] rrv64_vpn_t;
  typedef logic [RRV64_PPN_WIDTH-1:0] rrv64_ppn_t;
  typedef logic [RRV64_PTW_LVL_CNT_WIDTH-1:0] rrv64_ptw_lvl_t;
  typedef logic [RRV64_PHY_PAGE_PART_WIDTH-1:0]     rrv64_ppn_part_t;
  typedef logic [RRV64_ASID_WIDTH-1:0] rrv64_asid_t;
  typedef logic [RRV64_PTE_IDX_WIDTH-1:0] rrv64_pte_idx_t;

  typedef struct packed {
    logic       [9:0] reserved1;
    rrv64_ppn_t       ppn;
    logic       [1:0] reserved0;
    logic             dirty;
    logic             accessed;
    logic             global_map;
    logic             user;
    logic             perm_x;
    logic             perm_w;
    logic             perm_r;
    logic             valid;
  } rrv64_pte_t; // page table entry

  typedef struct packed {
    rrv64_asid_t              asid;
    rrv64_vpn_t             vpn;
    rrv64_pte_t             pte;
    rrv64_ptw_lvl_t         page_lvl;
    logic                   excp_valid;
    rrv64_excp_cause_t excp_cause;
  } rrv64_tlb_entry_t;

  typedef struct packed {
    rrv64_asid_t            asid;
    rrv64_vpn_t             vpn;
    logic                   g;
    rrv64_ptw_lvl_t         page_lvl;
  } rrv64_l2tlb_tag_t;

  typedef struct packed {
    rrv64_pte_t             pte;
    logic                   excp_valid;
    rrv64_excp_cause_t excp_cause; 
  } rrv64_l2tlb_data_t;

  typedef struct packed {
    logic [RRV64_L1_TLB_TRANS_ID_WIDTH - 1 : 0] trans_id;
    rrv64_vpn_t vpn;
    rrv64_access_type_t access_type;
  } rrv64_tlb_ptw_req_t;

  typedef struct packed {
    logic [RRV64_L1_TLB_TRANS_ID_WIDTH - 1 : 0] trans_id;
    logic excp_valid;
    rrv64_excp_cause_t excp_cause;
    rrv64_ptw_lvl_t lvl;
    rrv64_pte_t pte; 
  } rrv64_tlb_ptw_resp_t;

  //add***
  typedef enum logic [1:0] {
    IS_JUMP   = 2'b00,
    IS_FCALL  = 2'b01,
    IS_FRET   = 2'b10,
    IS_BRANCH = 2'b11
  } rrv64_bpu_pc_type_t;
      typedef struct packed {
  logic valid;
      rrv64_bpu_pc_type_t pc_type;
  logic rvc;
      logic [3:0]offset;
  rrv64_vaddr_t target;    
      } rrv64_branch_t;

  //***
  //branch predict update
  // typedef struct packed {

  //     rrv64_vaddr_t pc;
  //     rrv64_vaddr_t dest;
  //     logic         is_rvc;
  //       rrv64_bpu_pc_type_t pc_type;
  //     logic         taken;

  //     rrv64_bpu_state_info_t bp_state;
  //     logic resolved;                     // indicate whether predict is success or not. 1 for success
  // } rrv64_bp_update_req_t;


  typedef enum logic [2:0] {
                RRV64_ALU = 3'h0,
                RRV64_MUL = 3'h1,
                RRV64_CSR = 3'h2,
                RRV64_BRU = 3'h3,
                RRV64_DIV = 3'h4,
                RRV64_LSU = 3'h5
        } rrv64_exe_type_t;
       
        typedef struct packed {
        logic        rd_en;
        logic [5:0] rd_isa;
        logic       rs1_en;
        logic [5:0]rs1_isa;
        logic       rs2_en;
        logic [5:0]rs2_isa;
        logic       is_rvc;
        logic [38:0]   imm;
        rrv64_exe_type_t    exe_type;
        logic [4:0]     exe_sub_type;
        } rrv64_id2bk_t;

    //RVC
    typedef enum logic [1:0] {
    RVC_C0  = 2'b00,
    RVC_C1  = 2'b01,
    RVC_C2  = 2'b10
  } rrv64_rvc_opcode_t;
    //register file address
    typedef logic [4:0]                      rrv64_reg_addr_t;
    typedef logic [64-1:0]                   rrv64_data_t;

  
typedef enum logic [4:0] {
    RRV64_LOAD      = 5'h00,
    RRV64_MISC_MEM  = 5'h03,
    RRV64_OP_IMM    = 5'h04,
    RRV64_AUIPC     = 5'h05,
    RRV64_OP_IMM_32 = 5'h06,
    RRV64_STORE     = 5'h08,
    // AMO
    RRV64_AMO       = 5'h0B,
    RRV64_OP        = 5'h0C,
    RRV64_LUI       = 5'h0D,
    RRV64_OP_32     = 5'h0E,
    RRV64_BRANCH    = 5'h18,
    RRV64_JALR      = 5'h19,
    RRV64_JAL       = 5'h1B,
    RRV64_SYSTEM    = 5'h1C,
    RRV64_LOAD_FP   = 5'h01,
    RRV64_STORE_FP  = 5'h09,
    RRV64_OP_FP     = 5'h14,
    RRV64_FMADD     = 5'h10,
    RRV64_FMSUB     = 5'h11,
    RRV64_FNMADD    = 5'h13,
    RRV64_FNMSUB    = 5'h12
} rrv64_opcode_t;


  //redirect to frontend
  typedef enum logic [RRV64_REDIRECT_OPCODE_WIDTH - 1: 0] {
    RRV64_REDIRECT_JMP         = 'h00,
    RRV64_REDIRECT_FLUSH_L1    = 'h01,
    RRV64_REDIRECT_FLUSH_ITLB  = 'h02
  } rrv64_redirect_opcode_t;
  typedef struct packed {
      rrv64_redirect_opcode_t opcode;
      rrv64_vaddr_t addr;
  } rrv64_redirect_req_t;

  //
  //csr read/write
  typedef enum logic [RRV64_CSR_OPCODE_WIDTH - 1 : 0] {
    RRV64_CSR_READ   = 'h00,
    RRV64_CSR_WRITE  = 'h01,
    RRV64_CSR_RS     = 'h02,
    RRV64_CSR_RC     = 'h03
  } rrv64_csr_opcode_t;
  typedef struct packed {
      rrv64_csr_opcode_t opcode;
      rrv64_vaddr_t addr;
      logic[RRV64_XLEN - 1 : 0] data; 
  } rrv64_csr_req_t;
  typedef struct packed {
      logic[RRV64_XLEN - 1 : 0] data;
  } rrv64_csr_resp_t;
  
  typedef enum logic [3:0] {
    RRV64_BARE = 4'd0,
    RRV64_SV39 = 4'd8,
    RRV64_SV48 = 4'd9,
    RRV64_SV57 = 4'd10,
    RRV64_SV64 = 4'd11
  } rrv64_satp_mode_t;

  typedef struct packed {
    rrv64_satp_mode_t   mode;
    rrv64_asid_t        asid;
    rrv64_ppn_t         ppn;  
  } rrv64_csr_satp_t;

  typedef struct packed {
    logic [53:0]    addr; 
  } rrv64_csr_pmpaddr_t;

  typedef enum logic [1:0] {
    RRV64_OFF   = 2'b00,
    RRV64_TOR   = 2'b01,
    RRV64_NA4   = 2'b10,
    RRV64_NAPOT = 2'b11
  } rrv64_pmp_access_type;

  typedef struct packed {
    logic           l;
    logic [1:0]     reserved;
    rrv64_pmp_access_type a;
    logic           x;
    logic           w;
    logic           r;
  } rrv64_csr_pmpcfg_part_t;

  typedef struct packed {
    rrv64_csr_pmpcfg_part_t [RRV64_N_FIELDS_PMPCFG-1:0] pmpcfg;
  } rrv64_csr_pmpcfg_t;

  typedef enum logic [1:0] {
    RRV64_PRV_U = 2'b00,
    RRV64_PRV_S = 2'b01,
    RRV64_PRV_M = 2'b11
  } rrv64_prv_t;


  typedef struct packed {
    logic         SD;
    logic [26:0]  reserved_62_to_36;
    logic [ 1:0]  SXL;
    logic [ 1:0]  UXL;
    logic [ 8:0]  reserved_31_to_23;
    logic         TSR;
    logic         TW;
    logic         TVM;
    logic         MXR;
    logic         SUM;
    logic         MPRV;
    logic [ 1:0]  XS;
    logic [ 1:0]  FS;
    rrv64_prv_t   MPP;
    logic [ 1:0]  VS;
    logic         SPP;
    logic         MPIE;
    logic         reserved_6;
    logic         SPIE;
    logic         reserved_4;
    logic         MIE;
    logic         reserved_2;
    logic         SIE;
    logic         reserved_0;
  } rrv64_csr_mstatus_t;

    typedef struct packed {
        logic busy;
        logic done;

    } rrv64_rob_ctrl_t;
    typedef struct packed {
        logic is_compressed;
        rrv64_isa_reg_t rd;
        rrv64_phy_reg_t phy_rd;
        rrv64_phy_reg_t Last_phy_rd; 
    } rrv64_rob_info_t;
  //for floating
  //-----------------------
    typedef enum logic [2:0] {
    RRV64_FRM_RNE   = 3'b000,
    RRV64_FRM_RTZ   = 3'b001,
    RRV64_FRM_RDN   = 3'b010,
    RRV64_FRM_RUP   = 3'b011,
    RRV64_FRM_RMM   = 3'b100,
    RRV64_FRM_RSVD0 = 3'b101,
    RRV64_FRM_RSVD1 = 3'b110,
    RRV64_FRM_DYN   = 3'b111
    } rrv64_frm_e;
    typedef struct packed {
      logic nv;
      logic dz;
      logic of;
      logic uf;
      logic nx;
    } rrv64_fflags_t;
    typedef struct packed {
      rrv64_frm_e     frm;
      rrv64_fflags_t  fflags; 
    } rrv64_csr_fcsr_t;
//Backend package
//===============================================

`include "rrv64_core_be_typedef_pkg.sv"

//LSU typedef
`include "rrv64_core_lsu_typedef_pkg.sv"



typedef struct packed {
        logic[RRV64_L1D_TAG_W -1:0]         tag;
        logic[RRV64_L1D_SET_IDX_W -1:0]     set_idx;
        logic                               bank_idx;  
      }rrv64_l1d_line_addr_t;

typedef struct packed {
        rrv64_l1d_line_addr_t             line_addr;
        logic[RRV64_LINE_OFFSET_W -1:0]   offset;
      }rrv64_l1d_addr_t;

typedef struct packed {
        logic[RRV64_LSU_ID_WIDTH -1:0]         lsu_id;
        logic[RRV64_ROB_ADDR_W -1:0]           rob_id;
        lsu_op_e                               req_type;
        rrv64_l1d_addr_t                       paddr;
        logic[RRV64_INT_PHY_REG_ADDR_W -1:0]   ld_rd_idx;
        logic[RRV64_INT_REG_DATA_W     -1:0]   st_dat;
        logic                                  is_cacheable;
        logic                                  is_secure;
} rrv64_lsu_l1d_req_t;

typedef struct packed {
        logic[RRV64_LSU_ID_WIDTH -1:0]        lsu_id;
        logic[RRV64_ROB_ADDR_W -1:0]          rob_id;
        lsu_op_e                              req_type;
        logic[RRV64_INT_REG_DATA_W -1:0]      ld_data;
        logic[RRV64_INT_PHY_REG_ADDR_W-1:0]   ld_rd_idx;
        logic                                 err;  
} rrv64_lsu_l1d_resp_t;

endpackage
