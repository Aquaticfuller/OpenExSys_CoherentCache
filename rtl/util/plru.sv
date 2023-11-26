`ifndef __PLRU_SV__
`define __PLRU_SV__

module plru
#(
    parameter int unsigned N_WAYS = 2,
    parameter int unsigned N_SETS = 2
)
(
    input logic                           touch_valid_i,
    input logic [$clog2(N_SETS)-1:0]      touch_addr_i,
    input logic [$clog2(N_WAYS)-1:0]      touch_way_i,

    output logic [$clog2(N_WAYS)-1:0]     alloc_way_o,

    input logic                           clk,
    input logic                           rst                             
);

logic [N_SETS-1:0][N_WAYS-2:0] plru_regs;

generate
    if(N_WAYS == 2) begin
        assign alloc_way_o = plru_regs[touch_addr_i][0];
    end 
    else if (N_WAYS == 4) begin
        assign alloc_way_o = plru_regs[touch_addr_i][0] ? 
                                    {plru_regs[touch_addr_i][0], plru_regs[touch_addr_i][2]} : 
                                    {plru_regs[touch_addr_i][0], plru_regs[touch_addr_i][1]};
    end
    else if (N_WAYS == 8) begin
        always_comb begin
            if (plru_regs[touch_addr_i][0]) begin
                if (plru_regs[touch_addr_i][2]) begin
                    alloc_way_o = {plru_regs[touch_addr_i][0], plru_regs[touch_addr_i][2], plru_regs[touch_addr_i][6]};
                end
                else begin
                    alloc_way_o = {plru_regs[touch_addr_i][0], plru_regs[touch_addr_i][2], plru_regs[touch_addr_i][5]};
                end
            end
            else begin
                if (plru_regs[touch_addr_i][1]) begin
                    alloc_way_o = {plru_regs[touch_addr_i][0], plru_regs[touch_addr_i][1], plru_regs[touch_addr_i][4]};
                end
                else begin
                    alloc_way_o = {plru_regs[touch_addr_i][0], plru_regs[touch_addr_i][1], plru_regs[touch_addr_i][3]};
                end
            end
        end
    end
endgenerate

generate
    if(N_WAYS == 2) begin
        always_ff @(posedge clk) begin
            if (rst) begin
                plru_regs <= 0;
            end
            else if (touch_valid_i) begin
                if (touch_way_i == alloc_way_o) begin
                    plru_regs[touch_addr_i] <= ~plru_regs[touch_addr_i];
                end
            end
        end
    end 
    else if (N_WAYS == 4) begin
        always_ff @(posedge clk) begin
            if (rst) begin
                plru_regs <= 0;
            end
            else if (touch_valid_i & (alloc_way_o == touch_way_i)) begin
                if (plru_regs[touch_addr_i][0]) begin
                    plru_regs[touch_addr_i][0] <= ~plru_regs[touch_addr_i][0];
                    plru_regs[touch_addr_i][2] <= ~plru_regs[touch_addr_i][2];
                end
                else begin
                    plru_regs[touch_addr_i][0] <= ~plru_regs[touch_addr_i][0];
                    plru_regs[touch_addr_i][1] <= ~plru_regs[touch_addr_i][1];
                end
            end
        end
    end
    else if (N_WAYS == 8) begin
        always_ff @(posedge clk) begin
            if (rst) begin
                plru_regs <= 0;
            end
            else if (touch_valid_i & (alloc_way_o == touch_way_i)) begin
                if (plru_regs[touch_addr_i][0]) begin
                    if (plru_regs[touch_addr_i][2]) begin
                        plru_regs[touch_addr_i][0] <= ~plru_regs[touch_addr_i][0];
                        plru_regs[touch_addr_i][2] <= ~plru_regs[touch_addr_i][2];
                        plru_regs[touch_addr_i][6] <= ~plru_regs[touch_addr_i][6];
                    end
                    else begin
                        plru_regs[touch_addr_i][0] <= ~plru_regs[touch_addr_i][0];
                        plru_regs[touch_addr_i][2] <= ~plru_regs[touch_addr_i][2];
                        plru_regs[touch_addr_i][5] <= ~plru_regs[touch_addr_i][5];
                    end
                end
                else begin
                    if (plru_regs[touch_addr_i][1]) begin
                        plru_regs[touch_addr_i][0] <= ~plru_regs[touch_addr_i][0];
                        plru_regs[touch_addr_i][2] <= ~plru_regs[touch_addr_i][2];
                        plru_regs[touch_addr_i][4] <= ~plru_regs[touch_addr_i][4];
                    end
                    else begin
                        plru_regs[touch_addr_i][0] <= ~plru_regs[touch_addr_i][0];
                        plru_regs[touch_addr_i][2] <= ~plru_regs[touch_addr_i][2];
                        plru_regs[touch_addr_i][3] <= ~plru_regs[touch_addr_i][3];
                    end
                end
            end
        end
    end
endgenerate
    

endmodule

`endif