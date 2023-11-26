//import  rrv64_core_typedef_pkg::*;


typedef enum logic[2:0]{//{{{
    EXE_TYPE_ALU    = 3'd0,
    EXE_TYPE_MUL    = 3'd1,
    EXE_TYPE_CSR    = 3'd2,
    EXE_TYPE_BRU    = 3'd3,
    EXE_TYPE_DIV    = 3'd4,
    EXE_TYPE_LSU    = 3'd5,
    EXE_TYPE_SYS    = 3'd6,
    EXE_TYPE_FPU    = 3'd7 //}}}
}exe_type_e;
typedef enum logic[1:0]{//{{{
    EXE_FP_WR_LSU  = 2'd0,
    // EXE_FP_WR_LSU1  = 2'd1,
    // EXE_FP_WR_FPU   = 2'd2,
    EXE_FP_WR_FPU   = 2'd1//}}}
}exe_fp_wr_port_e;
typedef enum logic[3:0]{//{{{
    EXE_INT_WR_ALU0 = 4'd0,
    EXE_INT_WR_ALU1 = 4'd1,
    EXE_INT_WR_MUL0 = 4'd2,
    EXE_INT_WR_MUL1 = 4'd3,
    EXE_INT_WR_BRU  = 4'd4,
    EXE_INT_WR_DIV  = 4'd5,
    EXE_INT_WR_LSU0 = 4'd6,
    // EXE_INT_WR_LSU1 = 4'd7,
    EXE_INT_WR_FPU  = 4'd7//}}}
}exe_int_wr_port_e;
typedef enum logic[1:0]{//{{{
    EXE_INT_EARLY_WR_MUL0   = 2'd0,
    EXE_INT_EARLY_WR_MUL1   = 2'd1,
    EXE_INT_EARLY_WR_LSU    = 2'd2
    // EXE_INT_EARLY_WR_MUL1   = 3'd3,
    // EXE_INT_EARLY_WR_BRU    = 3'd4,
    // EXE_INT_EARLY_WR_DIV    = 3'd5,
    // EXE_INT_EARLY_WR_LSU0   = 3'd6,
    // EXE_INT_EARLY_WR_LSU1   = 3'd7,//}}}
}exe_int_early_wr_port_e;
typedef enum logic[3:0]{//{{{
    ROB_WR_ALU0     = 4'd0,
    ROB_WR_ALU1     = 4'd1,
    ROB_WR_MUL0     = 4'd2,
    ROB_WR_MUL1     = 4'd3,
    ROB_WR_BRU      = 4'd4,
    ROB_WR_DIV      = 4'd5,
    ROB_WR_LSU0     = 4'd6,
    ROB_WR_LSU1     = 4'd7,
    ROB_WR_FPU      = 4'd8//}}}
}exe_rob_wr_e;
typedef enum logic[1:0]{//{{{
    BP_JUMP     = 2'b00,
    BP_FCALL    = 2'b01,
    BP_FRET     = 2'b10,
    BP_BR       = 2'b11//}}}
}ct_type_e;
typedef enum logic[1:0]{//{{{
    ROB_RD_ALU0 = 2'd0,
    ROB_RD_ALU1 = 2'd1,
    ROB_RD_BRU  = 2'd2//}}}
}issuew_rob_e;
typedef enum logic[4:0] {//{{{
    ALU_ADDI        = 5'd0 ,
    ALU_SLTI        = 5'd1 ,
    ALU_SLTIU       = 5'd2 ,
    ALU_ANDI        = 5'd3 ,
    ALU_ORI         = 5'd4 ,
    ALU_XORI        = 5'd5 ,
    ALU_SLLI        = 5'd6 ,
    ALU_SRLI        = 5'd7 ,
    ALU_SRAI        = 5'd8 ,
    ALU_LUI         = 5'd9 ,
    ALU_AUIPC       = 5'd10,
    ALU_ADD         = 5'd11,
    ALU_SLT         = 5'd12,
    ALU_SLTU        = 5'd13,
    ALU_AND         = 5'd14,
    ALU_OR          = 5'd15,
    ALU_XOR         = 5'd16,
    ALU_SLL         = 5'd17,
    ALU_SRL         = 5'd18,
    ALU_SUB         = 5'd19,
    ALU_SRA         = 5'd20,
    ALU_NOP         = 5'd21,
    ALU_ADDIW       = 5'd22,
    ALU_SLLIW       = 5'd23,
    ALU_SRLIW       = 5'd24,
    ALU_SRAIW       = 5'd25,
    ALU_ADDW        = 5'd26,
    ALU_SLLW        = 5'd27,
    ALU_SRLW        = 5'd28,
    ALU_SUBW        = 5'd29,
    ALU_SRAW        = 5'd30//}}}
}alu_op_e;
typedef enum logic[2:0] {//{{{
    CSR_CSRRW          = 3'd0,
    CSR_CSRRS          = 3'd1,
    CSR_CSRRC          = 3'd2,
    CSR_CSRRWI         = 3'd3,
    CSR_CSRRSI         = 3'd4,
    CSR_CSRRCI         = 3'd5//}}}
}csr_op_e;
typedef enum logic[3:0] {//{{{
    SYS_ECALL       = 4'd0,
    SYS_EBREAK      = 4'd1,
    SYS_FENCE       = 4'd2,
    SYS_FENCEI      = 4'd3,
    SYS_MRET        = 4'd4,
    SYS_SRET        = 4'd5,
    SYS_DRET        = 4'd6,
    SYS_WFI         = 4'd7,
    SYS_SFENCEVMA   = 4'd8//}}}
}sys_op_e;
typedef enum logic[2:0] {//{{{
    MUL_MUL         = 3'd0,
    MUL_MULH        = 3'd1,
    MUL_MULHU       = 3'd2,
    MUL_MULHSU      = 3'd3,
    MUL_MULW        = 3'd4//}}}
}mul_op_e;
typedef enum logic[2:0] {//{{{
    BRU_JAL         = 3'd0,
    BRU_JALR        = 3'd1,
    BRU_BE          = 3'd2,
    BRU_BNE         = 3'd3,
    BRU_BLT         = 3'd4,
    BRU_BLTU        = 3'd5,
    BRU_BGE         = 3'd6,
    BRU_BGEU        = 3'd7//}}}
}bru_op_e;
typedef enum logic[2:0] {//{{{
    DIV_DIV         = 3'd0,
    DIV_DIVU        = 3'd1,
    DIV_REM         = 3'd2,
    DIV_REMU        = 3'd3,
    DIV_DIVW        = 3'd4,
    DIV_DIVUW       = 3'd5,
    DIV_REMW        = 3'd6,
    DIV_REMUW       = 3'd7//}}}
}div_op_e;

typedef enum logic[5:0] {//{{{
    LSU_NONE                = 6'd0 ,
    LSU_LB                  = 6'd1 ,
    LSU_LBU                 = 6'd2 ,
    LSU_LH                  = 6'd3 ,
    LSU_LHU                 = 6'd4 ,
    LSU_LW                  = 6'd5 ,
    LSU_LWU                 = 6'd6 ,
    LSU_LD                  = 6'd7 ,
    LSU_SB                  = 6'd8 ,
    LSU_SH                  = 6'd9 ,
    LSU_SW                  = 6'd10,
    LSU_SD                  = 6'd11,
    LSU_LRW                 = 6'd12,
    LSU_LRD                 = 6'd13,
    LSU_SCW                 = 6'd14,
    LSU_SCD                 = 6'd15,
    LSU_AMOSWAPW            = 6'd16,
    LSU_AMOSWAPD            = 6'd17,
    LSU_AMOADDW             = 6'd18,
    LSU_AMOADDD             = 6'd19,
    LSU_AMOANDW             = 6'd20,
    LSU_AMOANDD             = 6'd21,
    LSU_AMOORW              = 6'd22,
    LSU_AMOORD              = 6'd23,
    LSU_AMOXORW             = 6'd24,
    LSU_AMOXORD             = 6'd25,
    LSU_AMOMAXW             = 6'd26,
    LSU_AMOMAXD             = 6'd27,
    LSU_AMOMAXUW            = 6'd28,
    LSU_AMOMAXUD            = 6'd29,
    LSU_AMOMINW             = 6'd30,
    LSU_AMOMIND             = 6'd31,
    LSU_AMOMINUW            = 6'd32,
    LSU_AMOMINUD            = 6'd33,
    LSU_FLW                 = 6'd34,
    LSU_FSW                 = 6'd35,
    LSU_FLD                 = 6'd36,
    LSU_FSD                 = 6'd37,
    LSU_FENCE               = 6'd38,
    LSU_FENCEI              = 6'd39,
    LSU_SFENCEVMA_ALL       = 6'd40,
    LSU_SFENCEVMA_ASID      = 6'd41,
    LSU_SFENCEVMA_VA        = 6'd42,
    LSU_SFENCEVMA_ASID_VA   = 6'd43
}lsu_op_e;
typedef enum  logic[5:0]{
    //{{{
    FPU_FADD_S            = {1'b0,5'd0 },
    FPU_FSUB_S            = {1'b0,5'd1 },
    FPU_FMUL_S            = {1'b0,5'd2 },
    FPU_FDIV_S            = {1'b0,5'd3 },
    FPU_FMIN_S            = {1'b0,5'd4 },
    FPU_FMAX_S            = {1'b0,5'd5 },
    FPU_FSQRT_S           = {1'b0,5'd6 },
    FPU_FMADD_S           = {1'b0,5'd7 },
    FPU_FNMADD_S          = {1'b0,5'd8 },
    FPU_FMSUB_S           = {1'b0,5'd9 },
    FPU_FNMSUB_S          = {1'b0,5'd10},
    FPU_FCVT_S_W          = {1'b0,5'd11},
    FPU_FCVT_S_WU         = {1'b0,5'd12},
    FPU_FCVT_S_L          = {1'b0,5'd13},
    FPU_FCVT_S_LU         = {1'b0,5'd14},
    FPU_FCVT_W_S          = {1'b0,5'd15},
    FPU_FCVT_WU_S         = {1'b0,5'd16},
    FPU_FCVT_L_S          = {1'b0,5'd17},
    FPU_FCVT_LU_S         = {1'b0,5'd18},
    FPU_FSGNJ_S           = {1'b0,5'd19},
    FPU_FSGNJN_S          = {1'b0,5'd20},
    FPU_FSGNJX_S          = {1'b0,5'd21},
    FPU_FMV_W_X           = {1'b0,5'd22},
    FPU_FMV_X_W           = {1'b0,5'd23},
    FPU_FCMPEQ_S          = {1'b0,5'd24},
    FPU_FCMPLT_S          = {1'b0,5'd25},
    FPU_FCMPLE_S          = {1'b0,5'd26},
    FPU_FCLASS_S          = {1'b0,5'd27},
    FPU_FADD_D            = {1'b1,5'd0 },
    FPU_FSUB_D            = {1'b1,5'd1 },
    FPU_FMUL_D            = {1'b1,5'd2 },
    FPU_FDIV_D            = {1'b1,5'd3 },
    FPU_FMIN_D            = {1'b1,5'd4 },
    FPU_FMAX_D            = {1'b1,5'd5 },
    FPU_FSQRT_D           = {1'b1,5'd6 },
    FPU_FMADD_D           = {1'b1,5'd7 },
    FPU_FNMADD_D          = {1'b1,5'd8 },
    FPU_FMSUB_D           = {1'b1,5'd9 },
    FPU_FNMSUB_D          = {1'b1,5'd10},
    FPU_FCVT_D_W          = {1'b1,5'd11},
    FPU_FCVT_D_WU         = {1'b1,5'd12},
    FPU_FCVT_D_L          = {1'b1,5'd13},
    FPU_FCVT_D_LU         = {1'b1,5'd14},
    FPU_FCVT_W_D          = {1'b1,5'd15},
    FPU_FCVT_WU_D         = {1'b1,5'd16},
    FPU_FCVT_L_D          = {1'b1,5'd17},
    FPU_FCVT_LU_D         = {1'b1,5'd18},
    FPU_FCVT_S_D          = {1'b1,5'd19},
    FPU_FCVT_D_S          = {1'b1,5'd20},
    FPU_FSGNJ_D           = {1'b1,5'd21},
    FPU_FSGNJN_D          = {1'b1,5'd22},
    FPU_FSGNJX_D          = {1'b1,5'd23},
    FPU_FMV_D_X           = {1'b1,5'd24},
    FPU_FMV_X_D           = {1'b1,5'd25},
    FPU_FCMPEQ_D          = {1'b1,5'd26},
    FPU_FCMPLT_D          = {1'b1,5'd27},
    FPU_FCMPLE_D          = {1'b1,5'd28},
    FPU_FCLASS_D          = {1'b1,5'd29}//}}}
}fpu_op_e;

    





typedef struct packed{//{{{
    logic                           use_rd;
    logic                           rd_is_fp;
    logic[RRV64_REG_ADDR_W-1:0]     rd;
    logic                           use_rs1;
    logic                           rs1_is_fp;
    logic[RRV64_REG_ADDR_W-1:0]     rs1;
    logic                           use_rs2;
    logic                           rs2_is_fp;
    logic[RRV64_REG_ADDR_W-1:0]     rs2;
    logic                           use_rs3;//only for fp
    logic[RRV64_REG_ADDR_W-1:0]     rs3;
    logic[RRV64_VPC_W-1:0]          pc;//virtual pc
    exe_type_e                      exe_type;
    logic[RRV64_EXE_SUB_OP_W-1:0]   exe_sub_op;
    logic                           is_rvc;//for branch prediction
    ct_type_e                       ct_type;
    logic[RRV64_VPC_W-1:0]          pred_npc;//for branch prediction,target pc
    logic                           pred_taken;//for branch prediction
    logic[RRV64_DCD_IMM_W-1:0]      imm;
    rrv64_frm_e                     frm;
    rrv64_exception_t               excp_info;
    //}}}
}dcd_be_info_t;

typedef struct packed{//{{{
    logic[RRV64_VPC_W-1:0]              pc;//virtual pc
    exe_type_e                          exe_type;
    logic[RRV64_EXE_SUB_OP_W-1:0]       exe_sub_op;
    ct_type_e                           ct_type;
    logic                               is_rvc;//for branch prediction
    logic[RRV64_VPC_W-1:0]              pred_npc;//for branch prediction,target pc
    logic                               pred_taken;//for branch prediction
    logic[RRV64_DCD_IMM_W-1:0]          imm;
//    logic                               use_rd;
    logic                               rd_is_fp;
    logic                               use_rs1;
    logic                               rs1_is_fp;
    logic                               use_rs2;
    logic                               rs2_is_fp;
    logic                               use_rs3;
    logic[RRV64_REG_ADDR_W-1:0]         rd;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prs1;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prs2;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prs3;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prd;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     lprd;
    rrv64_frm_e                         frm;
    rrv64_exception_t                   excp_info;
    //}}}
}rename_disp_t;

typedef struct packed{//{{{
    logic[RRV64_REG_ADDR_W-1:0]         rd;
    logic                               rd_is_fp;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prd;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     lprd;//}}}
}rob_rename_t;
typedef struct packed{//{{{
    logic[RRV64_REG_ADDR_W-1:0]     rd;
    logic                           rd_is_fp;
    logic[RRV64_PHY_REG_ADDR_W-1:0] prd;
    logic[RRV64_PHY_REG_ADDR_W-1:0] lprd;
    logic[RRV64_VPC_W-1:0]          pc;
    logic                           is_loadstore;
    logic                           is_br;
    logic                           sys_inst;
    sys_op_e                        sys_inst_type;//}}}
}disp_rob_t;

typedef struct packed{//{{{
    logic[RRV64_ROB_ADDR_W-1:0]         rob_idx;
    logic[RRV64_EXE_SUB_OP_W-1:0]       exe_sub_op;
//    logic                               use_rd;
    logic                               use_rs1;
    logic                               use_rs2;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prd;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prs1;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prs2;//}}}
}disp_issuew_comm_t;

typedef struct packed{//{{{
    disp_issuew_comm_t          comm;//common signal shared by all issueq 
    exe_type_e                  exe_type;
    logic[RRV64_ALU_IMM_W-1:0]  imm;
    logic[RRV64_REG_ADDR_W-1:0] rd;
    //}}}
}disp_issuew_alu_t;
typedef struct packed{//{{{
    disp_issuew_comm_t          comm;//common signal shared by all issueq 
    logic[RRV64_BRU_IMM_W-1:0]  imm;
    logic                       is_rvc;
    ct_type_e                   ct_type;
    logic[RRV64_VPC_W-1:0]      pred_npc;
    logic                       pred_taken;//}}}
}disp_issuew_bru_t;
typedef struct packed{//{{{
    disp_issuew_comm_t          comm;//common signal shared by all issueq 
    logic[RRV64_LSU_IMM_W-1:0]  imm;
    logic                       rs2_is_fp;//}}}
}disp_issuew_lsu_t;
typedef struct packed{//{{{
    disp_issuew_comm_t              comm;//common signal shared by all issueq 
    logic                           rs1_is_fp;
    logic                           use_rs3;
    logic[RRV64_PHY_REG_ADDR_W-1:0] prs3;
    rrv64_frm_e                     frm;//}}}

}disp_issuew_fpu_t;

typedef struct packed{//{{{
    logic[RRV64_ROB_ADDR_W-1:0]             rob_idx;
    logic[RRV64_EXE_SUB_OP_W-1:0]           exe_sub_op;
    logic                                   src1_vld;
    logic[RRV64_REG_DATA_W-1:0]             src1_data;
    logic                                   src2_vld;//immedate should be put in src2 register after doing sign extension.
    logic[RRV64_REG_DATA_W-1:0]             src2_data;
//    logic                                   use_rd;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prd;//}}}
}issuew_rsvst_comm_t;
typedef struct packed{//{{{
    issuew_rsvst_comm_t             comm;
    exe_type_e                      exe_type;
    //}}}
}issuew_rsvst_alu_t;
typedef struct packed{//{{{
    issuew_rsvst_comm_t             comm;
    logic[RRV64_VPC_W-1:0]          pc;
    logic[RRV64_BRU_IMM_W-1:0]      imm;
    logic                           is_rvc;
    ct_type_e                       ct_type;
    logic[RRV64_VPC_W-1:0]          pred_npc;
    logic                           pred_taken;//}}}
}issuew_rsvst_bru_t;
typedef struct packed{//{{{
    issuew_rsvst_comm_t             comm;
    logic[RRV64_LSU_IMM_W-1:0]      imm;///}}}
}issuew_rsvst_lsu_t;
typedef struct packed{//{{{
    issuew_rsvst_comm_t             comm;
    logic                           src3_vld;
    logic[RRV64_REG_DATA_W-1:0]     src3_data;
    rrv64_frm_e                     frm;//}}}
}issuew_rsvst_fpu_t;
typedef struct packed{//{{{
    ct_type_e                       ct_type;//control transfer type
    logic                           is_rvc;
    logic                           taken;//for branch
    logic                           mis_pred;
    logic[RRV64_VPC_W-1:0]          pc;
    logic[RRV64_VPC_W-1:0]          npc;//}}}
}bru_bp_t;
typedef struct packed{//{{{
    logic[RRV64_ROB_ADDR_W-1:0]           rob_idx;
    logic[RRV64_EXE_SUB_OP_W-1:0]         exe_sub_op;
    logic[RRV64_REG_DATA_W-1:0]       src1_data;
    logic[RRV64_REG_DATA_W-1:0]       src2_data;
    logic[RRV64_PHY_REG_ADDR_W-1:0]   prd;//}}}
}rsvst_exe_comm_t;
typedef struct packed{//{{{
    rsvst_exe_comm_t                comm;
    exe_type_e                      exe_type;//}}}
}rsvst_exe_alu_t;
typedef struct packed{//{{{
    rsvst_exe_comm_t                comm;
    logic[RRV64_VPC_W-1:0]          pc;
    logic[RRV64_BRU_IMM_W-1:0]      imm;
    logic                           is_rvc;
    ct_type_e                       ct_type;
    logic[RRV64_VPC_W-1:0]          pred_npc;
    logic                           pred_taken;//}}}
}rsvst_exe_bru_t;
typedef struct packed{//{{{
    rsvst_exe_comm_t                comm;
    logic[RRV64_REG_DATA_W-1:0]     src3_data;
    rrv64_frm_e                     frm;//}}}
}rsvst_exe_fpu_t;
typedef struct packed{//{{{
    rsvst_exe_comm_t                comm;
    logic[RRV64_LSU_IMM_W-1:0]      imm;//}}}
}rsvst_exe_lsu_t;

typedef struct packed{//{{{
    logic[RRV64_ROB_ADDR_W-1:0]           rob_idx;
    lsu_op_e         sub_op;
    logic[RRV64_REG_DATA_W-1:0]           addr;
    logic[RRV64_REG_DATA_W-1:0]           data;
    logic[RRV64_PHY_REG_ADDR_W-1:0]       prd;
    logic[RRV64_LSU_IMM_W-1:0]            imm;//}}}
} be_rsvst_lsu_req_t;












//csr typedef
//---------------------------------------
  typedef enum logic [11:0] {//{{{
    // M mode accessible registers
    RRV64_CSR_ADDR_MSTATUS         = 12'h300,
    RRV64_CSR_ADDR_MISA            = 12'h301,
    RRV64_CSR_ADDR_MEDELEG         = 12'h302,
    RRV64_CSR_ADDR_MIDELEG         = 12'h303,
    RRV64_CSR_ADDR_MIE             = 12'h304,
    RRV64_CSR_ADDR_MTVEC           = 12'h305,
    RRV64_CSR_ADDR_MCOUNTEREN      = 12'h306,
    RRV64_CSR_ADDR_MSCRATCH        = 12'h340,
    RRV64_CSR_ADDR_MEPC            = 12'h341,
    RRV64_CSR_ADDR_MCAUSE          = 12'h342,
    RRV64_CSR_ADDR_MTVAL           = 12'h343,
    RRV64_CSR_ADDR_MIP             = 12'h344,
    RRV64_CSR_ADDR_PMPCFG0         = 12'h3A0,
    RRV64_CSR_ADDR_PMPCFG1         = 12'h3A1,
    RRV64_CSR_ADDR_PMPCFG2         = 12'h3A2,
    RRV64_CSR_ADDR_PMPCFG3         = 12'h3A3,
    RRV64_CSR_ADDR_PMPADDR0        = 12'h3B0,
    RRV64_CSR_ADDR_PMPADDR1        = 12'h3B1,
    RRV64_CSR_ADDR_PMPADDR2        = 12'h3B2,
    RRV64_CSR_ADDR_PMPADDR3        = 12'h3B3,
    RRV64_CSR_ADDR_PMPADDR4        = 12'h3B4,
    RRV64_CSR_ADDR_PMPADDR5        = 12'h3B5,
    RRV64_CSR_ADDR_PMPADDR6        = 12'h3B6,
    RRV64_CSR_ADDR_PMPADDR7        = 12'h3B7,
    RRV64_CSR_ADDR_PMPADDR8        = 12'h3B8,
    RRV64_CSR_ADDR_PMPADDR9        = 12'h3B9,
    RRV64_CSR_ADDR_PMPADDR10       = 12'h3BA,
    RRV64_CSR_ADDR_PMPADDR11       = 12'h3BB,
    RRV64_CSR_ADDR_PMPADDR12       = 12'h3BC,
    RRV64_CSR_ADDR_PMPADDR13       = 12'h3BD,
    RRV64_CSR_ADDR_PMPADDR14       = 12'h3BE,
    RRV64_CSR_ADDR_PMPADDR15       = 12'h3BF,
    RRV64_CSR_ADDR_MCOUNTINHIBIT   = 12'h320,
    RRV64_CSR_ADDR_MHPMEVENT3      = 12'h323,
    RRV64_CSR_ADDR_MHPMEVENT4      = 12'h324,
    RRV64_CSR_ADDR_MHPMEVENT5      = 12'h325,
    RRV64_CSR_ADDR_MHPMEVENT6      = 12'h326,
    RRV64_CSR_ADDR_MHPMEVENT7      = 12'h327,
    RRV64_CSR_ADDR_MHPMEVENT8      = 12'h328,
    RRV64_CSR_ADDR_MHPMEVENT9      = 12'h329,
    RRV64_CSR_ADDR_MHPMEVENT10     = 12'h32A,
    RRV64_CSR_ADDR_MHPMEVENT11     = 12'h32B,
    RRV64_CSR_ADDR_MHPMEVENT12     = 12'h32C,
    RRV64_CSR_ADDR_MHPMEVENT13     = 12'h32D,
    RRV64_CSR_ADDR_MHPMEVENT14     = 12'h32E,
    RRV64_CSR_ADDR_MHPMEVENT15     = 12'h32F,
    RRV64_CSR_ADDR_MHPMEVENT16     = 12'h330,
    RRV64_CSR_ADDR_MHPMEVENT17     = 12'h331,
    RRV64_CSR_ADDR_MHPMEVENT18     = 12'h332,
    RRV64_CSR_ADDR_MHPMEVENT19     = 12'h333,
    RRV64_CSR_ADDR_MHPMEVENT20     = 12'h334,
    RRV64_CSR_ADDR_MHPMEVENT21     = 12'h335,
    RRV64_CSR_ADDR_MHPMEVENT22     = 12'h336,
    RRV64_CSR_ADDR_MHPMEVENT23     = 12'h337,
    RRV64_CSR_ADDR_MHPMEVENT24     = 12'h338,
    RRV64_CSR_ADDR_MHPMEVENT25     = 12'h339,
    RRV64_CSR_ADDR_MHPMEVENT26     = 12'h33A,
    RRV64_CSR_ADDR_MHPMEVENT27     = 12'h33B,
    RRV64_CSR_ADDR_MHPMEVENT28     = 12'h33C,
    RRV64_CSR_ADDR_MHPMEVENT29     = 12'h33D,
    RRV64_CSR_ADDR_MHPMEVENT30     = 12'h33E,
    RRV64_CSR_ADDR_MHPMEVENT31     = 12'h33F,
    RRV64_CSR_ADDR_TSELECT         = 12'h7A0,
    RRV64_CSR_ADDR_TDATA1          = 12'h7A1,
    RRV64_CSR_ADDR_TDATA2          = 12'h7A2,
    RRV64_CSR_ADDR_TDATA3          = 12'h7A3,
    RRV64_CSR_ADDR_DCSR            = 12'h7B0,
    RRV64_CSR_ADDR_DPC             = 12'h7B1,
    RRV64_CSR_ADDR_DSCRATCH0       = 12'h7B2,
    RRV64_CSR_ADDR_DSCRATCH1       = 12'h7B3,
    RRV64_CSR_ADDR_MCYCLE          = 12'hB00,
    RRV64_CSR_ADDR_MINSTRET        = 12'hB02,
    RRV64_CSR_ADDR_MHPMCOUNTER3    = 12'hB03,
    RRV64_CSR_ADDR_MHPMCOUNTER4    = 12'hB04,
    RRV64_CSR_ADDR_MHPMCOUNTER5    = 12'hB05,
    RRV64_CSR_ADDR_MHPMCOUNTER6    = 12'hB06,
    RRV64_CSR_ADDR_MHPMCOUNTER7    = 12'hB07,
    RRV64_CSR_ADDR_MHPMCOUNTER8    = 12'hB08,
    RRV64_CSR_ADDR_MHPMCOUNTER9    = 12'hB09,
    RRV64_CSR_ADDR_MHPMCOUNTER10   = 12'hB0A,
    RRV64_CSR_ADDR_MHPMCOUNTER11   = 12'hB0B,
    RRV64_CSR_ADDR_MHPMCOUNTER12   = 12'hB0C,
    RRV64_CSR_ADDR_MHPMCOUNTER13   = 12'hB0D,
    RRV64_CSR_ADDR_MHPMCOUNTER14   = 12'hB0E,
    RRV64_CSR_ADDR_MHPMCOUNTER15   = 12'hB0F,
    RRV64_CSR_ADDR_MHPMCOUNTER16   = 12'hB10,
    RRV64_CSR_ADDR_MHPMCOUNTER17   = 12'hB11,
    RRV64_CSR_ADDR_MHPMCOUNTER18   = 12'hB12,
    RRV64_CSR_ADDR_MHPMCOUNTER19   = 12'hB13,
    RRV64_CSR_ADDR_MHPMCOUNTER20   = 12'hB14,
    RRV64_CSR_ADDR_MHPMCOUNTER21   = 12'hB15,
    RRV64_CSR_ADDR_MHPMCOUNTER22   = 12'hB16,
    RRV64_CSR_ADDR_MHPMCOUNTER23   = 12'hB17,
    RRV64_CSR_ADDR_MHPMCOUNTER24   = 12'hB18,
    RRV64_CSR_ADDR_MHPMCOUNTER25   = 12'hB19,
    RRV64_CSR_ADDR_MHPMCOUNTER26   = 12'hB1A,
    RRV64_CSR_ADDR_MHPMCOUNTER27   = 12'hB1B,
    RRV64_CSR_ADDR_MHPMCOUNTER28   = 12'hB1C,
    RRV64_CSR_ADDR_MHPMCOUNTER29   = 12'hB1D,
    RRV64_CSR_ADDR_MHPMCOUNTER30   = 12'hB1E,
    RRV64_CSR_ADDR_MHPMCOUNTER31   = 12'hB1F,
    RRV64_CSR_ADDR_MVENDORID       = 12'hF11,
    RRV64_CSR_ADDR_MARCHID         = 12'hF12,
    RRV64_CSR_ADDR_MIMPID          = 12'hF13,
    RRV64_CSR_ADDR_MHARTID         = 12'hF14,

    // S mode accessible csrs
    RRV64_CSR_ADDR_SSTATUS         = 12'h100,
    RRV64_CSR_ADDR_SEDELEG         = 12'h102,
    RRV64_CSR_ADDR_SIDELEG         = 12'h103,
    RRV64_CSR_ADDR_SIE             = 12'h104,
    RRV64_CSR_ADDR_STVEC           = 12'h105,
    RRV64_CSR_ADDR_SCOUNTEREN      = 12'h106,
    RRV64_CSR_ADDR_SSCRATCH        = 12'h140,
    RRV64_CSR_ADDR_SEPC            = 12'h141,
    RRV64_CSR_ADDR_SCAUSE          = 12'h142,
    RRV64_CSR_ADDR_STVAL           = 12'h143,
    RRV64_CSR_ADDR_SIP             = 12'h144,
    RRV64_CSR_ADDR_SATP            = 12'h180,

    // U mode accessible csrs
    RRV64_CSR_ADDR_USTATUS         = 12'h000,
    RRV64_CSR_ADDR_UIE             = 12'h004,
    RRV64_CSR_ADDR_UTVEC           = 12'h005,
    RRV64_CSR_ADDR_USCRATCH        = 12'h040,
    RRV64_CSR_ADDR_UEPC            = 12'h041,
    RRV64_CSR_ADDR_UCAUSE          = 12'h042,
    RRV64_CSR_ADDR_UTVAL           = 12'h043,
    RRV64_CSR_ADDR_UIP             = 12'h044,
    RRV64_CSR_ADDR_FFLAGS          = 12'h001,
    RRV64_CSR_ADDR_FRM             = 12'h002,
    RRV64_CSR_ADDR_FCSR            = 12'h003,
    RRV64_CSR_ADDR_CYCLE           = 12'hC00,
    RRV64_CSR_ADDR_TIME            = 12'hC01,
    RRV64_CSR_ADDR_INSTRET         = 12'hC02,
    RRV64_CSR_ADDR_HPMCOUNTER3     = 12'hC03,
    RRV64_CSR_ADDR_HPMCOUNTER4     = 12'hC04,
    RRV64_CSR_ADDR_HPMCOUNTER5     = 12'hC05,
    RRV64_CSR_ADDR_HPMCOUNTER6     = 12'hC06,
    RRV64_CSR_ADDR_HPMCOUNTER7     = 12'hC07,
    RRV64_CSR_ADDR_HPMCOUNTER8     = 12'hC08,
    RRV64_CSR_ADDR_HPMCOUNTER9     = 12'hC09,
    RRV64_CSR_ADDR_HPMCOUNTER10    = 12'hC0A,
    RRV64_CSR_ADDR_HPMCOUNTER11    = 12'hC0B,
    RRV64_CSR_ADDR_HPMCOUNTER12    = 12'hC0C,
    RRV64_CSR_ADDR_HPMCOUNTER13    = 12'hC0D,
    RRV64_CSR_ADDR_HPMCOUNTER14    = 12'hC0E,
    RRV64_CSR_ADDR_HPMCOUNTER15    = 12'hC0F,
    RRV64_CSR_ADDR_HPMCOUNTER16    = 12'hC10,
    RRV64_CSR_ADDR_HPMCOUNTER17    = 12'hC11,
    RRV64_CSR_ADDR_HPMCOUNTER18    = 12'hC12,
    RRV64_CSR_ADDR_HPMCOUNTER19    = 12'hC13,
    RRV64_CSR_ADDR_HPMCOUNTER20    = 12'hC14,
    RRV64_CSR_ADDR_HPMCOUNTER21    = 12'hC15,
    RRV64_CSR_ADDR_HPMCOUNTER22    = 12'hC16,
    RRV64_CSR_ADDR_HPMCOUNTER23    = 12'hC17,
    RRV64_CSR_ADDR_HPMCOUNTER24    = 12'hC18,
    RRV64_CSR_ADDR_HPMCOUNTER25    = 12'hC19,
    RRV64_CSR_ADDR_HPMCOUNTER26    = 12'hC1A,
    RRV64_CSR_ADDR_HPMCOUNTER27    = 12'hC1B,
    RRV64_CSR_ADDR_HPMCOUNTER28    = 12'hC1C,
    RRV64_CSR_ADDR_HPMCOUNTER29    = 12'hC1D,
    RRV64_CSR_ADDR_HPMCOUNTER30    = 12'hC1E,
    RRV64_CSR_ADDR_HPMCOUNTER31    = 12'hC1F // }}}
  } rrv64_csr_addr_t;

  typedef struct packed { // {{{
    logic Z;
    logic Y;
    logic X;
    logic W;
    logic V;
    logic U;
    logic T;
    logic S;
    logic R;
    logic Q;
    logic P;
    logic O;
    logic N;
    logic M;
    logic L;
    logic K;
    logic J;
    logic I;
    logic H;
    logic G;
    logic F;
    logic E;
    logic D;
    logic C;
    logic B;
    logic A;// }}}
  } rrv64_misa_ext_t;
  typedef struct packed { // {{{
    logic [ 1:0]  MXL; // [63:62]
    // logic [35:0]  reserved_61_to_26;
    rrv64_misa_ext_t  EXTENSIONS; // [25:0] }}}
  } rrv64_csr_misa_t;
  typedef enum logic [63:0] { // {{{
    RRV64_TRAP_CAUSE_U_SW_INT = {1'b1, 63'('d0)},
    RRV64_TRAP_CAUSE_S_SW_INT = {1'b1, 63'('d1)},
    RRV64_TRAP_CAUSE_M_SW_INT = {1'b1, 63'('d3)},
    RRV64_TRAP_CAUSE_U_TIME_INT = {1'b1, 63'('d4)},
    RRV64_TRAP_CAUSE_S_TIME_INT = {1'b1, 63'('d5)},
    RRV64_TRAP_CAUSE_M_TIME_INT = {1'b1, 63'('d7)},
    RRV64_TRAP_CAUSE_U_EXT_INT = {1'b1, 63'('d8)},
    RRV64_TRAP_CAUSE_S_EXT_INT = {1'b1, 63'('d9)},
    RRV64_TRAP_CAUSE_M_EXT_INT = {1'b1, 63'('d11)},
    RRV64_TRAP_CAUSE_INST_ADDR_MISALIGNED = {1'b0, 63'('d0)},
    RRV64_TRAP_CAUSE_INST_ACCESS_FAULT = {1'b0, 63'('d1)},
    RRV64_TRAP_CAUSE_ILLEGAL_INST = {1'b0, 63'('d2)},
    RRV64_TRAP_CAUSE_BREAKPOINT = {1'b0, 63'('d3)},
    RRV64_TRAP_CAUSE_LOAD_ADDR_MISALIGNED = {1'b0, 63'('d4)},
    RRV64_TRAP_CAUSE_LOAD_ACCESS_FAULT = {1'b0, 63'('d5)},
    RRV64_TRAP_CAUSE_STORE_ADDR_MISALIGNED = {1'b0, 63'('d6)},
    RRV64_TRAP_CAUSE_STORE_ACCESS_FAULT = {1'b0, 63'('d7)},
    RRV64_TRAP_CAUSE_ECALL_FROM_U = {1'b0, 63'('d8)},
    RRV64_TRAP_CAUSE_ECALL_FROM_S = {1'b0, 63'('d9)},
    RRV64_TRAP_CAUSE_ECALL_FROM_M = {1'b0, 63'('d11)},
    RRV64_TRAP_CAUSE_INST_PAGE_FAULT = {1'b0, 63'('d12)},
    RRV64_TRAP_CAUSE_LOAD_PAGE_FAULT = {1'b0, 63'('d13)},
    RRV64_TRAP_CAUSE_STORE_PAGE_FAULT = {1'b0, 63'('d15)}
    // }}}
  } rrv64_csr_trap_cause_t;



























    typedef enum logic [1:0] { // {{{
    RRV64_CSR_TVEC_DIRECT = 2'b00,
    RRV64_CSR_TVEC_VECTORED = 2'b01,
    RRV64_CSR_TVEC_RSVD0 = 2'b10,
    RRV64_CSR_TVEC_RSVD1 = 2'b11 // }}}
  } rrv64_csr_tvec_mode_t;
  typedef struct packed { // {{{
    logic [61:0]  base;
    rrv64_csr_tvec_mode_t mode; // }}}
  } rrv64_csr_tvec_t;
  typedef struct packed { // {{{
    logic [51:0]  reserved_63_to_12;
    logic         MEIP;
    logic         reserved_10;
    logic         SEIP;
    logic         reserved_8;
    logic         MTIP;
    logic         reserved_6;
    logic         STIP;
    logic         reserved_4;
    logic         MSIP;
    logic         reserved_2;
    logic         SSIP;
    logic         reserved_0;//}}}
  } rrv64_csr_ip_t;
  typedef struct packed { // {{{
    logic [51:0]  reserved_63_to_12;
    logic         MEIE;
    logic         reserved_10;
    logic         SEIE;
    logic         reserved_8;
    logic         MTIE;
    logic         reserved_6;
    logic         STIE;
    logic         reserved_4;
    logic         MSIE;
    logic         reserved_2;
    logic         SSIE;
    logic         reserved_0; // }}}
  } rrv64_csr_ie_t;
  typedef struct packed { // {{{
    logic         HPM31;
    logic         HPM30;
    logic         HPM29;
    logic         HPM28;
    logic         HPM27;
    logic         HPM26;
    logic         HPM25;
    logic         HPM24;
    logic         HPM23;
    logic         HPM22;
    logic         HPM21;
    logic         HPM20;
    logic         HPM19;
    logic         HPM18;
    logic         HPM17;
    logic         HPM16;
    logic         HPM15;
    logic         HPM14;
    logic         HPM13;
    logic         HPM12;
    logic         HPM11;
    logic         HPM10;
    logic         HPM9;
    logic         HPM8;
    logic         HPM7;
    logic         HPM6;
    logic         HPM5;
    logic         HPM4;
    logic         HPM3;
    logic         IR;
    logic         TM;
    logic         CY; // }}}
  } rrv64_csr_counteren_t;
  typedef struct packed { // {{{
    logic         HPM31;
    logic         HPM30;
    logic         HPM29;
    logic         HPM28;
    logic         HPM27;
    logic         HPM26;
    logic         HPM25;
    logic         HPM24;
    logic         HPM23;
    logic         HPM22;
    logic         HPM21;
    logic         HPM20;
    logic         HPM19;
    logic         HPM18;
    logic         HPM17;
    logic         HPM16;
    logic         HPM15;
    logic         HPM14;
    logic         HPM13;
    logic         HPM12;
    logic         HPM11;
    logic         HPM10;
    logic         HPM9;
    logic         HPM8;
    logic         HPM7;
    logic         HPM6;
    logic         HPM5;
    logic         HPM4;
    logic         HPM3;
    logic         IR;
    logic         O;
    logic         CY; // }}}
  } rrv64_csr_counter_inhibit_t;
  // Supervisor csrs
  typedef struct packed { // {{{
    logic           SD;
    logic [28:0]    reserved_62_to_34;
    logic [1:0]     UXL;
    logic [11:0]    reserved_31_to_20;
    logic           MXR;
    logic           SUM;
    logic           reserved_17;
    logic [1:0]     XS;
    logic [1:0]     FS;
    logic [3:0]     reserved_12_to_9;
    logic           SPP;
    logic [1:0]     reserved_7_to_6;
    logic           SPIE;
    logic           UPIE;
    logic [1:0]     reserved_3_to_2;
    logic           SIE;
    logic           UIE; // }}}
  } rrv64_csr_sstatus_t;

    typedef struct packed { // {{{
    logic [47:0] reserved_63_to_16;
    logic        store_page_fault;
    logic        reserved_14;
    logic        load_page_fault;
    logic        inst_page_fault;
    logic        ecall_from_m;
    logic        reserved_10;
    logic        ecall_from_s;
    logic        ecall_from_u;
    logic        store_access_fault;
    logic        store_addr_misaligned;
    logic        load_access_fault;
    logic        load_addr_misaligned;
    logic        breakpoint;
    logic        illegal_inst;
    logic        inst_access_fault;
    logic        inst_addr_misaligned; // }}}
  } rrv64_csr_edeleg_t;
  typedef struct packed {//{{{
    logic [51:0]  reserved_63_to_12;
    logic         meip;
    logic         reserved_10;
    logic         seip;
    logic         reserved_8;
    logic         mtip;
    logic         reserved_6;
    logic         stip;
    logic         reserved_4;
    logic         msip;
    logic         reserved_2;
    logic         ssip;
    logic         reserved_0;//}}}
  } rrv64_csr_ideleg_t;

  typedef enum logic [3:0] {//{{{
//    RRV64_INT_U_SW    = 'd0,
    RRV64_INT_S_SW    = 'd1,
    RRV64_INT_M_SW    = 'd3,
//    RRV64_INT_U_TIME  = 'd4,
    RRV64_INT_S_TIME  = 'd5,
    RRV64_INT_M_TIME  = 'd7,
//    RRV64_INT_U_EXT   = 'd8,
    RRV64_INT_S_EXT   = 'd9,
    RRV64_INT_M_EXT   = 'd11//}}}
  } rrv64_int_cause_t;

  typedef enum logic [2:0] {//{{{
    DCAUSE_EBREAK   = 3'd1,
    DCAUSE_TM       = 3'd2,
    DCAUSE_HALTREQ  = 3'd3,
    DCAUSE_STEP     = 3'd4
  //}}}
  }rrv64_dcause_e;
  typedef struct packed{//{{{
  logic [3:0]       XDEBUGVER;
  logic [11:0]      reserved_27_to_16;
  logic             EBREAKM;
  logic             reserved_14;
  logic             EBREAKS;
  logic             EBREAKU;
  logic             STEPIE;
  logic             STOPCOUNT;
  logic             STOPTIME;
  rrv64_dcause_e    CAUSE;
  logic             reserved_5;
  logic             MPRVEN;
  logic             NMIP;
  logic             STEP;
  rrv64_prv_t       PRV;//}}}
  }rrv64_dcsr_t;

  typedef enum logic [3:0] { 
    NO_TRIGGER           =  4'd0,
    SIFIVE_ADDR_TRIGGER  =  4'd1,
    ADDR_OR_DATA_TRIGGER =  4'd2,
    INSTR_CNT_TRIGGER    =  4'd3,
    INTERRRUPT_TRIGGER   =  4'd4,
    EXCPTION_TRIGGER     =  4'd5
  } rrv64_tri_type;

  typedef enum logic [3:0] { 
    RAISE_BREAKPOINT_EXCP = 4'd0,
    ENTER_DEBUG_MODE = 4'd1
  } rrv64_tri_action;

 typedef struct packed {
    rrv64_tri_type trig_type;
    logic          dmode;
    logic[5:0]     maskmax;
    logic[29:0]    reserved_52_to_23;
    logic[1:0]     sizehi;
    logic          hit;
    logic          select;
    logic          timing;
    logic[1:0]     sizelo;
    rrv64_tri_action action;
    logic          chain;
    logic[3:0]     match;
    logic          m;
    logic          reserved_5;
    logic          s;
    logic          u;
    logic          execute;
    logic          store;
    logic          load;
 } rrv64_mcontrol_t;

//  typedef struct packed {
//     rrv64_tri_type trig_type;
//     logic          dmode;
//     logic          select;
//     logic          timing;
//     rrv64_tri_action action;
//     logic          chain;
//     logic [3:0]    match;
//     logic          m;
//     logic          s;
//     logic          u;
//     logic          execute;
//     rrv64_tdata_t  tdata2;
//  } trigger_iru_pkt_t;
 
//  typedef struct packed {
//     rrv64_tri_type trig_type;
//     logic          select;
//     logic[3:0]     match;
//     logic          execute;
//     rrv64_tdata_t  tdata2;
//  } trigger_rob_pkt_t;
  
  
//  typedef struct packed {
//     rrv64_tri_type trig_type;
//     logic      select;
//     logic[3:0] match;
//     logic      store;
//     logic      load;
//     rrv64_tdata_t tdata2;
//  } trigger_lsu_pkt_t;

  typedef struct packed{//{{{
    logic                               valid;
    logic                               done;
    logic                               excp;
//    rrv64_excp_cause_t                  excp_cause;
//    logic   [RRV64_INT_REG_DATA_W-1:0]  excp_tval;
    rrv64_fflags_t                      fflags_info;
    logic[RRV64_REG_ADDR_W-1:0]         rd;
    logic                               rd_is_fp;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     prd;
    logic[RRV64_PHY_REG_ADDR_W-1:0]     lprd;
    logic[RRV64_VPC_W-1:0]              pc;
    logic                               is_loadstore;
    logic                               is_br;
    logic                               sys_inst;
    sys_op_e                            sys_inst_type;
    logic[RRV64_ROB_ADDR_W-1:0]         specu_rob_idx;
    logic                               specu_resolved;
    logic                               lsu_wakeup_done;
    logic                               mis_pred;
    logic                               lsu_replay;
  } rob_entry_t;

  typedef struct packed {
    logic  valid;
    rrv64_data_t pc;
  } target_pc_t ;

