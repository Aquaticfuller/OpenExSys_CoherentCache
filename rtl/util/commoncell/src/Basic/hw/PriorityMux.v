module PriorityMux #(
    parameter int unsigned InputWidth = 8,
    parameter int unsigned DataWidth  = 8
) (
    input wire [InputWidth-1:0] sel_i,
    input wire [InputWidth-1:0][DataWidth-1:0] data_i,
    output wire [DataWidth-1:0] data_o
);

  wire [InputWidth-1:0] sel_oh;

  assign sel_oh = sel_i & (~(sel_i - 1));

  MuxOH #(
      .InputWidth(InputWidth),
      .DataWidth (DataWidth)
  ) u_MuxOH (
      .sel_i (sel_oh),
      .data_i(data_i),
      .data_o(data_o)
  );


endmodule
