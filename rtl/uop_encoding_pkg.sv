`ifndef __UOP_ENCODING_PKG_SV__
`define __UOP_ENCODING_PKG_SV__

package uop_encoding_pkg;

    localparam int unsigned MAJOR_OP_WIDTH = 3;
    
    
    localparam int unsigned MINOR_OP_WIDTH = 5;

    localparam int unsigned ALU_OP_WIDTH = 4;
    localparam int unsigned MUL_OP_WIDTH = 3;
    localparam int unsigned DIV_OP_WIDTH = 3;
    localparam int unsigned BRU_OP_WIDTH = 3;
    
    localparam int unsigned INT_OP_WIDTH = 4;
    
    localparam int unsigned CSR_OP_WIDTH = 4;
    
    localparam int unsigned LDU_OP_WIDTH = 3;
    localparam int unsigned STU_OP_WIDTH = 5;
    localparam int unsigned LSU_OP_WIDTH = STU_OP_WIDTH > LDU_OP_WIDTH ? STU_OP_WIDTH : LDU_OP_WIDTH;    

    typedef enum logic [2:0] {
        NONE,
        IIMM,
        SIMM,
        SBIMM,
        UIMM,
        UJIMM
    } imm_type_t;


    typedef enum logic [MAJOR_OP_WIDTH-1:0] {
        OP_ALU,
        OP_MUL,
        OP_DIV,
        OP_BRU,
        OP_CSR,
        OP_LDU,
        OP_STU,
        OP_FPU
    } major_op_t;

    typedef enum logic [ALU_OP_WIDTH-1:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_SLL,
        ALU_SLT,
        ALU_SLTU,
        ALU_XOR,
        ALU_SRL,
        ALU_SRA,
        ALU_OR,
        ALU_AND,
        // RV64 Only
        ALU_ADDW,
        ALU_SUBW,
        ALU_SLLW,
        ALU_SRLW,
        ALU_SRAW
    } alu_minor_op_t;

    typedef enum logic [MUL_OP_WIDTH-1:0] {
        MUL_MUL,
        MUL_MULH,
        MUL_MULHSU,
        MUL_MULHU,
        // RV64 Only
        MUL_MULW
    } mul_minor_op_t;

    typedef enum logic [DIV_OP_WIDTH-1:0] {
        DIV_DIV,
        DIV_DIVU,
        DIV_REM,
        DIV_REMU,
        // RV64 Only
        DIV_DIVW,
        DIV_DIVUW,
        DIV_REMW,
        DIV_REMUW
    } div_minor_op_t;

    typedef enum logic [BRU_OP_WIDTH-1:0] {
        BRU_JAL,
        BRU_JALR,
        BRU_BEQ,
        BRU_BNE,
        BRU_BLT,
        BRU_BGE,
        BRU_BLTU,
        BRU_BGEU
    } bru_minor_op_t;

    typedef enum logic [CSR_OP_WIDTH-1:0] {
        CSR_CSRRW,
        CSR_CSRRS,
        CSR_CSRRC,
        CSR_CSRR,
        CSR_MRET,
        CSR_SRET,
        CSR_DRET,
        CSR_WFI,
        CSR_FENCEI,
        CSR_SFENCE_VMA
    } csr_minor_op_t;

    typedef enum logic [LDU_OP_WIDTH-1:0] {
        LDU_LB,
        LDU_LH,
        LDU_LW,
        LDU_LBU,
        LDU_LHU,
        LDU_LWU,
        // RV64 Only
        LDU_LD
    } ldu_minor_op_t;

    typedef enum logic [STU_OP_WIDTH-1:0] {
        STU_SB,
        STU_SH,
        STU_SW,
        // RV64 Only
        STU_SD,
        STU_FENCE,

        STU_LRW     ,
        STU_LRD     ,
        STU_SCW     ,
        STU_SCD     ,
        STU_AMOSWAPW,
        STU_AMOSWAPD,
        STU_AMOADDW ,
        STU_AMOADDD ,
        STU_AMOANDW ,
        STU_AMOANDD ,
        STU_AMOORW  ,
        STU_AMOORD  ,
        STU_AMOXORW ,
        STU_AMOXORD ,
        STU_AMOMAXW ,
        STU_AMOMAXD ,
        STU_AMOMAXUW,
        STU_AMOMAXUD,
        STU_AMOMINW ,
        STU_AMOMIND ,
        STU_AMOMINUW,
        STU_AMOMINUD
    } stu_minor_op_t;


endpackage

`endif