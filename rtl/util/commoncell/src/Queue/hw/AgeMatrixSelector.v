module AgeMatrixSelector #(
    parameter int unsigned EntryCount = 4,
    parameter int unsigned EnqWidth   = 2,
    parameter int unsigned SelWidth   = 2
) (
    input wire [EnqWidth-1:0] enq_fire_i,
    input wire [EnqWidth-1:0][EntryCount-1:0] enq_mask_i,
    input wire deq_fire_i,
    input wire [EntryCount-1:0] deq_mask_i,
    input wire [EntryCount-1:0] sel_mask_i,
    output wire [SelWidth-1:0][EntryCount-1:0] result_mask_o,
    input wire [EntryCount-1:0] entry_vld_i,
    input wire clk,
    input wire rstn
);

  wire [EntryCount-1:0] age_matrix_clk_en;
  wire [EntryCount-1:0] enq_age_matrix_en;
  wire [EntryCount-1:0] deq_age_matrix_en;
  wire [EnqWidth-1:0][EntryCount-1:0] enq_dependency_vec;
  wire [EntryCount-1:0][EnqWidth-1:0] enq_entry_sel_mask;
  wire [EntryCount-1:0][EntryCount-1:0] enq_age_matrix;
  wire [EntryCount-1:0][EntryCount-1:0] deq_age_matrix;
  reg [EntryCount-1:0][EntryCount-1:0] age_matrix_d, age_matrix_q;

  wire [SelWidth-1:0][EntryCount-1:0] selected_vec;
  wire [SelWidth-1:0][EntryCount-1:0][EntryCount-1:0] masked_age_matrix;

  // In age order select
  generate
    for (genvar i = 0; i < SelWidth; i++) begin : gen_selected_vec
      if (i == 0) begin : gen_initial_one
        assign selected_vec[i] = {EntryCount{1'b0}};
      end else begin : gen_others
        assign selected_vec[i] = selected_vec[i-1] | result_mask_o[i-1];
      end
    end
    for (genvar i = 0; i < SelWidth; i++) begin : gen_sel_matrix
      for (genvar col = 0; col < EntryCount; col++) begin : gen_col
        for (genvar row = 0; row < EntryCount; row++) begin : gen_row
          if (col == row) begin : gen_masked_vld
            assign masked_age_matrix[i][row][col] = sel_mask_i[col] & ~selected_vec[i][col];
          end else begin : gen_masked_dependency
            assign masked_age_matrix[i][row][col] = (sel_mask_i[col] & ~selected_vec[i][col]) ?
                age_matrix_q[row][col] : 1'b1;
          end
        end
      end
    end
    for (genvar i = 0; i < SelWidth; i++) begin : gen_multi_result
      for (genvar row = 0; row < EntryCount; row++) begin : gen_one
        assign result_mask_o[i][row] = &masked_age_matrix[i][row];
      end
    end
  endgenerate


  // Enq -> Set dependency bits
  generate
    for (genvar i = 0; i < EntryCount; i++) begin : gen_enq_entry_en
      assign enq_age_matrix_en[i] = |enq_entry_sel_mask[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_dependency_vec
      if (i == 0) begin : gen_init_vec
        assign enq_dependency_vec[i] = deq_fire_i ? (~entry_vld_i | deq_mask_i) : ~entry_vld_i;
      end else begin : gen_vec_with_inter_check
        assign enq_dependency_vec[i] = enq_fire_i[i-1] ?
          (enq_dependency_vec[i-1] & ~enq_mask_i[i-1]) : enq_dependency_vec[i-1];
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < EntryCount; i++) begin : gen_enq_entry_sel_mask
      for (genvar j = 0; j < EnqWidth; j++) begin : gen_sel
        assign enq_entry_sel_mask[i][j] = enq_fire_i[j] & enq_mask_i[j][i];
      end
    end
  endgenerate

  // Deq -> Clear dependency bits
  generate
    for (genvar i = 0; i < EntryCount; i++) begin : gen_deq_entry_clk_en
      assign deq_age_matrix[i] = age_matrix_q[i] | deq_mask_i;
    end
  endgenerate

  generate
    for (genvar i = 0; i < EntryCount; i++) begin : gen_deq_entry_en
      assign deq_age_matrix_en[i] = deq_fire_i & entry_vld_i[i];
    end
  endgenerate

  assign age_matrix_clk_en = enq_age_matrix_en | deq_age_matrix_en;

  // Age matrix update

  always @(*) begin : age_matrix_vld_dff
    for (int i = 0; i < EntryCount; i++) begin
      age_matrix_q[i][i] = entry_vld_i[i];
    end
  end

  generate
    for (genvar i = 0; i < EntryCount; i++) begin : gen_age_matrix_update_logic
      MuxOH #(
          .InputWidth(2),
          .DataWidth (EntryCount)
      ) u_age_matrix_update_MuxOH (
          .sel_i ({enq_age_matrix_en[i], deq_age_matrix_en[i]}),
          .data_i({enq_age_matrix[i], deq_age_matrix[i]}),
          .data_o(age_matrix_d[i])
      );
    end
  endgenerate


  generate
    for (genvar i = 0; i < EntryCount; i++) begin : gen_entry_update_dependency_vec
      MuxOH #(
          .InputWidth(EnqWidth),
          .DataWidth (EntryCount)
      ) u_depend_vec_MuxOH (
          .sel_i (enq_entry_sel_mask[i]),
          .data_i(enq_dependency_vec),
          .data_o(enq_age_matrix[i])
      );
    end
  endgenerate

  always @(posedge clk or negedge rstn) begin : age_matrix_dependency_dff
    if (~rstn) begin
      for (int row = 0; row < EntryCount; row++) begin
        for (int col = 0; col < EntryCount; col++) begin
          if (row != col) begin
            age_matrix_q[row][col] <= 1'b0;
          end
        end
      end
    end else begin
      for (int row = 0; row < EntryCount; row++) begin
        if (age_matrix_clk_en[row]) begin
          for (int col = 0; col < EntryCount; col++) begin
            if (row != col) begin
              age_matrix_q[row][col] <= age_matrix_d[row][col];
            end
          end
        end
      end
    end
  end

`ifndef SYNTHESIS
  default disable iff (~rstn);
  generate
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_checker
      ENQ_VLD_ENTRY :
      assert property (@(posedge clk) enq_fire_i[i] |-> ((enq_mask_i[i] & entry_vld_i) == 0))
      else begin
        $fatal("\n Error : Enqueueing a valid entry! enq_mask[%b]\n", enq_mask_i[i]);
      end
    end
    for (genvar i = 0; i < SelWidth; i++) begin : gen_sel_checker
      SEL_INVLD_ENTRY :
      assert property (@(negedge clk) |sel_mask_i |-> ((result_mask_o[i] & ~entry_vld_i) == 0))
      else begin
        $fatal("\n Error : Selecting a invalid entry! sel_mask[%b]\n",
               (result_mask_o[i] & ~entry_vld_i));
      end

      RESULT_MASK_IS_ONEHOT :
      assert property (@(negedge clk) |sel_mask_i |-> $onehot0(result_mask_o[i]))
      else begin
        $fatal("\n Error : Got multi-choice which should never happend! result_mask[%b]\n",
               result_mask_o[i]);
      end
    end
  endgenerate
`endif


endmodule


