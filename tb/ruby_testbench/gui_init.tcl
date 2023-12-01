set timeout_count 1000000000
set debug_print 1
set rseed0 2375
set rseed1 543
fsdbDumpvars 0 top_sliced_llc +struct +mda  +all +trace_process
# run 10 us