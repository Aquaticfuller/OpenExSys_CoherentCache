//===============================================
//Name          : STD_DFFRVE
//Author        : cuiluping
//Email         : luping.cui@rivai-ic.com.cn
//Date          : 2019-08-24
//Description   : with reset ,with enable D flip flop,
//                reset value can be configured
//-----------------------------------------------
//All Rights Reserved by rivai company
//===============================================

module std_dffrve
#(
    parameter WIDTH = 8
)
(
    input                       clk,
    input                       rstn,
    input       [WIDTH-1:0]     rst_val,
    input                       en,
    input       [WIDTH-1:0]     d,
    output      [WIDTH-1:0]     q
);

logic    [WIDTH-1:0]     dff_q;

always_ff @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        dff_q <= rst_val;
    end
    else if(en)begin
        dff_q <= d;
    end
end

assign  q = dff_q;

endmodule
