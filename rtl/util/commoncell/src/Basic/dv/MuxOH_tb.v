module MuxOH_tb;

  // Parameters
  localparam int unsigned InputWidth = 8;
  localparam int unsigned DataWidth = 8;

  // Ports
  reg [InputWidth-1:0] sel_i;
  reg [InputWidth-1:0][DataWidth-1:0] data_i;
  wire [DataWidth-1:0] data_o;

  MuxOH #(
      .InputWidth(InputWidth),
      .DataWidth (DataWidth)
  ) u_MuxOH (
      .sel_i (sel_i),
      .data_i(data_i),
      .data_o(data_o)
  );

  function automatic [DataWidth-1:0] GlodenModel;
    input bit [InputWidth-1:0] sel;
    input bit [InputWidth-1:0][DataWidth-1:0] data;
    bit [DataWidth-1:0] result;
    begin
      for (int i = 0; i < InputWidth; i++) begin
        if (sel[i]) begin
          result = data[i];
        end
      end
      GlodenModel = result;
    end
  endfunction

`ifdef DUMPON
  initial begin : GEN_WAVEFORM
    $fsdbDumpfile("MuxOH_tb.fsdb");
    $fsdbDumpvars(0, MuxOH_tb);
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon();
  end
`endif


  initial begin
    repeat (10000) begin : GEN_CASE
      sel_i = 1 << $urandom_range(0, InputWidth - 1);
      for (int i = 0; i < InputWidth; i++) begin
        data_i[i] = $urandom();
      end
      #100;
      NOT_EQUAL :
      assert (data_o == GlodenModel(sel_i, data_i))
      else begin
        $fatal("Input[%b], Output[%d], Gloden[%d]\n", sel_i, data_o, GlodenModel(sel_i, data_i));
        break;
      end
    end
    #100;
    $info("PASS\n");
    $finish;
  end


endmodule
