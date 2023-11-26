`ifndef __AGE_ORDER_SELECTOR_SV__
`define __AGE_ORDER_SELECTOR_SV__
/* 
 *      Age Matrix
 * |    Dependency bit   |
 * |E|   | 0 | 1 | 2 | 3 |
 * |N| 0 | 1 | 1 | 1 | 1 |
 * |T| 1 | 0 | 1 | 1 | 1 |
 * |R| 2 | 0 | 0 | 1 | 1 |
 * |Y| 3 | 0 | 0 | 0 | 1 |
 *
 * age_matrix_r[i][i] : valid signal for entry(i)
 * age_matrix_r[i][j] : if entry(j) deponds on entry(i)
 * 
 * */

module age_order_selector #(
    parameter  int unsigned ENTRY_COUNT = 4,
    parameter  int unsigned ENQ_WIDTH   = 1,
    parameter  int unsigned DEQ_WIDTH   = 1,
    parameter  int unsigned SEL_WIDTH   = 1,
    localparam int unsigned ENTRY_TAG   = $clog2(ENTRY_COUNT)
) (
    // Enqueue
    input logic [ENQ_WIDTH-1:0]                enq_vld_i,
    input logic [ENQ_WIDTH-1:0][ENTRY_TAG-1:0] enq_tag_i,

    // Dequeue
    input logic [DEQ_WIDTH-1:0]                deq_vld_i,
    input logic [DEQ_WIDTH-1:0][ENTRY_TAG-1:0] deq_tag_i,

    // Status
    output logic [ENTRY_COUNT-1:0] vld_mask_o,

    // Select Oldest 
    input  logic [SEL_WIDTH-1:0][ENTRY_COUNT-1:0] sel_mask_i,
    output logic [SEL_WIDTH-1:0][ENTRY_COUNT-1:0] sel_oldest_mask_o,

    // Flush
    input logic flush_i,

    input clk,
    input rst
);

    logic [ENTRY_COUNT-1:0][ENTRY_COUNT-1:0] age_matrix_r, age_matrix_n;

    logic [ENTRY_COUNT-1:0] vld_mask;

    logic [SEL_WIDTH-1:0][ENTRY_COUNT-1:0][ENTRY_COUNT-1:0] sel_age_matrix;
    logic [SEL_WIDTH-1:0][ENTRY_COUNT-1:0] sel_oldest_mask;


    logic clk_en;
    assign clk_en = (|enq_vld_i) | (|deq_vld_i) | flush_i;


    always_comb begin : get_vld_mask
        for (int row = 0; row < ENTRY_COUNT; row++) begin
            vld_mask[row] = age_matrix_r[row][row];
        end
    end


    // Sel Oldest Logic
    always_comb begin : gen_sel_matrix
        for (int i = 0; i < SEL_WIDTH; i++) begin
            for (int row = 0; row < ENTRY_COUNT; row++) begin
                for (int col = 0; col < ENTRY_COUNT; col++) begin
                    if (row == col) begin
                        sel_age_matrix[i][row][col] = sel_mask_i[i][col];
                    end else begin
                        sel_age_matrix[i][row][col] = sel_mask_i[i][col] ? age_matrix_r[row][col] :
                            1'b1;
                    end
                end
            end
        end
    end

    always_comb begin : gen_sel_oldest_mask
        for (int i = 0; i < SEL_WIDTH; i++) begin
            for (int row = 0; row < ENTRY_COUNT; row++) begin
                sel_oldest_mask[i][row] = &sel_age_matrix[i][row];
            end
        end
    end

    // Update Logic
    always_comb begin : update_logic
        age_matrix_n = age_matrix_r;
        for (int i = 0; i < ENQ_WIDTH; i++) begin
            if (enq_vld_i[i]) begin
                for (int col = 0; col < ENTRY_COUNT; col++) begin
                    age_matrix_n[enq_tag_i[i]][col] = ~age_matrix_r[col][col];  // Set Dependency
                    for(int j = 0; j < i; j++) begin
                        if(enq_vld_i[j]) begin
                            age_matrix_n[enq_tag_i[i]][enq_tag_i[j]] = 1'b0;
                        end
                    end
                end
            end
        end
        for (int i = 0; i < DEQ_WIDTH; i++) begin
            if (deq_vld_i[i]) begin
                for (int row = 0; row < ENTRY_COUNT; row++) begin
                    age_matrix_n[row][deq_tag_i[i]] = deq_tag_i[i] !=
                        row[ENTRY_TAG-1:0];  // Clear Dependency
                end
            end
        end
        if (flush_i) begin
            for (int row = 0; row < ENTRY_COUNT; row++) begin
                for (int col = 0; col < ENTRY_COUNT; col++) begin
                    age_matrix_n[row][col] = 1'b0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin : age_matrix_dff
        if (rst) begin
            for (int row = 0; row < ENTRY_COUNT; row++) begin
                for (int col = 0; col < ENTRY_COUNT; col++) begin
                    age_matrix_r[row][col] <= 1'b0;
                end
            end
        end else begin
            if (clk_en) begin
                age_matrix_r <= age_matrix_n;
            end
        end
    end


    //  Output 
    assign vld_mask_o    = vld_mask;
    assign sel_oldest_mask_o = sel_oldest_mask;


endmodule : age_order_selector

`endif