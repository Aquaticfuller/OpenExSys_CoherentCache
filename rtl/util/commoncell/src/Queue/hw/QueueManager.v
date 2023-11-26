module QueueManager #(
    parameter int unsigned Depth = 8,
    parameter int unsigned EnqWidth = 2,
    parameter int unsigned DeqWidth = 2,
    parameter bit FlagEnable = 0,
    parameter bit EnqCollapse = 0,
    parameter bit DeqCollapse = 0,
    parameter bit InitFull = 0,
    localparam int unsigned PtrWidth = $clog2(Depth),
    localparam int unsigned CntWidth = $clog2(Depth + 1),
    localparam int unsigned TagWidth = PtrWidth + FlagEnable
) (
    input wire [EnqWidth-1:0] enq_fire_i,
    input wire [EnqWidth-1:0] enq_eval_i,
    output wire [EnqWidth-1:0][TagWidth-1:0] enq_tag_o,
    input wire [DeqWidth-1:0] deq_fire_i,
    input wire [DeqWidth-1:0] deq_eval_i,
    output wire [DeqWidth-1:0][TagWidth-1:0] deq_tag_o,
    input wire flush_i,
    input wire clk,
    input wire rstn
);

  localparam int unsigned EnqCountWidth = $clog2(EnqWidth + 1);
  localparam int unsigned DeqCountWidth = $clog2(DeqWidth + 1);

  function automatic [TagWidth-1:0] tagPlusOne;
    input [TagWidth-1:0] originalTag;
    begin
      if (FlagEnable) begin
        if (originalTag[PtrWidth-1:0] == Depth - 1) begin
          tagPlusOne = {~originalTag[TagWidth-1], {PtrWidth{1'b0}}};
        end else begin
          tagPlusOne = originalTag + 1'b1;
        end
      end else begin
        if (originalTag[PtrWidth-1:0] == Depth - 1) begin
          tagPlusOne = {PtrWidth{1'b0}};
        end else begin
          tagPlusOne = originalTag + 1'b1;
        end
      end
    end
  endfunction

  function automatic [TagWidth-1:0] tagPlus;
    input [TagWidth-1:0] originalTag;
    input [PtrWidth-1:0] delta;
    reg [PtrWidth:0] sum;
    reg [PtrWidth:0] reverse_sum;
    begin
      if (2 ** $clog2(Depth) == Depth) begin
        tagPlus = originalTag + delta;
      end else begin
        sum = $unsigned({1'b0, originalTag[PtrWidth-1:0]}) + $unsigned({{1'b0}, delta});
        reverse_sum = $signed(sum) - $unsigned(Depth);
        if ($signed(reverse_sum) >= 0) begin
          if (FlagEnable) begin
            tagPlus = {~originalTag[TagWidth-1], reverse_sum[PtrWidth-1:0]};
          end else begin
            tagPlus = reverse_sum[PtrWidth-1:0];
          end
        end else begin
          if (FlagEnable) begin
            tagPlus = {originalTag[TagWidth-1], sum[PtrWidth-1:0]};
          end else begin
            tagPlus = sum[PtrWidth-1:0];
          end
        end
      end
    end
  endfunction

  wire enq_tag_clk_en;
  wire [EnqWidth-1:0] enq_rdy_mask, enq_collapse_rdy_mask;
  wire [EnqCountWidth-1:0] enq_cnt;
  wire [PtrWidth-1:0] enq_delta;
  reg [TagWidth-1:0] enq_tag_d, enq_tag_q;

  wire deq_tag_clk_en;
  wire [DeqCountWidth-1:0] deq_cnt;
  wire [PtrWidth-1:0] deq_delta;
  reg [TagWidth-1:0] deq_tag_d, deq_tag_q;

  assign enq_tag_clk_en = (|enq_fire_i);
  assign deq_tag_clk_en = (|deq_fire_i);

  assign enq_delta = {{PtrWidth - EnqCountWidth{1'b0}}, enq_cnt};
  assign deq_delta = {{PtrWidth - DeqCountWidth{1'b0}}, deq_cnt};


  generate
    for (genvar i = 0; i < EnqWidth; i++) begin : gen_enq_ptr
      if (i == 0) begin : gen_first_enq_ptr
        assign enq_tag_o[i] = enq_tag_q;
      end else begin : gen_next_enq_ptr
        assign enq_tag_o[i] = (EnqCollapse & ~enq_eval_i[i-1]) ? enq_tag_o[i-1] : tagPlusOne(
            enq_tag_o[i-1]
        );
      end
    end
    for (genvar i = 0; i < DeqWidth; i++) begin : gen_deq_ptr
      if (i == 0) begin : gen_first_deq_ptr
        assign deq_tag_o[i] = deq_tag_q;
      end else begin : gen_next_deq_ptr
        assign deq_tag_o[i] = (DeqCollapse & ~deq_eval_i[i-1]) ? deq_tag_o[i-1] : tagPlusOne(
            deq_tag_o[i-1]
        );
      end
    end
  endgenerate

  always @(*) begin : enq_tag_update_logic
    enq_tag_d = enq_tag_q;
    if (enq_tag_clk_en) begin
      enq_tag_d = tagPlus(enq_tag_q, enq_delta);
    end
    if (flush_i) begin
      if (InitFull & FlagEnable) begin
        enq_tag_d = {~deq_tag_q[TagWidth-1], deq_tag_q[PtrWidth-1:0]};
      end else begin
        enq_tag_d = deq_tag_q;
      end
    end
  end

  always @(*) begin : deq_tag_update_logic
    deq_tag_d = deq_tag_q;
    if (deq_tag_clk_en) begin
      deq_tag_d = tagPlus(deq_tag_q, deq_delta);
    end
    if (flush_i) begin
      deq_tag_d = deq_tag_q;
    end
  end

  CountOne #(
      .InputWidth(EnqWidth)
  ) u_enqCounter (
      .bits_i(enq_fire_i),
      .cnt_o (enq_cnt)
  );
  CountOne #(
      .InputWidth(DeqWidth)
  ) u_deqCounter (
      .bits_i(deq_fire_i),
      .cnt_o (deq_cnt)
  );

  DFFRE #(
      .Width(TagWidth)
  ) u_enq_tag_dff (
      .CLK(clk),
      .RSTN(rstn),
      .EN(enq_tag_clk_en | flush_i),
      .DRST({(InitFull & FlagEnable), {TagWidth - 1{1'b0}}}),
      .D(enq_tag_d),
      .Q(enq_tag_q)
  );

  DFFRE #(
      .Width(TagWidth)
  ) u_deq_tag_dff (
      .CLK(clk),
      .RSTN(rstn),
      .EN(deq_tag_clk_en | flush_i),
      .DRST({TagWidth{1'b0}}),
      .D(deq_tag_d),
      .Q(deq_tag_q)
  );

`ifndef SYNTHESIS
  default disable iff (~rstn);

  int unsigned usage = 0;
  always @(posedge clk) begin : gen_usage
    if (~rstn) begin
      usage = 0;
    end else begin
      if (flush_i) begin
        usage = 0;
      end else if (enq_tag_clk_en & deq_tag_clk_en) begin
        usage = usage + enq_cnt - deq_cnt;
      end else if (enq_tag_clk_en) begin
        usage = usage + enq_cnt;
      end else if (deq_tag_clk_en) begin
        usage = usage - deq_cnt;
      end
    end
  end

  CHECK_ENQ_WHEN_FULL :
  assert property (@(posedge clk) enq_tag_clk_en |-> (Depth - usage >= enq_cnt))
  else begin
    $fatal("\n Error : Enqueue count[%d] > Availible count[%d]\n", enq_cnt, Depth - usage);
  end

  CHECK_DEQ_WHEN_EMPTY :
  assert property (@(posedge clk) deq_tag_clk_en |-> (usage >= deq_cnt))
  else begin
    $fatal("\n Error : Dequeue count[%d] > Availible count[%d]\n", deq_cnt, usage);
  end

`endif

endmodule
