//===============================================
//Name          : STD_DFFRE
//Author        : cuiluping
//Email         : luping.cui@rivai-ic.com.cn
//Date          : 2019-08-24
//Description   : with reset ,with enable D flip flop
//-----------------------------------------------
//All Rights Reserved by rivai company
//===============================================

module std_dffre
#(
    parameter WIDTH = 8
)
(
    input                       clk,
    input                       rstn,
    input                       en,
    input       [WIDTH-1:0]     d,
    output      [WIDTH-1:0]     q
);

logic     [WIDTH-1:0]     dff_q;

always_ff @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        dff_q <= {WIDTH{1'b0}};
    end
    else if(en)begin
        dff_q <= d;
    end
end

assign  q = dff_q;

endmodule
