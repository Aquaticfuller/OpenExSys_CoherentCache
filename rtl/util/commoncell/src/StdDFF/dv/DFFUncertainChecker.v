module DFFUncertainChecker #(
    parameter int unsigned Width = 8
) (
    input wire CLK,
    input wire EN,
    input reg [Width-1:0] Q
);

`ifndef SYNTHESIS
  CHECK_UNCERTAIN :
  assert property (@(posedge CLK) EN |=> (|Q !== 1'bx))
  else begin
    $fatal("\n Error : detected a X value which should never happen!\n");
  end
`endif

endmodule
