module SyncFIFO_tb;

  // Parameters
  localparam int unsigned Depth = 8;
  localparam int unsigned WordWidth = 32;

  // Ports
  reg push_i = 0;
  reg [WordWidth-1:0] push_payload_i;
  reg pop_i = 0;
  wire [WordWidth-1:0] pop_payload_o;
  wire full_o;
  wire empty_o;
  reg flush_i = 0;
  reg clk = 0;
  reg rstn = 0;

  bit [WordWidth-1:0] golden_fifo[$];
  bit [WordWidth-1:0] random_payload;
  bit [WordWidth-1:0] golden_fifo_front;

  int iter = 1000000;

  initial begin
    begin
      #10 rstn = 1'b1;
      repeat (iter) begin : random_test
        @(negedge clk);
        pop_i  = 1'b0;
        push_i = 1'b0;
        if ($urandom_range(0, 1) && ~empty_o) begin : test_pop
          pop_i = 1'b1;
          golden_fifo_front = golden_fifo.pop_front();
          CHECK_EQUALATION :
          assert (pop_payload_o == golden_fifo_front)
          else begin
            $fatal("\n Error: Fail when check equalation, ours[%x] -- gloden[%x]", pop_payload_o,
                   golden_fifo_front);
          end
          ;
        end
        if ($urandom_range(0, 1) && ~full_o) begin : test_push
          random_payload = $urandom();
          push_i = 1'b1;
          push_payload_i = random_payload;
          golden_fifo.push_back(random_payload);
        end
      end
      $info("\n PASS after %d iter \n", iter);
      $finish;
    end
  end

  SyncFIFO #(
      .Depth(Depth),
      .WordWidth(WordWidth)
  ) SyncFIFO_dut (
      .push_i(push_i),
      .push_payload_i(push_payload_i),
      .pop_i(pop_i),
      .pop_payload_o(pop_payload_o),
      .full_o(full_o),
      .empty_o(empty_o),
      .flush_i(flush_i),
      .clk(clk),
      .rstn(rstn)
  );

`ifdef DUMPON
  initial begin : GEN_WAVEFORM
    $fsdbDumpfile("SyncFIFO_tb.fsdb");
    $fsdbDumpvars(0, SyncFIFO_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif



  always #20 clk = !clk;

endmodule
