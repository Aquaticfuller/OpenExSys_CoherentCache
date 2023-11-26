`ifndef __RISCV_PKG_SV__
`define __RISCV_PKG_SV__

package riscv_pkg;



    localparam int unsigned PRIV_LVL_WIDTH = 2;
    localparam int unsigned PMA_ACCESS_WIDTH = 2;
    localparam int unsigned EXCP_CAUSE_WIDTH = rvh_pkg::XLEN;
    localparam int unsigned EXCP_TVAL_WIDTH = rvh_pkg::XLEN;
    localparam int unsigned REG_TYPE_WIDTH = 2;
    localparam int unsigned ISA_REG_TAG_WIDTH = 5;
    localparam int unsigned CSR_ADDR_WIDTH = 12;


    localparam int unsigned PTE_LVL_WIDTH = 2;

    typedef enum logic [3:0] {
        ModeOff  = 0,
        ModeSv32 = 1,
        ModeSv39 = 8,
        ModeSv48 = 9,
        ModeSv57 = 10,
        ModeSv64 = 11
    } vm_mode_t;

    typedef enum logic [PTE_LVL_WIDTH-1:0] {
        PAGE_4KB = 0,
        PAGE_1MB = 1,
        PAGE_1GB = 2
    } pte_lvl_t;

    // SATP
    localparam vm_mode_t MODE_SV = ModeSv39;
    localparam MODE_WIDTH = 4;
    localparam ASID_WIDTH = 16;
    localparam PAGE_OFFSET_WIDTH = 12;
    localparam VPN_WIDTH = rvh_pkg::VADDR_WIDTH - PAGE_OFFSET_WIDTH;
    localparam PPN_WIDTH = rvh_pkg::PADDR_WIDTH - PAGE_OFFSET_WIDTH;
    localparam PTE_WIDTH = rvh_pkg::XLEN;
    localparam PAGE_LVL_WIDTH = $clog2(VPN_WIDTH/9);

    typedef enum logic [REG_TYPE_WIDTH-1:0] {
        TYPE_NONE,
        TYPE_INT,
        TYPE_FP,
        TYPE_VEC
    } reg_type_t;

    typedef enum logic [PMA_ACCESS_WIDTH-1:0] {
        PMA_ACCESS_LOAD  = 0,
        PMA_ACCESS_STORE = 1,
        PMA_ACCESS_EXEC  = 2
    } pma_access_t;


    typedef enum logic [PRIV_LVL_WIDTH-1:0] {
        PRIV_M = 2'b11,
        PRIV_S = 2'b01,
        PRIV_U = 2'b00
    } priv_lvl_t;


    // type which holds xlen
    typedef enum logic [1:0] {
        XLEN_32  = 2'b01,
        XLEN_64  = 2'b10,
        XLEN_128 = 2'b11
    } xlen_e;

    typedef enum logic [1:0] {
        Off     = 2'b00,
        Initial = 2'b01,
        Clean   = 2'b10,
        Dirty   = 2'b11
    } xs_t;

    typedef struct packed {
        logic sd;  // signal dirty state - read-only
        logic [62:36] wpri4;  // writes preserved reads ignored
        xlen_e sxl;  // variable supervisor mode xlen - hardwired to zero
        xlen_e uxl;  // variable user mode xlen - hardwired to zero
        logic [8:0] wpri3;  // writes preserved reads ignored
        logic tsr;  // trap sret
        logic tw;  // time wait
        logic tvm;  // trap virtual memory
        logic mxr;  // make executable readable
        logic sum;  // permit supervisor user memory access
        logic mprv;  // modify privilege - privilege level for ld/st
        xs_t xs;  // extension register - hardwired to zero
        xs_t fs;  // floating point extension register
        priv_lvl_t mpp;  // holds the previous privilege mode up to machine
        logic [1:0] wpri2;  // writes preserved reads ignored
        logic spp;  // holds the previous privilege mode up to supervisor
        logic mpie;  // machine interrupts enable bit active prior to trap
        logic wpri1;  // writes preserved reads ignored
        logic spie;  // supervisor interrupts enable bit active prior to trap
        logic upie;  // user interrupts enable bit active prior to trap - hardwired to zero
        logic mie;  // machine interrupts enable
        logic wpri0;  // writes preserved reads ignored
        logic sie;  // supervisor interrupts enable
        logic uie;  // user interrupts enable - hardwired to zero
    } mstatus_t;

    localparam logic [63:0] SSTATUS_UIE  = 'h00000001;
    localparam logic [63:0] SSTATUS_SIE  = 'h00000002;
    localparam logic [63:0] SSTATUS_SPIE = 'h00000020;
    localparam logic [63:0] SSTATUS_SPP  = 'h00000100;
    localparam logic [63:0] SSTATUS_FS   = 'h00006000;
    localparam logic [63:0] SSTATUS_XS   = 'h00018000;
    localparam logic [63:0] SSTATUS_SUM  = 'h00040000;
    localparam logic [63:0] SSTATUS_MXR  = 'h00080000;
    localparam logic [63:0] SSTATUS_UPIE = 'h00000010;
    localparam logic [63:0] SSTATUS_UXL  = 64'h0000000300000000;
    localparam logic [63:0] SSTATUS_SD   = {1'b1, 31'h00000000, 1'b0, 31'h00000000};

    localparam logic [63:0] MSTATUS_UIE  = 'h00000001;
    localparam logic [63:0] MSTATUS_SIE  = 'h00000002;
    localparam logic [63:0] MSTATUS_HIE  = 'h00000004;
    localparam logic [63:0] MSTATUS_MIE  = 'h00000008;
    localparam logic [63:0] MSTATUS_UPIE = 'h00000010;
    localparam logic [63:0] MSTATUS_SPIE = 'h00000020;
    localparam logic [63:0] MSTATUS_HPIE = 'h00000040;
    localparam logic [63:0] MSTATUS_MPIE = 'h00000080;
    localparam logic [63:0] MSTATUS_SPP  = 'h00000100;
    localparam logic [63:0] MSTATUS_HPP  = 'h00000600;
    localparam logic [63:0] MSTATUS_MPP  = 'h00001800;
    localparam logic [63:0] MSTATUS_FS   = 'h00006000;
    localparam logic [63:0] MSTATUS_XS   = 'h00018000;
    localparam logic [63:0] MSTATUS_MPRV = 'h00020000;
    localparam logic [63:0] MSTATUS_SUM  = 'h00040000;
    localparam logic [63:0] MSTATUS_MXR  = 'h00080000;
    localparam logic [63:0] MSTATUS_TVM  = 'h00100000;
    localparam logic [63:0] MSTATUS_TW   = 'h00200000;
    localparam logic [63:0] MSTATUS_TSR  = 'h00400000;
    localparam logic [63:0] MSTATUS_UXL  = {30'h0000000, 1'b1, 1'b1, 32'h00000000};
    localparam logic [63:0] MSTATUS_SXL  = {28'h0000000, 1'b1, 1'b1, 34'h00000000};
    localparam logic [63:0] MSTATUS_SD   = {1'b1, 31'h00000000, 1'b0, 31'h00000000};

    typedef struct packed {
        logic [63:60] mode;
        logic [59:44] asid;
        logic [43:0]  ppn;
    } satp_t;

    localparam int unsigned IRQ_S_SOFT = 1;
    localparam int unsigned IRQ_M_SOFT = 3;
    localparam int unsigned IRQ_S_TIMER = 5;
    localparam int unsigned IRQ_M_TIMER = 7;
    localparam int unsigned IRQ_S_EXT = 9;
    localparam int unsigned IRQ_M_EXT = 11;

    localparam logic [rvh_pkg::XLEN-1:0] MIP_SSIP = 1 << IRQ_S_SOFT;
    localparam logic [rvh_pkg::XLEN-1:0] MIP_MSIP = 1 << IRQ_M_SOFT;
    localparam logic [rvh_pkg::XLEN-1:0] MIP_STIP = 1 << IRQ_S_TIMER;
    localparam logic [rvh_pkg::XLEN-1:0] MIP_MTIP = 1 << IRQ_M_TIMER;
    localparam logic [rvh_pkg::XLEN-1:0] MIP_SEIP = 1 << IRQ_S_EXT;
    localparam logic [rvh_pkg::XLEN-1:0] MIP_MEIP = 1 << IRQ_M_EXT;


    localparam logic [EXCP_CAUSE_WIDTH-1:0] INSTR_ADDR_MISALIGNED = 0;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] INSTR_ACCESS_FAULT =1;  // Illegal access as governed by PMPs and PMAs
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ILLEGAL_INSTR = 2;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] BREAKPOINT = 3;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] LD_ADDR_MISALIGNED = 4;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] LD_ACCESS_FAULT =
        5;  // Illegal access as governed by PMPs and PMAs
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ST_ADDR_MISALIGNED = 6;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ST_ACCESS_FAULT =
        7;  // Illegal access as governed by PMPs and PMAs
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ENV_CALL_UMODE = 8;  // environment call from user mode
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] ENV_CALL_SMODE = 9;  // environment call from supervisor mode
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] ENV_CALL_MMODE = 11;  // environment call from machine mode
    localparam logic [EXCP_CAUSE_WIDTH-1:0] INSTR_PAGE_FAULT = 12;  // Instruction page fault
    localparam logic [EXCP_CAUSE_WIDTH-1:0] LOAD_PAGE_FAULT = 13;  // Load page fault
    localparam logic [EXCP_CAUSE_WIDTH-1:0] STORE_PAGE_FAULT = 15;  // Store page fault
    // User define
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ORDER_FAILURE = 24;  // ordering failure

    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] S_SW_INTERRUPT = (1 << (rvh_pkg::XLEN - 1)) | IRQ_S_SOFT;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] M_SW_INTERRUPT = (1 << (rvh_pkg::XLEN - 1)) | IRQ_M_SOFT;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] S_TIMER_INTERRUPT = (1 << (rvh_pkg::XLEN - 1)) | IRQ_S_TIMER;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] M_TIMER_INTERRUPT = (1 << (rvh_pkg::XLEN - 1)) | IRQ_M_TIMER;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] S_EXT_INTERRUPT = (1 << (rvh_pkg::XLEN - 1)) | IRQ_S_EXT;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] M_EXT_INTERRUPT = (1 << (rvh_pkg::XLEN - 1)) | IRQ_M_EXT;



    // RV32/64G listings:
    // Quadrant 0
    localparam OpcodeLoad = 7'b0000011;
    localparam OpcodeLoadFp = 7'b0000111;
    localparam OpcodeCustom0 = 7'b0001011;
    localparam OpcodeMiscMem = 7'b0001111;
    localparam OpcodeOpImm = 7'b0010011;
    localparam OpcodeAuipc = 7'b0010111;
    localparam OpcodeOpImm32 = 7'b0011011;
    // Quadrant 1
    localparam OpcodeStore = 7'b0100011;
    localparam OpcodeStoreFp = 7'b0100111;
    localparam OpcodeCustom1 = 7'b0101011;
    localparam OpcodeAmo = 7'b0101111;
    localparam OpcodeOp = 7'b0110011;
    localparam OpcodeLui = 7'b0110111;
    localparam OpcodeOp32 = 7'b0111011;
    // Quadrant 2
    localparam OpcodeMadd = 7'b1000011;
    localparam OpcodeMsub = 7'b1000111;
    localparam OpcodeNmsub = 7'b1001011;
    localparam OpcodeNmadd = 7'b1001111;
    localparam OpcodeOpFp = 7'b1010011;
    localparam OpcodeRsrvd1 = 7'b1010111;
    localparam OpcodeCustom2 = 7'b1011011;
    // Quadrant 3
    localparam OpcodeBranch = 7'b1100011;
    localparam OpcodeJalr = 7'b1100111;
    localparam OpcodeRsrvd2 = 7'b1101011;
    localparam OpcodeJal = 7'b1101111;
    localparam OpcodeSystem = 7'b1110011;
    localparam OpcodeRsrvd3 = 7'b1110111;
    localparam OpcodeCustom3 = 7'b1111011;

    // RV64C/RV32C listings:
    // Quadrant 0
    localparam OpcodeC0 = 2'b00;
    localparam OpcodeC0Addi4spn = 3'b000;
    localparam OpcodeC0Fld = 3'b001;
    localparam OpcodeC0Lw = 3'b010;
    localparam OpcodeC0Ld = 3'b011;
    localparam OpcodeC0Rsrvd = 3'b100;
    localparam OpcodeC0Fsd = 3'b101;
    localparam OpcodeC0Sw = 3'b110;
    localparam OpcodeC0Sd = 3'b111;
    // Quadrant 1
    localparam OpcodeC1 = 2'b01;
    localparam OpcodeC1Addi = 3'b000;
    localparam OpcodeC1Addiw = 3'b001;  //for RV64I only
    localparam OpcodeC1Jal = 3'b001;  //for RV32I only
    localparam OpcodeC1Li = 3'b010;
    localparam OpcodeC1LuiAddi16sp = 3'b011;
    localparam OpcodeC1MiscAlu = 3'b100;
    localparam OpcodeC1J = 3'b101;
    localparam OpcodeC1Beqz = 3'b110;
    localparam OpcodeC1Bnez = 3'b111;
    // Quadrant 2
    localparam OpcodeC2 = 2'b10;
    localparam OpcodeC2Slli = 3'b000;
    localparam OpcodeC2Fldsp = 3'b001;
    localparam OpcodeC2Lwsp = 3'b010;
    localparam OpcodeC2Ldsp = 3'b011;
    localparam OpcodeC2JalrMvAdd = 3'b100;
    localparam OpcodeC2Fsdsp = 3'b101;
    localparam OpcodeC2Swsp = 3'b110;
    localparam OpcodeC2Sdsp = 3'b111;


    /* CSR */
    // Unprivileged Counter/Timers
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_CYCLE = 12'hC00;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_TIME = 12'hC01;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_INSTRET = 12'hC02;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER3 = 12'hC03;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER4 = 12'hC04;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER5 = 12'hC05;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER6 = 12'hC06;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER7 = 12'hC07;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER8 = 12'hC08;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER9 = 12'hC09;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER10 = 12'hC0A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER11 = 12'hC0B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER12 = 12'hC0C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER13 = 12'hC0D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER14 = 12'hC0E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER15 = 12'hC0F;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER16 = 12'hC10;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER17 = 12'hC11;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER18 = 12'hC12;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER19 = 12'hC13;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER20 = 12'hC14;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER21 = 12'hC15;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER22 = 12'hC16;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER23 = 12'hC17;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER24 = 12'hC18;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER25 = 12'hC19;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER26 = 12'hC1A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER27 = 12'hC1B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER28 = 12'hC1C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER29 = 12'hC1D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER30 = 12'hC1E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER31 = 12'hC1F;
    // Machine Information Registers
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MVENDORID = 12'hF11;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MARCHID = 12'hF12;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIMPID = 12'hF13;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHARTID = 12'hF14;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCONFIGPTR = 12'hF15;
    // Machine Trap Setup
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MSTATUS = 12'h300;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MISA = 12'h301;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MEDELEG = 12'h302;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIDELEG = 12'h303;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIE = 12'h304;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTVEC = 12'h305;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCOUNTEREN = 12'h306;
    // Machine Tap Handling 
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MSCRATCH = 12'h340;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MEPC = 12'h341;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCAUSE = 12'h342;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTVAL = 12'h343;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIP = 12'h344;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTINST = 12'h34A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTVAL2 = 12'h34B;
    // Machine Configuration
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MENVCFG = 12'h30A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MSECCFG = 12'h747;
    // Machine Memory Protection
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG0 = 12'h3A0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG2 = 12'h3A2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG4 = 12'h3A4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG6 = 12'h3A6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG8 = 12'h3A8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG10 = 12'h3AA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG12 = 12'h3AC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG14 = 12'h3AE;

    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR0 = 12'h3B0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR1 = 12'h3B1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR2 = 12'h3B2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR3 = 12'h3B3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR4 = 12'h3B4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR5 = 12'h3B5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR6 = 12'h3B6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR7 = 12'h3B7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR8 = 12'h3B8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR9 = 12'h3B9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR10 = 12'h3BA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR11 = 12'h3BB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR12 = 12'h3BC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR13 = 12'h3BD;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR14 = 12'h3BE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR15 = 12'h3BF;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR16 = 12'h3C0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR17 = 12'h3C1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR18 = 12'h3C2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR19 = 12'h3C3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR20 = 12'h3C4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR21 = 12'h3C5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR22 = 12'h3C6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR23 = 12'h3C7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR24 = 12'h3C8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR25 = 12'h3C9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR26 = 12'h3CA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR27 = 12'h3CB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR28 = 12'h3CC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR29 = 12'h3CD;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR30 = 12'h3CE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR31 = 12'h3CF;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR32 = 12'h3D0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR33 = 12'h3D1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR34 = 12'h3D2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR35 = 12'h3D3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR36 = 12'h3D4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR37 = 12'h3D5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR38 = 12'h3D6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR39 = 12'h3D7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR40 = 12'h3D8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR41 = 12'h3D9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR42 = 12'h3DA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR43 = 12'h3DB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR44 = 12'h3DC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR45 = 12'h3DD;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR46 = 12'h3DE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR47 = 12'h3DF;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR48 = 12'h3E0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR49 = 12'h3E1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR50 = 12'h3E2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR51 = 12'h3E3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR52 = 12'h3E4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR53 = 12'h3E5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR54 = 12'h3E6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR55 = 12'h3E7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR56 = 12'h3E8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR57 = 12'h3E9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR58 = 12'h3EA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR59 = 12'h3EB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR60 = 12'h3EC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR61 = 12'h3ED;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR62 = 12'h3EE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR63 = 12'h3EF;
    // Machine Counter / Timers
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCYCLE = 12'hB00;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MINSTRET = 12'hB02;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER3 = 12'hB03;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER4 = 12'hB04;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER5 = 12'hB05;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER6 = 12'hB06;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER7 = 12'hB07;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER8 = 12'hB08;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER9 = 12'hB09;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER10 = 12'hB0A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER11 = 12'hB0B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER12 = 12'hB0C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER13 = 12'hB0D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER14 = 12'hB0E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER15 = 12'hB0F;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER16 = 12'hB10;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER17 = 12'hB11;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER18 = 12'hB12;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER19 = 12'hB13;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER20 = 12'hB14;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER21 = 12'hB15;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER22 = 12'hB16;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER23 = 12'hB17;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER24 = 12'hB18;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER25 = 12'hB19;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER26 = 12'hB1A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER27 = 12'hB1B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER28 = 12'hB1C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER29 = 12'hB1D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER30 = 12'hB1E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER31 = 12'hB1F;
    // Machine Counter Setup
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCOUNTINHIBIT = 12'h320;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT3 = 12'h323;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT4 = 12'h324;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT5 = 12'h325;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT6 = 12'h326;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT7 = 12'h327;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT8 = 12'h328;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT9 = 12'h329;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT10 = 12'h32A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT11 = 12'h32B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT12 = 12'h32C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT13 = 12'h32D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT14 = 12'h32E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT15 = 12'h32F;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT16 = 12'h330;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT17 = 12'h331;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT18 = 12'h332;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT19 = 12'h333;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT20 = 12'h334;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT21 = 12'h335;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT22 = 12'h336;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT23 = 12'h337;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT24 = 12'h338;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT25 = 12'h339;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT26 = 12'h33A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT27 = 12'h33B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT28 = 12'h33C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT29 = 12'h33D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT30 = 12'h33E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT31 = 12'h33F;
    // Supervisor Trap Setup
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SSTATUS = 12'h100;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SIE = 12'h104;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_STVEC = 12'h105;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SCOUNTEREN = 12'h106;
    // Supervisor Configuration
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SENVCFG = 12'h10A;
    // Supervisor Trap Handling
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SSCRATCH = 12'h140;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SEPC = 12'h141;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SCAUSE = 12'h142;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_STVAL = 12'h143;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SIP = 12'h144;
    // Supervisor Protection and Translation
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SATP = 12'h180;

endpackage

`endif