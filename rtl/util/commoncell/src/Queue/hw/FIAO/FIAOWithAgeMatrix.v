// module FIAOWithAgeMatrix #(
//     parameter int unsigned Depth = 8,
//     parameter int unsigned EnqWidth = 2,
//     parameter int unsigned SelWidth = 2,
//     localparam int unsigned PtrWidth = $clog2(Depth)
// ) (
//     // Enqueue Port
//     input wire [EnqWidth-1:0] enq_fire_i,
//     input wire [EnqWidth-1:0] enq_eval_i,
//     output wire [Depth-1:0] enq_mask_o[EnqWidth],
//     output wire [PtrWidth-1:0] enq_ptr_o[EnqWidth],
//     // Select Port
//     input wire [Depth-1:0] sel_mask_i,
//     output wire [Depth-1:0] result_mask_o[SelWidth],
//     // Status
//     input wire [Depth-1:0] entry_vld_i,

//     input wire clk,
//     input wire rstn
// );

//   wire [Depth-1:0] enq_rdy_mask[EnqWidth];

//   generate
//     for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_rdy_mask
//       if (i == 0) begin : gen_initial_one
//         assign enq_rdy_mask[i] = ~entry_vld_i;
//       end else begin : gen_others
//         assign enq_rdy_mask[i] = enq_eval_i[i-1] ?
//           enq_rdy_mask[i-1] : (enq_rdy_mask[i-1] & ~enq_mask_o[i-1]);
//       end
//     end
//     for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_mask
//       assign enq_mask_o[i] = enq_rdy_mask[i] & ~(enq_rdy_mask[i] - 1'b1);
//       OH2UInt #(
//           .InputWidth(Depth)
//       ) u_OH2UInt (
//           .oh_i(enq_mask_o[i]),
//           .result_o(enq_ptr_o[i])
//       );

//     end
//   endgenerate

//   AgeMatrixSelector #(
//       .EntryCount(Depth),
//       .EnqWidth  (EnqWidth),
//       .SelWidth  (SelWidth)
//   ) u_AgeMatrixSelector (
//       .enq_fire_i(enq_fire_i),
//       .enq_mask_i(enq_mask_o),
//       .sel_mask_i(sel_mask_i),
//       .result_mask_o(result_mask_o),
//       .entry_vld_i(entry_vld_i),
//       .clk(clk),
//       .rstn(rstn)
//   );



// endmodule
