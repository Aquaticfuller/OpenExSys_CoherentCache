module rrv64_generic_ram
#(
  parameter ADDR_BITS   = 4,
  parameter DATA_BITS   = 8,
  parameter RAM_LATENCY = 2,
  // parameter WE_SIZE     = 1,

  parameter RESET       = 0,
  parameter RESET_HIGH  = 0
)
(
  input                          clk,
  input  [ADDR_BITS-1:0]         addr_i,
  output [DATA_BITS-1:0]         rd_o,
  input  [DATA_BITS-1:0]         wd_i,
  input                          cs_i,
  input  [DATA_BITS-1:0]         we_i
);
  reg [DATA_BITS-1:0]    rdata_reg;
  reg [DATA_BITS-1:0]    mem[(1'b1<<ADDR_BITS)-1:0];
  
  genvar                 i;
  generate
    if ((RESET != 0)  && (RESET_HIGH !=0))
      begin : g_reset_high
        for (i=0 ; i<(1'b1<<ADDR_BITS) ; i=i+1)
          begin : g_each_address
            initial 
              mem[i] = {DATA_BITS{1'b1}};
        end
      end
    else if (RESET !=0)
      begin : g_reset_low
        for (i=0; i<(1'b1<<ADDR_BITS) ; i=i+1)
          begin : g_each_address
            initial
              mem[i] = {DATA_BITS{1'b0}};
          end
      end
  endgenerate

  wire  read_cycle  = cs_i & (~|we_i);
  wire  write_cycle = cs_i & (|we_i);

  wire [DATA_BITS-1:0] real_we;

  genvar j;

  generate for (j = 0; j < DATA_BITS; j = j + 1) begin : g_we
    assign real_we[j] = cs_i ? we_i[j] : 1'b0;
  end endgenerate


  wire [DATA_BITS-1:0] nxt_data = (~real_we & mem[addr_i]) | (real_we & wd_i);






  always @ (posedge clk)
    if (write_cycle)
      mem[addr_i] <= nxt_data;






  wire [DATA_BITS-1:0] rdata_nxt = (read_cycle ? mem[addr_i] : {DATA_BITS{1'bX}});

  always @ (posedge clk)
    if (read_cycle)
      rdata_reg <= rdata_nxt;


  assign  rd_o = rdata_reg;

  endmodule
