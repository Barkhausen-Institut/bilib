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
#include "SiCo.h"

//maps SiCo::l9 values to VPI vpiBinStrVal characters
char logic9toVpiBinStrVal(SiCo::logic9 l9){
    switch(l9){
        case SiCo::logic9::zero: return '0';
        case SiCo::logic9::one: return '1';
        case SiCo::logic9::high: return 'Z';
        case SiCo::logic9::unknown: return 'X';
        default: {
            SiCo::logh(SiCo::warning) << "cannot convert logic9 value:" << l9
            << " to vpiBinStrVal - using 'X'" << std::endl;
            return 'X';
        }
    }
}

SiCo::logic9 vpiBinStrValtologic9(char c){
    switch(c){
        case '0': return SiCo::logic9::zero;
        case '1': return SiCo::logic9::one;
        case 'Z': return SiCo::logic9::high;
        case 'z': return SiCo::logic9::high;
        case 'X': return SiCo::logic9::unknown;
        case 'x': return SiCo::logic9::unknown;
        default: {
            SiCo::logh(SiCo::warning) << "cannot convert vpiBinStrVal '" << c
            << "' to logic9 - using uninitialized" << std::endl;
            return SiCo::logic9::uninitialized;
        }
    }
}

SiCo::bits vpiBinStrToBits(std::string &binstr){
    SiCo::bits bv;
    for(int i = binstr.length()-1; i >= 0; i--)
        bv.push_back(vpiBinStrValtologic9(binstr[i]));
    return bv;
}

std::string bitsToVpiBinStr(SiCo::bits &bits){
    std::string binstr;
    for(int i = bits.size()-1; i >= 0; i-- )
        binstr.push_back(logic9toVpiBinStrVal(bits[i]));
    return binstr;
}

SiCo::simTime vpiVal2simTime(p_vpi_value v) {
    uint32_t *raw = (uint32_t *)&(v->value.integer);
    return (SiCo::simTime)*raw;
}

void simTime2vpiVal(p_vpi_value v, SiCo::simTime tme) {
    uint32_t *raw = (uint32_t *)&(v->value.integer);
    *raw = (uint32_t)tme;
}

typedef void (voidfn)(void);
typedef PLI_INT32 (vpicall)(PLI_BYTE8 *);
typedef uint32_t FinishBreak;

void    setup(void);
vpicall SiCoVpiPlayerInit;
vpicall SiCoVpiPlayerGetNext;
vpicall SiCoVpiPlayerGet;
vpicall SiCoVpiRecorderInit;
vpicall SiCoVpiRecorderPut;
vpicall SiCoVpiTick;
vpicall SiCoVpiConfig;

void registerCall(vpicall *call, const char *name){
  s_vpi_systf_data task;
  task.type = vpiSysTask;
  task.tfname = reinterpret_cast<PLI_BYTE8*>(const_cast<char*>(name));
  task.calltf = call;
  task.compiletf = 0;
  vpi_register_systf(&task);
}

void registerCalls(void) {
    registerCall(SiCoVpiPlayerGet, "$SiCoVpiPlayerGet");
    registerCall(SiCoVpiPlayerGetNext, "$SiCoVpiPlayerGetNext");
    registerCall(SiCoVpiPlayerInit, "$SiCoVpiPlayerInit");
    registerCall(SiCoVpiRecorderInit, "$SiCoVpiRecorderInit");
    registerCall(SiCoVpiRecorderPut, "$SiCoVpiRecorderPut");
    registerCall(SiCoVpiTick, "$SiCoVpiTick");
    registerCall(SiCoVpiConfig, "$SiCoVpiConfig");
}

voidfn * vlog_startup_routines[] = {
    registerCalls,
    setup,
    0
};

std::map<std::string,SiCo::Player *> players;
std::map<std::string,SiCo::Recorder *> recorders;


// gets the value of the channel at the given time
//string channel, simTime now(hi,lo), logic[] buffer, logic sync, simTime deadline
PLI_INT32 SiCoVpiPlayerGet(PLI_BYTE8 *)
{
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiPlayerGet" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: channel
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string channel(vpiValue.value.str); //do we have to copy?

    //get arg 1&2: now
    SiCo::simTime now;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now = vpiVal2simTime(&vpiValue) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now |= vpiVal2simTime(&vpiValue);

    SiCo::Control & ctrl = SiCo::Control::getInst();

    //get new value from player
    SiCo::simTime   until;
    bool            sync;
    SiCo::Player *  player = players[channel];
    SiCo::bits      l9bits;
    double          wallDeadline = ctrl.getWall() + 2.0;
    if(player == 0){
        SiCo::logh(SiCo::fatal) << "cannot find channel:" << channel
        << " cannot get a value" << std::endl;
        throw std::runtime_error("cannot find channel:" + channel);
    }
    while(true){
        ctrl.waitHold();
        if(ctrl.isShutdown()){
            SiCo::logh("VPI", SiCo::info) << "detected inShutdown - finish simulator" << std::endl;
            vpi_control(vpiFinish);
            SiCo::logh("VPI", SiCo::info) << "releasing control" << std::endl;
            return -1;
        }
        try {
            l9bits = player->get(now, &sync, &until, 100);
            break;
        } catch(SiCo::TimedOut &) {
            if(wallDeadline != 0.0 && ctrl.getWall() > wallDeadline) {
                wallDeadline = 0.0;
                SiCo::logh("VPI", SiCo::warning) << "player waiting on channel:"
                    << channel << std::endl;
            }
        }
    }

    //convert to vpiBinStrVal
    std::string binstr = bitsToVpiBinStr(l9bits);
    SiCo::logh("VPI", SiCo::trace) << "player get @" << SiCo::chomp(now)
    << " sync:" << sync << " until:"
    << SiCo::chomp(until) << " value:" << binstr << std::endl; //*/

    //set arg 3: buffer
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiBinStrVal;
    vpiValue.value.str = (char *)binstr.c_str();
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);

    //set arg 4: sync 
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpiValue.value.integer = sync;
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);

    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    simTime2vpiVal(&vpiValue, until >> 32);
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    simTime2vpiVal(&vpiValue, until);
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);

    vpi_free_object(vpiArgs);
    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiPlayerGet" << std::endl;
    return 0;
}

// gets the next value of the channel 
//int channel, simTime now(hi,lo), logic[] buffer, logic valid
PLI_INT32 SiCoVpiPlayerGetNext(PLI_BYTE8 *)
{
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiPlayerGetNext" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: channel
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string channel(vpiValue.value.str); //do we have to copy?

    //get arg 1&2: now
    SiCo::simTime now;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now = vpiVal2simTime(&vpiValue) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now |= vpiVal2simTime(&vpiValue);

    //get new value from player
    bool            newVal;
    SiCo::Player *  player = players[channel];
    SiCo::bits      l9bits;
    SiCo::Control & ctrl = SiCo::Control::getInst();
    double          wallDeadline = ctrl.getWall() + 2.0;
    if(player == 0){
        SiCo::logh(SiCo::fatal) << "cannot find channel:" << channel
        << " cannot get a value" << std::endl;
        throw std::runtime_error("cannot find channel:" + channel);
    }
    while(true){
        ctrl.waitHold();
        if(ctrl.isShutdown()){
            SiCo::logh("VPI", SiCo::info) << "detected inShutdown - finish simulator" << std::endl;
            vpi_control(vpiFinish);
            SiCo::logh("VPI", SiCo::info) << "releasing control" << std::endl;
            return -1;
        }
        try {
            l9bits = player->getNext(now, &newVal, 100);
            break;
        } catch(SiCo::TimedOut &) {
            if(ctrl.getWall() > wallDeadline) {
                wallDeadline = ctrl.getWall() + 2.0;
                SiCo::logh("VPI", SiCo::warning) << "player waiting on channel:"
                    << channel << std::endl;
            }
        }
    }

    //convert to vpiBinStrVal
    std::string binstr = bitsToVpiBinStr(l9bits);
    if(newVal){
        SiCo::logh("VPI", SiCo::debug) << "player get next @" << SiCo::chomp(now)
        << " value:" << binstr << std::endl;
    }

    //set arg 3: buffer
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiBinStrVal;
    vpiValue.value.str = (char *)binstr.c_str();
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);

    //set arg 4: valid 
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpiValue.value.integer = newVal;
    vpi_put_value(vpiArg, &vpiValue, NULL, vpiNoDelay);

    vpi_free_object(vpiArgs);
    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiPlayerGetNext" << std::endl;
    return 0;
}

//int channel, simTime now(hi,lo), logic[] buffer, flags  force,sync
PLI_INT32 SiCoVpiRecorderPut(PLI_BYTE8 *)
{
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiRecorderPut" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: channel
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string channel(vpiValue.value.str); //do we have to copy?

    //get arg 1&2: now
    SiCo::simTime now;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now = vpiVal2simTime(&vpiValue) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now |= vpiVal2simTime(&vpiValue);

    //set arg 3: buffer
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiBinStrVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string binstr(vpiValue.value.str);

    //get arg 4: force,sync
    bool sync, force;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    sync = (bool)(vpiValue.value.integer & 1);
    force = (bool)((vpiValue.value.integer >> 1) & 1);

    //convert to bits
    SiCo::bits binbits = vpiBinStrToBits(binstr);

    //push to SiCo recorder
    SiCo::Recorder *rec = recorders[channel];
    if(rec == 0){
        SiCo::logh(SiCo::fatal) << "cannot find channel:" << channel
        << " do not put value" << std::endl;
        throw std::runtime_error("cannot find channel:" + channel);
    }
    rec->put(now, binbits, sync, force);

    vpi_free_object(vpiArgs);

    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiRecorderPut" << std::endl;
    return 0;
}

//int channel, logic[] reset, int flags(clocked,sync)
PLI_INT32 SiCoVpiPlayerInit(PLI_BYTE8 *)
{
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiPlayerInit" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: channel
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string channel(vpiValue.value.str);

    //get arg 1: reset
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiBinStrVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string binstr(vpiValue.value.str);

    //convert to bits
    SiCo::bits l9val = vpiBinStrToBits(binstr);

    //get arg 2: flags
    bool sync;
    bool clocked;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    sync = (vpiValue.value.integer & 1) != 0;
    clocked = (vpiValue.value.integer & 2) != 0;
    vpi_free_object(vpiArgs);

    //create player
    SiCo::Player *ply = new SiCo::Player(channel, l9val, sync, clocked);
    players[channel] = ply;
    SiCo::logh("VPI", SiCo::info) << "created player channel:" << channel
    << " reset:" << l9val.str() << " sync:" << sync << " clocked:" << clocked << std::endl;
    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiPlayerInit" << std::endl;
    return 0;
}

//int channel
PLI_INT32 SiCoVpiRecorderInit(PLI_BYTE8 *)
{
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiRecorderInit" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: channel
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string channel(vpiValue.value.str);

    //get arg 1: reset
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiBinStrVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string binstr(vpiValue.value.str);

    //convert to bits
    SiCo::bits l9val = vpiBinStrToBits(binstr);

    //get arg 2: flags
    bool clocked;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    clocked = ((vpiValue.value.integer & 2) != 0);
    vpi_free_object(vpiArgs);

    //create player
    SiCo::Recorder *rec = new SiCo::Recorder(channel, l9val, clocked);
    recorders[channel] = rec;
    SiCo::logh("VPI", SiCo::info) << "created recorder channel:" << channel
    << std::endl;
    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiRecorderInit" << std::endl;
    return 0;
}

void setup(void)
{
    SiCo::logh("VPI", SiCo::trace) << "setup - force Control creation" << std::endl;
    SiCo::Control &ctrl = SiCo::Control::getInst();
    ctrl.profile(); //shut up the compiler warning that ctrl is not used
}

//simTime now

PLI_INT32 SiCoVpiTick(PLI_BYTE8 *) {
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiTick" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0&1: now
    SiCo::simTime now;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    now = vpiVal2simTime(&vpiValue) << 32;
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiIntVal;
    vpi_get_value(vpiArg, &vpiValue);
    //vpi_get_value(vpiArg, &vpiValue);
    now |= vpiVal2simTime(&vpiValue);

    vpi_free_object(vpiArgs);

    SiCo::Control &ctrl = SiCo::Control::getInst();

    ctrl.reportTime(now);

    ctrl.waitHold();

    if(ctrl.checkBreak(SiCo::BreakType::stop)){
        SiCo::logh("VPI", SiCo::info) << "VPI tick: should Stop now" << std::endl;
        vpi_control(vpiStop);
    }
    if(ctrl.checkBreak(SiCo::BreakType::finish)){
        SiCo::logh("VPI", SiCo::info) << "VPI tick: should Finish now" << std::endl;
        ctrl.shutdown();
        vpi_control(vpiFinish);
    }
    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiTick" << std::endl;

    return 0;
}

//string configName, value
PLI_INT32 SiCoVpiConfig(PLI_BYTE8 *) {
    vpiHandle vpiSys, vpiArgs, vpiArg;
    t_vpi_value vpiValue;

    SiCo::logh("VPI", SiCo::trace) << "SiCoVpiConfig" << std::endl;

    //init VPI system
    vpiSys = vpi_handle(vpiSysTfCall, NULL);
    vpiArgs = vpi_iterate(vpiArgument, vpiSys);

    //get arg 0: name
    vpiArg = vpi_scan(vpiArgs);
    vpiValue.format = vpiStringVal;
    vpi_get_value(vpiArg, &vpiValue);
    std::string name(vpiValue.value.str);

    SiCo::Control &ctrl = SiCo::Control::getInst();

    SiCo::logh("VPI", SiCo::debug) << "SiCoVpiConfig name:" << name << std::endl;

    if(name == "tickFreq") {
        //get arg 1: tick frequency in Hz
        SiCo::simTime period;
        vpiArg = vpi_scan(vpiArgs);
        vpiValue.format = vpiIntVal;
        vpi_get_value(vpiArg, &vpiValue);
        period = SiCo::freq2period(vpiVal2simTime(&vpiValue));

        ctrl.setTickPeriod(period);
    }else if(name == "holdTime") {
        //get arg 1: hold time
        SiCo::simTime holdTime;
        vpiArg = vpi_scan(vpiArgs);
        vpiValue.format = vpiIntVal;
        vpi_get_value(vpiArg, &vpiValue);
        holdTime = vpiVal2simTime(&vpiValue);

        ctrl.addBreak(1, SiCo::BreakType::hold, holdTime, false);
    } else if(name == "loglevel") {
        //get arg 1: scope
        vpiArg = vpi_scan(vpiArgs);
        vpiValue.format = vpiStringVal;
        vpi_get_value(vpiArg, &vpiValue);
        std::string scope(vpiValue.value.str);
        //get arg 2: level
        vpiArg = vpi_scan(vpiArgs);
        vpiValue.format = vpiStringVal;
        vpi_get_value(vpiArg, &vpiValue);
        std::string level(vpiValue.value.str);

        SiCo::severity sev = SiCo::stringToSeverity(level);
        SiCo::setLogLevel(scope, sev);
    } else {
        throw std::runtime_error("unknown config in $SiCoVpiConfig name:" + name);
    }

    vpi_free_object(vpiArgs);

    SiCo::logh("VPI", SiCo::trace) << "/SiCoVpiConfig" << std::endl;
    return 0;
}
