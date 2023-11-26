module rrv64_cell_clkgate (
    input wire clk_i,
    input wire clk_enable_i,
    input wire clk_senable_i,
    output wire clk_gated_o
);

// CKGATE
// CKGATE_inst
//     (
//         .cko (clk_gated_o),
//         .cki (clk_i      ),
//         .e   (clk_enable_i),
//         .te  (clk_senable_i),   
//     );

    wire clk_en;
    reg clk_en_reg;

    assign clk_en = clk_enable_i | clk_senable_i;

    always @ (clk_i or clk_en) begin
        if(clk_i == 1'b0) begin
            clk_en_reg <= clk_en;
        end
    end

    assign clk_gated_o = clk_i & clk_en_reg;

endmodule