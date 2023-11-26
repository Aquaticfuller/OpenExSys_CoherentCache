module one_hot_rr_arb #(
  parameter N_INPUT = 2,
  localparam int unsigned N_INPUT_WIDTH = N_INPUT > 1 ? $clog2(N_INPUT) : 1,
  localparam int unsigned IS_LOG2 = (2 ** N_INPUT_WIDTH) == N_INPUT,

  parameter TIMEOUT_UPDATE_EN = 0,
  parameter TIMEOUT_UPDATE_CYCLE = 10
) (
  input   logic [N_INPUT-1:0] req_i,
  input   logic               update_i,
  output  logic [N_INPUT-1:0] grt_o,
  output  logic [N_INPUT_WIDTH-1:0] grt_idx_o,
  input   logic               rstn, clk
);

  logic [$clog2(TIMEOUT_UPDATE_CYCLE)-1:0] timeout_counter_q, timeout_counter_d;
  logic timeout_counter_add, timeout_counter_clr;
  logic timeout_counter_en;
  logic timeout_en;

  generate
    if(N_INPUT == 1) begin: gen_one_hot_rr_arb_one_input
      assign grt_o     = req_i;
      assign grt_idx_o = 0;
    end else begin: gen_one_hot_rr_arb_common_input

      logic req_vld;
      logic [N_INPUT*2-1:0] reversed_dereordered_selected_req_pre_shift, reversed_dereordered_selected_req_shift;
      logic [N_INPUT-1:0] reodered_req, reordered_selected_req;
      logic [N_INPUT-1:0] dereordered_selected_req;
      logic [N_INPUT-1:0] reversed_reordered_selected_req, reversed_dereordered_selected_req;
      logic [N_INPUT_WIDTH-1:0] round_ptr_q, round_ptr_d;
      logic [N_INPUT_WIDTH-1:0] round_ptr_q_comp;
      logic [N_INPUT_WIDTH-1:0] oh_to_idx;
      logic [N_INPUT_WIDTH-1:0] selected_req_idx;

      assign req_vld = update_i | timeout_en;

      always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
          round_ptr_q <= '0;
        end else begin
          if (req_vld) begin
            round_ptr_q <= round_ptr_d;
          end
        end
      end

      assign round_ptr_q_comp = N_INPUT - round_ptr_q;

    //7 6 5 4 3 2 1 0 // req_i
    //2 1 0 7 6 5 4 3 // reodered_req
    //7 6 5 4 3 2 1 0 // dereordered_selected_req

      left_circular_rotate
      #(
        .N_INPUT(N_INPUT )
      )
      left_circular_rotate_reodered_req_u (
        .ori_vector_i (req_i ),
        .req_left_rotate_num_i (round_ptr_q ),
        .roteted_vector_o  ( reodered_req)
      );

      one_hot_priority_encoder
      #(
        .SEL_WIDTH    (N_INPUT)
      )
      biased_one_hot_priority_encoder_u
      (
        .sel_i    (reodered_req           ),
        .sel_o    (reordered_selected_req )
      );

      left_circular_rotate
      #(
        .N_INPUT(N_INPUT )
      )
      left_circular_rotate_dereordered_selected_req_u (
        .ori_vector_i (reordered_selected_req ),
        .req_left_rotate_num_i (round_ptr_q_comp ),
        .roteted_vector_o  ( dereordered_selected_req)
      );

      oh2idx
      #(
        .N_INPUT(N_INPUT )
      )
      oh2idx_u (
        .oh_i   (dereordered_selected_req ),
        .idx_o  (oh_to_idx)
      );

      assign selected_req_idx = oh_to_idx[N_INPUT_WIDTH-1:0];

      assign round_ptr_d =  (selected_req_idx == '0)          ? N_INPUT-1 :
                            (selected_req_idx == (N_INPUT-1)) ? '0        :
                                                                (N_INPUT-1) - selected_req_idx;

      assign grt_o      = dereordered_selected_req;
      assign grt_idx_o  = selected_req_idx;




      // timeout update
      if(TIMEOUT_UPDATE_EN) begin
        assign timeout_counter_add = (|req_i) & ~req_vld;
        assign timeout_counter_clr = req_vld;
        assign timeout_counter_d   = timeout_counter_clr ? '0 : timeout_counter_q + 1;
        assign timeout_counter_en  = timeout_counter_add | (timeout_counter_clr & (timeout_counter_q != '0));
        always @(posedge clk or negedge rstn) begin
          if (~rstn) begin
            timeout_counter_q <= '0;
          end else begin
            if (timeout_counter_en) begin
              timeout_counter_q <= timeout_counter_d;
            end
          end
        end

        assign timeout_en = (timeout_counter_q == TIMEOUT_UPDATE_CYCLE);
      end else begin
        assign timeout_en = '0;
      end
    end
  endgenerate
endmodule
