#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdio.h>
#include <libgen.h>
extern void finish();
#define INFO(fmt,args...)       do {fprintf(stderr, "[info @ %s:%d ]: " fmt , basename((char*)__FILE__), __LINE__, ##args);} while(0)
#define WARNING(fmt,args...)    do {fprintf(stderr, "[warning @ %s:%d ]: " fmt , basename((char*)__FILE__), __LINE__, ##args);getchar();} while(0)
#define ERROR(fmt,args...)   do {fprintf(stderr, "[error @ %s:%d ]: " fmt , basename((char*)__FILE__), __LINE__, ##args); finish();} while(0)




#endif
