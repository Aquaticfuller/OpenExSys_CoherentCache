
module StaticPrioritySelector_tb;

  // Parameters
  localparam int unsigned Depth = 8;
  localparam int unsigned EnqWidth = 2;
  localparam int unsigned SelWidth = 2;
  localparam int unsigned PtrWidth = $clog2(Depth);

  // Ports
  wire [EnqWidth-1:0][Depth-1:0] enq_mask_o;
  reg [Depth-1:0] sel_mask_i;
  wire [SelWidth-1:0][Depth-1:0] result_mask_o;
  reg [Depth-1:0] entry_vld_i;

  int iter = 100000;

  bit [EnqWidth-1:0][Depth-1:0] golden_enq_mask;
  bit [SelWidth-1:0][Depth-1:0] golden_result_mask;

  int cnt;

  initial begin
    repeat (iter) begin
      entry_vld_i = $urandom_range(0, ((1 << Depth) - 1));
      sel_mask_i  = $urandom_range(0, ((1 << Depth) - 1)) & entry_vld_i;
      #100;
      for (int i = 0; i < EnqWidth; i++) begin : init_golden_enq_mask
        golden_enq_mask[i] = 0;
      end
      cnt = 0;
      for (int i = 0; i < Depth; i++) begin : gen_golden_enq_mask
        if (~entry_vld_i[i]) begin
          golden_enq_mask[cnt][i] = 1'b1;
          cnt = cnt + 1;
          if (cnt == EnqWidth) begin
            break;
          end
        end
      end
      for (int i = 0; i < SelWidth; i++) begin : init_golden_result_mask
        golden_result_mask[i] = 0;
      end
      cnt = 0;
      for (int i = 0; i < Depth; i++) begin : gen_golden_result_mask
        if (sel_mask_i[i]) begin
          golden_result_mask[cnt][i] = 1'b1;
          cnt = cnt + 1;
          if (cnt == SelWidth) begin
            break;
          end
        end
      end
      CheckEnqEqual :
      for (int i = 0; i < EnqWidth; i++) begin
        assert (golden_enq_mask[i] == enq_mask_o[i])
        else begin
          $fatal("\n Masks are not equal, ours[%b] - golden[%b] \n", enq_mask_o[i],
                 golden_enq_mask[i]);
        end
      end
      for (int i = 0; i < SelWidth; i++) begin
        CheckSelEqual :
        assert (golden_result_mask[i] == result_mask_o[i])
        else begin
          $fatal("\n Masks are not equal, ours[%b] - golden[%b] \n", result_mask_o[i],
                 golden_result_mask[i]);
        end
      end
    end
    #100;
    $info("PASS\n");
    $finish;
  end


  StaticPrioritySelector #(
      .Depth(Depth),
      .EnqWidth(EnqWidth),
      .SelWidth(SelWidth)
  ) StaticPrioritySelector_dut (
      .enq_mask_o(enq_mask_o),
      .sel_mask_i(sel_mask_i),
      .result_mask_o(result_mask_o),
      .entry_vld_i(entry_vld_i)
  );


`ifdef DUMPON
  initial begin : GEN_WAVEFORM
    $fsdbDumpfile("StaticPrioritySelector_tb.fsdb");
    $fsdbDumpvars(0, StaticPrioritySelector_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif

endmodule
