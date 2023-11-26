module StreamFIFO_tb;

  // Parameters
  localparam int unsigned Depth = 8;
  localparam int unsigned WordWidth = 64;

  // Ports
  reg enq_vld_i = 0;
  reg [WordWidth-1:0] enq_payload_i;
  wire enq_rdy_o;
  wire deq_vld_o;
  wire [WordWidth-1:0] deq_payload_o;
  reg deq_rdy_i = 0;
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
        enq_vld_i = 1'b0;
        deq_rdy_i = 1'b0;
        if ($urandom_range(0, 1) && deq_vld_o) begin : test_deq
          deq_rdy_i = 1'b1;
          golden_fifo_front = golden_fifo.pop_front();
          CHECK_EQUALATION :
          assert (deq_payload_o == golden_fifo_front)
          else begin
            $fatal("\n Error: Fail when check equalation, ours[%x] -- gloden[%x]", deq_payload_o,
                   golden_fifo_front);
          end
          ;
        end
        if ($urandom_range(0, 1) && enq_rdy_o) begin : test_push
          random_payload = $urandom();
          enq_vld_i = 1'b1;
          enq_payload_i = random_payload;
          golden_fifo.push_back(random_payload);
        end
      end
      $info("\n PASS after %d iter \n", iter);
      $finish;
    end
  end


  StreamFIFO #(
      .Depth(Depth),
      .WordWidth(WordWidth)
  ) StreamFIFO_dut (
      .enq_vld_i(enq_vld_i),
      .enq_payload_i(enq_payload_i),
      .enq_rdy_o(enq_rdy_o),
      .deq_vld_o(deq_vld_o),
      .deq_payload_o(deq_payload_o),
      .deq_rdy_i(deq_rdy_i),
      .flush_i(flush_i),
      .clk(clk),
      .rstn(rstn)
  );

`ifdef DUMPON
  initial begin : GEN_WAVEFORM
    $fsdbDumpfile("StreamFIFO_tb.fsdb");
    $fsdbDumpvars(0, StreamFIFO_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif

  always #20 clk = !clk;

endmodule
