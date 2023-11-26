module StreamFIFO #(
    parameter int unsigned Depth = 8,
    parameter int unsigned WordWidth = 64
) (
    input wire enq_vld_i,
    input wire [WordWidth-1:0] enq_payload_i,
    output wire enq_rdy_o,
    output wire deq_vld_o,
    output wire [WordWidth-1:0] deq_payload_o,
    input wire deq_rdy_i,
    input wire flush_i,
    input wire clk,
    input wire rstn
);

  wire push;
  wire [WordWidth-1:0] push_payload;
  wire pop;
  wire [WordWidth-1:0] pop_payload;
  wire full;
  wire empty;

  wire enq_fire;
  wire deq_fire;

  assign enq_rdy_o = ~full;
  assign enq_fire = enq_vld_i & enq_rdy_o;
  assign push = enq_fire;
  assign push_payload = enq_payload_i;

  assign pop = deq_fire;
  assign deq_vld_o = ~empty;
  assign deq_fire = deq_vld_o & deq_rdy_i;
  assign deq_payload_o = pop_payload;

  SyncFIFO #(
      .Depth(Depth),
      .WordWidth(WordWidth)
  ) u_SyncFIFO (
      .push_i(push),
      .push_payload_i(push_payload),
      .pop_i(pop),
      .pop_payload_o(pop_payload),
      .full_o(full),
      .empty_o(empty),
      .flush_i(flush_i),
      .clk(clk),
      .rstn(rstn)
  );


endmodule
