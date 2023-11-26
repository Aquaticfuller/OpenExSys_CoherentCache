module oh2idx
#(
  parameter int unsigned N_INPUT = 2,
  localparam int unsigned N_INPUT_WIDTH = N_INPUT > 1 ? $clog2(N_INPUT) : 1
)
(
  input  [N_INPUT-1:0]        oh_i,
  output [N_INPUT_WIDTH-1:0]  idx_o
);

genvar i, j;

logic [N_INPUT_WIDTH-1:0][N_INPUT-1:0] mask;

generate
  for(i = 0; i < N_INPUT_WIDTH; i++) begin: gen_mask_i
    for(j = 0; j < N_INPUT; j++) begin: gen_mask_j
      assign mask[i][j] = (j/(2**i)) % 2;
    end
  end
endgenerate

generate
  for(i = 0; i < N_INPUT_WIDTH; i++) begin: gen_idx_o
    assign idx_o[i] = |(oh_i & mask[i]);
  end
endgenerate

endmodule
