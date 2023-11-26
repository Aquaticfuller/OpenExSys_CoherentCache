`ifndef __FREELIST_SV__
`define __FREELIST_SV__

module freelist
#(
    parameter int unsigned ENTRY_COUNT = 4,
    localparam int unsigned ENTRY_TAG_WIDTH = $clog2(ENTRY_COUNT),
    localparam int unsigned IS_LOG2 = (2 ** ENTRY_TAG_WIDTH) == ENTRY_COUNT
)
(
    // Enqueue
    input logic enq_vld_i,
    input logic[ENTRY_TAG_WIDTH-1:0] enq_tag_i,
    // Dequeue
    input logic deq_vld_i,
    output logic[ENTRY_TAG_WIDTH-1:0] deq_tag_o,
    output logic deq_rdy_o,
    // Flush
    input logic flush_i,
    
    input clk,
    input rst
);
    
    logic [ENTRY_COUNT-1:0][ENTRY_TAG_WIDTH-1:0] ram_r,ram_n;
    logic [ENTRY_COUNT-1:0] ram_clk_en;
     
    logic [ENTRY_TAG_WIDTH-1:0] head_r,head_n;
    logic head_flag_r,head_flag_n;
    logic head_clk_en;
    
    logic [ENTRY_TAG_WIDTH-1:0] tail_r,tail_n;
    logic tail_flag_r,tail_flag_n;    
    logic tail_clk_en;

    logic enq_fire;
    logic deq_fire;    
    
    logic full,empty;
    logic flag_equal,tag_equal;
    
    assign enq_fire = enq_vld_i;
    assign deq_fire = deq_rdy_o & deq_vld_i;
    
    assign flag_equal = tail_flag_r == head_flag_r;
    assign tag_equal  = tail_r == head_r; 
    
    assign full  = ~flag_equal & tag_equal;
    assign empty = flag_equal & tag_equal; 
        
    // Output 
    assign deq_tag_o = ram_r[head_r];
    
    always_comb begin : ram_update
        ram_n = ram_r;
        ram_n[tail_r] = enq_tag_i; 
        if(flush_i) begin
            for(int i = 0 ; i < ENTRY_COUNT; i++) begin
                ram_n[i] = i[ENTRY_TAG_WIDTH-1:0];
            end
        end
    end
    
    always_comb begin : ram_clk_en_gen
        for(int i = 0 ; i < ENTRY_COUNT; i++) begin
            ram_clk_en[i] = (enq_fire & (i == tail_r)) | flush_i;
        end
    end
    
    
    always_comb begin : head_update
        if(IS_LOG2) begin
           {head_flag_n,head_n} = {head_flag_r,head_r} + 1'b1; 
        end else begin
            if(head_r == ENTRY_COUNT-1) begin
                head_n = {ENTRY_COUNT{1'b0}};
                head_flag_n = ~head_flag_r; 
            end else begin
                head_n = head_r + 1'b1;
                head_flag_n = head_flag_r; 
            end
        end
        if(flush_i) begin
            {head_flag_n,head_n} = {head_flag_r,head_r};
        end
    end    
    
    assign tail_clk_en = enq_fire | flush_i;
    assign deq_rdy_o   = ~empty;
    
    always_comb begin : tail_update
        if(IS_LOG2) begin
           {tail_flag_n,tail_n} = {tail_flag_r,tail_r} + 1'b1; 
        end else begin
            if(tail_r == ENTRY_COUNT-1) begin
                tail_n = {ENTRY_TAG_WIDTH{1'b0}};
                tail_flag_n = ~tail_flag_r; 
            end else begin
                tail_n = tail_r + 1'b1;
                tail_flag_n = tail_flag_r; 
            end
        end
        if(flush_i) begin
            {tail_flag_n,tail_n} = {~head_flag_r,head_r};
        end
    end
    
    assign head_clk_en = deq_fire | flush_i;
    
    always_ff@(posedge clk) begin : head_dff
        if(rst) begin
            {head_flag_r,head_r} <= {(ENTRY_TAG_WIDTH+1){1'b0}};
        end else begin
            if(head_clk_en) begin
                {head_flag_r,head_r} <= {head_flag_n,head_n};
            end 
        end
    end

    always_ff@(posedge clk) begin : tail_dff
        if(rst) begin
            {tail_flag_r,tail_r} <= {1'b1,{(ENTRY_TAG_WIDTH){1'b0}}};
        end else begin
            if(tail_clk_en) begin
                {tail_flag_r,tail_r} <= {tail_flag_n,tail_n};
            end 
        end
    end

    always_ff@(posedge clk) begin : ram_dff
        if(rst) begin
            for(int i = 0 ; i < ENTRY_COUNT; i++) begin
                ram_r[i] <= i[ENTRY_TAG_WIDTH-1:0];
            end
        end else begin
            for(int i = 0 ; i < ENTRY_COUNT; i++) begin
                if(ram_clk_en[i]) begin
                    ram_r[i] <= ram_n[i];
                end 
            end
        end
    end

    
    
endmodule : freelist

`endif