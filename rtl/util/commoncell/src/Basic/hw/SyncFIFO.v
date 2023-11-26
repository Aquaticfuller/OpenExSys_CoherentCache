module SyncFIFO #(
    parameter int unsigned Depth = 8,
    parameter int unsigned WordWidth = 64
) (
    input wire push_i,
    input wire [WordWidth-1:0] push_payload_i,
    input wire pop_i,
    output wire [WordWidth-1:0] pop_payload_o,
    output wire full_o,
    output wire empty_o,
    input wire flush_i,
    input wire clk,
    input wire rstn
);

  localparam int unsigned PtrWidth = $clog2(Depth);

  wire [Depth-1:0] payload_ram_clk_en;
  wire [Depth-1:0][WordWidth-1:0] payload_ram_d, payload_ram_q;

  wire head_clk_en;
  reg head_flag_d, head_flag_q;
  reg [PtrWidth-1:0] head_ptr_d, head_ptr_q;

  wire tail_clk_en;
  reg tail_flag_d, tail_flag_q;
  reg [PtrWidth-1:0] tail_ptr_d, tail_ptr_q;

  wire ptr_equal;
  wire flag_equal;

  assign head_clk_en = pop_i | flush_i;
  assign tail_clk_en = push_i | flush_i;

  generate
    for (genvar i = 0; i < Depth; i++) begin : gen_payload_update_logic
      assign payload_ram_clk_en[i] = (push_i & ~flush_i) & (tail_ptr_q == i);
      assign payload_ram_d[i] = payload_ram_clk_en[i] ? push_payload_i : payload_ram_q[i];
    end
  endgenerate

  always @(*) begin : tail_update_logic
    {tail_flag_d, tail_ptr_d} = {tail_flag_q, tail_ptr_q};
    if (push_i) begin
      if (tail_ptr_q == Depth - 1) begin
        {tail_flag_d, tail_ptr_d} = {~tail_flag_q, {PtrWidth{1'b0}}};
      end else begin
        tail_ptr_d = tail_ptr_q + 1'b1;
      end
    end
    if (flush_i) begin
      {tail_flag_d, tail_ptr_d} = {PtrWidth + 1{1'b0}};
    end
  end

  always @(*) begin : head_update_logic
    {head_flag_d, head_ptr_d} = {head_flag_q, head_ptr_q};
    if (pop_i) begin
      if (head_ptr_q == Depth - 1) begin
        {head_flag_d, head_ptr_d} = {~head_flag_q, {PtrWidth{1'b0}}};
      end else begin
        head_ptr_d = head_ptr_q + 1'b1;
      end
    end
    if (flush_i) begin
      {head_flag_d, head_ptr_d} = {PtrWidth + 1{1'b0}};
    end
  end

  assign flag_equal = head_flag_q == tail_flag_q;
  assign ptr_equal = head_ptr_q == tail_ptr_q;

  assign full_o = (~flag_equal & ptr_equal & ~pop_i);
  assign empty_o = flag_equal & ptr_equal;
  assign pop_payload_o = payload_ram_q[head_ptr_q];

  DFFRE #(
      .Width(PtrWidth + 1)
  ) u_head_dff (
      .CLK(clk),
      .RSTN(rstn),
      .EN(head_clk_en),
      .DRST({PtrWidth + 1{1'b0}}),
      .D({head_flag_d, head_ptr_d}),
      .Q({head_flag_q, head_ptr_q})
  );

  DFFRE #(
      .Width(PtrWidth + 1)
  ) u_tail_dff (
      .CLK(clk),
      .RSTN(rstn),
      .EN(tail_clk_en),
      .DRST({PtrWidth + 1{1'b0}}),
      .D({tail_flag_d, tail_ptr_d}),
      .Q({tail_flag_q, tail_ptr_q})
  );

  generate
    for (genvar i = 0; i < Depth; i++) begin : gen_payload_dff
      DFFE #(
          .Width(WordWidth)
      ) u_payload_dff (
          .CLK(clk),
          .EN (payload_ram_clk_en[i]),
          .D  (payload_ram_d[i]),
          .Q  (payload_ram_q[i])
      );
    end
  endgenerate

`ifndef SYNTHESIS

  default disable iff (~rstn); CHECK_POP_WHEN_EMPTY :
  assert property (@(posedge clk) pop_i |-> ~empty_o)
  else begin
    $error("Pop when empty\n");
  end

  CHECK_PUSH_WHEN_FULL :
  assert property (@(posedge clk) push_i |-> ~full_o)
  else begin
    $error("Push when full\n");
  end

`endif


endmodule
