module left_circular_rotate #(
  parameter N_INPUT = 2,
  localparam int unsigned N_INPUT_WIDTH = N_INPUT > 1 ? $clog2(N_INPUT) : 1
) (
  input   logic [N_INPUT-1:0]       ori_vector_i,
  input   logic [N_INPUT_WIDTH-1:0] req_left_rotate_num_i,

  output  logic [N_INPUT-1:0]       roteted_vector_o
);

  logic [N_INPUT*2-1:0] ori_vector_mid;
  assign ori_vector_mid = {ori_vector_i, ori_vector_i} << req_left_rotate_num_i;
  assign roteted_vector_o = ori_vector_mid[N_INPUT*2-1-:N_INPUT];

endmodule
