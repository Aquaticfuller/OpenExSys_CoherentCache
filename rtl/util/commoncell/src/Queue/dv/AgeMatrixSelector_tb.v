// module AgeMatrixSelector_tb;

//   // Parameters
//   localparam int unsigned EntryCount = 4;
//   localparam int unsigned EnqWidth = 2;
//   localparam int unsigned SelWidth = 2;

//   // Ports
//   reg [EnqWidth-1:0] enq_fire_i;
//   reg [EntryCount-1:0] enq_mask_i[EnqWidth];
//   reg [EntryCount-1:0] sel_mask_i;
//   wire [EntryCount-1:0] result_mask_o[SelWidth];
//   reg [EntryCount-1:0] entry_vld_i;
//   reg clk = 0;
//   reg rstn = 0;

//   bit [EntryCount-1:0][EntryCount-1:0] golden_age_matrix_d, golden_age_matrix_q;
//   bit [EntryCount-1:0][EntryCount-1:0] golden_masked_age_matrix[SelWidth];
//   bit [EntryCount-1:0] golden_selected_mask[SelWidth];
//   bit [EntryCount-1:0] golden_sel_result[SelWidth];

//   always @(posedge clk) begin
//     if (~rstn) begin
//       golden_age_matrix_q <= 0;
//     end else begin
//       for (int row = 0; row < EntryCount; row++) begin
//         for (int col = 0; col < EntryCount; col++) begin
//           if (row != col) begin
//             golden_age_matrix_q[row][col] <= golden_age_matrix_d[row][col];
//           end
//         end
//       end
//     end
//   end
//   always @(*) begin
//     for (int row = 0; row < EntryCount; row++) begin
//       golden_age_matrix_q[row][row] <= entry_vld_i[row];
//     end
//   end
//   always @(*) begin
//     golden_age_matrix_d = golden_age_matrix_q;
//     for (int i = 0; i < EnqWidth; i++) begin
//       if (enq_fire_i[i]) begin
//         for (int row = 0; row < EntryCount; row++) begin
//           if (enq_mask_i[i][row]) begin
//             for (int col = 0; col < EntryCount; col++) begin
//               golden_age_matrix_d[row][col] = ~golden_age_matrix_d[col][col];
//             end
//           end
//         end
//       end
//     end
//   end

//   always @(*) begin
//     for (int i = 0; i < EntryCount; i++) begin
//       if (i == 0) begin
//         golden_selected_mask[i] = 0;
//       end else begin
//         golden_selected_mask[i] = golden_selected_mask[i-1] | golden_sel_result[i-1];
//       end
//     end
//   end

//   always @(*) begin
//     for (int i = 0; i < SelWidth; i++) begin
//       golden_masked_age_matrix[i] = golden_age_matrix_q;
//       for (int col = 0; col < EntryCount; col++) begin
//         if (golden_selected_mask[i][col] | ~sel_mask_i[col]) begin
//           for (int row = 0; row < EntryCount; row++) begin
//             golden_masked_age_matrix[i][row][col] = col != row;
//           end
//         end
//       end
//     end
//   end

//   always @(*) begin
//     for (int i = 0; i < SelWidth; i++) begin
//       for (int row = 0; row < EntryCount; row++) begin
//         golden_sel_result[i][row] = &golden_masked_age_matrix[i][row];
//       end
//     end
//   end

//   default disable iff (~rstn);

//   int iter = 10000;

//   int random_ptr;

//   CHECK_EQULATION :
//   assert property (@(negedge clk) golden_age_matrix_q == AgeMatrixSelector_dut.age_matrix_q)
//   else begin
//     $fatal("\n Error : Age matrix is not equal to golden one \n");
//   end

//   initial begin
//     #100 rstn = 1'b1;
//     entry_vld_i = 0;
//     enq_fire_i  = 0;
//     sel_mask_i  = 0;

//     repeat (iter) begin
//       @(posedge clk);
//       entry_vld_i = entry_vld_i & ~(entry_vld_i & $urandom_range(0, (1 << EntryCount) - 1));
//       for (int i = 0; i < EnqWidth; i++) begin
//         if (enq_fire_i[i]) begin
//           entry_vld_i = entry_vld_i | enq_mask_i[i];
//         end
//       end
//       sel_mask_i = $urandom_range(0, (1 << EntryCount) - 1) & entry_vld_i;

//       @(negedge clk);
//       for (int i = 0; i < EnqWidth; i++) begin
//         enq_fire_i[i] = 0;
//         enq_mask_i[i] = 0;
//         random_ptr = $urandom_range(0, EntryCount - 1);
//         if (~entry_vld_i[random_ptr]) begin
//           enq_fire_i[i] = 1;
//           enq_mask_i[i][random_ptr] = 1;
//         end
//         for(int j = 0 ; j < i; j++) begin
//           if(enq_fire_i[j] && (enq_mask_i[j] == enq_mask_i[i])) begin
//             enq_fire_i[i] = 0;
//           end
//         end
//       end
//       for (int i = 0; i < SelWidth; i++) begin
//         assert (result_mask_o[i] == golden_sel_result[i])
//         else begin
//           $fatal("\n Error : Selection is not equal, golden[%b] our[%b] \n", golden_sel_result[i],
//                  result_mask_o[i]);
//         end
//       end
//     end
//     $info("\n PASS after %d iter \n",iter);
//     $finish();
//   end


//   AgeMatrixSelector #(
//       .EntryCount(EntryCount),
//       .EnqWidth  (EnqWidth),
//       .SelWidth  (SelWidth)
//   ) AgeMatrixSelector_dut (
//       .enq_fire_i(enq_fire_i),
//       .enq_mask_i(enq_mask_i),
//       .sel_mask_i(sel_mask_i),
//       .result_mask_o(result_mask_o),
//       .entry_vld_i(entry_vld_i),
//       .clk(clk),
//       .rstn(rstn)
//   );

// `ifdef DUMPON
//   initial begin : GEN_WAVEFORM
//     $fsdbDumpfile("AgeMatrixSelector_tb.fsdb");
//     $fsdbDumpvars(0, AgeMatrixSelector_tb);
//     $fsdbDumpvars("+mda");
//     $fsdbDumpvars("+all");
//     $fsdbDumpon();
//   end
// `endif

//   always #20 clk = !clk;

// endmodule
