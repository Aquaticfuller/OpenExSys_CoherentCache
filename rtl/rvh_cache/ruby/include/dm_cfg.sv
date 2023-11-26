
package dm_cfg;

    parameter logic [3:0] DBG_VER_013= 4'h2;

    // how many harts need to support
    parameter int  DLEN          = 32;
    parameter int  N_HARTS       = 4;

    parameter int  PROG_BUF_SIZE     = 8;
    parameter int  DATA_COUNT        = 3;
    parameter int  ABSTRACT_CMD_SIZE = 16; 

    parameter int HART_SEL_LEN = (N_HARTS == 1) ? 1 : $clog2(N_HARTS);
    parameter int N_HARTS_ALIGN = 2**HART_SEL_LEN;
    parameter int DBG_MEM_ADDR_WIDTH    = 12;

    // follow the sifive standard
    // address to which a hart should jump when it was requested to halt
    parameter logic [31:0] HALT_ADDR      = 32'h800;
    parameter logic [31:0] RESUME_ADDR    = HALT_ADDR + 4;
    parameter logic [31:0] EXCP_ADDR      = HALT_ADDR + 8;
    

endpackage
