//===============================================
//Name          : STD_DFFE
//Author        : cuiluping
//Email         : luping.cui@rivai-ic.com.cn
//Date          : 2019-08-24
//Description   : no reset ,with enable D flip flop
//-----------------------------------------------
//All Rights Reserved by rivai company
//===============================================

module std_dffe
#(
    parameter WIDTH = 8
)
(
    input                       clk,
    input                       en,
    input       [WIDTH-1:0]     d,
    output      [WIDTH-1:0]     q
);

logic    [WIDTH-1:0] dff_q;

always_ff @(posedge clk) begin
    if(en) begin
        dff_q <= d;
    end
end
assign  q = dff_q;

endmodule
