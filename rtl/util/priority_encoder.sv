`ifndef __PRIORITY_ENCODER_SV__
`define __PRIORITY_ENCODER_SV__
module priority_encoder
#(
    parameter int unsigned SEL_WIDTH = 8,
    localparam int unsigned SEL_ID_WIDHT = SEL_WIDTH > 1 ? $clog2(SEL_WIDTH) : 1
)
(
    input logic[SEL_WIDTH-1:0] sel_i,
    output logic id_vld_o,
    output logic[SEL_ID_WIDHT-1:0] id_o
);
    
    if(SEL_WIDTH == 1) begin

        assign id_vld_o = sel_i;
        assign id_o     = 1'b0;

    end
    else begin

        logic [SEL_WIDTH-1:0] sel_mask;
        logic [SEL_ID_WIDHT+1-1:0] sel_result; 
        
        assign sel_mask = ((~sel_i + 1'b1) & sel_i) - 1'b1;
        
        one_counter #(
            .DATA_WIDTH(SEL_WIDTH)
        ) one_counter_u (
            .data_i(sel_mask),
            .cnt_o(sel_result)
        );
        
        assign id_o =  sel_result[SEL_ID_WIDHT-1:0];
        assign id_vld_o = |sel_i;

    end
    
    
    
endmodule : priority_encoder

`endif