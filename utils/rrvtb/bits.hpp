#ifndef __BIGINT_H__
#define __BIGINT_H__
#include <cstring>
#include <gmp.h>
#include <algorithm>
#include <stdint.h>
#include "common.h"
using namespace std;



class Bits
{
	#define MAX(a, b) (a > b ? a : b)
public:
	Bits(uint64_t op, uint32_t size = 64)
	{
		mpz_init_set_ui(mpz, op);
        this->size = size;
		this->create_mask(size);
		this->do_mask();
	}
	// Bits(signed int op, uint32_t size = 32)
	// {
	// 	mpz_init_set_si(mpz, op);
    //     this->size = size;
	// 	this->create_mask(size);
	// 	this->do_mask();
	// }

	// Bits(const char *str)
	// {
	// 	mpz_init(mpz);
	// 	set_from_str(str);
	// 	this->create_mask(this->size);
	// 	this->do_mask();
    // }

	Bits(const char *str, int base, int size = -1)
	{
		mpz_init(mpz);
		set_from_str(str, base, size);
		this->create_mask(this->size);
		this->do_mask();
    }

	Bits(const string &str)
	{
		mpz_init(mpz);
		set_from_str(str.c_str());
		this->create_mask(this->size);
		this->do_mask();
	}

	Bits(const string &str, int base, int size = -1)
	{
		mpz_init(mpz);
		set_from_str(str.c_str(), base, size);
		this->create_mask(this->size);
		this->do_mask();
	}

	Bits(const Bits &op, int size = -1)
	{
		if (size == -1)
		{
			mpz_init_set(mpz, op.mpz);
			this->size = op.size;
		}
		else if (size > 0)
		{
			mpz_t mask_mpz;
		
			mpz_init_set(mpz, op.mpz);

			mpz_init_set_ui(mask_mpz, 1);
			mpz_mul_2exp(mask_mpz, mask_mpz, size);
			mpz_sub_ui(mask_mpz, mask_mpz, 1);
			
			mpz_and(mpz, mask_mpz, mpz);

			this->size = size;
		}
		else 
		{
			ERROR("Invalid size for variable!\n");
		}
		this->create_mask(this->size);
		this->do_mask();
	}

	// Bits()
	// {
	// 	mpz_init (mpz);
	// 	this->size = 0;
	// 	this->create_mask(this->size);
	// }
private:
	Bits(mpz_t &mpz, int size)
	{
		mpz_init_set(this->mpz, mpz);
		mpz_clear(mpz);
		this->create_mask(size);
		this->do_mask();
	}

public:
	~Bits()
	{
		mpz_clear(mpz);
		mpz_clear(mask_mpz);
	};


	friend Bits operator+(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_add(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator-(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_sub(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator*(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_mul(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator/(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_fdiv_q(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator%(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_fdiv_r(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}

	friend bool operator==(const Bits &lop, const Bits &rop)
	{
		int r;
		r = mpz_cmp(lop.mpz, rop.mpz);
		return r == 0 ? true : false;
	}
	friend bool operator!=(const Bits &lop, const Bits &rop)
	{
		int r;
		r = mpz_cmp(lop.mpz, rop.mpz);
		return r == 0 ? false : true;
	}
	friend bool operator>(const Bits &lop, const Bits &rop)
	{
		int r;
		r = mpz_cmp(lop.mpz, rop.mpz);
		return r > 0 ? true : false;
	}
	friend bool operator<(const Bits &lop, const Bits &rop)
	{
		int r;
		r = mpz_cmp(lop.mpz, rop.mpz);
		return r < 0 ? true : false;
	}
	friend bool operator>=(const Bits &lop, const Bits &rop)
	{
		int r;
		r = mpz_cmp(lop.mpz, rop.mpz);
		return r >= 0 ? true : false;
	}
	friend bool operator<=(const Bits &lop, const Bits &rop)
	{
		int r;
		r = mpz_cmp(lop.mpz, rop.mpz);
		return r <= 0 ? true : false;
	}

	friend Bits operator&(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		// INFO("lop: %s, rop: %s\n", mpz_get_str(NULL, 16, lop.mpz), mpz_get_str(NULL, 16, rop.mpz));
		mpz_init(rslt_mpz);
		mpz_and(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator|(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_ior(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator^(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_xor(rslt_mpz, lop.mpz, rop.mpz);
		return Bits(rslt_mpz, MAX(lop.size, rop.size));
	}
	friend Bits operator<<(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_mul_2exp(rslt_mpz, lop.mpz, mpz_get_ui(rop.mpz));
		return Bits(rslt_mpz, lop.size);
	}
	friend Bits operator>>(const Bits &lop, const Bits &rop)
	{
		mpz_t rslt_mpz;
		mpz_init(rslt_mpz);
		mpz_fdiv_q_2exp(rslt_mpz,lop.mpz, mpz_get_ui(rop.mpz));
		return Bits(rslt_mpz, lop.size);
	}

	friend bool operator&&(const Bits &lop, const Bits &rop)
	{
		return  (mpz_cmp_ui(lop.mpz, 0) == 0) || (mpz_cmp_ui(rop.mpz, 0) == 0) ? false : true;
	}
	friend bool operator||(const Bits &lop, const Bits &rop)
	{
		return  (mpz_cmp_ui(lop.mpz, 0) == 0) && (mpz_cmp_ui(rop.mpz, 0) == 0) ? false : true;
	}
	bool operator!()
	{
		return mpz_cmp_ui(this->mpz, 0) == 0 ? true : false;
	}

	// Bits operator~()
	// {
	// 	mpz_t rslt_mpz;
	// 	mpz_init(rslt_mpz);
	// 	mpz_neg(rslt_mpz, this->mpz);
	// 	mpz_sub_ui(rslt_mpz, this->mpz, 1);
	// 	return Bits(rslt_mpz, this->size);
	// }
	// Bits operator-()
	// {
	// 	mpz_t rslt_mpz;
	// 	mpz_init(rslt_mpz);
	// 	mpz_neg(rslt_mpz, this->mpz);
	// 	return Bits(rslt_mpz, this->size);
	// }

	void copy_from(const Bits &op)
	{
		mpz_set(mpz, op.mpz);
		mpz_set(mask_mpz, op.mask_mpz);
		this->size = op.size;
	}
	Bits operator=(const Bits &op)
	{
		mpz_set(mpz, op.mpz);
		do_mask();
		return *this;
	}
	Bits operator=(const char *str)
	{
		set_from_str(str);
		this->set_mask(this->size);
		this->do_mask();
		return *this;
	}

	Bits operator=(const string &str)
	{
		set_from_str(str.c_str());
		this->set_mask(this->size);
		this->do_mask();
		return *this;
	}

	friend ostream &operator<<(ostream &output, const Bits &num )
	{
		char *p;
		for (int i = num.size - mpz_sizeinbase(num.mpz, 2); i >= 4; i -= 4)
		{
			output << "0";
		}
		output << (p = mpz_get_str(NULL, 16, num.mpz));
		free(p);
		return output;            
	}

	Bits operator()(size_t pos)
	{    
		return Bits(mpz_tstbit(mpz, pos), 1);
    }

    Bits operator()(unsigned int upper, unsigned int lower)
	{
		unsigned int len;
		if (upper < lower)
		{
			ERROR("Invalid indexes!\n");
		}
		len = upper - lower + 1;
		return Bits(*this >> lower, len);
    }
	
	string to_str(int base=10) const
	{
		char *p;
		string s;
		p = mpz_get_str(NULL, base, mpz);
		s = p;
		free(p);
		return s;
	}

	uint64_t to_ulong() const
	{
		return mpz_get_ui(mpz);
	}

private:
	string to_lestr() const
	{
		string s;
		s = this->to_str(2);
		reverse(s.begin(),s.end());
		return s;
	}
	void set_from_str(const char *t_str)
	{
		const char *p_sv_b, *p_sv_d, *p_sv_h;
		char *str;

		if (!t_str || strlen(t_str) == 0) ERROR("Illegal initialization string\n");

		str = (char*)malloc(strlen(t_str) + 1);
		strcpy(str, t_str);
		for (int i = 0; str[i] != '\0'; i++) 
		{
			if (str[i] == 'x' || str[i] == 'X')
			{
				str[i] = '0';
			}
		}

		if (strlen(str) > 2 && (str[0] == '0' && (str[1] == 'b' || str[1] == 'B')))		// c style binary
		{
			this->size = strlen(str + 2);
			mpz_set_str(mpz, str + 2, 2);
		}
		else if (strlen(str) > 2 && (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')))	// c style hexadecimal
		{
			this->size = strlen(str + 2) * 4;
			mpz_set_str(mpz, str + 2, 16);
		}
		else if (strlen(str) >= 4 && ((p_sv_b = strstr(str, "'b")) || (p_sv_d = strstr(str, "'d")) || (p_sv_h = strstr(str, "'h"))))  // sv style number
		{
			this->size = atoi(str);
			if (this->size == 0) ERROR("Illegal initialization string\n");

			if (p_sv_b)
				mpz_set_str(mpz, p_sv_b + 2, 2);
			else if (p_sv_h)
				mpz_set_str(mpz, p_sv_h + 2, 16);
			else if (p_sv_d)
				mpz_set_str(mpz, p_sv_d + 2, 10);
			else 							// should never reach here
				ERROR("Internel Error!");
		}
		else 
		{
			if (str[0] == '0')
			{
				ERROR("The size of decimal number is derived automatically, DO NOT use '0' to specify the bit width for decimal number!\n");
			}
			else 
			{
				WARNING("The size of decimal number is derived automatically. To specify the bit width of a decimal number, please declare explicitly\n");
			}
			mpz_set_str(mpz, str, 10);
			this->size = mpz_sizeinbase(mpz, 2);
		}
		free(str);
	}

	void set_from_str(const char *t_str, int base, int size = -1)
	{
		const char *p_sv_b, *p_sv_d, *p_sv_h;
		char *str;

		if (!t_str || strlen(t_str) == 0) ERROR("Illegal initialization string\n");

		str = (char*)malloc(strlen(t_str) + 1);
		strcpy(str, t_str);
		for (int i = 0; str[i] != '\0'; i++) 
		{
			if (str[i] == 'x' || str[i] == 'X')
			{
				str[i] = '0';
			}
		}

		p_sv_b = strstr(str, "'b");
		p_sv_d = strstr(str, "'d");
		p_sv_h = strstr(str, "'h");

        if (base == 2)
        {
            if (strlen(str) > 2 && (str[0] == '0' && (str[1] == 'b' || str[1] == 'B')))
            {
				this->size = size == -1 ? strlen(str + 2) : size;
				mpz_set_str(mpz, str + 2, base);
            }
			else if (strlen(str) >= 4 && p_sv_b)
			{
				this->size = atoi(str);
				if (this->size == 0) ERROR("Illegal initialization string\n");
				if (size != -1 && size != this->size) ERROR("The size defined by the argument conflicts with the size defined in the string\n");
				mpz_set_str(mpz, p_sv_b + 2, 2);
			}
            else 
            {
                this->size = size == -1 ? strlen(str) : size;
                mpz_set_str(mpz, str, base);
            }
        }
        else if (base == 10)
        {
			if (strlen(str) >= 4 && p_sv_d)
			{
				this->size = atoi(str);
				if (this->size == 0) ERROR("Illegal initialization string\n");
				if (size != -1 && size != this->size) ERROR("The size defined by the argument conflicts with the size defined in the string\n");
				mpz_set_str(mpz, p_sv_d + 2, 10);
			}
			else if (size == -1)
			{
				if (str[0] == '0')
				{
					ERROR("The size of decimal number is derived automatically, DO NOT use '0' to specify the bit width for decimal number!\n");
				}
				else 
				{
					WARNING("The size of decimal number is derived automatically. To specify the bit width of a decimal number, please declare explicitly\n");
				}
				mpz_set_str(mpz, str, base);
            	this->size = mpz_sizeinbase(mpz, 2);
			}
            else
			{
				mpz_set_str(mpz, str, base);
            	this->size = size;
			}
        }
        else if (base == 16)
        {
            if (strlen(str) > 2 && (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')))
            {
				this->size = size == -1 ? strlen(str + 2) * 4 : size;
				mpz_set_str(mpz, str + 2, base);
            }
			else if (strlen(str) >= 4 && p_sv_h)
			{
				this->size = atoi(str);
				if (this->size == 0) ERROR("Illegal initialization string\n");
				if (size != -1 && size != this->size) ERROR("The size defined by the argument conflicts with the size defined in the string\n");
				mpz_set_str(mpz, p_sv_h + 2, 16);
			}
            else 
            {
                this->size = size == -1 ? strlen(str) * 4 : size;
                mpz_set_str(mpz, str, base);
            }
        }
        else 
        {
            ERROR("We currently only support binary, decimal and hexadecimal numbers!\n");
        }
		free(str);
	}
	
	void create_mask(int size)
	{
		mpz_init_set_ui(mask_mpz, 1);
		mpz_mul_2exp(mask_mpz, mask_mpz, size);
		mpz_sub_ui(mask_mpz, mask_mpz, 1);
	}
	void set_mask(int size)
	{
		mpz_set_ui(mask_mpz, 1);
		mpz_mul_2exp(mask_mpz, mask_mpz, size);
		mpz_sub_ui(mask_mpz, mask_mpz, 1);
	}
	void do_mask()
	{
		mpz_and(mpz, mask_mpz, mpz);
	}
private:
	mpz_t   mpz;
	mpz_t   mask_mpz;
    int32_t size;
};


#endif