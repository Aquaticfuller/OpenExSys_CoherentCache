#ifndef __RRVTB_H__
#define __RRVTB_H__

#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <string>
#include <iostream>
#include <sstream>
#include <cassert>
#include "vpi_user.h"
#include "sv_vpi_user.h"
#include "bits.hpp"
#include "common.h"
#include <map>
#include <vector>
#include <initializer_list>
using namespace std;

typedef void (*trigger_cb_func_t)(void *, const vector<Bits> &);
typedef void (*timer_cb_func_t)(void *);
typedef void (*initial_func_t)();
typedef struct __attribute__((packed))
{
    trigger_cb_func_t cb_func;
    vector<string> *tri_sigs;
} trig_record_t;

extern char __trigger_ptr_section_start, __trigger_ptr_section_end;
#define always(name, sig...) extern "C" void __$trig_func_##name##__(void *, const vector<Bits> &sigs);\
vector<string> __$trig_sigs_name_##name##__ = {sig};\
__attribute__((section(".trigger_ptr_section"))) trig_record_t __$trig_rec_##name##__= {&__$trig_func_##name##__, &__$trig_sigs_name_##name##__};\
void __$trig_func_##name##__(void *, const vector<Bits> &sigs)

extern char __init_func_ptr_section_start, __init_func_ptr_section_end;
#define initial(name) extern "C" void __$init_func_##name##__();\
__attribute__((section(".init_func_ptr_section"))) initial_func_t __$init_func_ptr_##name##__ = __$init_func_##name##__;\
void __$init_func_##name##__()

class SVObject
{
	#define _BINARY_ARITH_OP_OVERLOAD_TYPE_0(op) \
		friend const Bits operator op(const SVObject &lop, const SVObject &rop) \
		{ \
			return Bits(lop.to_bits() op rop.to_bits()); \
		}
	#define _BINARY_ARITH_OP_OVERLOAD_TYPE_1(op) \
		friend const Bits operator op(const SVObject &lop, const Bits &rop) \
		{ \
			return Bits(lop.to_bits() op rop); \
		}
	#define _BINARY_ARITH_OP_OVERLOAD_TYPE_2(op) \
		friend const Bits operator op(const Bits &lop, const SVObject &rop) \
		{ \
			return Bits(lop op rop.to_bits()); \
		}
	#define BINARY_ARITH_OP_OVERLOAD(op) \
		_BINARY_ARITH_OP_OVERLOAD_TYPE_0(op) \
		_BINARY_ARITH_OP_OVERLOAD_TYPE_1(op) \
		_BINARY_ARITH_OP_OVERLOAD_TYPE_2(op)

	#define _BINARY_LOGIC_OP_OVERLOAD_TYPE_0(op) \
		friend const bool operator op(const SVObject &lop, const SVObject &rop) \
		{ \
			return lop.to_bits() op rop.to_bits(); \
		}
	#define _BINARY_LOGIC_OP_OVERLOAD_TYPE_1(op) \
		friend const bool operator op(const SVObject &lop, const Bits &rop) \
		{ \
			return lop.to_bits() op rop; \
		}
	#define _BINARY_LOGIC_OP_OVERLOAD_TYPE_2(op) \
		friend const bool operator op(const Bits &lop, const SVObject &rop) \
		{ \
			return lop op rop.to_bits(); \
		}
	#define BINARY_LOGIC_OP_OVERLOAD(op) \
		_BINARY_LOGIC_OP_OVERLOAD_TYPE_0(op) \
		_BINARY_LOGIC_OP_OVERLOAD_TYPE_1(op) \
		_BINARY_LOGIC_OP_OVERLOAD_TYPE_2(op)

public:
    explicit SVObject(const char *s)
    {
        if (!(vpi_h = vpi_handle_by_name((PLI_BYTE8 *)s, NULL)))
        {
            fprintf(stderr, "SV object \"%s\" is not found!", s);
            exit(-1);
        }
    }
    SVObject()
    {
        if (!(vpi_h = vpi_handle_by_name((PLI_BYTE8 *)"testbench", NULL)))
        {
            fprintf(stderr, "SV object \"testbench\" is not found!");
            exit(-1);
        }
        // vpi_printf(" Size is %d, type is: %d\n", vpi_get(vpiSize, vpi_h), vpi_get(vpiType, vpi_h));
    }

	SVObject operator[](const char *s)
	{
		SVObject new_obj;
        if (!(new_obj.vpi_h = vpi_handle_by_name((PLI_BYTE8*)s, this->vpi_h)))
        {
            fprintf(stderr, "SV object \"%s\" is not found in scope \"%s\"!", s, vpi_get_str(vpiFullName, vpi_h));
            exit(-1);
        }

		return new_obj;
	}

    SVObject operator=(const Bits &op)
	{
        s_vpi_value val = {vpiBinStrVal};
        string s = op.to_str(2);
		s_vpi_time time_s;
        val.value.str = (char *)s.c_str();
		time_s.type = vpiSimTime;
		time_s.high = 0;
		time_s.low = 0;
		vpi_put_value(vpi_h, &val, &time_s, vpiNoDelay);
        return *this;
	}

    SVObject operator=(const SVObject &op)
	{
        *this = op.to_bits();
        return *this;
	}

	SVObject operator<<=(const Bits &op)
	{
        s_vpi_value val = {vpiBinStrVal};
        string s = op.to_str(2);
        val.value.str = (char *)s.c_str();
		vpi_put_value(vpi_h, &val, 0, vpiNoDelay);
        return *this;
	}

    SVObject operator<<=(const SVObject &op)
	{
        *this <<= op.to_bits();
        return *this;
	}

	// Overload Operators
    BINARY_ARITH_OP_OVERLOAD(+)
    BINARY_ARITH_OP_OVERLOAD(-)
	BINARY_ARITH_OP_OVERLOAD(*)
	BINARY_ARITH_OP_OVERLOAD(/)
	BINARY_ARITH_OP_OVERLOAD(%)
	BINARY_ARITH_OP_OVERLOAD(&)
	BINARY_ARITH_OP_OVERLOAD(|)
	BINARY_ARITH_OP_OVERLOAD(^)
	BINARY_ARITH_OP_OVERLOAD(<<)
	BINARY_ARITH_OP_OVERLOAD(>>)

	BINARY_LOGIC_OP_OVERLOAD(==)
	BINARY_LOGIC_OP_OVERLOAD(!=)
	BINARY_LOGIC_OP_OVERLOAD(>)
	BINARY_LOGIC_OP_OVERLOAD(<)
	BINARY_LOGIC_OP_OVERLOAD(>=)
	BINARY_LOGIC_OP_OVERLOAD(<=)
	BINARY_LOGIC_OP_OVERLOAD(&&)
	BINARY_LOGIC_OP_OVERLOAD(||)

	bool operator!()
	{
		return !this->to_bits();
	}
	
	// const Bits operator~()
	// {
	// 	return Bits(~this->to_bits());
	// }

	SVObject operator()(size_t pos)
	{   
		ostringstream ostr;
		ostr << vpi_get_str(vpiFullName, vpi_h) << "[" << pos << "]";
		return SVObject(ostr.str().c_str());
    }

    SVObject operator()(unsigned int upper, unsigned int lower)
	{
		string s;
		ostringstream ostr;
		ostr << vpi_get_str(vpiFullName, vpi_h) << "[" << upper << ":" << lower <<"]";
		return SVObject(ostr.str().c_str());
    }

	friend ostream &operator<<(ostream &output, const SVObject &obj )
	{
		output << obj.to_bits();
		return output;            
	}

	const Bits value() const
	{
		return to_bits();
	}

private:
    Bits to_bits() const
	{
		int size;
        s_vpi_value val = {vpiBinStrVal};
		
		size  = vpi_get(vpiSize, vpi_h);
		if (size <= 0)
		{
			ERROR("The object %s is not a computable object!\n", vpi_get_str(vpiFullName, vpi_h));
		}
        vpi_get_value(vpi_h, &val);
		return Bits(val.value.str, 2, size);
	}
    // void set(const Bits &op) const
	// {
    //     s_vpi_value val = {vpiBinStrVal};
    //     string s = op.to_str(2);
    //     val.value.str = (char *)s.c_str();
    //     vpi_put_value(vpi_h, &val, 0, vpiNoDelay);
	// }
private:
	vpiHandle   vpi_h;
};

extern const char *scan_plusargs(const char *);
extern uint64_t get_time();
extern void finish();
extern void register_signal_cb(trigger_cb_func_t, void*, initializer_list<const char*> );
extern void register_timer_cb(timer_cb_func_t, void*, uint64_t, bool);
#endif
