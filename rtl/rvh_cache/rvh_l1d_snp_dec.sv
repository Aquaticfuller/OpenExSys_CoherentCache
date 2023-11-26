// | msg type class | msg type           | description                                                                                                                                                    |
// | -------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
// | scu snoop req  | SnpShared          | Snoop request to obtain a copy of the cache line in Shared state while leaving any cached copy in Shared state. Must not leave the cache line in Unique state. |
// |                | SnpUnique          | Snoop request to obtain a copy of the cache line in Unique state while invalidating any cached copies. Must change the cache line to Invalid state.            |
// |                | SnpCleanInvalid    | Snoop request to Invalidate the cache line at the Snoopee and obtain any Dirty copy, used in SF eviction.                                                      |

module rvh_l1d_snp_dec
  import rvh_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
#(
)
(
  input  cache_scu_cc_snp_t scu_pc_snp_i,
  output snp_req_buf_t      snp_req_buf_entry_o
);

  assign snp_req_buf_entry_o.snp_line_addr = scu_pc_snp_i.addr[PADDR_WIDTH-1:L1D_OFFSET_WIDTH];
  assign snp_req_buf_entry_o.id            = scu_pc_snp_i.id;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
  assign snp_req_buf_entry_o.snp_line_addr_offset = scu_pc_snp_i.addr[L1D_OFFSET_WIDTH-1:0];
  assign snp_req_buf_entry_o.data_resp_with_critical_word_first = scu_pc_snp_i.data_resp_with_critical_word_first;
`endif

  always_comb begin
    unique case (scu_pc_snp_i.rtype)
      SnpUnique: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b1;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b0;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b0;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      end
      SnpShared: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b0;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b1;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b0;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      end

      // ReadNotSharedDirty: begin
      //   snp_req_buf_entry_o.snp_leave_invalid     = 1'b0;
      //   snp_req_buf_entry_o.snp_leave_sharedclean = 1'b1;
      //   snp_req_buf_entry_o.snp_return_clean_data = 1'b1;
      //   snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      // end
      // ReadUnique: begin
      //   snp_req_buf_entry_o.snp_leave_invalid     = 1'b1;
      //   snp_req_buf_entry_o.snp_leave_sharedclean = 1'b0;
      //   snp_req_buf_entry_o.snp_return_clean_data = 1'b1;
      //   snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      // end
      // CleanInvalid: begin
      //   snp_req_buf_entry_o.snp_leave_invalid     = 1'b1;
      //   snp_req_buf_entry_o.snp_leave_sharedclean = 1'b0;
      //   snp_req_buf_entry_o.snp_return_clean_data = 1'b0;
      //   snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      // end
      default: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b0;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b1;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b0;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b0;
      end
    endcase
  end

endmodule
