module PLRU_tb;

  // Parameters
  localparam ENTRY_COUNT = 4;

  // Ports
  reg [ENTRY_COUNT-1:0] access_mask_i;
  wire [ENTRY_COUNT-1:0] least_used_mask_o;
  reg clk = 0;
  reg rstn = 0;

  PLRU #(
      .ENTRY_COUNT(ENTRY_COUNT)
  ) PLRU_dut (
      .access_mask_i(access_mask_i),
      .least_used_mask_o(least_used_mask_o),
      .clk(clk),
      .rstn(rstn)
  );

  initial begin
    begin
      #10 rstn = 1'b1;
      repeat (10000) begin
        @(negedge clk);
        if (|access_mask_i) begin
          $info("\n Access Entry[%d], PLRU Change to [%d]\n", $countones(access_mask_i-1), $countones(
                least_used_mask_o - 1));
        end
        access_mask_i = 1 << $urandom_range(0, ENTRY_COUNT - 1);
        @(posedge clk);
      end
      $finish;
    end
  end

`ifdef DUMPON
  initial begin : GEN_WAVEFORM
    $fsdbDumpfile("PLRU_tb.fsdb");
    $fsdbDumpvars(0, PLRU_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif

  always #20 clk = !clk;

endmodule
