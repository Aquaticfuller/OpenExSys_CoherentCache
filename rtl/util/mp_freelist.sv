`ifndef __MP_FREELIST_SV__
`define __MP_FREELIST_SV__ 


module mp_freelist #(
    parameter  int unsigned ENTRY_COUNT    = 12,
    parameter  int unsigned ALLOC_WIDTH    = 4,
    parameter  int unsigned DEALLOC_WIDTH  = 4,
    parameter  bit          MUST_TAKEN_ALL = 1,
    localparam int unsigned TAG_WIDTH      = $clog2(ENTRY_COUNT)
) (
    // Enqueue
    input logic [ALLOC_WIDTH-1:0] alloc_vld_i,
    output logic [ALLOC_WIDTH-1:0][TAG_WIDTH-1:0] alloc_tag_o,
    output logic [ALLOC_WIDTH-1:0] alloc_rdy_o,
    // Dequeue
    input logic [DEALLOC_WIDTH-1:0] dealloc_vld_i,
    input logic [DEALLOC_WIDTH-1:0][TAG_WIDTH-1:0] dealloc_tag_i,

    input logic flush_i,

    input clk,
    input rst
);
  localparam int unsigned AVAIL_CNT_WIDTH = $clog2(ENTRY_COUNT + 1);

  // Clk gate
  logic [ENTRY_COUNT-1:0] ram_clk_en;


  // Status
  logic [DEALLOC_WIDTH-1:0][TAG_WIDTH-1:0] head;
  logic [ALLOC_WIDTH-1:0][TAG_WIDTH-1:0] tail;
  logic [AVAIL_CNT_WIDTH-1:0] usage;

  logic [ENTRY_COUNT-1:0][TAG_WIDTH-1:0] ram_d, ram_q;


  // Allocate
  logic [ALLOC_WIDTH-1:0] alloc_fire;
  logic [ALLOC_WIDTH-1:0][TAG_WIDTH-1:0] alloc_entry_ptr;


  // Deallocate
  logic [DEALLOC_WIDTH-1:0] dealloc_fire;
  logic [DEALLOC_WIDTH-1:0][TAG_WIDTH-1:0] dealloc_entry_ptr;


  always_comb begin : gen_alloc_rdy
    if (MUST_TAKEN_ALL) begin
      for (int i = 0; i < ALLOC_WIDTH; i++) begin
        alloc_rdy_o[i] = (ENTRY_COUNT - usage) >= ALLOC_WIDTH;
      end
    end else begin
      for (int i = 0; i < ALLOC_WIDTH; i++) begin
        alloc_rdy_o[i] = (ENTRY_COUNT - usage) > i;
      end
    end
  end

  generate
    for (genvar i = 0; i < ALLOC_WIDTH; i++) begin : gen_alloc_tag
      assign alloc_tag_o[i] = ram_q[alloc_entry_ptr[i]];
    end
  endgenerate

  assign alloc_fire = alloc_vld_i & alloc_rdy_o;

  assign alloc_entry_ptr = head;



  assign dealloc_fire = dealloc_vld_i;

  assign dealloc_entry_ptr = tail;

  always_comb begin : gen_ram_clk_en
    ram_clk_en = {ENTRY_COUNT{flush_i}};
    for (int i = 0; i < DEALLOC_WIDTH; i++) begin
      if(dealloc_fire[i]) begin
          ram_clk_en[dealloc_entry_ptr[i]] = 1'b1;
      end
    end
  end

  always_comb begin : ram_update
    ram_d = ram_q;
    for (int i = 0; i < DEALLOC_WIDTH; i++) begin
      ram_d[dealloc_entry_ptr[i]] = dealloc_tag_i[i];
    end
    if (flush_i) begin
      for (int i = 0; i < ENTRY_COUNT; i++) begin
        ram_d[i] = i[TAG_WIDTH-1:0];
      end
    end
  end

  always_ff @(posedge clk) begin : ram_dff
    if (rst) begin
      for (int i = 0; i < ENTRY_COUNT; i++) begin
        ram_q[i] <= i[TAG_WIDTH-1:0];
      end
    end else begin
      for (int i = 0; i < ENTRY_COUNT; i++) begin
        if (ram_clk_en[i]) begin
          ram_q[i] <= ram_d[i];
        end
      end
    end
  end


  usage_manager #(
      .ENTRY_COUNT(ENTRY_COUNT),
      .ENQ_WIDTH(DEALLOC_WIDTH),
      .DEQ_WIDTH(ALLOC_WIDTH),
      .FLAG_EN(0),
      .INIT_IS_FULL(1),
      .COMB_DEQ_EN(1),
      .COMB_ENQ_EN(1)
  ) u_usage_manager (
      .enq_fire_i(dealloc_fire),
      .deq_fire_i(alloc_fire),
      .head_o(head),
      .tail_o(tail),
      .avail_cnt_o(usage),
      .flush_i(flush_i),
      .clk(clk),
      .rst(rst)
  );

endmodule : mp_freelist

`endif
