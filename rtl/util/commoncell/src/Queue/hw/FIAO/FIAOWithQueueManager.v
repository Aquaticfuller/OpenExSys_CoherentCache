module FIAOWithQueueManager #(
    parameter int unsigned Depth = 8,
    parameter int unsigned EnqWidth = 2,
    parameter int unsigned DeqWidth = 2,
    parameter int unsigned SelWidth = 2,
    localparam int unsigned PtrWidth = $clog2(Depth)
) (
    // Enqueue Port
    input wire [EnqWidth-1:0] enq_fire_i,
    input wire [EnqWidth-1:0] enq_eval_i,
    output wire [EnqWidth-1:0][Depth-1:0] enq_mask_o,
    output wire [EnqWidth-1:0][PtrWidth-1:0] enq_ptr_o,
    // Select Port
    input wire [Depth-1:0] sel_mask_i,
    output wire [SelWidth-1:0][Depth-1:0] result_mask_o,
    // Status
    input wire [Depth-1:0] entry_vld_i,

    input wire clk,
    input wire rstn
);

  localparam int unsigned TagWidth = PtrWidth + 1;

  wire [EnqWidth-1:0][PtrWidth-1:0] enq_ptr;
  wire [EnqWidth-1:0] enq_flag;
  wire [EnqWidth-1:0][TagWidth-1:0] enq_tag;
  wire [DeqWidth-1:0] enq_eval;
  wire [DeqWidth-1:0] enq_fire;

  wire [DeqWidth-1:0][PtrWidth-1:0] deq_ptr;
  wire [DeqWidth-1:0] deq_flag;
  wire [DeqWidth-1:0][TagWidth-1:0] deq_tag;
  wire [DeqWidth-1:0] deq_eval;
  wire [DeqWidth-1:0] deq_fire;

  wire first_enq_flag;
  wire [PtrWidth-1:0] first_enq_ptr;
  wire first_deq_flag;
  wire [PtrWidth-1:0] first_deq_ptr;
  wire flag_equal;
  wire [Depth-1:0] head_inv_mask;
  wire [Depth-1:0] tail_inv_mask;
  wire [Depth-1:0] head_side_sel_mask[SelWidth-1:0];
  wire [Depth-1:0] tail_side_sel_mask[SelWidth-1:0];
  wire [Depth-1:0] head_side_sel_result[SelWidth-1:0];
  wire [Depth-1:0] tail_side_sel_result[SelWidth-1:0];
  wire [Depth-1:0] selected_mask[SelWidth-1:0];

  // Enqueue Logic
  assign enq_eval  = enq_eval_i;
  assign enq_fire  = enq_fire_i;
  assign enq_ptr_o = enq_ptr;
  generate
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_logic
      assign enq_ptr[i] = enq_tag[i][PtrWidth-1:0];
      assign enq_flag[i] = enq_tag[i][TagWidth-1];
      assign enq_mask_o[i] = {{Depth - 1{1'b0}}, 1'b1} << enq_ptr[i];
    end
  endgenerate


  // Select Logic
  assign first_enq_flag = enq_flag[0];
  assign first_enq_ptr = enq_ptr[0];
  assign first_deq_flag = deq_flag[0];
  assign first_deq_ptr = deq_ptr[0];
  assign flag_equal = ~(first_enq_flag ^ first_deq_flag);

  assign head_inv_mask = (({{PtrWidth - 1{1'b0}}, {1'b1}} << first_deq_ptr) - 1'b1);
  assign tail_inv_mask = ~(({{PtrWidth - 1{1'b0}}, {1'b1}} << first_enq_ptr) - 1'b1);

  generate
    for (genvar i = 0; i < SelWidth; i++) begin : gen_selected_mask
      if (i == 0) begin : gen_initial_one
        assign selected_mask[i] = {Depth{1'b0}};
      end else begin : gen_others
        assign selected_mask[i] = selected_mask[i-1] | result_mask_o[i-1];
      end
    end
    for (genvar i = 0; i < SelWidth; i++) begin : gen_side_sel_mask
      assign head_side_sel_mask[i] = sel_mask_i & ~selected_mask[i] & ~head_inv_mask;
      assign tail_side_sel_mask[i] = sel_mask_i & ~selected_mask[i] & ~tail_inv_mask;
    end
    for (genvar i = 0; i < SelWidth; i++) begin : gen_priority_select_result
      assign head_side_sel_result[i] = head_side_sel_mask[i] & ~(head_side_sel_mask[i] - 1'b1);
      assign tail_side_sel_result[i] = tail_side_sel_mask[i] & ~(tail_side_sel_mask[i] - 1'b1);
      assign result_mask_o[i]        = flag_equal ? head_side_sel_result[i] :
        (|head_side_sel_result[i] ? head_side_sel_result[i] : tail_side_sel_result[i]);

    end
  endgenerate

  // Dequeue Logic
  generate
    for (genvar i = 0; i < DeqWidth; i++) begin : gen_deq_logic
      assign deq_ptr[i]  = deq_tag[i][PtrWidth-1:0];
      assign deq_flag[i] = deq_tag[i][TagWidth-1];
      assign deq_eval[i] = 1'b1;
      assign deq_fire[i] = ~entry_vld_i[deq_tag[i]];
    end
  endgenerate

  QueueManager #(
      .Depth(Depth),
      .EnqWidth(EnqWidth),
      .DeqWidth(DeqWidth),
      .FlagEnable(1),
      .EnqCollapse(1),
      .DeqCollapse(0),
      .InitFull(0)
  ) u_QueueManager (
      .enq_fire_i(enq_fire),
      .enq_eval_i(enq_eval),
      .enq_tag_o(enq_tag),
      .deq_fire_i(deq_fire),
      .deq_eval_i(deq_eval),
      .deq_tag_o(deq_tag),
      .flush_i(1'b0),
      .clk(clk),
      .rstn(rstn)
  );



endmodule
