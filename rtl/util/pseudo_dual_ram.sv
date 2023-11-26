`ifndef __PSEUDO_DUAL_RAM_SV__
`define __PSEUDO_DUAL_RAM_SV__

module pseudo_dual_ram
#(
    parameter int unsigned WIDTH = 8,
    parameter int unsigned DEPTH = 8
)
(
    input logic [$clog2(DEPTH)-1:0] ra,
    input logic                     re,
    output logic [WIDTH-1:0]        rd,
    
    input logic [$clog2(DEPTH)-1:0] wa,
    input logic                     we,
    input logic [WIDTH-1:0]         wd,
    
    input logic                     rst,
    input logic                     clk
);

logic [DEPTH-1:0][WIDTH-1:0] ram;

logic [$clog2(DEPTH)-1:0] ra_ff;
logic                     re_ff;
logic [$clog2(DEPTH)-1:0] wa_ff;
logic                     we_ff;
logic [WIDTH-1:0]         wd_ff;

//sync
always_ff@(posedge clk) begin
    if (rst) begin
        ra_ff <= 0;
        re_ff <= 0;
    end
    else begin
        ra_ff <= ra;
        re_ff <= re;     
    end
end

always_ff@(posedge clk) begin
    if (rst) begin
        wa_ff <= 0;
        we_ff <= 0;
        wd_ff <= 0;
    end
    else begin
        wa_ff <= wa;
        we_ff <= we;     
        wd_ff <= wd;     
    end
end

// read
always_comb begin
    rd = 0;
    if (re_ff) begin
        // write bypass read
        if (we_ff && wa_ff == ra_ff) begin
            rd = wd_ff;
        end
        else begin
            rd = ram[ra_ff];
        end
    end
end

// write
always_ff@(posedge clk) begin
    if (rst) begin
        for (int i=0; i<DEPTH; i++) begin
            ram[i] <= 0;
        end
    end
    else if (we_ff) begin
        ram[wa_ff] <= wd_ff;
    end
end
endmodule

`endif