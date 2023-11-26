`ifndef __INORDER_ROUTER_SV__
`define __INORDER_ROUTER_SV__
module inorder_router 
#(
    parameter int unsigned SRC_COUNT = 4,
    parameter int unsigned DES_COUNT = 4  
) (
    input  logic[SRC_COUNT-1:0] src_vld_i,
    input  logic[SRC_COUNT-1:0][DES_COUNT-1:0] src_des_en_i,
    output logic[SRC_COUNT-1:0] success_o,
    output logic[DES_COUNT-1:0][SRC_COUNT-1:0] src_des_sel_o
);
    logic[SRC_COUNT-1:0] success;
    logic[SRC_COUNT-1:0][DES_COUNT-1:0] des_sel_mask;
    logic[SRC_COUNT-1:0][DES_COUNT-1:0] des_disable_mask;
    logic[SRC_COUNT-1:0][DES_COUNT-1:0] des_rdy_mask;
    
    generate
        for(genvar src = 0 ; src < SRC_COUNT; src++) begin : gen_des_disable_mask
            if(src == 0) begin
                assign des_disable_mask[src] = {DES_COUNT{1'b0}};
            end else begin
                assign des_disable_mask[src] = des_disable_mask[src-1] | des_sel_mask[src-1];       
            end
        end
    endgenerate
    

    generate
        for(genvar src = 0 ; src < SRC_COUNT ; src++) begin : gen_des_rdy_mask
            if(src == 0) begin
                assign des_rdy_mask[src] = {DES_COUNT{src_vld_i[src]}} & src_des_en_i[src];
            end else begin
                assign des_rdy_mask[src] = {DES_COUNT{src_vld_i[src]}} & src_des_en_i[src] & ~des_disable_mask[src] & {DES_COUNT{success[src-1]}};
            end
        end
    endgenerate

    generate
        for(genvar src = 0 ; src < SRC_COUNT ; src++) begin : gen_success_vec
            assign success[src] = |des_sel_mask[src];
        end
    endgenerate

    always_comb begin : output_logic
        success_o = success;
        for(int src = 0 ; src < SRC_COUNT; src++) begin
            for(int des = 0 ; des < DES_COUNT; des++) begin
                src_des_sel_o[des][src] = des_sel_mask[src][des];
            end
        end
    end
    generate
        for(genvar src = 0 ; src < SRC_COUNT ; src++) begin
            one_hot_priority_encoder
            #(
                .SEL_WIDTH(DES_COUNT)
            ) u_routing_encoder (
                .sel_i(des_rdy_mask[src]),
                .sel_o(des_sel_mask[src])
            );
        end
    endgenerate

endmodule

`endif