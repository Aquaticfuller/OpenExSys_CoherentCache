`ifdef TRACE_INPUT

typedef enum logic [1:0] {
    LD      = 0,
    ST      = 1,
    IFETCH  = 2
} ls_op_e;

function ls_op_e str2enum_ls_op_e (string x_str);
  for (ls_op_e e = e.first, int i=0; i<e.num; e=e.next, i++) begin
    if(e.name==x_str) return e;
    if(i+1>=e.num) return e.first;
  end
endfunction

// `define macro_str2enum(T) \
// function T str2enum_``T (string x_str); \
//   for (T e = e.first, int i=0; i<e.num; e=e.next, i++) begin \
//     if(e.name==x_str) return e; \
//     if(i+1>=e.num) return e.first; \
//   end \
// endfunction

// `define macro_str2enum(ls_op_e)

module trace_input
  import riscv_pkg::*;
  import rvh_pkg::*;
  import uop_encoding_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
  parameter CORE_NUM = L1D_NUM,
  parameter CORE_NUM_W = CORE_NUM > 1 ? $clog2(CORE_NUM) : 1,
  
  parameter TRACE_BUFFER_PER_CORE_DEPTH = 8,
  parameter TRACE_BUFFER_PER_CORE_EQ_NUM = 2,
  parameter TRACE_BUFFER_PER_CORE_DQ_NUM = 1,

  parameter TRACE_BUFFER_UNIFIED_DEPTH  = TRACE_BUFFER_PER_CORE_DEPTH*CORE_NUM,
  parameter TRACE_BUFFER_UNIFIED_EQ_NUM = TRACE_BUFFER_PER_CORE_EQ_NUM*CORE_NUM,
  // parameter TRACE_BUFFER_UNIFIED_EQ_NUM = 1,
  parameter TRACE_BUFFER_UNIFIED_DQ_NUM = TRACE_BUFFER_PER_CORE_DQ_NUM*CORE_NUM,

  parameter IN_FLIGHT_LD_NUM_MAX = L1D_MSHR_NUM * 2,
  parameter IN_FLIGHT_LD_NUM_MAX_W = $clog2(IN_FLIGHT_LD_NUM_MAX) + 1
)
(
  // load interface
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_vld,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_io_region,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][ ROB_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_rob_tag,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][PREG_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_prd,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode,

  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_INDEX_WIDTH-1:0 ] ls_pipe_l1d_ld_req_idx,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_ld_req_offset,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][  L1D_TAG_WIDTH-1:0]    ls_pipe_l1d_ld_req_vtag,

  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_rdy,

  // store interface
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_vld,
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_io_region,
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_rob_tag,
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_prd,
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode,
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][       PADDR_WIDTH-1:0] ls_pipe_l1d_st_req_paddr,
  output logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0][            XLEN  -1:0] ls_pipe_l1d_st_req_data, // data from lsu
  input  logic [L1D_NUM-1:0][LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_rdy,

  // DTLB -> D$
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_vld,
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_excp_vld, // s1 kill
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_hit,      // s1 kill
  output logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][       PPN_WIDTH-1:0]   dtlb_l1d_resp_ppn,  // VIPT, get at s1 if tlb hit
  
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_rdy,

  // D$ -> LSQ, mshr full replay
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_replay_vld,
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_mshr_full,

  // D$ -> ROB : Write Back
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0]                         l1d_rob_wb_vld,
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag,
  // D$ -> Int PRF : Write Back
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]                         l1d_int_prf_wb_vld,
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] l1d_int_prf_wb_tag,
  input  logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0][              XLEN-1:0] l1d_int_prf_wb_data,


  input  logic clk,
  input  logic rstn
);

typedef struct packed {
  logic [64-1:0]          cycle;
  logic [CORE_NUM_W-1:0]  core_id;
  ls_op_e                 op;
  logic [3:0]             size;
  logic [32-1:0]          paddr;
} trace_entry_t;

logic         [TRACE_BUFFER_UNIFIED_EQ_NUM-1:0] trace_fifo_unified_eq_vld;
logic         [TRACE_BUFFER_UNIFIED_EQ_NUM-1:0] trace_fifo_unified_eq_rdy;
trace_entry_t [TRACE_BUFFER_UNIFIED_EQ_NUM-1:0] trace_fifo_unified_eq_pl;

logic         [TRACE_BUFFER_UNIFIED_DQ_NUM-1:0] trace_fifo_unified_dq_vld;
logic         [TRACE_BUFFER_UNIFIED_DQ_NUM-1:0] trace_fifo_unified_dq_rdy;
trace_entry_t [TRACE_BUFFER_UNIFIED_DQ_NUM-1:0] trace_fifo_unified_dq_pl;

logic         [CORE_NUM-1:0][TRACE_BUFFER_PER_CORE_EQ_NUM-1:0] trace_fifo_per_core_eq_vld;
logic         [CORE_NUM-1:0][TRACE_BUFFER_PER_CORE_EQ_NUM-1:0] trace_fifo_per_core_eq_rdy;
trace_entry_t [CORE_NUM-1:0][TRACE_BUFFER_PER_CORE_EQ_NUM-1:0] trace_fifo_per_core_eq_pl;

logic         [CORE_NUM-1:0][TRACE_BUFFER_PER_CORE_DQ_NUM-1:0] trace_fifo_per_core_dq_vld;
logic         [CORE_NUM-1:0][TRACE_BUFFER_PER_CORE_DQ_NUM-1:0] trace_fifo_per_core_dq_rdy;
trace_entry_t [CORE_NUM-1:0][TRACE_BUFFER_PER_CORE_DQ_NUM-1:0] trace_fifo_per_core_dq_pl;

logic         [CORE_NUM-1:0] trace_fifo_per_core_head_cycle_reach;

logic [CORE_NUM-1:0] in_flight_load_num_not_full;
logic [CORE_NUM-1:0] in_flight_load_num_not_empty;

integer fd;
string trace_file;
string str0, str1;

logic[64-1:0]         fd_cycle;
logic[CORE_NUM_W-1:0] fd_core_id;
string                fd_op;
logic [3:0]           fd_size;
logic [32-1:0]        fd_paddr;

logic[64-1:0]         init_cycle;
logic[CORE_NUM_W-1:0] init_core_id;
string                init_op;
logic [3:0]           init_size;
logic [32-1:0]        init_paddr;

// cycle
logic [64-1:0] trace_cycle_d, trace_cycle_q;
logic          trace_cycle_ena;

assign trace_cycle_ena = '1;
assign trace_cycle_d   = (trace_cycle_q == 0) ? init_cycle : trace_cycle_q + 1;

std_dffre
#(.WIDTH(64))
U_DAT_TRACE_CYCLE
(
  .clk (clk),
  .rstn(rstn),
  .en  (trace_cycle_ena),
  .d   (trace_cycle_d),
  .q   (trace_cycle_q)
);



// read trace file
initial begin
  $value$plusargs("trace_file=%s",trace_file);
  fd=$fopen(trace_file,"r");
  // $fscanf(fd, "%d %d  %s 0x%x");
  $fgets(str0, fd);
  $fscanf(fd, "%d %d  %s   %d 0x%x", init_cycle, init_core_id, init_op, init_size, init_paddr);
end

always_ff @(posedge clk) begin
  trace_fifo_unified_eq_vld = '0;
  trace_fifo_unified_eq_pl  = '0;
  if(rstn) begin
    if(trace_fifo_unified_eq_rdy) begin
      for(int i = 0; i < TRACE_BUFFER_UNIFIED_EQ_NUM; i++) begin
        if(!$feof(fd)) begin
          $fscanf(fd, "%d %d  %s   %d 0x%x", fd_cycle, fd_core_id, fd_op, fd_size, fd_paddr);
          $fgets(str1, fd);
          trace_fifo_unified_eq_vld[i] = 1'b1;
          trace_fifo_unified_eq_pl[i].cycle   = 64'(fd_cycle);
          trace_fifo_unified_eq_pl[i].core_id = CORE_NUM_W'(fd_core_id);
          trace_fifo_unified_eq_pl[i].op      = str2enum_ls_op_e(fd_op);
          trace_fifo_unified_eq_pl[i].size    = 4'(fd_size);
          trace_fifo_unified_eq_pl[i].paddr   = 32'(fd_paddr);
        end else begin
          if((|in_flight_load_num_not_empty) | (|trace_fifo_unified_eq_vld) | (|trace_fifo_per_core_eq_vld) | (|trace_fifo_per_core_dq_vld)) begin // have load not finished
            break;
          end else begin
            $fclose(fd);
            $finish();            
          end
        end
      end
    end
  end
end

// buffer the trace into a unified fifo
mp_fifo
#(
  .payload_t          (trace_entry_t          ),
  .ENQUEUE_WIDTH      (TRACE_BUFFER_UNIFIED_EQ_NUM    ),
  .DEQUEUE_WIDTH      (TRACE_BUFFER_UNIFIED_DQ_NUM    ),
  .DEPTH              (TRACE_BUFFER_UNIFIED_DEPTH     ),
  .MUST_TAKEN_ALL     (1                      )
)
trace_fifo_unified_u
(
  // Enqueue
  .enqueue_vld_i          (trace_fifo_unified_eq_vld ),
  .enqueue_payload_i      (trace_fifo_unified_eq_pl  ),
  .enqueue_rdy_o          (trace_fifo_unified_eq_rdy ),
  // Dequeue
  .dequeue_vld_o          (trace_fifo_unified_dq_vld ),
  .dequeue_payload_o      (trace_fifo_unified_dq_pl  ),
  .dequeue_rdy_i          (trace_fifo_unified_dq_rdy ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk                           ),
  .rst                    (~rstn                         )
);

// pop trace entry from unified buffer, push into per core buffer
always_comb begin
  trace_fifo_per_core_eq_vld  = '0;
  trace_fifo_per_core_eq_pl   = '0;
  trace_fifo_unified_dq_rdy   = '0;
  for(int i = 0; i < TRACE_BUFFER_UNIFIED_DQ_NUM; i++) begin
    if(trace_fifo_unified_dq_vld[i]) begin
      if(((&trace_fifo_per_core_eq_vld[trace_fifo_unified_dq_pl[i].core_id]) == '0) &&  // at least one enqueue slot is unassigned
         (trace_fifo_per_core_eq_rdy[trace_fifo_unified_dq_pl[i].core_id])) begin       // and the per core buffer is ready
        for(int j = 0; j < TRACE_BUFFER_PER_CORE_EQ_NUM; j++) begin
          if(trace_fifo_per_core_eq_vld[trace_fifo_unified_dq_pl[i].core_id][j] == '0) begin
            trace_fifo_per_core_eq_vld[trace_fifo_unified_dq_pl[i].core_id][j] = 1'b1;
            trace_fifo_per_core_eq_pl [trace_fifo_unified_dq_pl[i].core_id][j] = trace_fifo_unified_dq_pl[i];
            break;
          end
        end
        trace_fifo_unified_dq_rdy[i] = 1'b1;
      end else begin // no empty slot, stop assigning
        break;
      end
    end
  end
end


// buffer the trace into a fifo per core
generate
  for(genvar core_id = 0; core_id < CORE_NUM; core_id++) begin: gen_trace_fifo_per_core_u
    mp_fifo
    #(
      .payload_t          (trace_entry_t          ),
      .ENQUEUE_WIDTH      (TRACE_BUFFER_PER_CORE_EQ_NUM    ),
      .DEQUEUE_WIDTH      (TRACE_BUFFER_PER_CORE_DQ_NUM    ),
      .DEPTH              (TRACE_BUFFER_PER_CORE_DEPTH     ),
      .MUST_TAKEN_ALL     (1                      )
    )
    trace_fifo_per_core_u
    (
      // Enqueue
      .enqueue_vld_i          (trace_fifo_per_core_eq_vld  [core_id]  ),
      .enqueue_payload_i      (trace_fifo_per_core_eq_pl   [core_id]  ),
      .enqueue_rdy_o          (trace_fifo_per_core_eq_rdy  [core_id]  ),
      // Dequeue
      .dequeue_vld_o          (trace_fifo_per_core_dq_vld  [core_id]),
      .dequeue_payload_o      (trace_fifo_per_core_dq_pl   [core_id]),
      .dequeue_rdy_i          (trace_fifo_per_core_dq_rdy  [core_id]),
      
      .flush_i                (1'b0                             ),
      
      .clk                    (clk                           ),
      .rst                    (~rstn                         )
    );
  end
endgenerate

// send req to dut
generate
  for(genvar core_id = 0; core_id < CORE_NUM; core_id++) begin: gen_req_to_dut
    for(genvar port_id = 0; port_id < 2 /* min(LSU_ADDR_PIPE_COUNT, LSU_DATA_PIPE_COUNT) */; port_id++) begin
      if(port_id < TRACE_BUFFER_PER_CORE_DQ_NUM) begin
        
        assign trace_fifo_per_core_dq_rdy[core_id][port_id] = ls_pipe_l1d_ld_req_vld[core_id][port_id] ? ls_pipe_l1d_ld_req_rdy[core_id][port_id] :
                                                              ls_pipe_l1d_st_req_vld[core_id][port_id] ? ls_pipe_l1d_st_req_rdy[core_id][port_id] :
                                                                                                         '0;
        
        assign trace_fifo_per_core_head_cycle_reach[core_id] = trace_fifo_per_core_dq_vld[core_id][port_id] &
                                                               (trace_fifo_per_core_dq_pl[core_id][0].cycle <= trace_cycle_q);
        if(port_id == 0) begin
          assign ls_pipe_l1d_ld_req_vld[core_id][port_id] = trace_fifo_per_core_dq_vld[core_id][port_id] & 
                                                            (trace_fifo_per_core_dq_pl[core_id][port_id].op != ST) &
                                                            in_flight_load_num_not_full[core_id] &
                                                            trace_fifo_per_core_head_cycle_reach[core_id];
          assign ls_pipe_l1d_st_req_vld[core_id][port_id] = trace_fifo_per_core_dq_vld[core_id][port_id] & 
                                                            (trace_fifo_per_core_dq_pl[core_id][port_id].op == ST) &
                                                            trace_fifo_per_core_head_cycle_reach[core_id];
        end else begin
          assign ls_pipe_l1d_ld_req_vld[core_id][port_id] = trace_fifo_per_core_dq_vld[core_id][port_id] & 
                                                            (trace_fifo_per_core_dq_pl[core_id][port_id].op != ST) & 
                                                            trace_fifo_per_core_dq_rdy[core_id][port_id-1] &
                                                            in_flight_load_num_not_full[core_id] &
                                                            trace_fifo_per_core_head_cycle_reach[core_id];
          assign ls_pipe_l1d_st_req_vld[core_id][port_id] = trace_fifo_per_core_dq_vld[core_id][port_id] & 
                                                            (trace_fifo_per_core_dq_pl[core_id][port_id].op == ST) & 
                                                            trace_fifo_per_core_dq_rdy[core_id][port_id-1] &
                                                            trace_fifo_per_core_head_cycle_reach[core_id];
        end

        assign ls_pipe_l1d_ld_req_io_region[core_id][port_id] = '0;
        assign ls_pipe_l1d_ld_req_rob_tag  [core_id][port_id] = ROB_TAG_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].cycle);
        assign ls_pipe_l1d_ld_req_prd      [core_id][port_id] = '0;
        assign ls_pipe_l1d_ld_req_opcode   [core_id][port_id] = LDU_LB;

        assign ls_pipe_l1d_ld_req_idx      [core_id][port_id] = L1D_INDEX_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].paddr[L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH-1:L1D_OFFSET_WIDTH]);
        assign ls_pipe_l1d_ld_req_offset   [core_id][port_id] = L1D_OFFSET_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].paddr[L1D_OFFSET_WIDTH-1:0]);
        assign ls_pipe_l1d_ld_req_vtag     [core_id][port_id] = L1D_TAG_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].paddr[32-1:L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH]);

        assign ls_pipe_l1d_st_req_io_region[core_id][port_id] = '0;
        assign ls_pipe_l1d_st_req_rob_tag  [core_id][port_id] = ROB_TAG_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].cycle);
        assign ls_pipe_l1d_st_req_prd      [core_id][port_id] = '0;
        assign ls_pipe_l1d_st_req_opcode   [core_id][port_id] = trace_fifo_per_core_dq_pl[core_id][port_id].size < 2 ? STU_SB :
                                                                trace_fifo_per_core_dq_pl[core_id][port_id].size < 4 ? STU_SH :
                                                                trace_fifo_per_core_dq_pl[core_id][port_id].size < 8 ? STU_SW :
                                                                                                                       STU_SD ;

        assign ls_pipe_l1d_st_req_paddr    [core_id][port_id] = PADDR_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].paddr);
        assign ls_pipe_l1d_st_req_data     [core_id][port_id] = XLEN'(trace_fifo_per_core_dq_pl[core_id][port_id].cycle);

      end else begin
        assign trace_fifo_per_core_dq_rdy[core_id][port_id] = '0;
        assign ls_pipe_l1d_ld_req_vld[core_id][port_id] = '0;
        assign ls_pipe_l1d_st_req_vld[core_id][port_id] = '0;
      end
    end
  end
endgenerate

// send tlb resp to dut
always_ff @(posedge clk or negedge rstn) begin
  if(~rstn) begin
    dtlb_l1d_resp_vld            <= '0;
    dtlb_l1d_resp_excp_vld       <= '0;
    dtlb_l1d_resp_hit            <= '0;
    dtlb_l1d_resp_ppn            <= '0;
  end
    dtlb_l1d_resp_vld            <= ls_pipe_l1d_ld_req_vld;
    dtlb_l1d_resp_excp_vld       <= 1'b0;
    dtlb_l1d_resp_hit            <= ls_pipe_l1d_ld_req_vld;
    for(int core_id = 0; core_id < L1D_NUM; core_id++) begin
      for(int port_id = 0; port_id < LSU_ADDR_PIPE_COUNT; port_id++) begin
        dtlb_l1d_resp_ppn[core_id][port_id] <= PPN_WIDTH'(trace_fifo_per_core_dq_pl[core_id][port_id].paddr[32-1:PAGE_OFFSET_WIDTH]);
      end
    end
  end


// in flight load track
logic [L1D_NUM-1:0][IN_FLIGHT_LD_NUM_MAX_W-1:0] in_flight_load_counter_d, in_flight_load_counter_q;
logic [L1D_NUM-1:0]                             in_flight_load_counter_plus, in_flight_load_counter_minus;
logic [L1D_NUM-1:0]                             in_flight_load_counter_ena;

logic [L1D_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]           ls_pipe_l1d_ld_req_hsk;
logic [L1D_NUM-1:0][$clog2(LSU_ADDR_PIPE_COUNT)+1-1:0] ls_pipe_l1d_ld_req_hsk_num;

logic [L1D_NUM-1:0][$clog2(LSU_ADDR_PIPE_COUNT)+1-1:0] l1d_int_prf_wb_vld_num;

generate
  for(genvar core_id = 0; core_id < CORE_NUM; core_id++) begin: gen_in_flight_load_counter_q
    assign in_flight_load_num_not_full [core_id] = in_flight_load_counter_q[core_id] < IN_FLIGHT_LD_NUM_MAX;
    assign in_flight_load_num_not_empty[core_id] = in_flight_load_counter_q[core_id] > 0;

    assign ls_pipe_l1d_ld_req_hsk[core_id] = ls_pipe_l1d_ld_req_vld[core_id] & ls_pipe_l1d_ld_req_rdy[core_id];
    one_counter
    #(
      .DATA_WIDTH (LSU_ADDR_PIPE_COUNT)
    )
    ls_pipe_l1d_ld_req_hsk_num_counter_u
    (
      .data_i       (ls_pipe_l1d_ld_req_hsk     [core_id]),
      .cnt_o        (ls_pipe_l1d_ld_req_hsk_num [core_id])
    );

    one_counter
    #(
      .DATA_WIDTH (LSU_ADDR_PIPE_COUNT)
    )
    l1d_int_prf_wb_vld_num_counter_u
    (
      .data_i       (l1d_int_prf_wb_vld[core_id] | l1d_ls_pipe_replay_vld[core_id]),
      .cnt_o        (l1d_int_prf_wb_vld_num [core_id])
    );

    assign in_flight_load_counter_plus [core_id] = |ls_pipe_l1d_ld_req_hsk[core_id];
    assign in_flight_load_counter_minus[core_id] = |(l1d_int_prf_wb_vld[core_id] | l1d_ls_pipe_replay_vld[core_id]);
    assign in_flight_load_counter_ena  [core_id] = in_flight_load_counter_plus[core_id] | in_flight_load_counter_minus[core_id];

    assign in_flight_load_counter_d[core_id] = in_flight_load_counter_q[core_id] +
                                               (in_flight_load_counter_plus [core_id] ? ls_pipe_l1d_ld_req_hsk_num[core_id] : '0) -
                                               (in_flight_load_counter_minus[core_id] ? l1d_int_prf_wb_vld_num[core_id]     : '0);

    std_dffre
    #(.WIDTH(IN_FLIGHT_LD_NUM_MAX_W))
    U_DAT_IN_FLIGHT_LOAD_COUNTER
    (
      .clk(clk),
      .rstn(rstn),
      .en (in_flight_load_counter_ena [core_id]),
      .d  (in_flight_load_counter_d   [core_id]),
      .q  (in_flight_load_counter_q   [core_id])
    );

`ifndef SYNTHESIS
    assert property(@(posedge clk)disable iff(~rstn) ((in_flight_load_counter_minus[core_id]) |-> (in_flight_load_counter_q[core_id] > 0)))
      else $fatal("minus in_flight_load_counter_q when it is empty");
    assert property(@(posedge clk)disable iff(~rstn) ((in_flight_load_counter_plus [core_id]) |-> (in_flight_load_counter_q[core_id] < IN_FLIGHT_LD_NUM_MAX)))
      else $fatal("plus in_flight_load_counter_q when it is full");
    assert property(@(posedge clk)disable iff(~rstn) (((in_flight_load_counter_q[core_id] <= IN_FLIGHT_LD_NUM_MAX) && (in_flight_load_counter_q[core_id] >= 0) )))
      else $fatal("in_flight_load_counter_q num illegal");
`endif
  end
endgenerate


endmodule
`endif