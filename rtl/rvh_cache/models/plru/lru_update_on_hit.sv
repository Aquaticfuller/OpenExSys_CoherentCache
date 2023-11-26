//===============================================
// Filename     : lru_update_on_hit.sv
// Author       : cuiluping
// Email        : luping.cui@rivai.ai
// Date         : 2021-09-26 20:29:35
// Description  : 
//================================================
module lru_update_on_hit
#(
    parameter   NCACHELINE  = 8,
    parameter   ADDR_W      = $clog2(NCACHELINE),
    parameter   LRU_W       = 7
)
(
    input   logic [LRU_W-1:0]                 old_lru,
    input   logic [ADDR_W-1:0]                hit_pos,//current replance position for cacheline refill
    output  logic [LRU_W-1:0]                 new_lru//new lru counters
);

logic [LRU_W-1:0] tmp;   //new LRU
int idx;
always_comb begin
    tmp = old_lru;
    idx = 1;
    for (int i=$clog2(NCACHELINE)-1;i>=0;i--) begin
             tmp[idx-1] = ~tmp[idx-1];      //flip the lru bit;
             idx = 2*idx + 32'(hit_pos[i]);
    end
    new_lru = tmp;
end
endmodule
