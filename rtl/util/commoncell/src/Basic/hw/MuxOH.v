module MuxOH #(
    parameter int unsigned InputWidth = 8,
    parameter int unsigned DataWidth  = 8
) (
    input wire [InputWidth-1:0] sel_i,
    input wire [InputWidth-1:0][DataWidth-1:0] data_i,
    output wire [DataWidth-1:0] data_o
);

  wire [DataWidth-1:0][InputWidth-1:0] dataT;

  generate
    for (genvar i = 0; i < DataWidth; i++) begin : gen_row
      for (genvar j = 0; j < InputWidth; j++) begin : gen_col
        assign dataT[i][j] = data_i[j][i];
      end
      assign data_o[i] = |(dataT[i] & sel_i);
    end
  endgenerate

endmodule
