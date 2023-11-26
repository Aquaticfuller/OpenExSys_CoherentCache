module PLRU #(
    parameter ENTRY_COUNT = 4
) (
    input [ENTRY_COUNT-1:0] access_mask_i,
    output [ENTRY_COUNT-1:0] least_used_mask_o,
    input clk,
    input rstn
);

  localparam PLRUTreeLvl = $clog2(ENTRY_COUNT);
  localparam NodeCount = ENTRY_COUNT - 1;

  generate
    if (ENTRY_COUNT == 1) begin : gen_one_entry_case
      assign least_used_mask_o = 1'b1;
    end else begin : gen_normal_case

      wire plru_nodes_clk_en;
      wire [NodeCount-1:0] plru_nodes_d;
      reg [NodeCount-1:0] plru_nodes_q;

      assign plru_nodes_clk_en = |access_mask_i;

      DFFRE #(
          .Width(NodeCount)
      ) u_plru_nodes_DFFRE (
          .CLK(clk),
          .RSTN(rstn),
          .DRST({NodeCount{1'b0}}),
          .EN(plru_nodes_clk_en),
          .D(plru_nodes_d),
          .Q(plru_nodes_q)
      );
      PLRUTree #(
          .TREE_LVL_COUNT(PLRUTreeLvl)
      ) u_PLRUTree (
          .access_mask_i(access_mask_i),
          .plru_old_node_i(plru_nodes_q),
          .plru_new_node_o(plru_nodes_d),
          .node_en_i(1'b1),
          .least_used_mask_o(least_used_mask_o),
          .clk(clk),
          .rstn(rstn)
      );
    end
  endgenerate

endmodule
