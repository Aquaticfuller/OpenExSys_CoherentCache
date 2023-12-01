// feature flags:
// `define S_TO_M_NO_DATA_TRANSFER
// `define SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST  // for ReadShared/ReadOnce req
// `define PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST  // for snp data resp
// `define PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY // for write back, only transfer dirty part
// `define PRIVATE_CACHE_TO_SCU_DATA_SNP_RESP_DIRTY_PART_ONLY  // for snp data resp, only transfer dirty part
// `define SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY // provide data to a store only for the clean part of it, to optimize the store from store buffer condition
// `define EBI

// debug flags:
// `define COMMON_DATA_VALID_LATENCY_EN
`define SET_INVALID_DATA_PART_ZERO_EN
`define ENABLE_TXN_ID

package rvh_uncore_param_pkg;
  `ifdef SLICED_LLC
  parameter L1D_NUM = 9;
  `else
  parameter L1D_NUM = 8;
  `endif

  `ifdef SYNTHESIS
  parameter L1D_MSHR_NUM = 2;
  parameter SCU_MSHR_NUM = 2;
  parameter SCU_REPL_MSHR_NUM = 2;
  `else
  parameter L1D_MSHR_NUM = 8;
  parameter SCU_MSHR_NUM = 8;
  parameter SCU_REPL_MSHR_NUM = 2;
  `endif
  parameter L1D_STB_ENTRY_NUM = 8;
  
  parameter DATA_LINE_W         = 512;
  parameter DATA_LENGTH_PER_PKG = 64; // bit
  parameter DATA_BURST_NUM      = DATA_LINE_W/DATA_LENGTH_PER_PKG; // burst num = 512/DATA_LENGTH_PER_PKG = 8
  parameter DATA_BURST_NUM_W    = $clog2(DATA_BURST_NUM) > 0 ? $clog2(DATA_BURST_NUM) : 1;


endpackage