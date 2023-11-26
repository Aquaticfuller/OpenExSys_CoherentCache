module CountOne_tb;

  // Parameters
  localparam int unsigned InputWidth = 8;
  localparam int unsigned CountWidth = $clog2(InputWidth + 1);

  // Ports
  reg  [InputWidth-1:0] bits_i;
  wire [CountWidth-1:0] cnt_o;

  CountOne #(
      .InputWidth(InputWidth)
  ) u_CountOne (
      .bits_i(bits_i),
      .cnt_o (cnt_o)
  );

  function automatic [CountWidth-1:0] GlodenModel;
    input bit [InputWidth-1:0] in;
    bit [CountWidth-1:0] sum;
    begin
      sum = 0;
      for (int i = 0; i < InputWidth; i++) begin
        sum = sum + in[i];
      end
      GlodenModel = sum;
    end
  endfunction

`ifdef DUMPON
  initial begin : GEN_WAVEFORM
    $fsdbDumpfile("CountOne_tb.fsdb");
    $fsdbDumpvars(0, CountOne_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif

  initial begin : RANDOM_TEST
    begin
      repeat (10000) begin : GEN_CASE
        bits_i = $urandom_range(0, InputWidth - 1);
        #100;
        NOT_EQUAL :
        assert (cnt_o == GlodenModel(bits_i))
        else begin
          $error("Input[%b], Output[%d], Gloden[%d]\n", bits_i, cnt_o, GlodenModel(bits_i));
          break;
        end
      end
      #100;
      $fatal("PASS\n");
      $finish;
    end
  end


endmodule
