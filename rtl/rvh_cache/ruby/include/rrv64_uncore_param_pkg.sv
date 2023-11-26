package rrv64_uncore_param_pkg;
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
//    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
//    import rrv64_core_typedef_pkg::*;
//acp
parameter RRV64_TCM_IDX_W = 2;
parameter RRV64_ACP_IDX_W = 2;
   
/////////////////L3 para//1111111111111111111111117
    parameter RRV64_L3_PORT_N =2;
    parameter RRV64_L3_BK_N =2;
    parameter RRV64_L3_SET_N = 512;
    parameter RRV64_L3_TAG_W = 40;
    parameter RRV64_L3_TAG_ECC_W = 7;
    parameter RRV64_L3_DATA_ECC_W = 11;

    parameter RRV64_L3_SET_IDX_W = $clog2(RRV64_L3_SET_N) ;
    parameter RRV64_L3_WAY_N = 8;
    parameter RRV64_L3_WAY_IDX_W = $clog2(RRV64_L3_WAY_N);
    parameter RRV64_L3_MSHR_D =8;
    parameter RRV64_L3_MSHR_IDX_W =$clog2(RRV64_L3_MSHR_D);
    parameter RRV64_L3_EWRQ_D =8;
    parameter RRV64_L3_STG_N = 4;
    parameter RRV64_L3_RD_ID_W = 3;
    parameter RRV64_L3_WR_ID_W = 3;
    
    //scu para//111111111111111111111111/
    
    parameter RRV64_SCU_SF_SET_N = 2048;
    parameter RRV64_SCU_SF_TAG_W = 39;
    parameter RRV64_SCU_SF_TAG_ECC_W = 0;
    parameter RRV64_SCU_SF_DATA_ECC_W = 0;

    parameter RRV64_SCU_SF_SET_IDX_W = $clog2(RRV64_SCU_SF_SET_N);
    parameter RRV64_SCU_SF_WAY_N = 8;
    parameter RRV64_SCU_SF_WAY_IDX_W = $clog2(RRV64_SCU_SF_WAY_N);
    parameter RRV64_SCU_SF_STG_N = 2;
    parameter RRV64_SCU_SF_STG_N_IDX_W=$clog2(RRV64_SCU_SF_STG_N);
    parameter RRV64_SCU_SST_D = 16;
    parameter RRV64_SCU_SST_IDX_W= $clog2(RRV64_SCU_SST_D);
    parameter RRV64_SCU_L2I_L3_RRQ_D = 8;
    parameter RRV64_SCU_L2DACP_L3_RRQ_D = 8;
    parameter RRV64_SCU_L2_L3_WRQ_D = 8;
    parameter RRV64_SCU_SNP_L3_WRQ_D = 8;
    parameter RRV64_SCU_SRQ_D = 8;
    parameter RRV64_SCU_SRQ_ID_W = $clog2(RRV64_SCU_SRQ_D);
    parameter RRV64_SCU_SRDQ_D = 8;
   
    //7111111111111/L2 para//1111111111111111111111111

    parameter RRV64_L2_WAY_N = 4;
    parameter RRV64_L2_WAY_W = $clog2(RRV64_L2_WAY_N);
    parameter RRV64_L2_MSHR_N = 4;
    //parameter RRV64_L2_MSHR_IDX_W= $clog2(RRV64_L2_MSHR_N)
    //parameter RRV64_Line_DATA_W = 512

    parameter RRV64_CACHELINE_W = 512;

    parameter RRV64_L2_PAGE_TABLE = 128;//KB
    parameter RRV64_L2_DATA_RAM_ADDR_D = RRV64_L2_PAGE_TABLE*1024*8/RRV64_CACHELINE_W;
    parameter RRV64_L2_DATA_RAM_ADDR_W = $clog2(RRV64_L2_DATA_RAM_ADDR_D);
    parameter RRV64_L2_TAG_RAM_ADDR_D = RRV64_L2_DATA_RAM_ADDR_D/RRV64_L2_WAY_N;
    parameter RRV64_L2_TAG_RAM_ADDR_W = $clog2(RRV64_L2_TAG_RAM_ADDR_D);
    parameter RRV64_L2_TAG_RAM_DATA_W = RRV64_LINE_ADDR_W-RRV64_L2_TAG_RAM_ADDR_W;





    // parameter  l2_way = 4;
    // parameter l2_way_width = $clog2(l2_way);
    //addr
    parameter addr_width = 56;
    //cacheline
    // parameter cacheline = 64;//B
    // parameter offset =$clog2(cacheline);
    //axi length
    //parameter length = 4;
    //parameter length_width = $clog2(length);
    //axi data
    //parameter cacheline_width = cacheline*8;
    //rameter data_width_axi = cacheline_width/length;
    //axi size
    //parameter rrv64_size = data_width_axi/8;
    //parameter rrv64_size_width = $clog2(rrv64_size);
    parameter data_width_axi = 128;
    parameter rrv64_length = RRV64_CACHELINE_W/data_width_axi-1;//axi transmission times
    parameter rrv64_size = $clog2(data_width_axi/8);
    
    //snoop rd id
    // parameter scu_srqcx_entry =4;
    // parameter scu_srqcx_entry_width = $clog2(scu_srqcx_entry);
    ////l1i rd id
    parameter L1I_RD_ID_W = RRV64_L1D_MSHR_IDX_W;
    //RRV64_L1D rd id
    parameter l1_mshr_entry = 256;
    parameter L1D_RD_ID_W = RRV64_L1D_MSHR_IDX_W;
    //RRV64_L1D wr id
    parameter  l1_ewrq_entry = 256;
    parameter l1_ewrq_entry_width = $clog2(l1_ewrq_entry);
    //l2 rd id
    parameter l2_mshr_entry = 4;
    parameter l2_mshr_entry_width = $clog2(l2_mshr_entry);

//l2 wr id
    parameter l2_ewrq_entry = 4;
    parameter l2_ewrq_entry_width = $clog2(l2_ewrq_entry);

//tmp
    parameter RRV64_L2_MSHR_IDX_W= l2_mshr_entry_width;
    parameter RRV64_L2_EWRQ_IDX_W = l2_ewrq_entry_width;
//##############l1_l2cross------->l2 cache
//###########mshr id size_width

//`define IMUX
// `ifdef IMUX
//     parameter l2_mshr_arid_width = l1i_rd_id_width;
// `else
//     parameter l2_mshr_arid_width = l1_mshr_entry_width;
// `endif
parameter l2_mshr_arid_width = RRV64_L1D_MSHR_IDX_W;
    // parameter page_table  =64;//kB
    // parameter data_ram_addr_size = page_table*1024/cacheline;
    // parameter data_ram_addr_width = $clog2(data_ram_addr_size);
    // parameter tag_ram_addr_size = data_ram_addr_size/l2_way;
    // parameter tag_ram_addr_width = $clog2(tag_ram_addr_size);
    // parameter tag_ram =addr_width-data_ram_addr_width-offset;

//addycy
    parameter EWRQ_DEPTH = 4;
    parameter EWDQ_DEPTH = 4;
    parameter AWLEN = 2'b10;// TBD
    parameter AWSIZE = 3'b001;//  TBD
    //parameter l2_mshr_entry = 4;//???from s2 ###########
    parameter L2_SCU_AR_CHNL_WIDTH =addr_width+$clog2(l2_mshr_entry)+10;//ar snoop [3:0],len[1:0],size[2:0]+is_dc
    parameter ARLEN = 2'b10;// TBD
    parameter ARSIZE = 3'b001;// TBD
    parameter EWDQ_DEPTH_BITS = $clog2 (EWDQ_DEPTH);
    parameter l2_mshr_entry_BITS = $clog2 (l2_mshr_entry);
    parameter EWRQ_DEPTH_BITS = $clog2 (EWRQ_DEPTH);
//1
//1/plic/debug module/timer parameter
//FIXME by cuiluping
 
parameter MEM_DATA_W = 32;
parameter MEM_BYTE_MASK_W = 4;
// Multi-Core
//parameter HARTID_W                     = 2;
//parameter  int CPUNOC_TID_DEBUGID_SIZE = 3;
//parameter int CPUNOC_TID_MASTERID_SIZE = 6;
parameter int CPUNOC_TID_SRCID_SIZE = 4;
parameter  int CPUNOC_TID_TID_SIZE = 8;//should be consistent with AXI ID field
parameter MEM_ADDR_W = 32;

`ifdef IRQ_1024
parameter SRC_NUM = 1024;
`elsif IRQ_512
parameter SRC_NUM = 512;
`elsif IRQ_256
parameter SRC_NUM = 256;
`elsif IRQ_128
parameter SRC_NUM = 128;
`elsif IRQ_64
parameter SRC_NUM = 64;
`elsif IRQ_32
parameter SRC_NUM = 32;
`else
parameter SRC_NUM = 64;
`endif

parameter PLIC_INTR_ID_W  = $clog2(SRC_NUM + 1);
parameter int TIMER_WIDTH = 64;
  
    //debug module
    //parameter int XLEN = 32;
    parameter int DEBUG_ADDR = 32;
    parameter int DEBUG_DATA = 64;
    //parameter  int DEBUG_STRB = 8;
    parameter REGBLK_SUBSYS_DATA0_ADDR = 32'h140;
    parameter REGBLK_SUBSYS_PROGBUF0_ADDR = 32'h100;
    parameter REGBLK_SUBSYS_DMSTATUS_ADDR = 32'h170;
    parameter REGBLK_SUBSYS_DMCONTROL_ADDR = 32'h174;
    parameter REGBLK_SUBSYS_HARTINFO_ADDR = 32'h178;
    parameter REGBLK_SUBSYS_ABSTRACTS_ADDR = 32'h17c;
    parameter REGBLK_SUBSYS_COMMAND_ADDR = 32'h180;
    parameter REGBLK_SUBSYS_ABSTRACTAUTO_ADDR = 32'h184;
    parameter REGBLK_SUBSYS_HALTSUM0_ADDR  = 32'h188;
    parameter REGBLK_SUBSYS_HALTSUM1_ADDR = 32'h18c;
    parameter REGBLK_SUBSYS_HALTSUM2_ADDR = 32'h190;
    parameter REGBLK_SUBSYS_HALTSUM3_ADDR =32'h194;
    parameter REGBLK_SUBSYS_DM_ADDR = 32'h1000;
    parameter SHARE0_BASE_ADDR = 32'h0;
    parameter SOC_DEBUG_BASE_ADDR = 32'h2300000;
    
    //1111111111111/L1d prefetch para//11111111111111/
    
    parameter PF_ADDR_WIDTH = 56;
    parameter PF_ADDR_OFFSET_WIDTH = 6;
    parameter PF_TRACK_TABLE_DEPTH = 4;
    parameter PF_TRACK_TABLE_OFFSET_WIDTH = 32;
    parameter PF_ENGINE_THRESHOLD =3;
    parameter PF_ENGINE_STRIDE_NUM = 3;
    parameter PF_REQ_BUFF_DEPTH = 4;
    parameter PF_TRANS_BUFF_DEPTH = 8;
endpackage