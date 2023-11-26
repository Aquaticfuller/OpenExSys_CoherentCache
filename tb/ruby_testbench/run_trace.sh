#!/bin/bash

BENCHMARKS="blackscholes bodytrack canneal dedup facesim ferret fluidanimate freqmine raytrace streamcluster swaptions vips x264"
DUTS="bl opt"
LOG_LENGTHS="1m 10m 100m 200m"
# LOG_LENGTHS="1m"

DUT_BUILD_PATH=/work/stu/zfu/rios/rvh1_repo/rvh_for_l1i/rvh1_230418/tb/ruby_testbench
LOG_PATH=/work/stu/zfu/rios/trace/parsec_traces
DUT_RUN_PATH=/work/stu/zfu/rios/trace/parsec_run_7_part_opt

# build dut
for dut in $DUTS;
do
  rm -rf ${DUT_RUN_PATH}/bld/$dut
  mkdir -p ${DUT_RUN_PATH}/bld/$dut
  cd $DUT_BUILD_PATH && \
  source $DUT_BUILD_PATH/../../env/sourceme && \
  make bld_trace_${dut} && \
  cp simv ${DUT_RUN_PATH}/bld/${dut}/simv && \
  cp -r simv.daidir ${DUT_RUN_PATH}/bld/${dut}/simv.daidir
done

# make trace
for benchmark in $BENCHMARKS; 
do
  mkdir -p ${DUT_RUN_PATH}/${benchmark}/trace
  
  for length in $LOG_LENGTHS;
  do
    head -c ${length} ${LOG_PATH}/${benchmark}/simsmall.trace_log > ${DUT_RUN_PATH}/${benchmark}/trace/simsmall.trace_log.${length}
  done

done

# run dut
for dut in $DUTS;
do
  for benchmark in $BENCHMARKS; 
  do
    for length in $LOG_LENGTHS; 
    do
      (
        (        
          (
            mkdir -p ${DUT_RUN_PATH}/run/$benchmark/$length/$dut
            echo -e "\033[32mStart running\033[35m dut:$dut; benchmark:$benchmark; length:$length\033[0m"
            cd ${DUT_RUN_PATH}/bld/${dut} && \
            time ./simv +vcs+loopreport +rseed0=2375 +rseed1=543 +dumpon=0 +sim_log=. +timeout_count=1000000000 +debug_print=0 +dc_debug_print=0 +ebi_debug_print=0 +noc_debug_print=0 \
            +trace_file=${DUT_RUN_PATH}/${benchmark}/trace/simsmall.trace_log.${length} \
            1> ${DUT_RUN_PATH}/run/$benchmark/$length/$dut/run_1.log \
            2> ${DUT_RUN_PATH}/run/$benchmark/$length/$dut/run_2.log
            echo -e "\033[35m dut:$dut; benchmark:$benchmark; length:$length \033[34mDone\033[0m"
          )&
          sleep 1
        )
      )
    done
  done
done