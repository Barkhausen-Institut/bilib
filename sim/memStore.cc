////    ////////////    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
////    ////////////    
////                    This source describes Open Hardware and is licensed under the
////                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
////////////    ////    
////////////    ////    
////    ////    ////    
////    ////    ////    
////////////            Authors:
////////////            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)

#include "vpi_user.h"
#include <iostream>
#include <map>

typedef void (voidfn)(void);
typedef PLI_INT32 (vpicall)(PLI_BYTE8 *);
typedef uint32_t FinishBreak;

void    memStoreSetup(void);
vpicall memStoreCreate;
vpicall memStoreGet;
vpicall memStorePut;

void registerCall(vpicall *call, const char *name)
{
  s_vpi_systf_data task;
  task.type = vpiSysTask;
  task.tfname = reinterpret_cast<PLI_BYTE8*>(const_cast<char*>(name));
  task.calltf = call;
  task.compiletf = 0;
  vpi_register_systf(&task);
}

void memStoreRegisterCalls(void) {
    registerCall(memStoreCreate, "$memStoreCreate");
    registerCall(memStoreGet, "$memStoreGet");
    registerCall(memStorePut, "$memStorePut");
}

voidfn * vlog_startup_routines[] = {
    memStoreRegisterCalls,
    memStoreSetup,
    0
};

std::map<std::string, std::map<uint64_t, uint64_t>> memStore;

void memStoreSetup(void) {
    std::cout << "memStoreInit" << std::endl;
}

// creates a new store
// string name
PLI_INT32 memStoreCreate(PLI_BYTE8 *) {
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;


    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: name
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string name(vpiValue.value.str); //do we have to copy?

    std::cout << "memStoreCreate:" << name << std::endl;

    vpi_free_object(vpiArgs);
    return 0;
}

//string store, addr[hi], addr[lo], data[hi], data[lo] 
PLI_INT32 memStoreGet(PLI_BYTE8 *) {
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: name
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string name(vpiValue.value.str);

    //get arg 1&2: address
    uint64_t addr;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    addr = ((uint64_t)vpiValue.value.integer) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    addr |= vpiValue.value.integer;

    uint64_t val = memStore[name][addr];

    //std::cout << "store[" << name << "][0x" << std::hex << addr << "] => " << val << std::endl;

    //put arg 3&4: data
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpiValue.value.integer = (uint32_t)(val >> 32);
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpiValue.value.integer = (uint32_t)val;
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);

    vpi_free_object(vpiArgs);
    return 0;
}

//string store, addr[hi], addr[lo], data[hi], data[lo] 
PLI_INT32 memStorePut(PLI_BYTE8 *) {
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: name
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string name(vpiValue.value.str);

    //get arg 1&2: address
    uint64_t addr;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    addr = ((uint64_t)vpiValue.value.integer) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    addr |= vpiValue.value.integer;

    //get arg 3&4: data
    uint64_t val;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    val = ((uint64_t)vpiValue.value.integer) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    val |= vpiValue.value.integer;

    memStore[name][addr] = val;

    //std::cout << "store[" << name << "][0x" << std::hex << addr << "] <= " << val << std::endl;

    vpi_free_object(vpiArgs);
    return 0;
}