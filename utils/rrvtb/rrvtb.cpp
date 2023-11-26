#include "rrvtb.hpp"
#include <map>
#include <set>
#include <vector>

typedef map <vpiHandle, set<trigger_cb_func_t>> sig2cb_table_t;
typedef set <vpiHandle> sigs_t;
typedef map <trigger_cb_func_t, set<pair<sigs_t, void*>>> cb2class_sig_table_t;
typedef set <vpiHandle> sig_changed_table_t;
struct timer_cb_entry{
    timer_cb_entry(timer_cb_func_t fn, void *pclass, uint64_t period, bool periodic)
    : fn(fn)
    , pclass(pclass)
    , period(period)
    , periodic(periodic)
    { }
    timer_cb_func_t fn; 
    void *pclass; 
    uint64_t period;
    bool periodic;
};

static sig_changed_table_t sig_changed_table;
static sig2cb_table_t sig2cb_table;
static cb2class_sig_table_t cb2class_sig_table;
static bool wait_sync = false;

const char *scan_plusargs(const char *plusarg)
{
    int argc, diff;
    char **argv, *a;
    const char *p;
    s_vpi_vlog_info vpi_vlog_info;
    if (! vpi_get_vlog_info(&vpi_vlog_info))
        return (char *)0;
    argv = vpi_vlog_info.argv;
    for (argc = 0; argc < vpi_vlog_info.argc; argc++, argv++) 
    {
        a = *argv;
        p = plusarg;
        if (*a != '+') 
            continue;
        a += 1;
        if (strlen(a) < strlen(p)) 
            continue;
        diff = 0;
        while (*p) 
        {
            if (*a != *p) 
            {
                diff = 1;
                break;
            }
            a++; 
            p++;
        }
        if (!diff) return a;
    }
    return (char *)0;
}

void finish()
{
    vpi_control(vpiFinish, 1);
}

uint64_t get_time()
{
    uint64_t ret;
    s_vpi_time current_time;
    current_time.type = vpiSimTime;
    vpi_get_time (NULL, &current_time);
    ret = current_time.high;
    ret <<= 32;
    ret |= current_time.low;
    return ret;
}

PLI_INT32 tb_end_of_step_cb (p_cb_data cb_data_p)
{
    vector<Bits> *parg = NULL;
    s_vpi_value value_s;
    set <trigger_cb_func_t> called_func_table;

    for (auto pchanged_sig = sig_changed_table.begin(); pchanged_sig != sig_changed_table.end(); pchanged_sig++) // Traverse all signals that have changed
    {
        // For each signal that has changed, call the callback function which listened on it
        for (auto pfunc = sig2cb_table[*pchanged_sig].begin(); pfunc != sig2cb_table[*pchanged_sig].end(); pfunc++)
        {
            if (called_func_table.find(*pfunc) != called_func_table.end()) 
                continue;

            for (auto pclass_sig = cb2class_sig_table[*pfunc].begin(); pclass_sig != cb2class_sig_table[*pfunc].end(); pclass_sig++)
            {
                bool need_to_call = false;
                for (auto psig = pclass_sig->first.begin(); psig != pclass_sig->first.end(); psig++)
                {
                    if (sig_changed_table.find(*psig) != sig_changed_table.end())
                    {
                        need_to_call = true;
                        break;
                    }
                }
                if (need_to_call)
                {
                    for (auto psig = pclass_sig->first.begin(); psig != pclass_sig->first.end(); psig++)               // For each argument of a callback function, we first read its value using VPI and create corresponding bits class then call the function
                    {
                        value_s.format = vpiBinStrVal;
                        vpi_get_value(*psig, &value_s);
                        if (!parg) parg = new vector<Bits>(1, Bits(value_s.value.str, 2, vpi_get(vpiSize, *psig)));
                        else parg->push_back(Bits(value_s.value.str, 2, vpi_get(vpiSize, *psig)));
                    }
                    (*pfunc)(pclass_sig->second, *parg);
                    delete parg;
                    parg = nullptr;
                }
            }
            called_func_table.insert(*pfunc);
        }
    }
    wait_sync = false;
    sig_changed_table.clear();
}

PLI_INT32 tb_value_change_cb (p_cb_data cb_data_p)
{
    vpiHandle cb_h;
    s_cb_data cb_data_s;
    s_vpi_time time_s;

    if (!wait_sync)
    {
        time_s.type = vpiSimTime;
        time_s.high = 0;
        time_s.low = 1;
        cb_data_s.reason = cbNextSimTime;//cbReadWriteSynch;//cbReadOnlySynch;
        cb_data_s.user_data = NULL;
        cb_data_s.cb_rtn = tb_end_of_step_cb;
        cb_data_s.obj = NULL;
        cb_data_s.time = &time_s;
        cb_data_s.value = NULL;
        cb_h = vpi_register_cb(&cb_data_s);
        vpi_free_object(cb_h); 

        wait_sync = true;
    }
    sig_changed_table.insert(cb_data_p->obj);
}


void register_signal_cb(trigger_cb_func_t fn, void *pclass, initializer_list<const char*> args)
{
    bool            need_register = false;
    vpiHandle       trig_h, cb_h;
    s_vpi_value     value_s;
    s_vpi_time      time_s;
    s_cb_data       cb_data_s;
    sigs_t          sigs;

    for (auto parg = args.begin(); parg != args.end(); parg++)
    {
        if (!(trig_h = vpi_handle_by_name((PLI_BYTE8 *)*parg, 0)))
        {
            ERROR("The signal \"%s\" is not exist!\n", *parg);
        }
        need_register = false;
        if (sig2cb_table.find(trig_h) == sig2cb_table.end()) need_register = true;
        sig2cb_table[trig_h].insert(fn);
        sigs.insert(trig_h);
        if (need_register)
        {
            time_s.type         = vpiSuppressTime;
            cb_data_s.reason    = cbValueChange;
            cb_data_s.cb_rtn    = tb_value_change_cb;
            cb_data_s.time      = &time_s;
            cb_data_s.value     = &value_s;
            cb_data_s.user_data = NULL;
            cb_data_s.obj       = trig_h;
            value_s.format      = vpiBinStrVal;
            cb_h = vpi_register_cb(&cb_data_s);
            vpi_free_object(cb_h);
        }
    }
    cb2class_sig_table[fn].insert(make_pair(sigs, pclass));
}


extern "C" PLI_INT32 tb_setup_cb(struct t_cb_data *data)
{
    vpiHandle       trig_h, cb_h;
    s_vpi_value     value_s;
    s_vpi_time      time_s;
    s_cb_data       cb_data_s;
    sig2cb_table_t::iterator iter;
    
    INFO("section start: %x\nsection end: %x\n", &__trigger_ptr_section_start, &__trigger_ptr_section_end);
    for (trig_record_t *p = (trig_record_t *)&__trigger_ptr_section_start; p < (trig_record_t *)&__trigger_ptr_section_end; p++)
    {
        sigs_t          sigs;
        INFO("func addr: %x, vector addr: %x\n", p->cb_func, p->tri_sigs);
        for (int i = 0; i < p->tri_sigs->size(); i++)
        {
            INFO("%s, ", p->tri_sigs->at(i).c_str());
            if (!(trig_h = vpi_handle_by_name((PLI_BYTE8 *)p->tri_sigs->at(i).c_str(), 0)))
            {
                ERROR("The signal \"%s\" is not exist!\n", p->tri_sigs->at(i).c_str());
                exit(1);
            }
            sig2cb_table[trig_h].insert(p->cb_func);
            sigs.insert(trig_h);
        }
        cb2class_sig_table[p->cb_func].insert(make_pair(sigs, nullptr));
        
        for (iter = sig2cb_table.begin(); iter != sig2cb_table.end(); iter++)
        {
            time_s.type         = vpiSuppressTime;
            cb_data_s.reason    = cbValueChange;
            cb_data_s.cb_rtn    = tb_value_change_cb;
            cb_data_s.time      = &time_s;
            cb_data_s.value     = &value_s;
            cb_data_s.user_data = NULL;
            cb_data_s.obj       = iter->first;
            value_s.format      = vpiBinStrVal;
            cb_h = vpi_register_cb(&cb_data_s);
            vpi_free_object(cb_h);
        }
    }

    // call initial functions
    for (initial_func_t* p = (initial_func_t*)&__init_func_ptr_section_start; p < (initial_func_t*)&__init_func_ptr_section_end; p++)
    {
        (*p)();
    }
}

extern "C" void tb_init_cb()
{
    const char      *file_name;
    vpiHandle       cb_h;
    s_cb_data       cb_data_s;

    INFO("start!\n");

    if (file_name = scan_plusargs("image="))
    {
        INFO("image: %s, addr: %x\n", file_name, file_name);
    }
    else
    {
        INFO("no image input!\n");
    }

    cb_data_s.reason    = cbStartOfSimulation;
    cb_data_s.cb_rtn    = tb_setup_cb;
    cb_data_s.time      = NULL;
    cb_data_s.value     = NULL;
    cb_data_s.user_data = NULL;
    cb_data_s.obj       = NULL;
    cb_h = vpi_register_cb(&cb_data_s);
    vpi_free_object(cb_h);
}

extern "C" PLI_INT32 tb_timer_cb(struct t_cb_data *data)
{
    s_cb_data cb_data_s;
    s_vpi_time vpi_time_s;
    timer_cb_entry *cb_entry = (timer_cb_entry *)data->user_data;

    cb_entry->fn(cb_entry->pclass);
    if (cb_entry->periodic)
    {
        vpi_time_s.type = vpiSimTime;
        vpi_time_s.high = cb_entry->period >> 32;
        vpi_time_s.low  = cb_entry->period & 0xffffffff;

        cb_data_s.reason    = cbAfterDelay;
        cb_data_s.cb_rtn    = tb_timer_cb;
        cb_data_s.obj       = NULL;
        cb_data_s.time      = &vpi_time_s;
        cb_data_s.value     = NULL;
        cb_data_s.user_data = data->user_data;

        vpiHandle new_hdl = vpi_register_cb(&cb_data_s);
        vpi_free_object(new_hdl); 
    }
    else 
    {
        delete data->user_data;
    }
}

void register_timer_cb(timer_cb_func_t fn, void *pclass, uint64_t period, bool periodic)
{
    s_cb_data cb_data_s;
    s_vpi_time vpi_time_s;

    vpi_time_s.type = vpiSimTime;
    vpi_time_s.high = period >> 32;
    vpi_time_s.low  = period & 0xffffffff;

    cb_data_s.reason    = cbAfterDelay;
    cb_data_s.cb_rtn    = tb_timer_cb;
    cb_data_s.obj       = NULL;
    cb_data_s.time      = &vpi_time_s;
    cb_data_s.value     = NULL;
    cb_data_s.user_data = (PLI_BYTE8 *)new timer_cb_entry(fn, pclass, period, periodic);

    vpiHandle new_hdl = vpi_register_cb(&cb_data_s);
    vpi_free_object(new_hdl); 
}
