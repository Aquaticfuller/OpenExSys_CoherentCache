module MultiPortStreamFIFO_tb;

  // Parameters
  localparam int unsigned Depth = 8;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned EnqWidth = 2;
  localparam int unsigned DeqWidth = 2;
  localparam int unsigned TakenAll = 0;

  // Ports
  reg [EnqWidth-1:0] enq_vld_i;
  reg [EnqWidth-1:0][DataWidth-1:0] enq_payload_i;
  wire [EnqWidth-1:0] enq_rdy_o;
  wire [DeqWidth-1:0] deq_vld_o;
  wire [DeqWidth-1:0][DataWidth-1:0] deq_payload_o;
  reg [DeqWidth-1:0] deq_rdy_i;
  reg flush_i = 0;
  reg clk = 0;
  reg rstn = 0;

  bit [DataWidth-1:0] golden_fifo[$];
  bit [DataWidth-1:0] golden_fifo_front;
  int usage = 0;

  int iter = 1000000;

  always @(posedge clk) begin
    for (int i = 0; i < DeqWidth; i++) begin : test_deq
      if (deq_vld_o[i] & deq_rdy_i[i]) begin
        usage = usage - 1;
        golden_fifo_front = golden_fifo.pop_front();
        assert (deq_payload_o[i] == golden_fifo_front)
        else begin
          $fatal("\n Error: Fail when check equalation, ours[%x] -- gloden[%x]", deq_payload_o[i],
                 golden_fifo_front);
        end
      end
    end
    for (int i = 0; i < EnqWidth; i++) begin : enq_test
      if (enq_vld_i[i] & enq_rdy_o[i]) begin
        usage = usage + 1;
        golden_fifo.push_back(enq_payload_i[i]);
      end
    end
  end

  initial begin
    #10 rstn = 1'b1;
    repeat (iter) begin : random_test
      @(negedge clk);
      deq_rdy_i = {DeqWidth{1'b0}};
      enq_vld_i = {EnqWidth{1'b0}};
      for (int i = 0; i < DeqWidth; i++) begin : gen_deq_rdy
        if ($urandom_range(0, 1)) begin
          deq_rdy_i[i] = 1'b1;
        end else begin
          break;
        end
      end
      for (int i = 0; i < EnqWidth; i++) begin : gen_enq_vld
        if ($urandom_range(0, 1)) begin
          enq_vld_i[i] = 1'b1;
          enq_payload_i[i] = $urandom();
        end else begin
          break;
        end
      end
      CHECK_USAGE :
      assert (usage == MultiPortStreamFIFO_dut.u_QueueManager.usage)
      else begin
        $fatal("\n Error : Usage is not equal, which should never happen! ours[%d] gloden[%d] \n",
               MultiPortStreamFIFO_dut.u_QueueManager.usage, usage);
      end
    end
    $info("\n PASS after %d iter \n", iter);
    $finish;
  end


  MultiPortStreamFIFO #(
      .Depth(Depth),
      .DataWidth(DataWidth),
      .EnqWidth(EnqWidth),
      .DeqWidth(DeqWidth),
      .TakenAll(TakenAll)
  ) MultiPortStreamFIFO_dut (
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
    $fsdbDumpfile("MultiPortStreamFIFO_tb.fsdb");
    $fsdbDumpvars(0, MultiPortStreamFIFO_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif

  always #20 clk = !clk;


endmodule
