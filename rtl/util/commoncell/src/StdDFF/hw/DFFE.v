module DFFE #(
    parameter int unsigned Width = 8
) (
    input wire CLK,
    input wire EN,
    input wire [Width-1:0] D,
    output reg [Width-1:0] Q
);

  always @(posedge CLK) begin : dff
    if (EN) begin
      Q <= D;
    end
  end

`ifndef SYNTHESIS

  DFFUncertainChecker #(
      .Width(Width)
  ) u_DFFUncertainChecker (
      .CLK(CLK),
      .EN (EN),
      .Q  (Q)
  );

`endif

endmodule
