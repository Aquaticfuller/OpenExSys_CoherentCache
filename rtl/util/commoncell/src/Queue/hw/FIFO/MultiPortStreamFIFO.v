module MultiPortStreamFIFO #(
    parameter int unsigned Depth = 8,
    parameter int unsigned DataWidth = 32,
    parameter int unsigned EnqWidth = 2,
    parameter int unsigned DeqWidth = 2,
    parameter int unsigned TakenAll = 0
) (
    input wire [EnqWidth-1:0] enq_vld_i,
    input wire [EnqWidth-1:0][DataWidth-1:0] enq_payload_i,
    output wire [EnqWidth-1:0] enq_rdy_o,
    output wire [DeqWidth-1:0] deq_vld_o,
    output wire [DeqWidth-1:0][DataWidth-1:0] deq_payload_o,
    input wire [DeqWidth-1:0] deq_rdy_i,
    input wire flush_i,
    input wire clk,
    input wire rstn
);

  localparam int unsigned PtrWidth = $clog2(Depth);

  reg [Depth-1:0] payload_clk_en;
  reg [Depth-1:0] vld_dff_d, vld_dff_q;
  reg [Depth-1:0][DataWidth-1:0] payload_dff_d, payload_dff_q;

  wire [EnqWidth-1:0][PtrWidth-1:0] enq_ptr;
  wire [DeqWidth-1:0][PtrWidth-1:0] deq_ptr;

  wire [EnqWidth-1:0] enq_rdy;
  wire [EnqWidth-1:0] enq_fire;
  wire [DeqWidth-1:0] deq_fire;

  assign enq_fire = enq_vld_i & enq_rdy_o;
  assign deq_fire = deq_vld_o & deq_rdy_i;

  always @(*) begin : vld_dff_update_logic
    vld_dff_d = vld_dff_q;
    for (int i = 0; i < EnqWidth; i++) begin
      if (enq_fire[i]) begin
        vld_dff_d[enq_ptr[i]] = 1'b1;
      end
    end
    for (int i = 0; i < DeqWidth; i++) begin
      if (deq_fire[i]) begin
        vld_dff_d[deq_ptr[i]] = 1'b0;
      end
    end
    if (flush_i) begin
      vld_dff_d = {Depth{1'b0}};
    end
  end

  always @(*) begin : payload_update_logic
    for (int i = 0; i < Depth; i++) begin : payload_init
      payload_clk_en[i] = 1'b0;
      payload_dff_d[i]  = payload_dff_q[i];
    end
    for (int i = 0; i < EnqWidth; i++) begin : enq_update
      if (enq_fire[i] & ~flush_i) begin
        payload_clk_en[enq_ptr[i]] = 1'b1;
        payload_dff_d[enq_ptr[i]]  = enq_payload_i[i];
      end
    end
  end

  generate
    if (TakenAll) begin : gen_rdy_if_need_taken_all
      assign enq_rdy_o = {EnqWidth{&enq_rdy}};
    end else begin : gen_normal_rdy
      assign enq_rdy_o = enq_rdy;
    end
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_rdy_logic
      assign enq_rdy[i] = ~vld_dff_q[enq_ptr[i]];
    end
    for (genvar i = 0; i < DeqWidth; i++) begin : gen_deq_logic
      assign deq_vld_o[i] = vld_dff_q[deq_ptr[i]];
      assign deq_payload_o[i] = payload_dff_q[deq_ptr[i]];
    end
  endgenerate


  DFFR #(
      .Width(Depth)
  ) u_vld_dff (
      .CLK(clk),
      .RSTN(rstn),
      .DRST({Depth{1'b0}}),
      .D(vld_dff_d),
      .Q(vld_dff_q)
  );

  generate
    for (genvar i = 0; i < Depth; i++) begin : gen_payload_dff
      DFFE #(
          .Width(DataWidth)
      ) u_payload_dff (
          .CLK(clk),
          .EN (payload_clk_en[i]),
          .D  (payload_dff_d[i]),
          .Q  (payload_dff_q[i])
      );
    end
  endgenerate

  QueueManager #(
      .Depth(Depth),
      .EnqWidth(EnqWidth),
      .DeqWidth(DeqWidth),
      .FlagEnable(0),
      .EnqCollapse(1),
      .DeqCollapse(0),
      .InitFull(0)
  ) u_QueueManager (
      .enq_fire_i(enq_fire),
      .enq_eval_i(enq_vld_i),
      .enq_tag_o(enq_ptr),
      .deq_fire_i(deq_fire),
      .deq_eval_i(deq_vld_o),
      .deq_tag_o(deq_ptr),
      .flush_i(flush_i),
      .clk(clk),
      .rstn(rstn)
  );

endmodule
