RUBY_TB_ROOT=$(PROJ_ROOT)/tb/ruby_testbench
INCLUDE = $(RUBY_TB_ROOT)/../include
FLIST = $(RUBY_TB_ROOT)/flist.f
FLIST_SLICED_LLC = $(RUBY_TB_ROOT)/flist_sliced_llc.f
FLIST_MESH = $(PROJ_ROOT)/flist/mesh.syn.f
dump_on = 0
debug_print_on = 1
dc_debug_print_on = 0
ebi_debug_print_on = 0
noc_debug_print_on = 1
rseed0 = 2375
rseed1 = 543
BUILD_STRING = $(shell date --iso=seconds)
sim_log=./$(BUILD_STRING)_logs
run_cmd=time ./simv +vcs+loopreport +rseed0=$(rseed0) +rseed1=$(rseed1) +dumpon=$(dump_on) +sim_log=. +timeout_count=1000000000 +debug_print=$(debug_print_on) +dc_debug_print=$(dc_debug_print_on) +ebi_debug_print=$(ebi_debug_print_on) +noc_debug_print=$(noc_debug_print_on)
run_cmd_2=+vcs+loopreport +rseed0=$(rseed0) +rseed1=$(rseed1) +sim_log=. +timeout_count=1000000000 +debug_print=$(debug_print_on) +dc_debug_print=$(dc_debug_print_on) +ebi_debug_print=$(ebi_debug_print_on) +noc_debug_print=$(noc_debug_print_on)
# run_trace=/work/stu/zfu/rios/rvh1_repo/rvh_for_l1i/rvh1_230418/tb/ruby_testbench/traces/one_producer_three_consumer
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/blackscholes/simsmall.trace_log.132k
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/bodytrack/simsmall.trace_log.161k
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/canneal/simsmall.trace_log.643k
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/dedup/simsmall.trace_log.252k
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/facesim/simsmall.trace_log.241k
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/fluidanimate/simsmall.trace_log.85k
# run_trace=/work/stu/zfu/rios/trace/parsec_logs/freqmine/simsmall.trace_log.256k
run_trace=/work/stu/zfu/rios/trace/parsec_logs/raytrace/simsmall.trace_log.132k
# opt_define=+define+S_TO_M_NO_DATA_TRANSFER \
#            +define+SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST \
# 					 +define+PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST \
# 					 +define+PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY \
# 					 +define+PRIVATE_CACHE_TO_SCU_DATA_SNP_RESP_DIRTY_PART_ONLY \
# 					 +define+SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY \
# 					 +define+COMMON_QOS_EXTRA_RT_VC
opt_define=+define+S_TO_M_NO_DATA_TRANSFER \
					 +define+PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY \
					 +define+PRIVATE_CACHE_TO_SCU_DATA_SNP_RESP_DIRTY_PART_ONLY \
					 +define+SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY \
					 +define+COMMON_QOS_EXTRA_RT_VC
bl_define=+define+SINGLE_VC_PER_INPUT_PORT


default: bld_sliced_llc

bld_whole_llc:
	-mkdir $(sim_log)
	echo "$(run_cmd)" > $(sim_log)/rerun
	chmod +x $(sim_log)/rerun
	vcs \
	$(opt_define) \
	+vcs+loopreport +vcs+lic+wait -sverilog +v2k -kdb +vc +error+10 -CC "-I$(INCLUDE)" -F "$(FLIST)"  +define+RUBY +lint=TFIPC-L +lint=PCWM -full64 -timescale=1ns/1ps -debug_access -debug_pp -l bld.log  -debug_all
	cp simv $(sim_log) 
	# $(run_cmd)

bld_sliced_llc:
	-mkdir $(sim_log)
	echo "$(run_cmd)" > $(sim_log)/rerun
	chmod +x $(sim_log)/rerun
	vcs \
	$(opt_define) \
	+vcs+loopreport +vcs+lic+wait -sverilog +v2k -kdb +vc +error+1 -CC "-I$(INCLUDE)" -F "$(FLIST_SLICED_LLC)" +define+SLICED_LLC +define+RUBY +lint=TFIPC-L +lint=PCWM -full64 -timescale=1ns/1ps -debug_access -debug_pp -l bld.log  -debug_all
	cp simv $(sim_log) 
	# $(run_cmd)

bld_mesh_syn:
	-mkdir $(sim_log)
	echo "$(run_cmd)" > $(sim_log)/rerun
	chmod +x $(sim_log)/rerun
	vcs +vcs+loopreport +vcs+lic+wait -sverilog +v2k -kdb +vc +error+1 -CC "-I$(INCLUDE)" -F "$(FLIST_MESH)" +define+SYNTHESIS +lint=TFIPC-L +lint=PCWM -full64 -timescale=1ns/1ps -debug_access -debug_pp -l bld.log # -debug_all
	cp simv $(sim_log) 
	# $(run_cmd)

bld_trace_opt:
	-mkdir $(sim_log)
	echo "$(run_cmd)" > $(sim_log)/rerun
	chmod +x $(sim_log)/rerun
	vcs +vcs+loopreport +vcs+lic+wait -sverilog +v2k -kdb +vc +error+10 -CC "-I$(INCLUDE)" -F "$(FLIST)"  \
	$(opt_define) \
	+define+TRACE_INPUT +lint=TFIPC-L +lint=PCWM -full64 -timescale=1ns/1ps -debug_access -debug_pp -l bld.log  -debug_all
	cp simv $(sim_log) 
	# $(run_cmd)

bld_trace_bl:
	-mkdir $(sim_log)
	echo "$(run_cmd)" > $(sim_log)/rerun
	chmod +x $(sim_log)/rerun
	vcs +vcs+loopreport +vcs+lic+wait -sverilog +v2k -kdb +vc +error+10 -CC "-I$(INCLUDE)" -F "$(FLIST)"  \
	$(bl_define) \
	+define+TRACE_INPUT +lint=TFIPC-L +lint=PCWM -full64 -timescale=1ns/1ps -debug_access -debug_pp -l bld.log  -debug_all
	cp simv $(sim_log) 
	# $(run_cmd)

run:
	$(run_cmd) 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log

run_gui:
	./simv -gui -i gui_init.tcl

run_trace:
	$(run_cmd) \
	+trace_file=$(run_trace) 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log

# run_trace_bl:
# 	$(run_cmd) +trace_file=/work/stu/zfu/rios/trace/parsec_logs/blackscholes/simsmall.trace_log.head 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log

# run_trace_bl:
# 	# cp simv_bl simv
# 	-mkdir simv.daidir
# 	cp -r simv_bl.daidir/* simv.daidir/
# 	time ./simv_bl $(run_cmd_2) \
# 	+dumpon=0 +trace_file=$(run_trace) 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log
# 	# $(run_cmd) +dumpon=10 +trace_file=/work/stu/zfu/rios/rvh1_repo/rvh_for_l1i/rvh1_230418/tb/ruby_testbench/traces/mem_set 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log
# 	# $(run_cmd) +trace_file=/work/stu/zfu/rios/trace/parsec_logs/blackscholes/simsmall.trace_log.head 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log

# run_trace_opt:
# 	# cp simv_opt simv
# 	-mkdir simv.daidir
# 	cp -r simv_opt.daidir/* simv.daidir/
# 	time ./simv_opt $(run_cmd_2) \
# 	+dumpon=0 +trace_file=$(run_trace) 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log
# 	# $(run_cmd) +dumpon=11 +trace_file=/work/stu/zfu/rios/rvh1_repo/rvh_for_l1i/rvh1_230418/tb/ruby_testbench/traces/mem_set 2>&1 | tee run_$(debug_print_on).log # > run_$(debug_print_on).log


wave:
	Verdi-SX -ssf ./waves_1.fsdb

clean:
	-rm bld.log simv ucli.key waves.* novas.conf
	-rm -rf csrc simv.daidir *_logs Verdi*
	-rm *.log
	-rm *.fsdb
	-rm *.rc
	-rm verdi_config_file
