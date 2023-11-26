module StaticPrioritySelector #(
    parameter int unsigned Depth = 8,
    parameter int unsigned EnqWidth = 2,
    parameter int unsigned SelWidth = 2
) (
    // Enqueue Port
    output wire [EnqWidth-1:0][Depth-1:0] enq_mask_o,
    // Select Port
    input wire [Depth-1:0] sel_mask_i,
    output wire [SelWidth-1:0][Depth-1:0] result_mask_o,
    // Status
    input wire [Depth-1:0] entry_vld_i
);


  wire [EnqWidth-1:0][Depth-1:0] enq_allocated_mask;
  wire [EnqWidth-1:0][Depth-1:0] masked_enq_rdy;

  wire [SelWidth-1:0][Depth-1:0] selected_mask;
  wire [SelWidth-1:0][Depth-1:0] masked_sel_mask;

  generate
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_allocated_mask
      if (i == 0) begin : gen_initial_one
        assign enq_allocated_mask[i] = {Depth{1'b0}};
      end else begin : gen_others
        assign enq_allocated_mask[i] = enq_allocated_mask[i-1] | enq_mask_o[i-1];
      end
      assign masked_enq_rdy[i] = ~enq_allocated_mask[i] & ~entry_vld_i;
    end
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_mask
      assign enq_mask_o[i] = masked_enq_rdy[i] & ~(masked_enq_rdy[i] - 1);
    end
  endgenerate


  generate
    for (genvar i = 0; i < SelWidth; i++) begin : gen_masked_sel_mask
      if (i == 0) begin : gen_initial_one
        assign selected_mask[i] = {Depth{1'b0}};
      end else begin : gen_others
        assign selected_mask[i] = selected_mask[i-1] | result_mask_o[i-1];
      end
      assign masked_sel_mask[i] = ~selected_mask[i] & sel_mask_i;
    end
    for (genvar i = 0; i < SelWidth; i++) begin : gen_sel_result
      assign result_mask_o[i] = masked_sel_mask[i] & ~(masked_sel_mask[i] - 1);
    end
  endgenerate


endmodule
