module OH2UInt #(
    parameter  int unsigned InputWidth  = 8,
    localparam int unsigned OutputWidth = InputWidth > 1 ? $clog2(InputWidth) : 1
) (
    input  wire [ InputWidth-1:0] oh_i,
    output wire [OutputWidth-1:0] result_o
);

  localparam int unsigned CountWidth = $clog2(InputWidth + 1);

  wire [InputWidth-1:0] maskLow;
  wire [CountWidth-1:0] count;


  assign maskLow  = oh_i - 1'b1;
  assign result_o = count[OutputWidth-1:0];

  CountOne #(
      .InputWidth(InputWidth)
  ) CountOne_dut (
      .bits_i(maskLow),
      .cnt_o (count)
  );

endmodule
