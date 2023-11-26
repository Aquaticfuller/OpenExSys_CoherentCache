//===============================================
// Filename     : lru_get_new_line.sv
// Author       : cuiluping
// Email        : luping.cui@rivai.ai
// Date         : 2021-09-26 20:19:13
// Description  : 
//================================================
module lru_get_new_line
#(
    parameter   NCACHELINE  = 8,
    parameter   ADDR_W      = $clog2(NCACHELINE),
    parameter   LRU_W       = 7
)
(
    input   logic [LRU_W-1:0]                 old_lru,
    output  logic [LRU_W-1:0]                 new_lru,//new lru counters
    output  logic [ADDR_W-1:0]                repl_pos//current replance position for cacheline refill
);
//walk the LRU binary tree to get a new line
        int             idx;
        logic [LRU_W:0] tmp;

    always_comb begin
        //parent : n , lef: 2n, right: 2n+1
        idx = 1;
        tmp = old_lru; 
        repl_pos= '0;
                
        for (int i=0;i<$clog2(NCACHELINE);i++) begin
             tmp[idx-1] = ~tmp[idx-1];                                  //flip the LRU bit during walk
             repl_pos= {repl_pos[0+:ADDR_W-1], old_lru[idx - 1]};       //left shift in the tree bit during the walk
             idx =  2*idx + 32'(repl_pos[0]);                           //array index is 0 basede                           
        end
        new_lru = tmp;
    end
endmodule
