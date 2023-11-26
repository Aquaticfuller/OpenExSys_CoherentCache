// SPDX-License-Identifier: Apache-2.0
// Copyright 2019 Western Digital Corporation or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//********************************************************************************
// $Id$
//
// Function: Wrapper for on-chip memory instantiations
// Comments:
//
//********************************************************************************

`default_nettype wire
module axi_mem
  #(parameter ID_WIDTH = 0,
    parameter MEM_SIZE = 0,
    parameter mem_clear = 0,
    parameter mem_simple_seq = 0,
    parameter AXI_DATA_WIDTH = 512,
    parameter READ_DELAY_CYCLE = 1,
    parameter READ_DELAY_CYCLE_RANDOMLIZE = 0,
    parameter READ_DELAY_CYCLE_RANDOMLIZE_UPDATE_CYCLE = 100,
    parameter INIT_FILE = "")
  (input wire 		      clk,
   input wire 		      rst_n,
//AW
   input wire [ID_WIDTH-1:0]  i_awid,
   input wire [31:0] 	      i_awaddr,
   input wire [7:0] 	         i_awlen,
   input wire [2:0] 	         i_awsize,
   input wire [1:0] 	         i_awburst,
   input wire 		            i_awvalid,
   output wire 		         o_awready,
//AR
   input wire [ID_WIDTH-1:0]  i_arid,
   input wire [31:0] 	      i_araddr,
   input wire [7:0] 	         i_arlen,
   input wire [2:0] 	         i_arsize,
   input wire [1:0] 	         i_arburst,
   input wire 		            i_arvalid,
   output wire 		         o_arready,
//W
   input wire [AXI_DATA_WIDTH-1:0] 	      i_wdata,
   input wire [63:0] 	         i_wstrb,
   input wire 		            i_wlast,
   input wire 		            i_wvalid,
   output wire 		         o_wready,
//B
   output wire [ID_WIDTH-1:0] o_bid,
   output wire [1:0] 	      o_bresp,
   output wire 		         o_bvalid,
   input wire 		            i_bready,
//R
   output wire [ID_WIDTH-1:0] o_rid,
   output wire [AXI_DATA_WIDTH-1:0] o_rdata,
   output wire [1:0] 	      o_rresp,
   output wire 		         o_rlast,
   output wire 		         o_rvalid,
   input wire 		            i_rready);

   wire 	                      mem_we;
   wire [31:0] 	             mem_addr;
   wire [AXI_DATA_WIDTH/8-1:0] mem_be;
   wire [AXI_DATA_WIDTH-1:0] 	 mem_wdata;
   wire [AXI_DATA_WIDTH-1:0] 	 mem_rdata;

   reg [64-1:0] cycle;
   always @(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         cycle   <= '0;
      end else begin
         cycle   <= cycle + 1;
      end
   end

   // as i_rready is always 1, can delay read resp by simply delay the r output
   reg [READ_DELAY_CYCLE-1:0] [ID_WIDTH-1:0] mid_rid;
   reg [READ_DELAY_CYCLE-1:0] [AXI_DATA_WIDTH-1:0] mid_rdata;
   reg [READ_DELAY_CYCLE-1:0] [1:0] 	      mid_rresp;
   reg [READ_DELAY_CYCLE-1:0] 		         mid_rlast;
   reg [READ_DELAY_CYCLE-1:0] 		         mid_rvalid;
   reg [$clog2(READ_DELAY_CYCLE)-1:0] mid_rrandom_resp_cycle_q, mid_rrandom_resp_cycle_d;

   // to periodiclally update mid_rrandom_resp_cycle_q, need to hold input req and wait resp queue clean
   reg [$clog2(READ_DELAY_CYCLE_RANDOMLIZE_UPDATE_CYCLE)-1+1:0] random_update_counter_q, random_update_counter_d;
   wire random_update_counter_updating;
   wire random_update_valid;
   wire mid_awvalid;
   wire mid_awready;
   wire mid_arvalid;
   wire mid_arready;
   wire mid_wvalid;
   wire mid_wready;

   assign random_update_counter_updating = READ_DELAY_CYCLE_RANDOMLIZE ? (random_update_counter_q >= READ_DELAY_CYCLE_RANDOMLIZE_UPDATE_CYCLE) : 0;
   assign random_update_valid = ~(|mid_rvalid) & random_update_counter_updating;
   
   // hold input req and wait resp queue clean
   assign mid_awvalid = ~random_update_counter_updating & i_awvalid;
   assign mid_arvalid = ~random_update_counter_updating & i_arvalid;
   assign mid_wvalid  = ~random_update_counter_updating & i_wvalid;
   assign o_awready   = ~random_update_counter_updating & mid_awready;
   assign o_arready   = ~random_update_counter_updating & mid_arready;
   assign o_wready    = ~random_update_counter_updating & mid_wready;


   assign random_update_counter_d = random_update_valid ? '0 : random_update_counter_q + 1;
   always @(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         random_update_counter_q   <= '0;
      end else begin
         random_update_counter_q   <= random_update_counter_d;
      end
   end

   
   assign mid_rrandom_resp_cycle_d = $urandom(cycle+128) % READ_DELAY_CYCLE;

   always @(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         mid_rrandom_resp_cycle_q <= READ_DELAY_CYCLE-1;
      end else if(READ_DELAY_CYCLE_RANDOMLIZE) begin
         if(random_update_valid) begin
            mid_rrandom_resp_cycle_q <= mid_rrandom_resp_cycle_d;
         end
      end
   end

   always @(posedge clk or negedge rst_n) begin
      for(int i = 1; i < READ_DELAY_CYCLE; i++) begin
         if(~rst_n) begin
            mid_rid[i]     <= '0;
            mid_rdata[i]   <= '0;
            mid_rresp[i]   <= '0;
            mid_rlast[i]   <= '0;
            mid_rvalid[i]  <= '0;
         end else if(i <= mid_rrandom_resp_cycle_q) begin
            mid_rid[i]     <= mid_rid[i-1];
            mid_rdata[i]   <= mid_rdata[i-1];
            mid_rresp[i]   <= mid_rresp[i-1];
            mid_rlast[i]   <= mid_rlast[i-1];
            mid_rvalid[i]  <= mid_rvalid[i-1];
         end
      end
   end

   assign o_rid      =  mid_rid[mid_rrandom_resp_cycle_q]   ;
   assign o_rdata    =  mid_rdata[mid_rrandom_resp_cycle_q] ;
   assign o_rresp    =  mid_rresp[mid_rrandom_resp_cycle_q] ;
   assign o_rlast    =  mid_rlast[mid_rrandom_resp_cycle_q] ;
   assign o_rvalid   =  mid_rvalid[mid_rrandom_resp_cycle_q];

   axi2mem
     #(.ID_WIDTH   (ID_WIDTH),
       .AXI_ADDR_WIDTH (32),
       .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
       .AXI_USER_WIDTH (0))
   ram_axi2mem
     (.clk_i  (clk),
      .rst_ni (rst_n),
      .slave_aw_id    (i_awid   ),
      .slave_aw_addr  (i_awaddr ),
      .slave_aw_len   (i_awlen  ),
      .slave_aw_size  (i_awsize ),
      .slave_aw_burst (i_awburst),
      .slave_aw_valid (mid_awvalid),
      .slave_aw_ready (mid_awready),
      .slave_ar_id    (i_arid   ),
      .slave_ar_addr  (i_araddr ),
      .slave_ar_len   (i_arlen  ),
      .slave_ar_size  (i_arsize ),
      .slave_ar_burst (i_arburst),
      .slave_ar_valid (mid_arvalid),
      .slave_ar_ready (mid_arready),
      .slave_w_data   (i_wdata ),
      .slave_w_strb   (i_wstrb ),
      .slave_w_last   (i_wlast ),
      .slave_w_valid  (mid_wvalid),
      .slave_w_ready  (mid_wready),
      .slave_b_id     (o_bid   ),
      .slave_b_resp   (o_bresp ),
      .slave_b_valid  (o_bvalid),
      .slave_b_ready  (i_bready),
      .slave_r_id     (mid_rid[0]   ),
      .slave_r_data   (mid_rdata[0] ),
      .slave_r_resp   (mid_rresp[0] ),
      .slave_r_last   (mid_rlast[0] ),
      .slave_r_valid  (mid_rvalid[0]),
      .slave_r_ready  (i_rready),
      .req_o  (),
      .we_o   (mem_we),
      .addr_o (mem_addr),
      .be_o   (mem_be),
      .data_o (mem_wdata),
      .data_i (mem_rdata));

`ifndef SYNTHESIS
   dpram64
     #(.SIZE (MEM_SIZE),
       .mem_clear (mem_clear),
       .mem_simple_seq(mem_simple_seq),
       .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
       .memfile (INIT_FILE))
   ram
     (.clk   (clk),
      .we    ({(AXI_DATA_WIDTH/8){mem_we}} & mem_be),
      .din   (mem_wdata),
      .waddr (mem_addr[31:0]),
      .raddr (mem_addr[31:0]),
      .dout  (mem_rdata));
`else
   assign mem_rdata = {AXI_DATA_WIDTH{1'b0}};
`endif

endmodule
