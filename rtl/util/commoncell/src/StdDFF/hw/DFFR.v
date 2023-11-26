module DFFR #(
    parameter int unsigned Width = 8
) (
    input wire CLK,
    input wire RSTN,
    input wire [Width-1:0] DRST,
    input wire [Width-1:0] D,
    output reg [Width-1:0] Q
);

  always @(posedge CLK or negedge RSTN) begin : dff
    if (~RSTN) begin
      Q <= DRST;
    end else begin
      Q <= D;
    end
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
