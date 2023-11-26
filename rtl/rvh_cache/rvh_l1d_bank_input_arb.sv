module rvh_l1d_bank_input_arb
    import riscv_pkg::*;
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
#(
  parameter int unsigned N_ARB_LD_IN_PORT = LSU_ADDR_PIPE_COUNT,
  parameter int unsigned N_ARB_ST_IN_PORT = 1, // if without stb: LSU_DATA_PIPE_COUNT,
  parameter int unsigned N_ARB_ST_IN_PORT_W = N_ARB_ST_IN_PORT > 1 ? $clog2(N_ARB_ST_IN_PORT) : 1
)
(
// input from lsu
    // LS Pipe -> D$ : Load request
    input  logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_ld_req_vld_i,
    input  logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_ld_req_io_i,
    input  logic [N_ARB_LD_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_rob_tag_i,
    input  logic [N_ARB_LD_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_prd_i,
    input  logic [N_ARB_LD_IN_PORT-1:0][      LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode_i,
`ifdef RUBY
    input  logic [N_ARB_LD_IN_PORT-1:0][RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_ld_req_lsu_tag_i,
`endif
    // input  logic [N_ARB_LD_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_index_i,
    input  logic [N_ARB_LD_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_idx_i, //
    input  logic [N_ARB_LD_IN_PORT-1:0][  L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_ld_req_offset_i, //
    input  logic [N_ARB_LD_IN_PORT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_vtag_i, // vtag
    input  logic [N_ARB_LD_IN_PORT-1:0]                         stb_l1d_ld_req_rdy_i, // need stb ready to cache to make sure the hsk is done
    output logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_ld_req_rdy_o,
    
    output logic [N_ARB_LD_IN_PORT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_hit_bank_id_o,
`ifdef RUBY
    output logic [N_ARB_ST_IN_PORT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_hit_bank_id_o,
`endif
    // LS Pipe -> D$ : DTLB response
    input  logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_dtlb_resp_vld_i,
    input  logic [N_ARB_LD_IN_PORT-1:0][         PPN_WIDTH-1:0] ls_pipe_l1d_dtlb_resp_ppn_i,
    input  logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_dtlb_resp_excp_vld_i,
    input  logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_dtlb_resp_hit_i,
    input  logic [N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_dtlb_resp_miss_i,
    // LS Pipe -> D$ : Store request
    input  logic [N_ARB_ST_IN_PORT-1:0]                         ls_pipe_l1d_st_req_vld_i,
    input  logic [N_ARB_ST_IN_PORT-1:0]                         ls_pipe_l1d_st_req_io_i,
    input  logic [N_ARB_ST_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_rob_tag_i,
    input  logic [N_ARB_ST_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_prd_i,
    input  logic [N_ARB_ST_IN_PORT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode_i,
`ifdef RUBY
    input  logic [N_ARB_ST_IN_PORT-1:0][RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_st_req_lsu_tag_i,
`endif
    // input  logic [N_ARB_ST_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_index_i,
    // input  logic [N_ARB_ST_IN_PORT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_tag_i,
    input  logic [N_ARB_ST_IN_PORT-1:0][       PADDR_WIDTH-1:0] ls_pipe_l1d_st_req_paddr_i, //
    input  logic [N_ARB_ST_IN_PORT-1:0][              XLEN-1:0] ls_pipe_l1d_st_req_data_i,
    output logic [N_ARB_ST_IN_PORT-1:0]                         ls_pipe_l1d_st_req_rdy_o,


// output to l1d cache banks
  // LS_PIPE -> D$ : LD Request
    output logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_ld_req_vld_o,
    output logic [L1D_BANK_ID_NUM-1:0][ ROB_TAG_WIDTH-1:0]      l1d_bank_ld_req_rob_tag_o,
    output logic [L1D_BANK_ID_NUM-1:0][PREG_TAG_WIDTH-1:0]      l1d_bank_ld_req_prd_o,
    output logic [L1D_BANK_ID_NUM-1:0][  LDU_OP_WIDTH-1:0]      l1d_bank_ld_req_opcode_o,
`ifdef RUBY
    output logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH -1:0] l1d_bank_ld_req_lsu_tag_o,
`endif

    output logic [L1D_BANK_ID_NUM-1:0][L1D_BANK_SET_INDEX_WIDTH-1:0 ]  l1d_bank_ld_req_idx_o,
    output logic [L1D_BANK_ID_NUM-1:0][L1D_BANK_OFFSET_WIDTH-1:0]      l1d_bank_ld_req_offset_o,
    output logic [L1D_BANK_ID_NUM-1:0][L1D_BANK_TAG_WIDTH-1:0]         l1d_bank_ld_req_vtag_o,

    output logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_stb_ld_req_rdy_o,
    input  logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_ld_req_rdy_i,
    
  // DTLB -> D$
    output logic [L1D_BANK_ID_NUM-1:0]                         dtlb_l1d_resp_vld_o,
    output logic [L1D_BANK_ID_NUM-1:0]                         dtlb_l1d_resp_excp_vld_o, // s1 kill
    output logic [L1D_BANK_ID_NUM-1:0]                         dtlb_l1d_resp_hit_o,      // s1 kill
    output logic [L1D_BANK_ID_NUM-1:0][       PPN_WIDTH-1:0]   dtlb_l1d_resp_ppn_o, // VIPT, get at s1 if tlb hit
    input  logic [L1D_BANK_ID_NUM-1:0]                         dtlb_l1d_resp_rdy_i,

  // LS_PIPE -> D$ : ST Request
    output logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_st_req_vld_o,
    output logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_st_req_io_region_o,
    output logic [L1D_BANK_ID_NUM-1:0][     ROB_TAG_WIDTH-1:0]  l1d_bank_st_req_rob_tag_o,
    output logic [L1D_BANK_ID_NUM-1:0][    PREG_TAG_WIDTH-1:0]  l1d_bank_st_req_prd_o,
    output logic [L1D_BANK_ID_NUM-1:0][      STU_OP_WIDTH-1:0]  l1d_bank_st_req_opcode_o,
`ifdef RUBY
    output logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH -1:0] l1d_bank_st_req_lsu_tag_o,
`endif
    output logic [L1D_BANK_ID_NUM-1:0][       PADDR_WIDTH-1:0]  l1d_bank_st_req_paddr_o,
    output logic [L1D_BANK_ID_NUM-1:0][  L1D_STB_DATA_WIDTH  -1:0]  l1d_bank_st_req_data_o, // data from stb
    output logic [L1D_BANK_ID_NUM-1:0][  L1D_STB_DATA_WIDTH/8-1:0]  l1d_bank_st_req_data_byte_mask_o, // data byte mask from stb

    input  logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_st_req_rdy_i,






    input clk,
    input rst
);
  
genvar i, j;
// 1. divide the lsu req to cache bank req by bank id
// LS Pipe -> D$ : Load request
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_input_arb_ld_req_vld;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_input_arb_ld_req_io;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_rob_tag;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_prd;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][      LDU_OP_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_opcode;
`ifdef RUBY
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_input_arb_ld_req_lsu_tag;
`endif
// logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_index;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_idx;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][  L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_offset;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_l1d_input_arb_ld_req_vtag;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0]                         stb_l1d_input_arb_ld_req_rdy;

logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0]                         ls_pipe_l1d_input_arb_ld_req_rdy;
// LS Pipe -> D$ : Store request
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0]                         ls_pipe_l1d_input_arb_st_req_vld;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0]                         ls_pipe_l1d_input_arb_st_req_io;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_input_arb_st_req_rob_tag;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_input_arb_st_req_prd;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_l1d_input_arb_st_req_opcode;
`ifdef RUBY
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_input_arb_st_req_lsu_tag;
`endif
// logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_input_arb_st_req_index;
// logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_l1d_input_arb_st_req_tag;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][       PADDR_WIDTH-1:0] ls_pipe_l1d_input_arb_st_req_paddr;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0][              XLEN-1:0] ls_pipe_l1d_input_arb_st_req_data;

logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0]                         ls_pipe_l1d_input_arb_st_req_rdy;

logic [N_ARB_LD_IN_PORT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] ld_req_bank_id, ld_req_bank_id_ff;
logic [N_ARB_LD_IN_PORT-1:0] lsu_pipe_ld_req_hsk;
logic [N_ARB_ST_IN_PORT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] st_req_bank_id, st_req_bank_id_ff;

generate
  for(i = 0; i < N_ARB_LD_IN_PORT; i++) begin
    assign ld_req_bank_id[i] = ls_pipe_l1d_ld_req_idx_i[i][L1D_BANK_ID_INDEX_WIDTH-1:0];
    assign lsu_pipe_ld_req_hsk[i] = ls_pipe_l1d_ld_req_vld_i[i] & ls_pipe_l1d_ld_req_rdy_o[i];
  end
  for(i = 0; i < N_ARB_ST_IN_PORT; i++) begin
    assign st_req_bank_id[i] = ls_pipe_l1d_st_req_paddr_i[i][L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_OFFSET_WIDTH];
  end
endgenerate

always_ff @(posedge clk or negedge rst) begin
  if(~rst) begin
    ld_req_bank_id_ff  <= '0;
  end else begin
    for(int i = 0; i < N_ARB_LD_IN_PORT; i++) begin
      if(lsu_pipe_ld_req_hsk[i]) begin
        ld_req_bank_id_ff[i] <= ld_req_bank_id[i];
      end
    end
  end
end

always_comb begin : lsu_ld_req_to_cache_bank_router
  ls_pipe_l1d_input_arb_ld_req_vld = '0;

  ls_pipe_l1d_input_arb_ld_req_io       = '0;
  ls_pipe_l1d_input_arb_ld_req_rob_tag  = '0;
  ls_pipe_l1d_input_arb_ld_req_prd      = '0;
  ls_pipe_l1d_input_arb_ld_req_opcode   = '0;
  ls_pipe_l1d_input_arb_ld_req_idx      = '0;
  ls_pipe_l1d_input_arb_ld_req_offset   = '0;
  ls_pipe_l1d_input_arb_ld_req_vtag     = '0;

  stb_l1d_input_arb_ld_req_rdy          = '0;

  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    for(int j = 0; j < N_ARB_LD_IN_PORT; j++) begin
      if(ld_req_bank_id[j] == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin // same bank id
        ls_pipe_l1d_input_arb_ld_req_vld    [i][j]  = ls_pipe_l1d_ld_req_vld_i    [j];// & ~(|(ls_pipe_l1d_input_arb_st_req_vld[i])); // give st higher priority as there will be a stb
        ls_pipe_l1d_input_arb_ld_req_io     [i][j]  = ls_pipe_l1d_ld_req_io_i     [j];
        ls_pipe_l1d_input_arb_ld_req_rob_tag[i][j]  = ls_pipe_l1d_ld_req_rob_tag_i[j]; 
        ls_pipe_l1d_input_arb_ld_req_prd    [i][j]  = ls_pipe_l1d_ld_req_prd_i    [j];
        ls_pipe_l1d_input_arb_ld_req_opcode [i][j]  = ls_pipe_l1d_ld_req_opcode_i [j];
`ifdef RUBY
        ls_pipe_l1d_input_arb_ld_req_lsu_tag[i][j]  = ls_pipe_l1d_ld_req_lsu_tag_i[j];
`endif
        // ls_pipe_l1d_input_arb_ld_req_index  [i][j]  = ls_pipe_l1d_ld_req_index_i  [j];
        ls_pipe_l1d_input_arb_ld_req_idx    [i][j]  = ls_pipe_l1d_ld_req_idx_i  [j];
        ls_pipe_l1d_input_arb_ld_req_offset [i][j]  = ls_pipe_l1d_ld_req_offset_i  [j];
        ls_pipe_l1d_input_arb_ld_req_vtag   [i][j]  = ls_pipe_l1d_ld_req_vtag_i    [j];

        stb_l1d_input_arb_ld_req_rdy        [i][j]  = stb_l1d_ld_req_rdy_i         [j];
      end
    end
  end
end

always_comb begin : lsu_st_req_to_cache_bank_router
  ls_pipe_l1d_input_arb_st_req_vld      = '0;

  ls_pipe_l1d_input_arb_st_req_io       = '0;
  ls_pipe_l1d_input_arb_st_req_rob_tag  = '0;
  ls_pipe_l1d_input_arb_st_req_prd      = '0;
  ls_pipe_l1d_input_arb_st_req_opcode   = '0;
  ls_pipe_l1d_input_arb_st_req_paddr    = '0;
  ls_pipe_l1d_input_arb_st_req_data     = '0;
  
  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    for(int j = 0; j < N_ARB_ST_IN_PORT; j++) begin
      if(st_req_bank_id[j] == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin // same bank id
        ls_pipe_l1d_input_arb_st_req_vld    [i][j]  = ls_pipe_l1d_st_req_vld_i    [j];
        ls_pipe_l1d_input_arb_st_req_io     [i][j]  = ls_pipe_l1d_st_req_io_i     [j];
        ls_pipe_l1d_input_arb_st_req_rob_tag[i][j]  = ls_pipe_l1d_st_req_rob_tag_i[j]; 
        ls_pipe_l1d_input_arb_st_req_prd    [i][j]  = ls_pipe_l1d_st_req_prd_i    [j];
        ls_pipe_l1d_input_arb_st_req_opcode [i][j]  = ls_pipe_l1d_st_req_opcode_i [j];
`ifdef RUBY
        ls_pipe_l1d_input_arb_st_req_lsu_tag[i][j]  = ls_pipe_l1d_st_req_lsu_tag_i[j];
`endif
        // ls_pipe_l1d_input_arb_st_req_index  [i][j]  = ls_pipe_l1d_st_req_index_i  [j];
        // ls_pipe_l1d_input_arb_st_req_tag    [i][j]  = ls_pipe_l1d_st_req_tag_i    [j];
        ls_pipe_l1d_input_arb_st_req_paddr  [i][j]  = ls_pipe_l1d_st_req_paddr_i  [j];
        ls_pipe_l1d_input_arb_st_req_data   [i][j]  = ls_pipe_l1d_st_req_data_i   [j];
      end
    end
  end
end

// 2. cache bank input arbiter
// 2.1 ld req input check if bank conflict
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0] l1d_bank_ld_req_grt;
logic [L1D_BANK_ID_NUM-1:0][$clog2(N_ARB_LD_IN_PORT)-1:0] l1d_bank_ld_req_grt_idx;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_LD_IN_PORT-1:0] l1d_bank_ld_req_hsk, l1d_bank_ld_req_hsk_ff;

  // cache bank input rr arbiter gen
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin
    one_hot_rr_arb #(
      .N_INPUT      (N_ARB_LD_IN_PORT) 
    ) ld_req_input_rr_arb_u (
      .req_i        (ls_pipe_l1d_input_arb_ld_req_vld[i]   ),
      .update_i     (|(ls_pipe_l1d_input_arb_ld_req_vld[i])),
      .grt_o        (l1d_bank_ld_req_grt[i]     ),
      .grt_idx_o    (l1d_bank_ld_req_grt_idx[i] ),
      .rstn         (rst                       ),
      .clk          (clk                        )
    );
  end
endgenerate

  // lsu ld input hsk with cache bank
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin
    assign l1d_bank_ld_req_hsk[i] = l1d_bank_ld_req_grt[i] & {N_ARB_LD_IN_PORT{l1d_bank_ld_req_rdy_i[i]}};
  end
endgenerate

always_ff@(posedge clk or negedge rst) begin
  if(~rst) begin
    l1d_bank_ld_req_hsk_ff <= '0;
  end else begin
    l1d_bank_ld_req_hsk_ff <= l1d_bank_ld_req_hsk; 
  end
end

always_comb begin
  ls_pipe_l1d_ld_req_rdy_o = '0;

  ls_pipe_l1d_ld_req_hit_bank_id_o = '0;

  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    for(int j = 0; j < N_ARB_LD_IN_PORT; j++) begin
      if(l1d_bank_ld_req_grt[i][j]) begin // if the bank grt one of the ld req
        ls_pipe_l1d_ld_req_rdy_o[j] = l1d_bank_ld_req_rdy_i[i]; // the lsu ld pipe rdy is assigned to the ld rdy of the cache bank
// `ifdef RUBY
        ls_pipe_l1d_ld_req_hit_bank_id_o[j] = i[  L1D_BANK_ID_INDEX_WIDTH-1:0];
// `endif
      end
    end
  end
end

// 2.2 st req input check if bank conflict (if stb added, there should be only 1 st req from stb per cycle)
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0] l1d_bank_st_req_grt;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT_W-1:0] l1d_bank_st_req_grt_idx;
logic [L1D_BANK_ID_NUM-1:0][N_ARB_ST_IN_PORT-1:0] l1d_bank_st_req_hsk;

  // cache bank input rr arbiter gen
generate
  if(N_ARB_ST_IN_PORT > 1) begin: gen_st_req_input_rr_arb_more_than_1_port
    for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_st_req_input_rr_arb
      one_hot_rr_arb #(
        .N_INPUT      (N_ARB_ST_IN_PORT) 
      ) st_req_input_rr_arb_u (
        .req_i        (ls_pipe_l1d_input_arb_st_req_vld[i]   ),
        .update_i     (|(ls_pipe_l1d_input_arb_st_req_vld[i])),
        .grt_o        (l1d_bank_st_req_grt[i]     ),
        .grt_idx_o    (l1d_bank_st_req_grt_idx[i] ),
        .rstn         (rst                       ),
        .clk          (clk                        )
      );
    end
  end else begin: gen_st_req_input_rr_arb_only_one_port
    for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_st_req_input_rr_arb
      assign l1d_bank_st_req_grt[i]     = 1'b1;
      assign l1d_bank_st_req_grt_idx[i] = 1'b0;
    end
  end
endgenerate

  // lsu ld input hsk with cache bank
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin
    assign l1d_bank_st_req_hsk[i] = l1d_bank_st_req_grt[i] & {N_ARB_ST_IN_PORT{l1d_bank_st_req_rdy_i[i]}};
  end
endgenerate

always_comb begin
  ls_pipe_l1d_st_req_rdy_o = '0;
`ifdef RUBY
  ls_pipe_l1d_st_req_hit_bank_id_o = '0;
`endif
  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    for(int j = 0; j < N_ARB_ST_IN_PORT; j++) begin
      if(l1d_bank_st_req_grt[i][j]) begin // if the bank grt one of the ld req
        ls_pipe_l1d_st_req_rdy_o[j] = l1d_bank_st_req_rdy_i[i]; // the lsu ld pipe rdy is assigned to the ld rdy of the cache bank
`ifdef RUBY
        ls_pipe_l1d_st_req_hit_bank_id_o[j] = i[  L1D_BANK_ID_INDEX_WIDTH-1:0];
`endif
      end
    end
  end
end








// 3. req signals to each cache bank
// trans XLEN st req into cache line size (for adding stb later)
logic [L1D_BANK_ID_NUM-1:0][L1D_STB_DATA_WIDTH-1:0]      ls_pipe_l1d_st_req_data_transed; // data from stb
logic [L1D_BANK_ID_NUM-1:0][L1D_STB_DATA_WIDTH/8-1:0]    ls_pipe_l1d_st_req_data_byte_mask_transed;
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin
    rrv2rvh_ruby_stmask_trans rrv2rvh_ruby_stmask_trans_st_req_u
    (
      .st_dat_i                             (ls_pipe_l1d_input_arb_st_req_data[i][l1d_bank_st_req_grt_idx[i]]),
      .st_offset_i                          (ls_pipe_l1d_input_arb_st_req_paddr[i][l1d_bank_st_req_grt_idx[i]][L1D_OFFSET_WIDTH-1:0]),
      .st_opcode_i                          (ls_pipe_l1d_input_arb_st_req_opcode [i][l1d_bank_st_req_grt_idx[i]]        ),
      .ls_pipe_l1d_st_req_data_o            (ls_pipe_l1d_st_req_data_transed[i]          ), // data from stb
      .ls_pipe_l1d_st_req_data_byte_mask_o  (ls_pipe_l1d_st_req_data_byte_mask_transed[i]) // data byte mask from stb
    );
  end
endgenerate

always_comb begin
  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    // LS_PIPE -> D$ : LD Request
    l1d_bank_ld_req_vld_o      [i]  = ls_pipe_l1d_input_arb_ld_req_vld    [i][l1d_bank_ld_req_grt_idx[i]];
    l1d_bank_ld_req_rob_tag_o  [i]  = ls_pipe_l1d_input_arb_ld_req_rob_tag[i][l1d_bank_ld_req_grt_idx[i]];
    l1d_bank_ld_req_prd_o      [i]  = ls_pipe_l1d_input_arb_ld_req_prd    [i][l1d_bank_ld_req_grt_idx[i]];
    l1d_bank_ld_req_opcode_o   [i]  = ls_pipe_l1d_input_arb_ld_req_opcode [i][l1d_bank_ld_req_grt_idx[i]];
`ifdef RUBY
    l1d_bank_ld_req_lsu_tag_o  [i]  = ls_pipe_l1d_input_arb_ld_req_lsu_tag[i][l1d_bank_ld_req_grt_idx[i]];
`endif
    l1d_bank_ld_req_idx_o      [i]  = ls_pipe_l1d_input_arb_ld_req_idx    [i][l1d_bank_ld_req_grt_idx[i]][L1D_INDEX_WIDTH-1-:L1D_BANK_SET_INDEX_WIDTH];
    l1d_bank_ld_req_offset_o   [i]  = ls_pipe_l1d_input_arb_ld_req_offset [i][l1d_bank_ld_req_grt_idx[i]][L1D_BANK_OFFSET_WIDTH-1:0];
    l1d_bank_ld_req_vtag_o     [i]  = ls_pipe_l1d_input_arb_ld_req_vtag   [i][l1d_bank_ld_req_grt_idx[i]][L1D_BANK_TAG_WIDTH-1:0];

    l1d_bank_stb_ld_req_rdy_o  [i]  = stb_l1d_input_arb_ld_req_rdy        [i][l1d_bank_ld_req_grt_idx[i]];

    // LS_PIPE -> D$ : ST Request
    l1d_bank_st_req_vld_o      [i]  = ls_pipe_l1d_input_arb_st_req_vld    [i][l1d_bank_st_req_grt_idx[i]];
    l1d_bank_st_req_io_region_o[i]  = 1'b0;
    l1d_bank_st_req_rob_tag_o  [i]  = ls_pipe_l1d_input_arb_st_req_rob_tag[i][l1d_bank_st_req_grt_idx[i]];
    l1d_bank_st_req_prd_o      [i]  = ls_pipe_l1d_input_arb_st_req_prd    [i][l1d_bank_st_req_grt_idx[i]];
    l1d_bank_st_req_opcode_o   [i]  = ls_pipe_l1d_input_arb_st_req_opcode [i][l1d_bank_st_req_grt_idx[i]];
`ifdef RUBY
    l1d_bank_st_req_lsu_tag_o  [i]  = ls_pipe_l1d_input_arb_st_req_lsu_tag[i][l1d_bank_st_req_grt_idx[i]];
`endif
    l1d_bank_st_req_paddr_o    [i]  = ls_pipe_l1d_input_arb_st_req_paddr[i][l1d_bank_st_req_grt_idx[i]];
    l1d_bank_st_req_data_o     [i]  = ls_pipe_l1d_st_req_data_transed[i];
    l1d_bank_st_req_data_byte_mask_o[i] = ls_pipe_l1d_st_req_data_byte_mask_transed[i]; // data byte mask from stb
  end
end

// 4. tlb resp, 1cycle later than req
always_comb begin
  dtlb_l1d_resp_vld_o = '0;

  dtlb_l1d_resp_excp_vld_o  = '0;
  dtlb_l1d_resp_hit_o       = '0;
  dtlb_l1d_resp_ppn_o       = '0;
  
  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    for(int j = 0; j < N_ARB_LD_IN_PORT; j++) begin
      if((ld_req_bank_id_ff[j] == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) & l1d_bank_ld_req_hsk_ff[i][j]) begin
        dtlb_l1d_resp_vld_o     [i] = ls_pipe_l1d_dtlb_resp_vld_i     [j];                                  
        dtlb_l1d_resp_excp_vld_o[i] = ls_pipe_l1d_dtlb_resp_excp_vld_i[j];     // s1 kill              
        dtlb_l1d_resp_hit_o     [i] = ls_pipe_l1d_dtlb_resp_hit_i     [j];     // s1 kill              
        dtlb_l1d_resp_ppn_o     [i] = ls_pipe_l1d_dtlb_resp_ppn_i     [j];     // VIPT, get at s1 if tlb hit
      end   
    end                         
  end
end

endmodule