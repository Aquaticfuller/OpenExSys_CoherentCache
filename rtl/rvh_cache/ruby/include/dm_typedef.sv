//===============================================
// Filename     : dm_typedef.sv
// Author       : yangjianzhi
// Email        : jianzhi.yang@rivai.ai
// Date         : 2021-04-20 22:17:43
// Description  : 
//================================================

`ifndef ___DM_TYPEDEF__SV__
`define ___DM_TYPEDEF__SV__
package dm_typedef;
    // debug registers
    typedef enum logic [7:0] {
      DATA0        = 8'h04,
      DATA1        = 8'h05,
      DATA2        = 8'h06,
      DATA3        = 8'h07,
      DATA4        = 8'h08,
      DATA5        = 8'h09,
      DATA6        = 8'h0A,
      DATA7        = 8'h0B,
      DATA8        = 8'h0C,
      DATA9        = 8'h0D,
      DATA10       = 8'h0E,
      DATA11       = 8'h0F,
      DMCONTROL    = 8'h10,
      DMSTATUS     = 8'h11, // r/o
      HARTINFO     = 8'h12,
      HALTSUM1     = 8'h13,
      HAWINDOWSEL  = 8'h14,
      HAWINDOW     = 8'h15,
      ABSTRACTCS   = 8'h16,
      COMMAND      = 8'h17,
      ABSTRACTAUTO = 8'h18,
      DEVTREEADDR0 = 8'h19,
      DEVTREEADDR1 = 8'h1A,
      DEVTREEADDR2 = 8'h1B,
      DEVTREEADDR3 = 8'h1C,
      NEXTDM       = 8'h1D,
      PROGBUF0     = 8'h20,
      PROGBUF1     = 8'h21,
      PROGBUF2     = 8'h22,
      PROGBUF3     = 8'h23,
      PROGBUF4     = 8'h24,
      PROGBUF5     = 8'h25,
      PROGBUF6     = 8'h26,
      PROGBUF7     = 8'h27,
      PROGBUF8     = 8'h28,
      PROGBUF9     = 8'h29,
      PROGBUF10    = 8'h2A,
      PROGBUF11    = 8'h2B,
      PROGBUF12    = 8'h2C,
      PROGBUF13    = 8'h2D,
      PROGBUF14    = 8'h2E,
      PROGBUF15    = 8'h2F,
      AUTHDATA     = 8'h30,
      HALTSUM2     = 8'h34,
      HALTSUM3     = 8'h35,
      SBADDRESS3   = 8'h37,
      SBCS         = 8'h38,
      SBADDRESS0   = 8'h39,
      SBADDRESS1   = 8'h3A,
      SBADDRESS2   = 8'h3B,
      SBDATA0      = 8'h3C,
      SBDATA1      = 8'h3D,
      SBDATA2      = 8'h3E,
      SBDATA3      = 8'h3F,
      HALTSUM0     = 8'h40
    } dm_csr_e;

    typedef struct packed {
      logic [31:23] zero1;
      logic         impebreak;
      logic [21:20] zero0;
      logic         allhavereset;
      logic         anyhavereset;
      logic         allresumeack;
      logic         anyresumeack;
      logic         allnonexistent;
      logic         anynonexistent;
      logic         allunavail;
      logic         anyunavail;
      logic         allrunning;
      logic         anyrunning;
      logic         allhalted;
      logic         anyhalted;
      logic         authenticated;
      logic         authbusy;
      logic         hasresethaltreq;
      logic         devtreevalid;
      logic [3:0]   version;
    } dmstatus_t;

    typedef struct packed {
      logic         haltreq;
      logic         resumereq;
      logic         hartreset;
      logic         ackhavereset;
      logic         zero1;
      logic         hasel;
      logic [25:16] hartsello;
      logic [15:6]  hartselhi;
      logic [5:4]   zero0;
      logic         setresethaltreq;
      logic         clrresethaltreq;
      logic         ndmreset;
      logic         dmactive;
    } dmcontrol_t;

    typedef struct packed {
      logic [31:24] zero1;
      logic [23:20] nscratch;
      logic [19:17] zero0;
      logic         dataaccess;
      logic [15:12] datasize;
      logic [11:0]  dataaddr;
    } hartinfo_t;

    typedef struct packed {
      logic [31:15] zero;
      logic [14:0]  hawindowsel;
    } hawindowsel_t;

    typedef enum logic [2:0] {
      CMD_ERR_NONE, CMD_ERR_BUSY, CMD_ERR_NOT_SUPPORTED,
      CMD_ERR_EXCEPTION, CMD_ERR_HALT_RESUME,
      CMD_ERR_BUS, CMD_ERR_OTHER = 7
    } cmderr_e;

    typedef struct packed {
      logic [31:29] zero3;
      logic [28:24] progbufsize;
      logic [23:13] zero2;
      logic         busy;
      logic         zero1;
      cmderr_e      cmderr;
      logic [7:4]   zero0;
      logic [3:0]   datacount;
    } abstractcs_t;

    typedef enum logic [7:0] {
      ACCESS_REGISTER = 8'h0,
      QUICK_ACCESS    = 8'h1,
      ACCESS_MEMORY   = 8'h2
    } cmd_e;

    typedef struct packed {
      cmd_e        cmdtype;
      logic [23:0] control;
    } command_t;

    typedef struct packed {
      logic [31:16] autoexecprogbuf;
      logic [15:12] zero0;
      logic [11:0]  autoexecdata;
    } abstractauto_t;

    typedef struct packed {
      logic         zero1;
      logic [22:20] aarsize;
      logic         aarpostincrement;
      logic         postexec;
      logic         transfer;
      logic         write;
      logic [15:0]  regno;
    } ac_ar_cmd_t;

    // DTM
    typedef enum logic [1:0] {
      DTM_NOP   = 2'h0,
      DTM_READ  = 2'h1,
      DTM_WRITE = 2'h2
    } dtm_op_e;

    typedef struct packed {
      logic [31:29] sbversion;
      logic [28:23] zero0;
      logic         sbbusyerror;
      logic         sbbusy;
      logic         sbreadonaddr;
      logic [19:17] sbaccess;
      logic         sbautoincrement;
      logic         sbreadondata;
      logic [14:12] sberror;
      logic [11:5]  sbasize;
      logic         sbaccess128;
      logic         sbaccess64;
      logic         sbaccess32;
      logic         sbaccess16;
      logic         sbaccess8;
    } sbcs_t;

    localparam logic [1:0] DTM_SUCCESS = 2'h0;

    // SBA state
    typedef enum logic [2:0] {
      SBA_IDLE,
      SBA_READ,
      SBA_WRITE,
      SBA_WAIT_READ,
      SBA_WAIT_WRITE
    } sba_state_e;

    typedef struct packed {
      logic [6:0]  addr;
      dtm_op_e     op;
      logic [31:0] data;
    } dmi_req_t;

    typedef struct packed  {
      logic [31:0] data;
      logic [1:0]  resp;
    } dmi_resp_t;

    // CSRs
    typedef enum logic [11:0] {
      // Floating-Point CSRs
      CSR_FFLAGS         = 12'h001,
      CSR_FRM            = 12'h002,
      CSR_FCSR           = 12'h003,
      CSR_FTRAN          = 12'h800,
      // Supervisor Mode CSRs
      CSR_SSTATUS        = 12'h100,
      CSR_SIE            = 12'h104,
      CSR_STVEC          = 12'h105,
      CSR_SCOUNTEREN     = 12'h106,
      CSR_SSCRATCH       = 12'h140,
      CSR_SEPC           = 12'h141,
      CSR_SCAUSE         = 12'h142,
      CSR_STVAL          = 12'h143,
      CSR_SIP            = 12'h144,
      CSR_SATP           = 12'h180,
      // Machine Mode CSRs
      CSR_MSTATUS        = 12'h300,
      CSR_MISA           = 12'h301,
      CSR_MEDELEG        = 12'h302,
      CSR_MIDELEG        = 12'h303,
      CSR_MIE            = 12'h304,
      CSR_MTVEC          = 12'h305,
      CSR_MCOUNTEREN     = 12'h306,
      CSR_MSCRATCH       = 12'h340,
      CSR_MEPC           = 12'h341,
      CSR_MCAUSE         = 12'h342,
      CSR_MTVAL          = 12'h343,
      CSR_MIP            = 12'h344,
      CSR_PMPCFG0        = 12'h3A0,
      CSR_PMPADDR0       = 12'h3B0,
      CSR_MVENDORID      = 12'hF11,
      CSR_MARCHID        = 12'hF12,
      CSR_MIMPID         = 12'hF13,
      CSR_MHARTID        = 12'hF14,
      CSR_MCYCLE         = 12'hB00,
      CSR_MINSTRET       = 12'hB02,
      CSR_DCACHE         = 12'h701,
      CSR_ICACHE         = 12'h700,

      CSR_TSELECT        = 12'h7A0,
      CSR_TDATA1         = 12'h7A1,
      CSR_TDATA2         = 12'h7A2,
      CSR_TDATA3         = 12'h7A3,
      CSR_TINFO          = 12'h7A4,

      // Debug CSR
      CSR_DCSR           = 12'h7b0,
      CSR_DPC            = 12'h7b1,
      CSR_DSCRATCH0      = 12'h7b2, // optional
      CSR_DSCRATCH1      = 12'h7b3, // optional

      // Counters and Timers
      CSR_CYCLE          = 12'hC00,
      CSR_TIME           = 12'hC01,
      CSR_INSTRET        = 12'hC02
    } csr_reg_t;

    // Instruction Generation Helpers
    function automatic logic [31:0] JAL (logic [4:0]  rd,
                                         logic [20:0] imm);
      // OpCode Jal
      return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h6f};
    endfunction

    function automatic logic [31:0] JALR (logic [4:0]  rd,
                                          logic [4:0]  rs1,
                                          logic [11:0] offset);
      // OpCode Jal
      return {offset[11:0], rs1, 3'b0, rd, 7'h67};
    endfunction

    function automatic logic [31:0] ANDI (logic [4:0]  rd,
                                          logic [4:0]  rs1,
                                          logic [11:0] imm);
      // OpCode andi
      return {imm[11:0], rs1, 3'h7, rd, 7'h13};
    endfunction

    function automatic logic [31:0] SLLI (logic [4:0] rd,
                                          logic [4:0] rs1,
                                          logic [5:0] shamt);
      // OpCode slli
      return {6'b0, shamt[5:0], rs1, 3'h1, rd, 7'h13};
    endfunction

    function automatic logic [31:0] SRLI (logic [4:0] rd,
                                          logic [4:0] rs1,
                                          logic [5:0] shamt);
      // OpCode srli
      return {6'b0, shamt[5:0], rs1, 3'h5, rd, 7'h13};
    endfunction

    function automatic logic [31:0] LOAD (logic [2:0]  size,
                                          logic [4:0]  dest,
                                          logic [4:0]  base,
                                          logic [11:0] offset);
      // OpCode Load
      return {offset[11:0], base, size, dest, 7'h03};
    endfunction

    function automatic logic [31:0] AUIPC (logic [4:0]  rd,
                                           logic [20:0] imm);
      // OpCode Auipc
      return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h17};
    endfunction

    function automatic logic [31:0] STORE (logic [2:0]  size,
                                           logic [4:0]  src,
                                           logic [4:0]  base,
                                           logic [11:0] offset);
      // OpCode Store
      return {offset[11:5], src, base, size, offset[4:0], 7'h23};
    endfunction

    function automatic logic [31:0] FLOAD (logic [2:0]  size,
                                           logic [4:0]  dest,
                                           logic [4:0]  base,
                                           logic [11:0] offset);
      // OpCode Load
      return {offset[11:0], base, size, dest, 7'b00_001_11};
    endfunction

    function automatic logic [31:0] FSTORE (logic [2:0]  size,
                                            logic [4:0]  src,
                                            logic [4:0]  base,
                                            logic [11:0] offset);
      // OpCode Store
      return {offset[11:5], src, base, size, offset[4:0], 7'b01_001_11};
    endfunction

    function automatic logic [31:0] CSRW (csr_reg_t   csr,
                                          logic [4:0] rs1);
      // CSRRW, rd, OpCode System
      return {csr, rs1, 3'h1, 5'h0, 7'h73};
    endfunction

    function automatic logic [31:0] CSRR (csr_reg_t   csr,
                                          logic [4:0] dest);
      // rs1, CSRRS, rd, OpCode System
      return {csr, 5'h0, 3'h2, dest, 7'h73};
    endfunction

    function automatic logic [31:0] BRANCH(logic [4:0]  src2,
                                           logic [4:0]  src1,
                                           logic [2:0]  funct3,
                                           logic [11:0] offset);
      // OpCode Branch
      return {offset[11], offset[9:4], src2, src1, funct3,
          offset[3:0], offset[10], 7'b11_000_11};
    endfunction

    function automatic logic [31:0] EBREAK ();
      return 32'h00100073;
    endfunction

    function automatic logic [31:0] WFI ();
      return 32'h10500073;
    endfunction

    function automatic logic [31:0] NOP ();
      return 32'h00000013;
    endfunction

    function automatic logic [31:0] ILLEGAL ();
      return 32'h00000000;
    endfunction

endpackage
`endif
