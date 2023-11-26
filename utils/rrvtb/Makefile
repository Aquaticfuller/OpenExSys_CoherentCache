CUR_MAKEFILE_PATH:=$(abspath $(lastword $(MAKEFILE_LIST)))
CUR_PATH:=$(patsubst %/,%, $(dir $(CUR_MAKEFILE_PATH)))
LDS_FILE:=$(CUR_PATH)/rrvtb.ld
RRVTB_FILES:=$(CUR_PATH)/rrvtb.cpp

rrvtb.so:
	g++ -O3 -fPIC -shared -I$(VCS_HOME)/include -T$(LDS_FILE) -o rrvtb.so  $(RRVTB_FILES) -lgmp -pthread

.PHONY : clean
clean:
	rm -rf rrvtb.so
