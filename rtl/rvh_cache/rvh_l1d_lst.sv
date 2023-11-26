module rvh_l1d_lst
  import rvh_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
     parameter entry_num=32
    ,parameter entry_idx=$clog2(entry_num)
    ,parameter way_num=4
    ,parameter way_idx=$clog2(way_num)
)
(
     input logic  clk
    ,input logic  rstn
    
    ,input logic  lst_mesi_wr_en_s0_req
    ,input logic [L1D_BANK_SET_INDEX_WIDTH-1:0] lst_mesi_wr_set_idx_s0_req
    ,input logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] lst_mesi_wr_way_idx_s0_req
    ,input rrv64_l1d_lst_req_t lst_wr_dat_s0_req
   
    ,input logic  lst_mesi_wr_en_snp 
    ,input logic [L1D_BANK_SET_INDEX_WIDTH-1:0] lst_mesi_wr_set_idx_snp
    ,input logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] lst_mesi_wr_way_idx_snp
    ,input rrv64_mesi_type_e lst_mesi_wr_dat_snp
    
    ,input logic  [L1D_BANK_SET_INDEX_WIDTH-1:0] lst_rd_idx_s0_req
    ,output rrv64_l1d_lst_t          lst_rd_dat_s0_req
    
    ,input logic  [L1D_BANK_SET_INDEX_WIDTH-1:0] lst_rd_idx_mlfb_peek
    ,output rrv64_l1d_lst_t lst_rd_dat_mlfb_peek
    
    // ,input logic  [entry_idx-1:0] lst_avail_way_rd_idx_mlfb_peek
    ,output logic [way_idx-1:0] lst_avail_way_rd_dat_mlfb_peek
    
    ,input logic  [L1D_BANK_SET_INDEX_WIDTH-1:0] lst_check_set_idx
    ,input logic  [L1D_BANK_WAY_INDEX_WIDTH-1:0] lst_check_way_idx
    ,input logic  lst_check_valid
    ,output logic lst_check_ready
);

rrv64_l1d_lst_t[entry_num-1:0] lst_entry; // a lst_entry_mesi_way wrapper
logic[entry_num-1:0][L1D_BANK_WAY_NUM-1:0][$bits(rrv64_mesi_type_e)-1:0]lst_entry_mesi_way; // lst entity
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
logic[entry_num-1:0][L1D_BANK_WAY_NUM-1:0][DATA_BURST_NUM-1:0]lst_entry_data_dirty; // lst entity
`endif
//logic[entry_num-1:0][L1D_BANK_WAY_NUM-1:0] lst_entry_lrsc_lock_way;

logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] mesi_wr_set_en;
rrv64_mesi_type_e[entry_num-1:0][L1D_BANK_WAY_NUM-1:0] mesi_wr_dat;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
logic[entry_num-1:0][L1D_BANK_WAY_NUM-1:0][DATA_BURST_NUM-1:0] data_dirty_wr_dat;
`endif
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lr_lock_wr_set_en;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] sc_rl_wr_set_en;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lrsc_wr_set_en;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lrsc_wr_dat;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lst_check_reserved_bit_set;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lst_check_reserved_bit_clr;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lst_check_reserved_bit_ena;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lst_check_reserved_bit_nxt;
logic[entry_num -1:0][L1D_BANK_WAY_NUM-1:0] lst_check_reserved_bit;
logic[way_num -1:0] set_avail_bit_list_mlfb_peek;

logic clk_lst, clk_lst_en;
assign clk_lst_en = lst_mesi_wr_en_s0_req | lst_mesi_wr_en_snp | lst_check_valid;
rrv64_cell_clkgate U_ICG_LST (.clk_i(clk) ,.clk_enable_i(clk_lst_en) ,.clk_senable_i('0),.clk_gated_o(clk_lst));

genvar ii,jj;
generate
for(ii=0; ii<entry_num; ii++)begin:GEN_RRV64_L1D_LST_SET
    //wr
    for(jj=0; jj<L1D_BANK_WAY_NUM; jj++)begin:GEN_RRV64_L1D_LST_WAY
        //mesi
        assign mesi_wr_set_en[ii][jj] = lst_mesi_wr_en_s0_req & (lst_mesi_wr_set_idx_s0_req ==ii) & (lst_mesi_wr_way_idx_s0_req==jj) |
                                        lst_mesi_wr_en_snp & (lst_mesi_wr_set_idx_snp ==ii) & (lst_mesi_wr_way_idx_snp==jj);
        assign mesi_wr_dat[ii][jj]        = lst_mesi_wr_en_s0_req ? lst_wr_dat_s0_req.mesi_sta : lst_mesi_wr_dat_snp;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
        assign data_dirty_wr_dat[ii][jj]  = lst_mesi_wr_en_s0_req ? lst_wr_dat_s0_req.data_dirty : '0;
`endif

        std_dffre #(.WIDTH($bits(rrv64_mesi_type_e))) U_RRV64_L1D_LST_MESI_WAY (.clk(clk_lst), .rstn(rstn), .en(mesi_wr_set_en[ii][jj]), .d(mesi_wr_dat[ii][jj]), .q(lst_entry_mesi_way[ii][jj]));
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
        std_dffre #(.WIDTH(DATA_BURST_NUM)) U_RRV64_L1D_LST_DATA_DIRTY (.clk(clk_lst), .rstn(rstn), .en(mesi_wr_set_en[ii][jj]), .d(data_dirty_wr_dat[ii][jj]), .q(lst_entry_data_dirty[ii][jj]));
`endif
        
        assign lst_entry[ii].mesi_sta[jj] = {lst_entry_mesi_way[ii][jj]};
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
        assign lst_entry[ii].data_dirty[jj] = {lst_entry_data_dirty[ii][jj]};
`endif

        //wr reserve bit
        assign lst_check_reserved_bit_set[ii][jj] = lst_check_valid & (~lst_check_reserved_bit[ii][jj]) & (lst_check_set_idx == ii) & (lst_check_way_idx == jj);
        assign lst_check_reserved_bit_clr[ii][jj] = lst_mesi_wr_en_s0_req & (mesi_wr_dat[ii][jj] != INVALID) &(lst_mesi_wr_set_idx_s0_req ==ii) & (lst_mesi_wr_way_idx_s0_req ==jj);
        assign lst_check_reserved_bit_ena[ii][jj] = lst_check_reserved_bit_set[ii][jj] | lst_check_reserved_bit_clr[ii][jj];
        assign lst_check_reserved_bit_nxt[ii][jj] = lst_check_reserved_bit_set[ii][jj] & (~lst_check_reserved_bit_clr[ii][jj]);
        std_dffre #(.WIDTH(1)) U_RRV64_L1D_LST_RESERVE_BIT (.clk(clk_lst) ,.rstn(rstn) ,.en(lst_check_reserved_bit_ena[ii][jj]) ,.d(lst_check_reserved_bit_nxt[ii][jj]) ,.q(lst_check_reserved_bit[ii][jj]));
    end
end
endgenerate
assign lst_check_ready = ~lst_check_reserved_bit[lst_check_set_idx][lst_check_way_idx];
assign lst_rd_dat_s0_req    = lst_entry[lst_rd_idx_s0_req];
assign lst_rd_dat_mlfb_peek = lst_entry[lst_rd_idx_mlfb_peek];

//peek avail entry
genvar kk;
generate
    for(kk=0; kk<way_num; kk++)begin:GEN_VALID_BIT
        assign set_avail_bit_list_mlfb_peek[kk]=(lst_entry[lst_rd_idx_mlfb_peek].mesi_sta[kk] == INVALID);
    end
endgenerate

// search_1st
// #(.bit_cnt(way_num)
// )
// U_AVAIL_WAY_IDX_MLFB_PEEK
// (
//      .bit_vec (set_avail_bit_list_mlfb_peek)
//     ,.td_1st_idx (lst_avail_way_rd_dat_mlfb_peek)
// );

always_comb begin
    lst_avail_way_rd_dat_mlfb_peek = '0;
    for(int i = 0; i < way_num; i++) begin
        if(set_avail_bit_list_mlfb_peek[i] == 1'b1) begin
            lst_avail_way_rd_dat_mlfb_peek = i[way_idx-1:0];
        end
    end
end

endmodule