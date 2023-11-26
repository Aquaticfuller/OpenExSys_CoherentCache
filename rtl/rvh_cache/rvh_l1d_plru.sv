module rvh_l1d_plru
    import rvh_l1d_pkg::*;
#(
     parameter entry_num=32
    ,parameter entry_idx=$clog2(entry_num)
    ,parameter way_num =4
    ,parameter way_num_idx=$clog2(way_num)
)
(
 input clk
,input rstn
,input upd_en_hit
,input[entry_idx-1:0] upd_set_idx_hit
,input[way_num_idx-1:0] upd_way_idx_hit
,input rd_en_refill
,input[entry_idx-1:0] rd_idx_refill
,output[way_num_idx-1:0] rd_dat_refill
);

localparam lru_entry_w = way_num -1;
logic[entry_num-1:0][lru_entry_w-1:0] lru_sta ;
logic[entry_num-1:0][lru_entry_w-1:0] lru_sta_nxt;
logic[entry_num-1:0] lru_sta_ena;

logic[lru_entry_w-1:0]lru_sta_old_hit;
logic[lru_entry_w -1 :0] lru_sta_old_refill;
logic[lru_entry_w -1:0] lru_sta_nxt_hit;
logic[lru_entry_w-1:0] lru_sta_nxt_refill;

genvar ii;
generate
for(ii=0; ii< entry_num; ii++) begin:GEN_LRU
    assign lru_sta_nxt[ii] = upd_en_hit ? lru_sta_nxt_hit : lru_sta_nxt_refill;
    assign lru_sta_ena[ii] = upd_en_hit & (upd_set_idx_hit == ii) |
                             rd_en_refill & (rd_idx_refill == ii);
    std_dffre #(.WIDTH(lru_entry_w)) U_PLRU (.clk(clk), .rstn(rstn), .en(lru_sta_ena[ii]), .d(lru_sta_nxt[ii]), .q(lru_sta[ii]));

end
endgenerate

assign lru_sta_old_hit    = lru_sta[upd_set_idx_hit];
assign lru_sta_old_refill = lru_sta[rd_idx_refill];

// miss
lru_get_new_line
#(
    .NCACHELINE(way_num),
    .LRU_W(lru_entry_w)
)
U_LRU_GET_NEW_LINE
(
    .old_lru(lru_sta_old_refill),
    .new_lru(lru_sta_nxt_refill),//new lru counters
    .repl_pos(rd_dat_refill)//current replance position for cacheline refill
);

// hit
lru_update_on_hit
#(
    .NCACHELINE(way_num),
    .LRU_W(lru_entry_w)
)
U_LRU_UPDATE_ON_HIT
(
    .old_lru(lru_sta_old_hit),
    .hit_pos(upd_way_idx_hit),
    .new_lru(lru_sta_nxt_hit)//new lru counters
);


endmodule