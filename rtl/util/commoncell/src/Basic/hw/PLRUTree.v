module PLRUTree #(
    parameter TREE_LVL_COUNT = 3,
    localparam ENTRY_COUNT = (1 << TREE_LVL_COUNT),
    localparam NODE_COUNT = ENTRY_COUNT - 1
) (
    input [ENTRY_COUNT-1:0] access_mask_i,
    input [NODE_COUNT-1:0] plru_old_node_i,
    output [NODE_COUNT-1:0] plru_new_node_o,
    input node_en_i,
    output [ENTRY_COUNT-1:0] least_used_mask_o,
    input clk,
    input rstn
);

  wire node_toggle_en;
  wire node;

  wire left_child_node_en;
  wire right_child_node_en;

  wire access_left;
  wire access_right;

  assign node = plru_old_node_i[0];
  assign node_toggle_en = (~node & access_left) | (node & access_right);
  assign plru_new_node_o[0] = node_toggle_en ? ~node : node;

  assign access_left = |access_mask_i[ENTRY_COUNT/2-1:0];
  assign access_right = |access_mask_i[ENTRY_COUNT-1:ENTRY_COUNT/2];

  assign left_child_node_en = node_en_i & ~node;
  assign right_child_node_en = node_en_i & node;

  generate
    if (TREE_LVL_COUNT > 1) begin : gen_child_tree
      PLRUTree #(
          .TREE_LVL_COUNT(TREE_LVL_COUNT - 1)
      ) u_left_child_PLRUTree (
          .access_mask_i(access_mask_i[ENTRY_COUNT/2-1:0]),
          .plru_old_node_i(plru_old_node_i[(NODE_COUNT-1)/2:1]),
          .plru_new_node_o(plru_new_node_o[(NODE_COUNT-1)/2:1]),
          .node_en_i(left_child_node_en),
          .least_used_mask_o(least_used_mask_o[ENTRY_COUNT/2-1:0]),
          .clk(clk),
          .rstn(rstn)
      );
      PLRUTree #(
          .TREE_LVL_COUNT(TREE_LVL_COUNT - 1)
      ) u_right_child_PLRUTree (
          .access_mask_i(access_mask_i[ENTRY_COUNT-1:ENTRY_COUNT/2]),
          .plru_old_node_i(plru_old_node_i[NODE_COUNT-1:(NODE_COUNT+1)/2]),
          .plru_new_node_o(plru_new_node_o[NODE_COUNT-1:(NODE_COUNT+1)/2]),
          .node_en_i(right_child_node_en),
          .least_used_mask_o(least_used_mask_o[ENTRY_COUNT-1:ENTRY_COUNT/2]),
          .clk(clk),
          .rstn(rstn)
      );
    end else begin : gen_leaf
      assign least_used_mask_o[0] = left_child_node_en;
      assign least_used_mask_o[1] = right_child_node_en;
    end
  endgenerate

endmodule
