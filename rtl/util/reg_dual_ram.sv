`ifndef __REG_DUAL_RAM_SV__
`define __REG_DUAL_RAM_SV__

module reg_dual_ram
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

// read
always_comb begin
    rd = 0;
    if (re) begin
        rd = ram[ra];
    end
end

// write
always_ff@(posedge clk) begin
    if (rst) begin
        for (int i=0; i<DEPTH; i++) begin
            ram[i] <= 0;
        end
    end
    else if (we) begin
        ram[wa] <= wd;
    end
end
endmodule

`endif