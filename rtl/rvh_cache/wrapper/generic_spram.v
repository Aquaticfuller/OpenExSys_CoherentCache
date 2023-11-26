module generic_spram
#(
    parameter int unsigned w = 8, // data width
    parameter int unsigned p = 8, // word partition size (data bits per write enable)
    parameter int unsigned d = 8, // data depth
    parameter int unsigned log2d = 3, // address width
    parameter int unsigned id = 0, // unique value per instance

    parameter RAM_LATENCY = 1,
    parameter RESET       = 0,
    parameter RESET_HIGH  = 0
)
(
    clk     ,
    ce      ,
    we      ,
    biten   ,
    addr    ,
    din     ,
    dout    
);


localparam ADDR_BITS = log2d;
localparam DATA_BITS = w;
localparam MASK_BITS = w/p;


input                               clk;
input                               ce;
input                               we;
input [MASK_BITS-1 :0]              biten;
input [ADDR_BITS-1 :0]              addr;
input [DATA_BITS-1 :0]              din;
output[DATA_BITS-1 :0]              dout;

wire   [MASK_BITS-1:0]    sim_biten;
wire   [DATA_BITS-1:0]    sim_real_biten; // bit enable
genvar i;
generate
    for(i = 0; i < MASK_BITS; i++) begin
        assign sim_real_biten[i*p+:p] = {p{sim_biten[i]}};
    end
endgenerate

assign sim_biten = we ? biten : 'b0;

// `define USE_SRAM
`ifndef USE_SRAM
rrv64_generic_ram #(
    .ADDR_BITS          (ADDR_BITS),
    .DATA_BITS          (DATA_BITS),
    .RAM_LATENCY        (RAM_LATENCY),
    // .WE_SIZE            (MASK_BITS),
    .RESET              (RESET    ),
    .RESET_HIGH         (RESET_HIGH)
)
generic_ram_u(
    .clk                (clk      ),
    .addr_i             (addr     ),
    .rd_o               (dout     ),
    .wd_i               (din      ),
    .cs_i               (ce       ),
    .we_i               (sim_real_biten)
);
`else

wire [((32-(DATA_BITS%32))%32)+DATA_BITS-1:0] din_fill;
wire [((32-(DATA_BITS%32))%32)+DATA_BITS-1:0] dout_fill;

assign din_fill = {{((32-(DATA_BITS%32))%32){1'b0}} ,din};
assign dout = dout_fill[DATA_BITS-1:0];

generate
    for(genvar sram_id = 0; sram_id < int'($ceil(DATA_BITS*1.0/32)) ; sram_id++) begin: gen_sram
        sky130_sram_1kbyte_1rw1r_32x256_8 sky130_sram_1kbyte_1rw1r_32x256_8_u(

            .clk0 (clk),
            .csb0 (ce),
            .web0 (we),
            .wmask0 ('1),
            .addr0 (addr),
            .din0 (din_fill[32*sram_id +: 32]),
            .dout0 (dout_fill[32*sram_id +: 32]),

            .clk1 (clk),
            .csb1 (1'b1),
            .addr1 ('0),
            .dout1 ()
        );
    end
endgenerate

`endif

//sky130_sram_1kbyte_1rw1r_32x256_8

endmodule
