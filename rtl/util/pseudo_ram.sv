`ifndef __PSEUDO_RAM_SV__
`define __PSEUDO_RAM_SV__

module pseudo_ram
#(
    parameter int unsigned WIDTH = 8,
    parameter int unsigned DEPTH = 8
)
(
    input logic                     we,
    input logic [$clog2(DEPTH)-1:0] a,
    input logic [WIDTH-1:0]         d,
    output logic [WIDTH-1:0]        q,
    
    input logic                     rst,
    input logic                     clk
);

logic [DEPTH-1:0][WIDTH-1:0] ram;

logic [$clog2(DEPTH)-1:0] a_ff;
logic                     we_ff;
logic [WIDTH-1:0]         d_ff;

//sync
always_ff@(posedge clk) begin
    if (rst) begin
        a_ff <= 0;
        d_ff <= 0;
        we_ff <= 0;
    end
    else begin
        a_ff <= a;
        d_ff <= d;
        we_ff <= we;
    end
end


// read
always_comb begin
    q = 0;
    if (!we_ff) begin
        q = ram[a_ff];
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
        ram[a_ff] <= d_ff;
    end
end
endmodule

`endif