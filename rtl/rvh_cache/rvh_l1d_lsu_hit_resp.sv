module rvh_l1d_lsu_hit_resp
    import riscv_pkg::*;
    import rvh_pkg::*;
    import rvh_l1d_pkg::*;
(
    input logic                                     resp_valid_i,
    input logic                                     refill_valid_i,
    input logic [L1D_BANK_WAY_NUM-1:0]              tag_compare_hit_per_way_i,
    input logic                                     ld_tlb_hit_i,
    input logic [L1D_BANK_LINE_DATA_SIZE-1:0]       lsu_ld_dat_i,
    input rrv64_l1d_req_type_dec_t                  lsu_ld_req_type_dec_i,
    input logic [     ROB_TAG_WIDTH-1:0]            ls_pipe_l1d_ld_req_rob_tag_i,
    input logic [    PREG_TAG_WIDTH-1:0]            ls_pipe_l1d_ld_req_prd_i,
`ifdef RUBY
    input logic [RRV64_LSU_ID_WIDTH -1:0]           ls_pipe_l1d_ld_req_lsu_tag_i,
`endif
  
//    input logic [       L1D_BANK_SET_INDEX_WIDTH-1:0    ]        ls_pipe_l1d_ld_req_idx_i,
    input logic [       L1D_BANK_OFFSET_WIDTH-1:0   ]        ls_pipe_l1d_ld_req_offset_i,

    // STB -> D$ : store buffer load bypass
    input  logic                          stb_l1d_bank_ld_bypass_valid_i,
    input  logic [            XLEN-1:0]   stb_l1d_bank_ld_bypass_data_i,

    // D$ -> ROB : Write Back
    output logic                          l1d_rob_wb_vld_o,
    output logic [     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag_o,
    // D$ -> Int PRF : Write Back
    output logic                          l1d_int_prf_wb_vld_o,
    output logic [    PREG_TAG_WIDTH-1:0] l1d_int_prf_wb_tag_o,
    output logic [              XLEN-1:0] l1d_int_prf_wb_data_o,
    output logic                          l1d_int_prf_wb_vld_from_mlfb_o,
`ifdef RUBY
    output logic [RRV64_LSU_ID_WIDTH -1:0]  l1d_lsu_lsu_tag_o,
`endif

    // D$ -> PTW : Response
    output logic                           l1d_ptw_walk_vld_o,
    output logic [      PTW_ID_WIDTH-1:0]  l1d_ptw_walk_id_o,
    output logic [         PTE_WIDTH-1:0]  l1d_ptw_walk_pte_o,

    output logic [              XLEN-1:0]  unsign_ext_dat_o
);

// output data select
logic [XLEN-1:0] lsu_ld_hit_dat;
logic [XLEN-1:0] lsu_ld_refill_dat;
logic [XLEN-1:0] lsu_ld_dat_unmasked;
logic [XLEN-1:0] lsu_ld_dat_valid_bit_mask;
logic [XLEN-1:0] lsu_ld_dat_sign_ext_bit_mask;

assign lsu_ld_dat_valid_bit_mask      = lsu_ld_req_type_dec_i.op_b  ? 64'hff :
                                        lsu_ld_req_type_dec_i.op_hw ? 64'hffff :
                                        lsu_ld_req_type_dec_i.op_w  ? 64'hffff_ffff :
                                        lsu_ld_req_type_dec_i.op_dw ? 64'hffff_ffff_ffff_ffff: '0;

assign lsu_ld_dat_sign_ext_bit_mask = lsu_ld_req_type_dec_i.ld_u ? '0 : 
                                      lsu_ld_req_type_dec_i.op_b  ? {{(XLEN-8){lsu_ld_dat_unmasked[8-1]}}, {8{1'b0}}} :
                                      lsu_ld_req_type_dec_i.op_hw ? {{(XLEN-8*2){lsu_ld_dat_unmasked[8*2-1]}}, {(8*2){1'b0}}} :
                                      lsu_ld_req_type_dec_i.op_w  ? {{(XLEN-8*4){lsu_ld_dat_unmasked[8*4-1]}}, {(8*4){1'b0}}} :
                                      lsu_ld_req_type_dec_i.op_dw ? {{(XLEN-8*8){lsu_ld_dat_unmasked[8*8-1]}}, {(8*8){1'b0}}} : '0;

assign lsu_ld_dat_unmasked = stb_l1d_bank_ld_bypass_valid_i ? stb_l1d_bank_ld_bypass_data_i :
                             refill_valid_i                 ? lsu_ld_refill_dat : lsu_ld_hit_dat;

// ld resp
assign unsign_ext_dat_o         = (lsu_ld_dat_valid_bit_mask & lsu_ld_dat_unmasked);
assign l1d_int_prf_wb_data_o    = lsu_ld_req_type_dec_i.is_sc ? lsu_ld_dat_i[XLEN-1:0] : 
                                                                (unsign_ext_dat_o | lsu_ld_dat_sign_ext_bit_mask);

assign l1d_rob_wb_vld_o         = resp_valid_i & (
                                  ((lsu_ld_req_type_dec_i.is_ld) & (ld_tlb_hit_i | refill_valid_i | stb_l1d_bank_ld_bypass_valid_i)) |
                                  (lsu_ld_req_type_dec_i.is_amo | lsu_ld_req_type_dec_i.is_lr | lsu_ld_req_type_dec_i.is_sc));
assign l1d_rob_wb_rob_tag_o     = ls_pipe_l1d_ld_req_rob_tag_i;

assign l1d_int_prf_wb_vld_o     = l1d_rob_wb_vld_o;
assign l1d_int_prf_wb_vld_from_mlfb_o = resp_valid_i & lsu_ld_req_type_dec_i.is_ld & refill_valid_i;
assign l1d_int_prf_wb_tag_o     = ls_pipe_l1d_ld_req_prd_i;

`ifdef RUBY
assign l1d_lsu_lsu_tag_o        = ls_pipe_l1d_ld_req_lsu_tag_i;
`endif

// ptw resp
assign l1d_ptw_walk_vld_o       = resp_valid_i & lsu_ld_req_type_dec_i.is_ptw_ld;
assign l1d_ptw_walk_id_o        = ls_pipe_l1d_ld_req_rob_tag_i;
assign l1d_ptw_walk_pte_o       = lsu_ld_dat_unmasked; // always 64-bit data

// get lsu_ld_refill_dat
logic [L1D_BANK_LINE_DATA_SIZE+XLEN-1:0]  lsu_ld_dat_zext;
logic [XLEN-1:0]    lsu_ld_refill_dat_sel_by_offset;

assign lsu_ld_dat_zext = {{XLEN{1'b0}}, lsu_ld_dat_i};
assign lsu_ld_refill_dat_sel_by_offset = lsu_ld_dat_zext[ls_pipe_l1d_ld_req_offset_i*8 +: XLEN];
assign lsu_ld_refill_dat = lsu_ld_refill_dat_sel_by_offset;

// get lsu_ld_hit_dat
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0]    lsu_ld_hit_dat_per_way_seg;
logic [L1D_BANK_WAY_NUM-1:0][XLEN-1:0] lsu_ld_hit_dat_per_way_seg_sel_by_offset;
always_comb begin: select_way_data
    for(int waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin
        lsu_ld_hit_dat_per_way_seg[waynum]                  = lsu_ld_dat_i[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)*waynum+:(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)];
        lsu_ld_hit_dat_per_way_seg_sel_by_offset[waynum]    = (lsu_ld_hit_dat_per_way_seg[waynum][ls_pipe_l1d_ld_req_offset_i[3]*XLEN+:XLEN]) >> (ls_pipe_l1d_ld_req_offset_i[2:0] * 8); //data ram output 128bit, lsu input 64bit, use offset[3] to diff
    end
end


onehot_mux
#(
    .SOURCE_COUNT(L1D_BANK_WAY_NUM),
    .DATA_WIDTH(XLEN)
)
L1D_RESP_OH_MUX
(
    .sel_i (tag_compare_hit_per_way_i),
    .data_i(lsu_ld_hit_dat_per_way_seg_sel_by_offset),
    .data_o(lsu_ld_hit_dat)
);


endmodule