`define LFSR_HIGH_16BIT_ENABLE

module LFSR #(parameter NUM_BITS)
(
    input i_Clk,
    input i_Enable,

    //Optional Seed Value
    input i_Seed_DV,
    input [NUM_BITS-1:0] i_Seed_Data,
    output[NUM_BITS-1:0] o_LFSR_Data,
    output o_LFSR_Done
);

 reg [NUM_BITS:1] r_LFSR = 0;
 reg              r_XNOR;

 always @(posedge i_Clk or negedge i_Enable)
    begin
        if(~i_Enable) begin
            r_LFSR <= i_Seed_Data;
        end else if (i_Seed_DV == 1'b1) begin
            r_LFSR <= i_Seed_Data;
        end else begin
            r_LFSR <= {r_LFSR[NUM_BITS-1:1],r_XNOR};
        end
    end

    // Linear Feedback Shift Register Taps refer to https://docs.xilinx.com/v/u/en-US/xapp052
    // use same or becaure the default seed can be '0, and should not be '1
    always @(*)
        begin
            case (NUM_BITS)
                2: begin
                    r_XNOR = r_LFSR[2] ^ ~r_LFSR[1];
                end
                3: begin
                    r_XNOR = r_LFSR[3] ^ ~r_LFSR[2];
                end
                4: begin
                    r_XNOR = r_LFSR[4] ^ ~r_LFSR[3];
                end
                5: begin
                    r_XNOR = r_LFSR[5] ^ ~r_LFSR[3];
                end
                6: begin
                    r_XNOR = r_LFSR[6] ^ ~r_LFSR[5];
                end
                7: begin
                    r_XNOR = r_LFSR[7] ^ ~r_LFSR[6];
                end
                8: begin
                    r_XNOR = r_LFSR[8] ^ ~r_LFSR[6] ^ ~r_LFSR[5] ^ ~r_LFSR[4];
                end
                9: begin
                    r_XNOR = r_LFSR[9] ^ ~r_LFSR[5];
                end
                10: begin
                    r_XNOR = r_LFSR[10] ^ ~r_LFSR[7];
                end
                11: begin
                    r_XNOR = r_LFSR[11] ^ ~r_LFSR[9];
                end
                12: begin
                    r_XNOR = r_LFSR[12] ^ ~r_LFSR[6] ^ ~r_LFSR[4] ^ ~r_LFSR[1];
                end
                13: begin
                    r_XNOR = r_LFSR[13] ^ ~r_LFSR[4] ^ ~r_LFSR[3] ^ ~r_LFSR[1];
                end
                14: begin
                    r_XNOR = r_LFSR[14] ^ ~r_LFSR[5] ^ ~r_LFSR[3] ^ ~r_LFSR[1];
                end
                15: begin
                    r_XNOR = r_LFSR[15] ^ ~r_LFSR[14];
                end
                16: begin
                    r_XNOR = r_LFSR[16] ^ ~r_LFSR[15] ^ ~r_LFSR[13] ^ ~r_LFSR[4];
                end
`ifdef LFSR_HIGH_16BIT_ENABLE
                17: begin
                    r_XNOR = r_LFSR[17] ^ ~r_LFSR[14];
                end
                18: begin
                    r_XNOR = r_LFSR[18] ^ ~r_LFSR[11];
                end
                19: begin
                    r_XNOR = r_LFSR[19] ^ ~r_LFSR[6] ^ ~r_LFSR[2] ^ ~r_LFSR[1];
                end
                20: begin
                    r_XNOR = r_LFSR[20] ^ ~r_LFSR[17];
                end
                21: begin
                    r_XNOR = r_LFSR[21] ^ ~r_LFSR[19];
                end
                22: begin
                    r_XNOR = r_LFSR[22] ^ ~r_LFSR[21];
                end
                23: begin
                    r_XNOR = r_LFSR[23] ^ ~r_LFSR[18];
                end
                24: begin
                    r_XNOR = r_LFSR[24] ^ ~r_LFSR[23] ^ ~r_LFSR[22] ^ ~r_LFSR[17];
                end
                25: begin
                    r_XNOR = r_LFSR[25] ^ ~r_LFSR[22];
                end
                26: begin
                    r_XNOR = r_LFSR[26] ^ ~r_LFSR[6] ^ ~r_LFSR[2] ^ ~r_LFSR[1];
                end
                27: begin
                    r_XNOR = r_LFSR[27] ^ ~r_LFSR[5] ^ ~r_LFSR[2] ^ ~r_LFSR[1];
                end
                28: begin
                    r_XNOR = r_LFSR[28] ^ ~r_LFSR[25];
                end
                29: begin
                    r_XNOR = r_LFSR[29] ^ ~r_LFSR[27];
                end
                30: begin
                    r_XNOR = r_LFSR[30] ^ ~r_LFSR[6] ^ ~r_LFSR[4] ^ ~r_LFSR[1];
                end
                31: begin
                    r_XNOR = r_LFSR[31] ^ ~r_LFSR[28];
                end
                32: begin
                    r_XNOR = r_LFSR[32] ^ ~r_LFSR[22] ^ ~r_LFSR[2] ^ ~r_LFSR[1];
                end
                64: begin
                    r_XNOR = r_LFSR[64] ^ ~r_LFSR[63] ^ ~r_LFSR[61] ^ ~r_LFSR[60];
                end
                80: begin
                    r_XNOR = r_LFSR[80] ^ ~r_LFSR[79] ^ ~r_LFSR[43] ^ ~r_LFSR[42];
                end
                128: begin
                    r_XNOR = r_LFSR[128] ^ ~r_LFSR[126] ^ ~r_LFSR[101] ^ ~r_LFSR[99];
                end
                168: begin
                    r_XNOR = r_LFSR[168] ^ ~r_LFSR[166] ^ ~r_LFSR[153] ^ ~r_LFSR[151];
                end
`endif
                default: begin
                    r_XNOR = '0;
                end

        endcase
    end


  assign o_LFSR_Data = r_LFSR[NUM_BITS:1];
  assign o_LFSR_Done = (r_LFSR[NUM_BITS:1] == i_Seed_Data) ? 1'b1 : 1'b0;
endmodule
module id_pool_2w1r
    #( parameter depth=8,
       parameter width=32,
       parameter ptr_sz=$clog2(depth) 
    )
    (
    input logic clk,
    input logic rst_n,
    input logic [1:0] c_srdy,
    output logic [1:0] c_drdy,
    input logic [1:0][width-1:0] c_data,
    output logic p_srdy,
    input  logic p_drdy,
    output logic [width-1:0] p_data,
    output logic [ptr_sz:0] usage
    );

    localparam depth_sub_1 = depth-1;
    localparam depth_sub_2 = depth-2;

    logic [ptr_sz-1:0] wr_addr_d;
    logic [ptr_sz-1:0] rd_addr_d;

    logic [ptr_sz-1:0] wr_addr_q;
    logic [ptr_sz-1:0] rd_addr_q;

    logic [depth-1:0][width-1:0] array_d;
    logic [depth-1:0][width-1:0] array_q;

    logic [ptr_sz:0] occupy_cnt_d;
    logic [ptr_sz:0] occupy_cnt_q;

    logic full;
    logic empty;

    logic wr_2_en;
    logic wr_2_vld;
    logic wr_en;
    logic rd_en;
    logic [ptr_sz-1:0] wr_addr_p1;

    assign c_drdy = wr_2_vld ? 2'b11 : (occupy_cnt_q == depth_sub_1) ? ((c_srdy == 2'b10) ? 2'b10 : 2'b01) : '0;
    assign p_srdy = ~empty;
    assign p_data = array_q[rd_addr_q];

    assign empty = (occupy_cnt_q == '0);
    assign full  = (occupy_cnt_q == depth[ptr_sz:0]);

    assign rd_en = p_drdy & ~empty;
    assign wr_en = (c_srdy[0] | c_srdy[1]) & ~full;
    assign wr_2_vld = (occupy_cnt_q < depth_sub_1);
    assign wr_2_en = (c_srdy == 2'b11) & wr_2_vld;

    assign rd_addr_d =  rd_en ? ((rd_addr_q == depth_sub_1) ? '0 : rd_addr_q+1) : rd_addr_q;
    assign wr_addr_p1 = (wr_addr_q == depth_sub_1) ? '0 : wr_addr_q+1;
    assign wr_addr_d = wr_2_en ? ((wr_addr_q == depth_sub_1) ? ptr_sz'('d1) : (wr_addr_q == depth_sub_2) ? '0 : wr_addr_q+2) : wr_en ? wr_addr_p1 : wr_addr_q;
    always_comb begin
        occupy_cnt_d = occupy_cnt_q;
        case ({wr_2_en,wr_en,rd_en})
            3'b110: begin
                occupy_cnt_d = occupy_cnt_q+{{(ptr_sz-1){1'b0}},2'd2};
            end
            3'b111: begin
                occupy_cnt_d = occupy_cnt_q+{{(ptr_sz){1'b0}},1'b1};
            end
            3'b010: begin
                occupy_cnt_d = occupy_cnt_q+{{(ptr_sz){1'b0}},1'b1};
            end
            3'b001: begin
                occupy_cnt_d = occupy_cnt_q-{{(ptr_sz){1'b0}},1'b1};
            end
    endcase
    end

std_dffr #(ptr_sz) FF_WR_ADDR (.clk(clk) ,.rstn(rst_n),.d(wr_addr_d),.q(wr_addr_q));
std_dffr #(ptr_sz) FF_RD_ADDR (.clk(clk) ,.rstn(rst_n),.d(rd_addr_d),.q(rd_addr_q));
std_dffrve #(ptr_sz+1) FF_OCCUPY_CNT (.clk(clk),.rstn(rst_n),.rst_val(depth),.en(1'b1),.d(occupy_cnt_d),.q(occupy_cnt_q));

generate
for (genvar ii=0; ii<depth ;ii++) begin
    assign array_d[ii] = ((wr_addr_q == ii[ptr_sz-1:0]) & wr_en) ? (c_srdy[0] ? c_data[0] : c_data[1]) :
                         ((wr_addr_p1 == ii[ptr_sz-1:0]) & wr_2_en) ? c_data[1] :
                         array_q[ii];
    std_dffrve #(width) FF_ARRAY (.clk(clk) ,.rstn(rst_n) ,.rst_val(ii) ,.en(1'b1) ,.d(array_d[ii]) ,.q(array_q[ii]));
end
endgenerate

assign usage = occupy_cnt_q;
endmodule

// module sd_id_pool
//     #( parameter depth=8,
//        parameter width=32,
//        parameter ptr_sz=$clog2(depth) 
//     )
//     (
//     input clk,
//     input rst,
//     input c_srdy,
//     output c_drdy,
//     input[width-1:0] c_data,
//     output p_srdy,
//     input  p_drdy,
//     output[width-1:0] p_data,
//     output[ptr_sz:0] usage
//     );

//     localparam depth_sub_1 = depth-1;
//     logic wr_en;
//     logic rd_en;
//     logic [ptr_sz-1:0] wr_addr;
//     logic [ptr_sz-1:0] rd_addr;
//     logic [ptr_sz-1:0] nxt_wr_addr;
//     logic [ptr_sz-1:0] nxt_rd_addr;
//     logic [depth-1:0][width-1:0] array;
//     logic [ptr_sz:0] occupy_cnt;
//     logic [ptr_sz:0] nxt_occupy_cnt;
//     logic full;
//     logic empty;

//     assign wr_en = c_srdy & ~full;
//     assign rd_en = p_srdy & p_drdy;

//     genvar ii;

//     generate
//         for(ii=0; ii<depth;ii=ii+1) begin: array_entry_ii
//             always @(posedge clk) begin
//                 if (rst) begin
//                     array[ii] <= ii[width-1:0];
//                 end

//                 else begin
//                     if ((wr_addr==ii[ptr_sz-1:0]) & wr_en)
//                         array[ii] <= c_data;
//                 end
//             end
//         end
//     endgenerate

//     assign p_data = array[rd_addr];

//     assign nxt_wr_addr = (wr_en) ? ((wr_addr==depth_sub_1[ptr_sz-1:0]) ? {ptr_sz{1'b0}} : wr_addr+1'b1) : wr_addr;
//     always @(posedge clk) begin
//         if (rst)
//            wr_addr <= {ptr_sz{1'b0}};
//         else
//            wr_addr <= nxt_wr_addr;
//     end
    
//     assign nxt_rd_addr = (rd_en) ? ((rd_addr==depth_sub_1[ptr_sz-1:0]) ? {ptr_sz{1'b0}} : rd_addr+1'b1) : rd_addr;
//     always @(posedge clk) begin
//         if (rst)
//             rd_addr <= {ptr_sz{1'b0}};
//         else
//             rd_addr <= nxt_rd_addr;
//     end

//     always @* begin
//         case ({wr_en, rd_en})
//             2'b00: begin
//                 nxt_occupy_cnt = occupy_cnt;
//             end
//             2'b01: begin
//                 nxt_occupy_cnt = occupy_cnt-1'b1;
//             end
//             2'b10: begin
//                 nxt_occupy_cnt = occupy_cnt+1'b1;
//             end
//             2'b11: begin
//                 nxt_occupy_cnt = occupy_cnt;
//             end
//         endcase
//     end

//     always @(posedge clk) begin
//         if(rst) begin
//             occupy_cnt <= depth[ptr_sz:0];
//         end
//         else begin
//             occupy_cnt <= nxt_occupy_cnt;
//         end
//     end

//     assign empty = (occupy_cnt == {(ptr_sz+1){1'b0}}) ? 1'b1 : 1'b0;
//     assign full = (occupy_cnt == depth[ptr_sz:0]) ? 1'b1 : 1'b0;
//     assign c_drdy = ~full;
//     assign p_srdy = ~empty;
//     assign usage = occupy_cnt;
// endmodule

// module rrv64_vld_rdy_rr_arb #(
//     parameter BACKEND_DOMAIN = 0,
//     parameter N_INPUT = 2
// )(
//     input logic [N_INPUT-1:0] vld,
//     input logic               rdy,
//     output logic [N_INPUT-1:0] grt,
//     input logic                rstn,clk
// );
//     localparam N_INPUT_BITS = $clog2(N_INPUT);

//     typedef enum logic { 
//         ST_PASS_THROUGH,
//         ST_HOLD
//     } vld_rdy_rr_arb_st_t;

// generate
//     if(N_INPUT==1) begin
//         assign grt = vld;
//     end else begin

//         vld_rdy_rr_arb_st_t rff_state, next_state;
//         logic [N_INPUT_BITS-1:0] rrf_last_grt_id, grt_id;
//         logic [N_INPUT-1:0] vld_with_priority;
//         logic [N_INPUT-1:0] grt_with_priority, next_grt, rff_grt;
//         logic               do_save_grt;

//         // vld_with_priority
//         always_comb begin
//             vld_with_priority = vld;
//             if (rff_last_grt_id != N_INPUT_BITS'(N_INPUT-1)) begin
//                 for(int i = 0;i < N_INPUT; i++) begin
//                     if(i > rff_last_grt_id) begin
//                         vld_with_priority[i - rff_last_grt_id - 1'b1] = vld[i];
//                     end else begin
//                         vld_with_priority[N_INPUT - rff_last_grt_id - 1'b1 + i] = vld[i];
//                     end
//                 end
//             end
//         end

// //grt_with_priority
// always_comb begin
//     grt_with_priority = {N_INPUT{1'b0}}:
//     if (|vld_with_priority) begin
//         for (int i = 0; i < N_INPUT; i++) begin
//             if (vld_with_priority[i] == 1'b1) begin
//                 grt_with_priority[i] = 1'b1;
//                 break;
//             end
//         end
//     end
// end

// // next_grt
// always_comb begin
//     if(rff_last_grt_id == N_INPUT_BITS'(N_INPUT-1)) begin
//         next_grt = grt_with_priority;
//     end else begin
//         for(int i = 0; i < N_INPUT;i++) begin
//             if(i > rff_last_grt_id) begin
//                 next_grt[i] = grt_with_priority[i - rff_last_grt_id - 1'b1];
//             end else begin
//                 next_grt[i] = grt_with_priority[N_INPUT - rff_last_grt_id - 1'b1 + i];
//             end
//         end
//     end
// end

// // Grant Update
// always_ff @(posedge clk or negedge rstn) begin
//     if (!rstn) begin
//         rff_grt <= '0;
//     end else begin
//         if (do_save_grt) begin
//             rff_grt <= grt;
//         end
//     end
// end

// always_ff @(posedge clk or negedge rstn ) begin 
//     if (!rstn) begin
//         rff_last_grt_id <= N_INPUT_BITS'(N_INPUT-1);
//     end else begin
//         if ((|grt) & rdy) begin
//             rff_last_grt_id <= grt_id;
//         end
//     end 
// end

// always_ff @(posedge clk or negedge rstn) begin
//     if(!rstn) begin
//         rff_state <= ST_PASS_THROUGH;
//     end else begin
//         rff_state <= next_state;
//     end
// end

// always_comb begin
//     case (rff_state)
//         ST_HOLD: begin
//             do_save_grt = '0;
//             if (rdy) begin
//                 next_state = ST_PASS_THROUGH;
//             end else begin
//                 next_state = ST_HOLD;
//             end
//             end
//             default: begin
//                 if((|grt) & ~rdy) begin
//                     do_save_grt = '1;
//                     next_state = ST_HOLD;
//                 end else begin
//                     do_save_grt = '0;
//                     next_state = ST_PASS_THROUGH;
//                 end
//             end
//         endcase
//     end

// assign grt = (rff_state == ST_HOLD) ? rff_grt: next_grt;
//     end
// endgenerate
//endmodule

