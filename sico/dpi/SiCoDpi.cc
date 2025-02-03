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

#include "svdpi.h"
#include "SiCo.h"

//imported from sVerilog
extern "C" void SiCoDpiFinish();
extern "C" void SiCoDpiStop();

//maps SiCo::l9 values to DPI svLogic
svLogic logic9ToSvLogic(SiCo::logic9 l9){
    switch(l9){
        case SiCo::logic9::zero: return sv_0;
        case SiCo::logic9::one: return sv_1;
        case SiCo::logic9::high: return sv_z;
        case SiCo::logic9::unknown: return sv_x;
        default: {
            SiCo::logh(SiCo::warning) << "cannot convert logic9 value to "
            << "DPI svLogic - using 'X'" << std::endl;
            return sv_x;
        }
    }
}

SiCo::logic9 svLogicToLogic9(svLogic l){
    switch(l){
        case sv_0: return SiCo::logic9::zero;
        case sv_1: return SiCo::logic9::one;
        case sv_z: return SiCo::logic9::high;
        case sv_x: return SiCo::logic9::unknown;
        default: {
            SiCo::logh(SiCo::warning) << "cannot convert svLogic '" << l
            << "' to logic9 - using uninitialized" << std::endl;
            return SiCo::logic9::uninitialized;
        }
    }
}

void svLogicVecValToBits(svLogicVecVal *vec, uint32_t size, SiCo::bits &bv)
{
    for(int i = 0; i < size; i++){
        bv.push_back(svLogicToLogic9(svGetBitselLogic(vec, i)));
    }
}

svLogicVecVal * bitsToDpiSvLogicVecVal(SiCo::bits &bits, svLogicVecVal *vec){
    for(int i = 0; i < bits.size(); i++ )
        svPutBitselLogic(vec, i, logic9ToSvLogic(bits[i]));
    return vec;
}

std::map<std::string,SiCo::Player *>    players;
std::map<std::string,SiCo::Recorder *>  recorders;

// gets the value of the channel at the given time
//int channel, simTime now(hi,lo), logic[] buffer, logic sync, simTime deadline
uint32_t SiCoDpiPlayerGet(
    const char *    p_channel,
    long long       p_now,
    svLogicVecVal * p_buffer,
    svLogic *       p_sync,
    long long *     p_deadline
) {
    SiCo::simTime now = p_now;
    std::string channel(p_channel);

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
            SiCo::logh("DPI", SiCo::info) << "detected inShutdown - finish simulator" << std::endl;
            SiCoDpiFinish();
            SiCo::logh("DPI", SiCo::info) << "releasing control" << std::endl;
            return -1;
        }
        try {
            l9bits = player->get(now, &sync, &until, 100);
            break;
        } catch(SiCo::TimedOut &) {
            if(ctrl.getWall() > wallDeadline) {
                wallDeadline = ctrl.getWall() + 2.0;
                SiCo::logh("DPI", SiCo::warning) << "player waiting on channel:"
                    << channel << std::endl;
            }
        }
    }

    //write out values
    bitsToDpiSvLogicVecVal(l9bits, p_buffer);
    *p_sync = logic9ToSvLogic(sync ? SiCo::logic9::one : SiCo::logic9::zero);
    *p_deadline = until;
    return 0;
}

extern "C" uint32_t SiCoDpiPlayerGet32(const char *p_channel, long long p_now, svLogicVecVal *p_buffer, svLogic *p_sync, long long * p_deadline) {
    return SiCoDpiPlayerGet(p_channel, p_now, p_buffer, p_sync, p_deadline);
}
extern "C" uint32_t SiCoDpiPlayerGet128(const char *p_channel, long long p_now, svLogicVecVal *p_buffer, svLogic *p_sync, long long * p_deadline) {
    return SiCoDpiPlayerGet(p_channel, p_now, p_buffer, p_sync, p_deadline);
}
extern "C" uint32_t SiCoDpiPlayerGet1024(const char *p_channel, long long p_now, svLogicVecVal *p_buffer, svLogic *p_sync, long long * p_deadline) {
    return SiCoDpiPlayerGet(p_channel, p_now, p_buffer, p_sync, p_deadline);
}

// gets the next value of the channel 
//int channel, simTime now(hi,lo), logic[] buffer, logic valid
uint32_t SiCoDpiPlayerGetNext(
    const char *    p_channel,
    long long       p_now,
    svLogicVecVal * p_buffer,
    svLogic *       p_valid
) {
    SiCo::simTime now = p_now;
    std::string channel(p_channel);

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
            SiCo::logh("DPI", SiCo::info) << "detected inShutdown - finish simulator" << std::endl;
            SiCoDpiFinish();
            SiCo::logh("DPI", SiCo::info) << "releasing control" << std::endl;
            return -1;
        }
        try {
            l9bits = player->getNext(now, &newVal, 100);
            break;
        } catch(SiCo::TimedOut &) {
            if(ctrl.getWall() > wallDeadline) {
                wallDeadline = ctrl.getWall() + 2.0;
                SiCo::logh("DPI", SiCo::warning) << "player waiting on channel:"
                    << channel << std::endl;
            }
        }
    }
    if(newVal){
        SiCo::logh("DPI", SiCo::debug) << "new value on channel:" << channel << " val:"
            << l9bits.str() << " @:" << now << std::endl;
    }

    //write out values
    bitsToDpiSvLogicVecVal(l9bits, p_buffer);
    *p_valid = logic9ToSvLogic(newVal ? SiCo::logic9::one : SiCo::logic9::zero);
    return 0;
}
extern "C" uint32_t SiCoDpiPlayerGetNext32(const char *p_channel, long long p_now, svLogicVecVal * p_buffer, svLogic *p_valid) {
    SiCoDpiPlayerGetNext(p_channel, p_now, p_buffer, p_valid);
}
extern "C" uint32_t SiCoDpiPlayerGetNext128(const char *p_channel, long long p_now, svLogicVecVal * p_buffer, svLogic *p_valid) {
    SiCoDpiPlayerGetNext(p_channel, p_now, p_buffer, p_valid);
}
extern "C" uint32_t SiCoDpiPlayerGetNext1024(const char *p_channel, long long p_now, svLogicVecVal * p_buffer, svLogic *p_valid) {
    SiCoDpiPlayerGetNext(p_channel, p_now, p_buffer, p_valid);
}

//int channel, simTime now(hi,lo), logic[] buffer, bool force,sync
uint32_t SiCoDpiRecorderPut(
    const char *    p_channel,
    long long       p_now,
    svLogicVecVal * p_buffer,
    uint32_t        p_size,
    uint32_t        p_flags
) {
    SiCo::simTime now = p_now;
    std::string channel(p_channel);
    SiCo::bits val;
    bool sync = p_flags & 0x1;
    bool force = (p_flags >> 1) & 0x1;

    svLogicVecValToBits(p_buffer, p_size, val);

    //push to SiCo recorder
    SiCo::Recorder *rec = recorders[channel];
    if(rec == 0){
        SiCo::logh(SiCo::warning) << "cannot find channel:" << channel
        << " do not put value" << std::endl;
        throw std::runtime_error("cannot find channel:" + channel);
    }
    rec->put(now, val, sync, force);

    return 0;
}
extern "C" uint32_t SiCoDpiRecorderPut32(
    const char *p_channel, long long p_now, svLogicVecVal *p_buffer,
    uint32_t p_size, uint32_t p_flags
) {
    return SiCoDpiRecorderPut(p_channel, p_now, p_buffer, p_size, p_flags);
}
extern "C" uint32_t SiCoDpiRecorderPut128(
    const char *p_channel, long long p_now, svLogicVecVal *p_buffer,
    uint32_t p_size, uint32_t p_flags
) {
    return SiCoDpiRecorderPut(p_channel, p_now, p_buffer, p_size, p_flags);
}
extern "C" uint32_t SiCoDpiRecorderPut1024(
    const char *p_channel, long long p_now, svLogicVecVal *p_buffer,
    uint32_t p_size, uint32_t p_flags
) {
    return SiCoDpiRecorderPut(p_channel, p_now, p_buffer, p_size, p_flags);
}

uint32_t SiCoDpiPlayerInit(
    const char *    p_channel,
    svLogicVecVal * p_reset,
    uint32_t        p_size,
    uint32_t        p_flags
) {
    std::string channel(p_channel);
    SiCo::bits reset;
    bool sync = (p_flags & 1) != 0;
    bool clocked = (p_flags & 2) != 0;

    svLogicVecValToBits(p_reset, p_size, reset);

    SiCo::Player *ply = new SiCo::Player(channel, reset, sync, clocked);
    players[channel] = ply;
    SiCo::logh("DPI", SiCo::info) << "created player channel:" << channel
    << " reset:" << reset.str() << " sync:" << sync << " clocked:" << clocked << std::endl;
    return 0;
}
extern "C" uint32_t SiCoDpiPlayerInit32(const char *p_channel, svLogicVecVal *p_reset, uint32_t p_size, uint32_t p_flags) {
    return SiCoDpiPlayerInit(p_channel, p_reset, p_size, p_flags);
}
extern "C" uint32_t SiCoDpiPlayerInit128(const char *p_channel, svLogicVecVal *p_reset, uint32_t p_size, uint32_t p_flags) {
    return SiCoDpiPlayerInit(p_channel, p_reset, p_size, p_flags);
}
extern "C" uint32_t SiCoDpiPlayerInit1024(const char *p_channel, svLogicVecVal *p_reset, uint32_t p_size, uint32_t p_flags) {
    return SiCoDpiPlayerInit(p_channel, p_reset, p_size, p_flags);
}

uint32_t SiCoDpiRecorderInit(
    const char *    p_channel,
    svLogicVecVal * p_reset,
    uint32_t        p_size,
    uint32_t        p_flags
) {
    std::string channel(p_channel);
    SiCo::bits reset;
    svLogicVecValToBits(p_reset, p_size, reset);
    bool clocked = (p_flags & 2) != 0;

    SiCo::Recorder *rec = new SiCo::Recorder(channel, reset, clocked);
    recorders[channel] = rec;
    SiCo::logh(SiCo::debug) << "created recorder channel:" << channel
    << std::endl;
    return 0;
}
extern "C" uint32_t SiCoDpiRecorderInit32(const char *p_channel, svLogicVecVal *p_reset, uint32_t p_size, uint32_t p_flags) {
    return SiCoDpiRecorderInit(p_channel, p_reset, p_size, p_flags);
}
extern "C" uint32_t SiCoDpiRecorderInit128(const char *p_channel, svLogicVecVal *p_reset, uint32_t p_size, uint32_t p_flags) {
    return SiCoDpiRecorderInit(p_channel, p_reset, p_size, p_flags);
}
extern "C" uint32_t SiCoDpiRecorderInit1024(const char *p_channel, svLogicVecVal *p_reset, uint32_t p_size, uint32_t p_flags) {
    return SiCoDpiRecorderInit(p_channel, p_reset, p_size, p_flags);
}


extern "C" void SiCoDpiSetup(void)
{
    SiCo::logh(SiCo::info) << "setup call" << std::endl;
    SiCo::Control &ctrl = SiCo::Control::getInst();
}

//simTime now

extern "C" uint32_t SiCoDpiTick(long long p_now)
{
    SiCo::simTime now = p_now;

    SiCo::Control &ctrl = SiCo::Control::getInst();

    SiCo::logh("DPI", SiCo::debug) << "DPI tick: @" << SiCo::chomp(now) << std::endl;
    ctrl.reportTime(now);

    if(ctrl.checkBreak(SiCo::BreakType::stop)){
        SiCo::logh("DPI", SiCo::info) << "DPI tick: should Stop now" << std::endl;
        SiCoDpiStop();
    }
    if(ctrl.checkBreak(SiCo::BreakType::finish)){
        SiCo::logh("DPI", SiCo::info) << "DPI tick: should Finish now" << std::endl;
        ctrl.shutdown();
        SiCoDpiFinish();
    }

    return 0;
}


//string configName, value
extern "C" uint32_t SiCoDpiConfigInt64(const char *p_name, uint64_t val) {
    std::string name(p_name);

    SiCo::Control &ctrl = SiCo::Control::getInst();

    if(name == "tickFreq") {
        //get arg 1: tick frequency in Hz
        SiCo::simTime period = SiCo::freq2period(val);
        ctrl.setTickPeriod(period);
    }else if(name == "holdTime") {
        //arg 1: absolute break time
        SiCo::simTime holdTime = val;
        ctrl.addBreak(1, SiCo::BreakType::hold, holdTime, false);
    }else{
        throw std::runtime_error("unknown config in $SiCoDpiConfigInt64 name:" + name);
    }

    return 0;
}

//string configName, value
extern "C" uint32_t SiCoDpiConfigStrStr(const char *p_name, const char *val1, const char *val2) {
    std::string name(p_name);

    SiCo::Control &ctrl = SiCo::Control::getInst();

    if(name == "loglevel") {
        //arg 1: scope
        std::string scope(val1);
        //arg 2: level as string
        std::string level(val2);
        SiCo::severity sev = SiCo::stringToSeverity(level);

        SiCo::setLogLevel(scope, sev);
    }else{
        throw std::runtime_error("unknown config in $SiCoDpiConfigStrStr name:" + name);
    }
    return 0;
}