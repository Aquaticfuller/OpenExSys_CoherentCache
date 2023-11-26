`ifndef __USAGE_MANAGER_SV__
`define __USAGE_MANAGER_SV__

module usage_manager #(
    parameter int unsigned ENTRY_COUNT = 8,
    parameter int unsigned ENQ_WIDTH = 2,
    parameter int unsigned DEQ_WIDTH = 2,
    parameter int unsigned FLAG_EN = 0,
    parameter int unsigned INIT_IS_FULL = 0,
    parameter int unsigned COMB_ENQ_EN = 0,
    parameter int unsigned COMB_DEQ_EN = 0,
    localparam int unsigned ENTRY_PTR_WIDTH = $clog2(ENTRY_COUNT),
    localparam int unsigned ENTRY_TAG_WIDTH = ENTRY_PTR_WIDTH + FLAG_EN,
    localparam int unsigned USAGE_CNT_WIDTH = $clog2(ENTRY_COUNT + 1)
) (
    // Enqueue
    input logic [ENQ_WIDTH-1:0] enq_fire_i,

    // Dequeue
    input logic [DEQ_WIDTH-1:0] deq_fire_i,

    // Status
    output logic [DEQ_WIDTH-1:0][ENTRY_TAG_WIDTH-1:0] head_o,
    output logic [ENQ_WIDTH-1:0][ENTRY_TAG_WIDTH-1:0] tail_o,
    output logic [USAGE_CNT_WIDTH-1:0] avail_cnt_o,

    input logic flush_i,

    input clk,
    input rst
);
    // Local Param
    localparam int unsigned ENQ_CNT_WIDTH = $clog2(ENQ_WIDTH + 1);
    localparam int unsigned DEQ_CNT_WIDTH = $clog2(DEQ_WIDTH + 1);
    localparam int unsigned IS_2N = (2 ** ENTRY_PTR_WIDTH == ENTRY_COUNT);
    // Function 
    function automatic [ENTRY_TAG_WIDTH-1:0] head_ptr_plus;
        input logic [ENTRY_TAG_WIDTH-1:0] head_ptr_i;
        input logic [DEQ_CNT_WIDTH-1:0] plus_cnt_i;

        logic flag;
        logic [ENTRY_PTR_WIDTH-1:0] index;
        logic [ENTRY_PTR_WIDTH:0] sum;
        logic [ENTRY_PTR_WIDTH:0] reverse_sum;
        begin
            if (IS_2N) begin
                head_ptr_plus = head_ptr_i + plus_cnt_i;
            end else begin
                index = head_ptr_i[ENTRY_PTR_WIDTH-1:0];
                flag = head_ptr_i[ENTRY_TAG_WIDTH-1];
                sum = index + plus_cnt_i;
                reverse_sum = sum - ENTRY_COUNT;
                if (FLAG_EN) begin
                    if (~reverse_sum[ENTRY_PTR_WIDTH]) begin
                        head_ptr_plus = {~flag, reverse_sum[ENTRY_PTR_WIDTH-1:0]};
                    end else begin
                        head_ptr_plus = {flag, sum[ENTRY_PTR_WIDTH-1:0]};
                    end
                end else begin
                    if (~reverse_sum[ENTRY_PTR_WIDTH]) begin
                        head_ptr_plus = reverse_sum[ENTRY_PTR_WIDTH-1:0];
                    end else begin
                        head_ptr_plus = sum[ENTRY_PTR_WIDTH-1:0];
                    end
                end
            end
        end
    endfunction : head_ptr_plus


    function automatic [ENTRY_TAG_WIDTH-1:0] ptr_plus_one;
        input logic [ENTRY_TAG_WIDTH-1:0] ptr_i;

        logic flag;
        logic [ENTRY_PTR_WIDTH-1:0] index;
        logic reverse_flag;
        begin
            if (IS_2N) begin
                ptr_plus_one = ptr_i + 1'b1;
            end else begin
                index = ptr_i[ENTRY_PTR_WIDTH-1:0];
                flag  = ptr_i[ENTRY_TAG_WIDTH-1];
                if (index == ENTRY_COUNT - 1) begin
                    index = {ENTRY_PTR_WIDTH{1'b0}};
                    reverse_flag = ~flag;
                end else begin
                    index = ptr_i + 1'b1;
                    reverse_flag = flag;
                end
                if (FLAG_EN) begin
                    ptr_plus_one = {reverse_flag, index};
                end else begin
                    ptr_plus_one = index;
                end
            end
        end
    endfunction : ptr_plus_one

    function automatic [ENTRY_TAG_WIDTH-1:0] tail_ptr_plus;
        input logic [ENTRY_TAG_WIDTH-1:0] tail_ptr_i;
        input logic [ENQ_CNT_WIDTH-1:0] plus_cnt_i;
        logic flag;
        logic [ENTRY_PTR_WIDTH-1:0] index;
        logic [ENTRY_PTR_WIDTH:0] sum;
        logic [ENTRY_PTR_WIDTH:0] reverse_sum;
        begin
            if (IS_2N) begin
                tail_ptr_plus = tail_ptr_i + plus_cnt_i;
            end else begin
                index = tail_ptr_i[ENTRY_PTR_WIDTH-1:0];
                flag = tail_ptr_i[ENTRY_TAG_WIDTH-1];
                sum = index + plus_cnt_i;
                reverse_sum = sum - ENTRY_COUNT;
                if (FLAG_EN) begin
                    if (~reverse_sum[ENTRY_PTR_WIDTH]) begin
                        tail_ptr_plus = {~flag, reverse_sum[ENTRY_PTR_WIDTH-1:0]};
                    end else begin
                        tail_ptr_plus = {flag, sum[ENTRY_PTR_WIDTH-1:0]};
                    end
                end else begin
                    if (~reverse_sum[ENTRY_PTR_WIDTH]) begin
                        tail_ptr_plus = reverse_sum[ENTRY_PTR_WIDTH-1:0];
                    end else begin
                        tail_ptr_plus = sum[ENTRY_PTR_WIDTH-1:0];
                    end
                end
            end
        end
    endfunction : tail_ptr_plus


    // Clock Gate
    logic enq_clk_en, deq_clk_en;


    logic [ENQ_CNT_WIDTH-1:0] enq_cnt;
    logic [DEQ_CNT_WIDTH-1:0] deq_cnt;
    logic [ENTRY_TAG_WIDTH-1:0] head_ptr_d, head_ptr_q;
    logic [ENTRY_TAG_WIDTH-1:0] tail_ptr_d, tail_ptr_q;
    logic [USAGE_CNT_WIDTH-1:0] avail_cnt_d, avail_cnt_q;


    assign enq_clk_en = |enq_fire_i;
    assign deq_clk_en = |deq_fire_i;

    // Output 
    always_comb begin : gen_head
        for (int i = 0; i < DEQ_WIDTH; i++) begin
            if (i == 0) begin
                head_o[i] = head_ptr_q;
            end else begin
                if(COMB_DEQ_EN) begin
                    head_o[i] = deq_fire_i[i-1] ? ptr_plus_one(head_o[i-1]) : head_o[i-1];
                end else begin
                    head_o[i] =  ptr_plus_one(head_o[i-1]);
                end
            end
        end
    end
    always_comb begin : gen_tail
        for (int i = 0; i < ENQ_WIDTH; i++) begin
            if (i == 0) begin
                tail_o[i] = tail_ptr_q;
            end else begin
                if(COMB_ENQ_EN) begin
                    tail_o[i] = enq_fire_i[i-1] ? ptr_plus_one(tail_o[i-1]) : tail_o[i-1];
                end else begin
                    tail_o[i] = ptr_plus_one(tail_o[i-1]);
                end
            end
        end
    end
    assign avail_cnt_o = avail_cnt_q;

    always_comb begin : head_ptr_update
        head_ptr_d = head_ptr_q;
        if (deq_clk_en) begin
            head_ptr_d = head_ptr_plus(head_ptr_q, deq_cnt);
        end
        if (flush_i) begin
            head_ptr_d = head_ptr_q;
        end
    end

    always_comb begin : tail_ptr_update
        tail_ptr_d = tail_ptr_q;
        if (enq_clk_en) begin
            tail_ptr_d = tail_ptr_plus(tail_ptr_q, enq_cnt);
        end
        if (flush_i) begin
            if((INIT_IS_FULL==1) && (FLAG_EN==1)) begin
                tail_ptr_d = {~head_ptr_q[ENTRY_TAG_WIDTH-1], head_ptr_q[ENTRY_PTR_WIDTH-1:0]};
            end else begin
                tail_ptr_d = head_ptr_q;
            end
        end
    end

    always_comb begin : avail_cnt_update
        avail_cnt_d = avail_cnt_q;
        if (enq_clk_en) begin
            avail_cnt_d = avail_cnt_q - enq_cnt;
        end
        if (deq_clk_en) begin
            avail_cnt_d = avail_cnt_q + deq_cnt;
        end
        if (enq_clk_en & deq_clk_en) begin
            avail_cnt_d = avail_cnt_q + deq_cnt - enq_cnt;
        end
        if (flush_i) begin
            if (INIT_IS_FULL) begin
                avail_cnt_d = {USAGE_CNT_WIDTH{1'b0}};
            end else begin
                avail_cnt_d = ENTRY_COUNT[USAGE_CNT_WIDTH-1:0];
            end
        end
    end

    always_ff @(posedge clk) begin : head_ptr_dff
        if (rst) begin
            head_ptr_q <= {ENTRY_TAG_WIDTH{1'b0}};
        end else begin
            if (deq_clk_en | flush_i) begin
                head_ptr_q <= head_ptr_d;
            end
        end
    end

    always_ff @(posedge clk) begin : tail_ptr_dff
        if (rst) begin
            if (INIT_IS_FULL & FLAG_EN) begin
                tail_ptr_q <= {1'b1, {ENTRY_PTR_WIDTH{1'b0}}};
            end else begin
                tail_ptr_q <= {ENTRY_TAG_WIDTH{1'b0}};
            end
        end else begin
            if (enq_clk_en | flush_i) begin
                tail_ptr_q <= tail_ptr_d;
            end
        end
    end

    always_ff @(posedge clk) begin : avail_cnt_dff
        if (rst) begin
            if (INIT_IS_FULL) begin
                avail_cnt_q <= {USAGE_CNT_WIDTH{1'b0}};
            end else begin
                avail_cnt_q <= ENTRY_COUNT[USAGE_CNT_WIDTH-1:0];
            end
        end else begin
            if (enq_clk_en | deq_clk_en | flush_i) begin
                avail_cnt_q <= avail_cnt_d;
            end
        end
    end


    one_counter #(
        .DATA_WIDTH(ENQ_WIDTH)
    ) u_enq_one_counter (
        .data_i(enq_fire_i),
        .cnt_o (enq_cnt)
    );

    one_counter #(
        .DATA_WIDTH(DEQ_WIDTH)
    ) u_deq_one_counter (
        .data_i(deq_fire_i),
        .cnt_o (deq_cnt)
    );

endmodule : usage_manager

`endif