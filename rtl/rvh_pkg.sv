`ifndef __RVH_PKG_SV__
`define __RVH_PKG_SV__
// `define SYNTHESIS
package rvh_pkg;

    /* ------ RCU Configuration ------ */
    localparam int unsigned XLEN = 64;
    localparam int unsigned VADDR_WIDTH = 39;
    localparam int unsigned PADDR_WIDTH = 40;
    localparam int unsigned BASE_ADDR = 39'h80000000;

    // Fetch & BPU 
    localparam int unsigned L1I_FETCH_WIDTH = 256;
    localparam int unsigned FETCH_WIDTH = 128;
    localparam int unsigned FETCH_BLKS = 2;
    localparam int unsigned PREDS_PER_LINE = 8;
    localparam int unsigned BLKS_FOR_SEL = 8;
    localparam int unsigned BTQ_N_SZ = 32;
    localparam int unsigned IB_PKT_NUM_N = 4;
    localparam int unsigned BR_OFFSET_WIDTH = 20;
    localparam int unsigned IFQ_DEPTH = 8;
    localparam int unsigned PC_LOB_WIDTH = $clog2(FETCH_WIDTH/8) + 1; 
    // Decode Width
    localparam int unsigned DECODE_WIDTH = 4;
    // Rename Width
    localparam int unsigned RENAME_WIDTH = 4;
    // Issue 
    localparam int unsigned INT0_IQ_DEPTH = 12;
    localparam int unsigned AGU0_IQ_DEPTH = 12;
    localparam int unsigned SDU0_IQ_DEPTH = 12;
    localparam int unsigned INT1_IQ_DEPTH = 12;
    localparam int unsigned AGU1_IQ_DEPTH = 12;
    localparam int unsigned SDU1_IQ_DEPTH = 12;
    localparam int unsigned COMPLEX_INT0_IQ_DEPTH = 12;
    localparam int unsigned BR0_IQ_DEPTH = 12;
    // Execute
    localparam int unsigned BRU_COUNT = 1;
    localparam int unsigned ALU_COUNT = 3;
    localparam int unsigned MUL_COUNT = 1;
    localparam int unsigned DIV_COUNT = 1;
    localparam int unsigned LSU_ADDR_PIPE_COUNT = 2;
    localparam int unsigned LSU_DATA_PIPE_COUNT = 2;

    localparam int unsigned INT_COMPLETE_WIDTH = 4;
    localparam int unsigned LSU_COMPLETE_WIDTH = LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT;

    // Forwarding Network
    localparam int unsigned INT_CDB_DEPTH = 1;
    localparam int unsigned INT_CDB_BUS_WIDTH = BRU_COUNT + ALU_COUNT + MUL_COUNT + DIV_COUNT + LSU_ADDR_PIPE_COUNT;
    localparam int unsigned INT_CDB_ID_WIDTH = $clog2(INT_CDB_BUS_WIDTH);

    localparam int unsigned RETIRE_WIDTH = 4;
    // Dispatch
    localparam int unsigned INT_DISP_QUEUE_DEPTH = 16;
    localparam int unsigned INT_DISP_WIDTH = 4;

    localparam int unsigned LSU_DISP_QUEUE_DEPTH = 16;
    localparam int unsigned LSU_DISP_WIDTH = 2;
    localparam int unsigned LSU_ALLOC_WIDTH = LSU_DISP_WIDTH;
    // ROB
    localparam int unsigned ROB_SIZE = 128;
    localparam int unsigned ROB_BLOCK_PER_ENTRY = 1;
    localparam int unsigned ROB_ENTRY_COUNT = ROB_SIZE / ROB_BLOCK_PER_ENTRY;
    localparam int unsigned ROB_CB_WIDTH = INT_COMPLETE_WIDTH + LSU_COMPLETE_WIDTH;
    localparam int unsigned ROB_RE_WIDTH = LSU_ADDR_PIPE_COUNT;
    localparam int unsigned ROB_BR_WIDTH = BRU_COUNT;
    // Physical Register File
    localparam int unsigned INT_PREG_COUNT = 128;
    localparam int unsigned INT_PRF_ALLOC_PORT_COUNT = RENAME_WIDTH;
    localparam int unsigned INT_PRF_DISP_PORT_COUNT = 2 * (INT_DISP_WIDTH + LSU_DISP_WIDTH);
    localparam int unsigned INT_PRF_WR_PORT_COUNT = 6;
    localparam int unsigned INT_PRF_RD_PORT_COUNT = 6;
    // BTQ
    localparam int unsigned BTQ_ENTRY_COUNT = BTQ_N_SZ;
    // BRQ
    localparam int unsigned BRQ_ENTRY_COUNT = 12;
    // LDQ
    localparam int unsigned LDQ_ENTRY_COUNT = 12;
    localparam int unsigned RAR_QUEUE_ENTRY_COUNT = 32;
    localparam int unsigned RAW_QUEUE_ENTRY_COUNT = 32;
    // STQ
    localparam int unsigned STQ_ENTRY_COUNT = 48;
    // PMP
    localparam int unsigned PMP_ENTRY_COUNT = 8;
    // PTW
    localparam int unsigned PTW_COUNT = 1;
    localparam int unsigned PTW_ID_WIDTH = PTW_COUNT > 1 ? $clog2(PTW_COUNT) : 1;
    // L1D Cache
    localparam int unsigned L1D_SIZE       = 16 * (2 ** 10);
    localparam int unsigned L1D_LINE_SIZE  = 64;
    localparam int unsigned L1D_WAY_COUNT  = 4;
    localparam int unsigned L1D_BANK_COUNT = 8;
    localparam int unsigned L1D_SET_COUNT  = L1D_SIZE / (L1D_LINE_SIZE * L1D_WAY_COUNT);
    localparam int unsigned L1D_BANK_SET_COUNT = L1D_SET_COUNT / L1D_BANK_COUNT;
    // L1 DTLB
    localparam int unsigned DTLB_ENTRY_COUNT = 16;
    localparam int unsigned DTLB_MSHR_COUNT  = 4;
    localparam int unsigned DTLB_TRANS_ID_WIDTH = DTLB_MSHR_COUNT > 1 ? $clog2(DTLB_MSHR_COUNT) : 1;
    localparam int unsigned ITLB_ENTRY_COUNT = 16;
    localparam int unsigned ITLB_TRANS_ID_WIDTH = DTLB_TRANS_ID_WIDTH;
    /* ------------------------------- */

    // L1D Cache 
    localparam int unsigned L1D_OFFSET_WIDTH_CORE = $clog2(L1D_LINE_SIZE);
    localparam int unsigned L1D_BANK_ID_WIDTH_CORE = $clog2(L1D_BANK_COUNT);
    localparam int unsigned L1D_SET_ID_WIDTH_CORE = $clog2(L1D_BANK_SET_COUNT);
    localparam int unsigned L1D_INDEX_WIDTH_CORE = L1D_BANK_ID_WIDTH_CORE + L1D_SET_ID_WIDTH_CORE + L1D_OFFSET_WIDTH_CORE;
    localparam int unsigned L1D_TAG_WIDTH_CORE  = PADDR_WIDTH - (L1D_INDEX_WIDTH_CORE > 12 ? 12 : L1D_INDEX_WIDTH_CORE);


    // PMP Config
    localparam int unsigned PMP_GROUP_COUNT = PMP_ENTRY_COUNT > 8 ? (PMP_ENTRY_COUNT / 8) : 1;
    localparam int unsigned PMP_CFG_TAG_WIDTH = PMP_GROUP_COUNT > 1 ? $clog2(PMP_GROUP_COUNT) : 1;
    localparam int unsigned PMP_ADDR_TAG_WIDTH = $clog2(PMP_ENTRY_COUNT);

    // LSQ
    localparam int unsigned LDQ_TAG_WIDTH = $clog2(LDQ_ENTRY_COUNT);
    localparam int unsigned STQ_TAG_WIDTH = $clog2(STQ_ENTRY_COUNT);
    localparam int unsigned RAW_TAG_WIDTH = $clog2(RAW_QUEUE_ENTRY_COUNT);
    localparam int unsigned RAR_TAG_WIDTH = $clog2(RAR_QUEUE_ENTRY_COUNT);
    localparam
        int unsigned LSQ_TAG_WIDTH = LDQ_TAG_WIDTH > STQ_TAG_WIDTH ? LDQ_TAG_WIDTH : STQ_TAG_WIDTH;
    // BTQ
    localparam int unsigned BTQ_TAG_WIDTH = $clog2(BTQ_ENTRY_COUNT) + 1;
    // BRQ
    localparam int unsigned BRQ_TAG_WIDTH = $clog2(BRQ_ENTRY_COUNT);
    // Physical Register File Config    
    localparam int unsigned INT_PREG_TAG_WIDTH = $clog2(INT_PREG_COUNT);
    localparam int unsigned PREG_TAG_WIDTH = INT_PREG_TAG_WIDTH;
    // ROB
    localparam int unsigned ROB_OFFSET_WIDTH = ROB_BLOCK_PER_ENTRY > 1 ? $clog2(
        ROB_BLOCK_PER_ENTRY
    ) : 1;
    localparam int unsigned ROB_INDEX_WIDTH = $clog2(ROB_ENTRY_COUNT);
    localparam int unsigned ROB_PTR_WIDTH = 1 + ROB_INDEX_WIDTH;
    localparam int unsigned ROB_TAG_WIDTH = ROB_PTR_WIDTH + ROB_OFFSET_WIDTH;
    localparam int unsigned ROB_PC_OFFSET_WIDTH = $clog2(FETCH_WIDTH / 8) - 1;
    localparam int unsigned ROB_PC_BASE_WIDTH = VADDR_WIDTH - ROB_PC_OFFSET_WIDTH - 1;


    // INT Encoding
    localparam int unsigned INT_TYPE_WIDTH = 2;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_ALU_TYPE = 0;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_MUL_TYPE = 1;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_DIV_TYPE = 2;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_BRU_TYPE = 3;

    localparam int unsigned LSU_TYPE_WIDTH = 1;
    localparam logic [LSU_TYPE_WIDTH-1:0] LSU_LD_TYPE = 0;
    localparam logic [LSU_TYPE_WIDTH-1:0] LSU_ST_TYPE = 1;

    // AGU IQ TAG
    localparam int unsigned AGU_IQ_TAG_WIDHT = $clog2(AGU0_IQ_DEPTH);
    


    typedef struct packed {logic [VADDR_WIDTH-1:0] pc;} l1ic_req_t;

    typedef struct packed {
        logic                   replay;
        logic [FETCH_WIDTH-1:0] line;
    } l1ic_resp_t;

endpackage : rvh_pkg

`endif