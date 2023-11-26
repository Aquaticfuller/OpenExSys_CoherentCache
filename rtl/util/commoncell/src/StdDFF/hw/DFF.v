module DFF #(
    parameter int unsigned Width = 8
) (
    input wire CLK,
    input wire [Width-1:0] D,
    output reg [Width-1:0] Q
);

  always @(posedge CLK) begin : dff
    Q <= D;
  end

`ifndef SYNTHESIS

  DFFUncertainChecker #(
      .Width(Width)
  ) u_DFFUncertainChecker (
      .CLK(CLK),
      .EN (1'b1),
      .Q  (Q)
  );

`endif

endmodule
