package rrv64_top_typedef_pkg;
  import rrv64_top_param_pkg::*;

//l1 Icache-l2 data channel
typedef struct packed {
logic[L1I_L2_AXI_RADDR_WIDTH -1:0]       araddr;
logic[L1I_L2_AXI_RID_WIDTH-1:0]          arid;
logic[3:0]                               arlen;
logic[2:0]                               arsize;
logic[1:0]                               arburst;
logic[1:0]                               arlock;
logic[3:0]                               arcache;
logic[2:0]                               arprot; 
}core_uncore_l1i_axi_ar_t;

typedef struct packed {
logic[L1I_L2_AXI_RDATA_WIDTH -1:0]       rdata;
logic[L1I_L2_AXI_RID_WIDTH -1:0]         rid;
logic[1:0]                               rresp;
logic                                    rlast;  
}core_uncore_l1i_axi_r_t;


//#############################################################
//###################l1d-l2 intf##############################

//l1 Dcache-l2 data channel
typedef struct packed {
logic[L1D_L2_AXI_RADDR_WIDTH -1:0]       araddr;
logic[L1D_L2_AXI_RID_WIDTH -1:0]         arid;
logic[3:0]                               arlen;
logic[2:0]                               arsize;
logic[1:0]                               arburst;
logic[1:0]                               arlock;
logic[3:0]                               arcache;
logic[2:0]                               arprot;
logic                                    rd_type;
}core_uncore_l1d_axi_ar_t;

typedef struct packed {
logic[L1D_L2_AXI_RDATA_WIDTH -1:0]       rdata;
logic[L1D_L2_AXI_RID_WIDTH -1:0]         rid;
logic[1:0]                               rresp;
logic                                    rlast;
logic [1:0]                              rmesi;
logic                                    err;
logic[3:0]                               sst_idx;
logic                                    l2_hit;  
}core_uncore_l1d_axi_r_t;

typedef struct packed {
logic[L1D_L2_AXI_WADDR_WIDTH -1:0]       awaddr;
logic[L1D_L2_AXI_WID_WIDTH-1:0]          awid;
logic[3:0]                               awlen;
logic[2:0]                               awsize;
logic[1:0]                               awburst;
logic[1:0]                               awlock;
logic[3:0]                               awcache;
logic[2:0]                               awprot;
logic[1:0]                               wmesi;
}core_uncore_l1d_axi_aw_t;

typedef struct packed {
logic[L1D_L2_AXI_WDATA_WIDTH -1:0]       wdata;
logic[L1D_L2_AXI_WID_WIDTH -1:0]         wid;
logic[3:0]                               wstrb;
logic                                    wlast;
}core_uncore_l1d_axi_w_t;

typedef struct packed {
logic[L1D_L2_AXI_WID_WIDTH -1:0]         bid;
logic[1:0]                               bresp; 
}core_uncore_l1d_axi_b_t;

//RRV64-OUT M channel 0/1
typedef struct packed {
logic[UNCORE_OUT_AXI_M_RADDR_WIDTH -1:0]      araddr;
logic[UNCORE_OUT_AXI_M_RID_WIDTH -1:0]        arid;
logic[7:0]                                    arlen;
logic[2:0]                                    arsize;
logic[1:0]                                    arburst;
logic[1:0]                                    arlock;
logic[3:0]                                    arcache;
logic[2:0]                                    arprot;
logic[3:0]                                    aruser;
logic[3:0]                                    arqos;
logic[3:0]                                    arregion;
}uncore_out_axi_m_ar_t; 
 
typedef struct packed { 
logic[UNCORE_OUT_AXI_M_RDATA_WIDTH -1:0]      rdata;
logic[UNCORE_OUT_AXI_M_RID_WIDTH -1:0]        rid;
logic[1:0]                                    rresp;
logic                                         rlast;
}uncore_out_axi_m_r_t; 
 
typedef struct packed { 
logic[UNCORE_OUT_AXI_M_WADDR_WIDTH -1:0]      awaddr;
logic[UNCORE_OUT_AXI_M_WID_WIDTH -1:0]        awid;
logic[7:0]                                    awlen;
logic[2:0]                                    awsize;
logic[1:0]                                    awburst;
logic[1:0]                                    awlock;
logic[3:0]                                    awcache;
logic[2:0]                                    awprot;
logic[3:0]                                    awuser;
logic[3:0]                                    awqos;
logic[3:0]                                    awregion;
}uncore_out_axi_m_aw_t; 
 
typedef struct packed { 
logic[UNCORE_OUT_AXI_M_WDATA_WIDTH -1:0]       wdata;
logic[UNCORE_OUT_AXI_M_WID_WIDTH -1:0]         wid;
logic[UNCORE_OUT_AXI_M_WDATA_WIDTH/8 -1:0]    wstrb;
logic                                         wlast; 
}uncore_out_axi_m_w_t;

typedef struct packed {
logic[UNCORE_OUT_AXI_M_WID_WIDTH -1 :0]      bid;
logic[1:0]                                   bresp;  
}uncore_out_axi_m_b_t;

//RRV64-OUT M channel peri
typedef struct packed {
logic[UNCORE_OUT_AXI_M_PERI_RADDR_WIDTH -1:0]  araddr;
logic[UNCORE_OUT_AXI_M_PERI_RID_WIDTH -1:0]    arid;
logic[7:0]                                    arlen;
logic[2:0]                                    arsize;
logic[1:0]                                    arburst;
logic[1:0]                                    arlock;
logic[3:0]                                    arcache;
logic[2:0]                                    arprot;
logic[3:0]                                    aruser;
logic[3:0]                                    arqos;
logic[3:0]                                    arregion;
}uncore_out_axi_m_peri_ar_t;

typedef struct packed { 
logic[UNCORE_OUT_AXI_M_PERI_RDATA_WIDTH -1:0]   rdata;
logic[UNCORE_OUT_AXI_M_PERI_RID_WIDTH -1:0]     rid;
logic[1:0]                                    rresp;
logic                                         rlast;
}uncore_out_axi_m_peri_r_t;

typedef struct packed { 
logic[UNCORE_OUT_AXI_M_PERI_WADDR_WIDTH -1:0]  awaddr;
logic[UNCORE_OUT_AXI_M_PERI_WID_WIDTH -1:0]    awid;
logic[7:0]                                    awlen;
logic[2:0]                                    awsize;
logic[1:0]                                    awburst;
logic[1:0]                                    awlock;
logic[3:0]                                    awcache;
logic[2:0]                                    awprot;
logic[3:0]                                    awuser;
logic[3:0]                                    awqos;
logic[3:0]                                    awregion;
}uncore_out_axi_m_peri_aw_t;

typedef struct packed { 
logic[UNCORE_OUT_AXI_M_PERI_WDATA_WIDTH -1:0]   wdata;
logic[UNCORE_OUT_AXI_M_PERI_WID_WIDTH -1:0]     wid;
logic[UNCORE_OUT_AXI_M_PERI_WDATA_WIDTH/8 -1:0] wstrb;
logic                                           wlast; 
}uncore_out_axi_m_peri_w_t;

typedef struct packed {
logic[UNCORE_OUT_AXI_M_PERI_WID_WIDTH -1 :0]   bid;
logic[1:0]                                    bresp;  
}uncore_out_axi_m_peri_b_t;

//OUT-RRV64 TCM S channel
typedef struct packed {
logic[OUT_UNCORE_AXI_S_TCM_RADDR_WIDTH -1:0]  araddr;
logic[OUT_UNCORE_AXI_S_TCM_RID_WIDTH -1:0]    arid;
logic[7:0]                                    arlen;
logic[2:0]                                    arsize;
logic[1:0]                                    arburst;
logic[1:0]                                    arlock;
logic[3:0]                                    arcache;
logic[2:0]                                    arprot;
logic[3:0]                                    aruser;
logic[3:0]                                    arqos;
logic[3:0]                                    arregion;
}out_uncore_axi_s_tcm_ar_t;

typedef struct packed { 
logic[OUT_UNCORE_AXI_S_TCM_RDATA_WIDTH -1:0]  rdata;
logic[OUT_UNCORE_AXI_S_TCM_RID_WIDTH -1:0]    rid;
logic[1:0]                                    rresp;
logic                                         rlast;
}out_uncore_axi_s_tcm_r_t;

typedef struct packed { 
logic[OUT_UNCORE_AXI_S_TCM_WADDR_WIDTH -1:0]   awaddr;
logic[OUT_UNCORE_AXI_S_TCM_WID_WIDTH -1:0]     awid;
logic[7:0]                                    awlen;
logic[2:0]                                    awsize;
logic[1:0]                                    awburst;
logic[1:0]                                    awlock;
logic[3:0]                                    awcache;
logic[2:0]                                    awprot;
logic[3:0]                                    awuser;
logic[3:0]                                    awqos;
logic[3:0]                                    awregion;
}out_uncore_axi_s_tcm_aw_t;

typedef struct packed { 
logic[OUT_UNCORE_AXI_S_TCM_WDATA_WIDTH -1:0]   wdata;
logic[OUT_UNCORE_AXI_S_TCM_WID_WIDTH -1:0]     wid;
logic[OUT_UNCORE_AXI_S_TCM_WDATA_WIDTH/8 -1:0] wstrb;
logic                                         wlast; 
}out_uncore_axi_s_tcm_w_t;

typedef struct packed {
logic[OUT_UNCORE_AXI_S_TCM_WID_WIDTH -1 :0]    bid;
logic[1:0]                                    bresp;  
}out_uncore_axi_s_tcm_b_t;

typedef struct packed {
logic[OUT_UNCORE_AXI_S_TCM_RID_WIDTH - 1:0] trans_id;
logic[OUT_UNCORE_AXI_S_TCM_RADDR_WIDTH -1:0] addr;
logic wren;
logic[OUT_UNCORE_AXI_S_TCM_WDATA_WIDTH -1:0]   wdata;  
}uncore_core_tcm_req_t;

typedef struct packed {
logic[OUT_UNCORE_AXI_S_TCM_RID_WIDTH - 1:0] trans_id;
logic[OUT_UNCORE_AXI_S_TCM_RDATA_WIDTH -1:0]   rdata;
logic[1:0] error;
}uncore_core_tcm_resp_t;

 //OUT-RRV64 ACP S channel
typedef struct packed {
logic[OUT_UNCORE_AXI_S_ACP_RADDR_WIDTH -1:0]   araddr;
logic[OUT_UNCORE_AXI_S_ACP_RID_WIDTH -1:0]     arid;
logic[7:0]                                    arlen;
logic[2:0]                                    arsize;
logic[1:0]                                    arburst;
logic[1:0]                                    arlock;
logic[3:0]                                    arcache;
logic[2:0]                                    arprot;
logic[3:0]                                    aruser;
logic[3:0]                                    arqos;
logic[3:0]                                    arregion;
}out_uncore_axi_s_acp_ar_t;

typedef struct packed { 
logic[OUT_UNCORE_AXI_S_ACP_RDATA_WIDTH -1:0]   rdata;
logic[OUT_UNCORE_AXI_S_ACP_RID_WIDTH -1:0]     rid;
logic[1:0]                                    rresp;
logic                                         rlast;
}out_uncore_axi_s_acp_r_t;

typedef struct packed { 
logic[OUT_UNCORE_AXI_S_ACP_WADDR_WIDTH -1:0]   awaddr;
logic[OUT_UNCORE_AXI_S_ACP_WID_WIDTH -1:0]     awid;
logic[7:0]                                    awlen;
logic[2:0]                                    awsize;
logic[1:0]                                    awburst;
logic[1:0]                                    awlock;
logic[3:0]                                    awcache;
logic[2:0]                                    awprot;
logic[3:0]                                    awuser;
logic[3:0]                                    awqos;
logic[3:0]                                    awregion;
}out_uncore_axi_s_acp_aw_t;

typedef struct packed { 
logic[OUT_UNCORE_AXI_S_ACP_WDATA_WIDTH -1:0]  wdata;
logic[OUT_UNCORE_AXI_S_ACP_WID_WIDTH -1:0]    wid;
logic[OUT_UNCORE_AXI_S_ACP_WDATA_WIDTH/8 -1:0] wstrb;
logic                                         wlast; 
}out_uncore_axi_s_acp_w_t;

typedef struct packed {
logic[OUT_UNCORE_AXI_S_ACP_WID_WIDTH -1 :0]    bid;
logic[1:0]                                    bresp;  
}out_uncore_axi_s_acp_b_t;


endpackage
