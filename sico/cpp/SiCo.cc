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

#include <string>
#include <queue>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <unistd.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <signal.h>
#include <map>
#include <poll.h>
#include <mutex>
#include <condition_variable>
#include "SiCo.h"

namespace SiCo {

const char *LOG_PREFIX = "SiCo";
const char *LOG_CRESET =    "\033[0m";
const char *LOG_CRED =      "\033[31m";
const char *LOG_CYELLOW =   "\033[33m";
const char *LOG_CGREEN =    "\033[32m";
const char *LOG_CBLUE =     "\033[34m";
const char *LOG_MAGENTA =   "\033[35m";

uint8_t get8(const char *data, int index){
    return data[index];
}

uint16_t get16(const char *data, int index){
    return ntohs(*(uint16_t *)(data + index));
}

uint32_t get32(const char *data, int index){
    return ntohl(*(uint32_t *)(data + index));
}

uint64_t get64(const char *data, int index){
    return be64toh(*(uint64_t *)(data + index));
}

simTime getSimTime(const char *data, int index, bool &cycles){
    simTime time = get64(data, index);
    cycles = get8(data, index + 9) != 0;
    return time;
}

void put8(char *data, int index, uint8_t val){
    data[index] = val;
}

void put16(char *data, int index, uint16_t val){
    *(uint16_t *)(data + index) = htons(val);
}

void put32(char *data, int index, uint32_t val){
    *(uint32_t *)(data + index) = htonl(val);
}

void put64(char *data, int index, uint64_t val){
    *(uint64_t *)(data + index) = htobe64(val);
}

void putSimTime(char *data, int index, simTime time, bool cycles){
    put64(data, index, time);
    put8(data, index + 8, cycles);
}

std::string chomp(uint64_t num, bool cycles){
    if(cycles){
        std::ostringstream msg;
        msg << num << "c";
        return msg.str();
    }
                //  s  m  u  n  p
    uint64_t mask = 1000000000000ull;
    std::ostringstream msg;
    bool active = false;
    const char *unit[] = {"s", "m", "u", "n", "p"};
    for(int i = 0; i < 5; i++){
        uint64_t val = num / mask;
        if(active){
            msg.fill('0');
            msg << std::setw(3) << val << unit[i];
        }else if(val != 0){
            active = true;
            msg << val << unit[i];
        }
        num %= mask;
        mask /= 1000;
    }
    return msg.str();
}

class null_out_buf : public std::streambuf {
    public:
        virtual std::streamsize xsputn (const char * s, std::streamsize n) {
            (void)s; //silence unused warning
            return n;
        }
        virtual int overflow (int c) {
            (void)c; //silence unused warning
            return 1;
        }
};

class null_out_stream : public std::ostream {
    public:
        null_out_stream() : std::ostream (&buf) {}
    private:
        null_out_buf buf;
};


std::map<std::string, severity> logLevels;

null_out_stream logDummyOut;

std::ostream & logh(severity s){
    return logh("", s);
}

std::ostream & logh(const std::string &scope, severity s){
    //SiCo @xxxxx INFO  yyyyyyyy:  Hallo logging
    //SiCo @  xxx ERROR yyyyyy:  Problem Logging
    //check if logging is enabled
    severity level = getLogLevel(scope);
    std::ostream &out = s < level ? logDummyOut : std::cout;
    //output
    out << LOG_PREFIX << " @";
    out << std::setw(14) << chomp(Control::getClock());
    out << " ";
    switch(s){
        case severity::trace:
            out << LOG_CGREEN << "TRACE" << LOG_CRESET;
            break;
        case severity::debug:
            out << LOG_CBLUE << "DEBUG" << LOG_CRESET;
            break;
        case severity::info:
            out << "INFO ";
            break;
        case severity::warning:
            out << LOG_CYELLOW << "WARN " << LOG_CRESET;
            break;
        case severity::error:
            out << LOG_CRED << "ERROR" << LOG_CRESET;
            break;
        case severity::fatal:
            out << LOG_MAGENTA << "FATAL" << LOG_CRESET;
            break;
    }
    out << " " << scope << ":  ";
    return out;
}

severity getLogLevel(const std::string &scope) {
    severity curr = info;
    size_t maxLen = 0;
    for(std::map<std::string, severity>::iterator it=logLevels.begin(); it != logLevels.end(); it++) {
        int pos = scope.rfind(it->first, 0);
        if(pos == 0){
            if(it->first.length() >= maxLen){
                curr = it->second;
                maxLen = it->first.length();
            }
        }
    }
    return curr;
}

void setLogLevel(const std::string &scope, severity level) {
    logLevels[scope] = level;
}

severity stringToSeverity(const std::string &str) {
    if(str == "trace" || str == "TRACE")
        return trace;
    if(str == "debug" || str == "DEBUG")
        return debug;
    if(str == "info" || str == "INFO")
        return info;
    if(str == "warning" || str == "WARNING" || str == "warn" || str == "WARN")
        return warning;
    if(str == "error" || str == "ERROR")
        return error;
    if(str == "fatal" || str == "FATAL")
        return fatal;
    return info;
}

Message::Message(const char *raw) {
    int msgLength = get32(raw, 0);  //0  message length
    int chanLength = get32(raw, 4); //4  chan string length
    dataLength = msgLength - 8 - chanLength;
    //channel
    channel = std::string(raw + 8, chanLength);
    //data
    if(dataLength != 0) {
        data = new char[dataLength];
        mempcpy(data, raw + 8 + chanLength, dataLength);
    }else
        data = NULL;
    //
    logh("message", trace) << "decoded message len:" << msgLength
        << " channel:" << channel << std::endl;
}

Message::Message(std::string chan, int length) :
    channel(chan),
    dataLength(length)
{
    data = new char[length];
}

Message::Message(int length) :
    dataLength(length)
{
    data = new char[length];
}

Message::Message(Message && o){
    channel = o.channel;
    dataLength = o.dataLength;
    data = o.data;
    o.data = NULL; //mark as moved
}

Message::~Message() {
    if(data)
        delete data;
}

void Message::pack(char *buffer) {
    put32(buffer, 0, getSize());        //0 message length
    int chanLength = channel.length();
    put32(buffer, 4, chanLength);       //4 chan string length
    memcpy(buffer + 8, channel.c_str(), chanLength);
    memcpy(buffer + 8 + chanLength, data, dataLength);         
}

MessageQueue::MessageQueue() :
    queue(),
    queueMutex(),
    availCond()
{}

void MessageQueue::push(Message &msg)
{
    //aquire lock
    std::unique_lock<std::mutex> lock(queueMutex); 
    //add message to queue
    queue.push(std::move(msg)); 
    //in case someone is waiting for a message, send wake call
    availCond.notify_one(); 
}

Message MessageQueue::pop()
{
    // acquire lock 
    std::unique_lock<std::mutex> lock(queueMutex); 
    // wait until queue is not empty 
    availCond.wait(lock, [this]() { return !queue.empty(); }); 
    // retrieve item
    Message m = std::move(queue.front());
    queue.pop(); 
    // return item 
    return m;  
}

bool MessageQueue::wait(int timeout) {
    // acquire lock 
    std::unique_lock<std::mutex> lock(queueMutex); 
    // wait until queue is not empty 
    if(timeout == 0)
        availCond.wait(lock, [this]() { return !queue.empty(); }); 
    else
        availCond.wait_for(lock, std::chrono::milliseconds(timeout), [this]() { return !queue.empty(); }); 
    // return item 
    return !queue.empty();  
}

bool MessageQueue::empty() {
    std::unique_lock<std::mutex> lock(queueMutex); 
    return queue.empty();
}

int createSocket()
{
    //create socket address
    struct sockaddr_un sockAddress;
    sockAddress.sun_family = AF_UNIX;
    strcpy(sockAddress.sun_path, "SiCo.sock");
    //remote old socket file
    logh("connection", info) << "start listening" << std::endl;
    if(sockAddress.sun_family == AF_UNIX)
        unlink(sockAddress.sun_path);
    //create new socket
    int listenSocket = socket(sockAddress.sun_family, SOCK_STREAM, 0);
    if(listenSocket < 0) {
        logh("connection", error) << "Failt to open socket" << std::endl;
        return 0;
    }
    if(bind(listenSocket, (const struct sockaddr *)&sockAddress, sizeof(sockAddress)) == -1){
        logh("connection", error) << "Failt to bind:" << errno << " - " << strerror(errno) << std::endl;
        return 0;
    }
    if(listen(listenSocket, 1) == -1) {
        logh("connection", error) << "Failt to listen:" << errno << " - " << strerror(errno) <<std::endl;
        return 0;
    }
    logh("connection", info) << "listening on:" << sockAddress.sun_path <<std::endl;
    return listenSocket;
}

int acceptConnection(int sock)
{
    struct sockaddr addr;
    socklen_t alen;
    alen = sizeof(struct sockaddr);
    int fd = accept(sock, &addr, &alen);
    if(fd == -1){
        logh("connection", error) << "cannot accept:" << errno << " - " << strerror(errno) <<std::endl;
        return 0;
    }
    logh("connection", info) << "new connection" <<std::endl;
    return fd;
}

Connection::Connection() {
    running = true;
    draining = false;
    connectedSocket = 0;
    connectedEst = 0;
    connectedTerm = 0;
    connThread = std::thread(&Connection::runConn, this);
    sendThread = std::thread(&Connection::runSend, this);
    recvThread = std::thread(&Connection::runRecv, this);
}

Message Connection::pop() {
    return recvQueue.pop();
}

void Connection::push(Message &msg) {
    sendQueue.push(msg);
}

void Connection::runConn() {
    std::unique_lock<std::mutex> llock(connectedMutex, std::defer_lock);
    int listenSocket = 0;
    while(listenSocket == 0){
        listenSocket = createSocket();
        if(listenSocket == 0){
            logh("connection", info) << "retrying listen on Socket in 10 seconds" << std::endl;
            sleep(10);
        }
    }
    while(running){
        //accept connection
        llock.lock();
        connectedSocket = acceptConnection(listenSocket);
        connectedEst += 1;
        llock.unlock();
        connectedCond.notify_all();
        llock.lock();
        connectedCond.wait(llock, [this]() { return connectedTerm >= connectedEst; });
        close(connectedSocket);
        llock.unlock();
    }
    close(connectedSocket);
}

void Connection::runSend() {
    std::unique_lock<std::mutex> llock(connectedMutex, std::defer_lock);
    int curr;
    while(running){
        //wait for connection
        llock.lock();
        connectedCond.wait(llock, [this]() { return connectedEst > connectedTerm; });
        curr = connectedEst;
        llock.unlock();
        try{
            //send message
            if (draining && sendQueue.empty()) {
                logh("connection", info) << "draining done" << std::endl;
                running = false;
            }else{
                sendMessage();
            }
        }catch(ConnectionAbort &e){
            llock.lock();
            connectedTerm = curr;
            llock.unlock();
        }
    }
}

void Connection::runRecv() {
    std::unique_lock<std::mutex> llock(connectedMutex, std::defer_lock);
    int curr;
    while(running){
        //wait for connection
        llock.lock();
        connectedCond.wait(llock, [this]() { return connectedEst > connectedTerm; });
        curr = connectedEst;
        llock.unlock();
        try{
            recvMessage();
        }catch(ConnectionAbort &e){
            llock.lock();
            connectedTerm = curr;
            llock.unlock();
        }
    }
}

void Connection::sendMessage()
{
    Message msg = sendQueue.pop();
    severity level = msg.getChannel() == "ctrl" ? trace : debug;
    logh("connection", level) << "sending a message channel:" << msg.getChannel()
        << " len:" << msg.getSize() << std::endl;
    //prepare
    int sendSize = msg.getSize();
    if(sendSize > 1024 * 1024) {
        logh("connection", error) << "message unresonably big:" << sendSize << " - skip" <<std::endl;
        sendSize = 0;
        return;
    }
    char sendBuf[sendSize];
    msg.pack(sendBuf);
    //send
    int sendPos = 0;
    while(sendPos < sendSize){
        size_t ret = write(connectedSocket, sendBuf + sendPos, sendSize - sendPos);
        if((long int)ret == -1){
            if(!running)
                throw ConnectionAbort();
            if(errno == EAGAIN)
                continue;
            logh("connection", error) << "Error on connection - close" <<std::endl;
            throw ConnectionAbort();
        }
        sendPos += ret;
        logh("connection", trace) << "sent:" << sendPos << " of:" << sendSize << std::endl;
    }
}

void Connection::recvBytes(char *buf, int amount)
{
    int recvSize = 0;
    while(recvSize < amount){
        ssize_t ret = read(connectedSocket, buf + recvSize, amount - recvSize);
        if(!running)
            throw ConnectionAbort();
        if(ret == 0){
            logh("connection", info) << "EOF - Connection close" <<std::endl;
            throw ConnectionAbort();
        }
        if(ret == -1){
            if(errno == EAGAIN)
                continue;
            logh("connection", info) << "Error on connection - close" <<std::endl;
            throw ConnectionAbort();
        }
        recvSize += ret;
    }
}

void Connection::recvMessage()
{
    logh("connection", trace) << "receiving a message" << std::endl;
    //receive message length
    char lenBuf[4];
    recvBytes(lenBuf, 4);
    int msgLength = get32(lenBuf, 0);
    if(msgLength < 16 || msgLength > 1024 * 1024) {
        logh("connection", error) << "msgLength:" << msgLength << " < 16" <<std::endl;
        throw ConnectionAbort();
    }
    //receive message
    char buf[msgLength];
    put32(buf, 0, msgLength);
    recvBytes(buf + 4, msgLength - 4);
    //unpack message
    Message msg(buf);
    logh("connection", trace) << "received a message len:" << msg.getSize() << std::endl;
    recvQueue.push(msg);
}

Control Control::inst;

Control::Control() :
    connection(NULL),
    nowAt(0),
    tickPeriod(MHz),
    profileCycle(5.0), //seconds
    profileLastSim(0)
{
    connection = new Connection();
    time(&profileLastWall);
    time(&wallStart);
    ctrlThread = std::thread(&Control::ctrlRun, this);
    dispatchThread = std::thread(&Control::dispatchRun, this);
}

void Control::setConfig(Message &msg) {
    char *data = msg.getData();
    int pos = 4; //first four bytes are the command
    std::string name(data + pos + 4);
    pos += 4 + get32(data, pos); //string length
    if(name == "loglevel") {
        std::string scope(data + pos + 4);
        pos += 4 + get32(data, pos);
        int level = get32(data, pos);
        logh("control", info) << "setting loglevel on scope:" << scope << " level:" << level << std::endl;
        setLogLevel(scope, static_cast<severity>(level));
    }else{
        logh("control", warning) << "setConfig Message contains unkonwn name:" << name << std::endl;
    }
}

MessageQueue & Control::getQueue(const std::string &chan) {
    std::unique_lock<std::mutex> lock(channelMutex);
    return channels[chan];
}

double Control::getWall() {
    time_t wall;
    time(&wall);
    return difftime(wall, wallStart);
}

void Control::addBreak(int id, BreakType type, simTime tme, bool relative){
    std::unique_lock<std::mutex> lock(breakMutex);
    breakList.push_back(Break(id, type, tme, relative));
    breakCond.notify_all();
}

void Control::remBreak(int id){
    std::unique_lock<std::mutex> lock(breakMutex);
    bool found = false;
    for(auto it = breakList.begin(); it != breakList.end(); it++){
        if(it->id == id){
            breakList.erase(it);
            found = true;
            break;
        }
    }
    if(found == false)
        throw std::runtime_error("break id not found");
    breakCond.notify_all();
}

void Control::ctrlRun(){
    MessageQueue &ctrlChannel = getQueue("ctrl");
    logh("control", debug) << "Ctrl run started" << std::endl;
    while(true){
        //process a message
        if(ctrlChannel.wait(100)){
            logh("control", trace) << "Control got message" << std::endl;
            Message msg = ctrlChannel.pop();
            ctrlProcess(msg);
        }
        //profile
        profile();
    }
}

void Control::ctrlProcess(Message &msg) {
    char *data = msg.getData();
    Command cmd = (Command)get32(data, 0);
    bool cycles;
    switch(cmd) {
        case Command::tick: {
            logh("control", trace) << "Control received tick command" << std::endl;
            Message tock("ctrl", 13);
            put32(tock.getData(), 0, (uint32_t)Command::tock);
            putSimTime(tock.getData(), 4, nowAt, false);
            push(tock);
            profileTickCount++;
        } break;
        case Command::addBreak: {
            logh("control", debug) << "Control received break command" << std::endl;
            int id = get32(data, 4);
            simTime thresh = getSimTime(data, 8, cycles);
            BreakType typ = (BreakType)get8(data, 17);
            bool relative = (bool)get8(data, 18);
            addBreak(id, typ, thresh, relative);
        } break;
        case Command::remBreak:
            logh("control", debug) << "Control received release command" << std::endl;
            remBreak(get32(data, 4));
            break;
        case Command::shutdown:
            logh("control", info) << "Control received shutdown command" << std::endl;
            shutdown();
            break;
        case Command::set:
            logh("control", info) << "Control received set command" << std::endl;
            setConfig(msg);
            break;
        default:
            logh("control", warning) << "SimControl received unknown command:" << cmd <<std::endl;
    }
}

void Control::dispatchRun()
{
    while(true){
        logh("control", trace) << "dispatcher wait for message" << std::endl;
        Message msg = connection->pop();
        MessageQueue &queue = getQueue(msg.getChannel());
        severity level = msg.getChannel() == "ctrl" ? trace : debug;
        logh("control", level) << "dispatcher push message to channel:" << msg.getChannel() << std::endl;
        queue.push(msg);
    }
}

void Control::reportTime(uint64_t tme) {
    nowAt = tme;
}

void Control::shutdown() {
    //send exit message
    Message msg("ctrl", 4);
    put32(msg.getData(), 0, (uint32_t)Command::shutdown);
    push(msg);
    inShutdown = true;
}

bool Control::checkBreak(BreakType typ, bool doLock) {
    std::unique_lock<std::mutex> lock(breakMutex, std::defer_lock);
    if(doLock)
        lock.lock();
    bool ret = false;
    for(auto it = breakList.begin(); it != breakList.end(); it++){
        //check if we have to announce the break
        if(!it->ack){
            if(it->rel)
                it->thresh += nowAt;
            if(it->thresh < nowAt)
                it->thresh = nowAt;
            it->ack = true;
            logh("control", debug) << "ack break:" << it->id << " @:" << chomp(it->thresh) 
            << " typ:" << it->type << std::endl;
            Message msg("ctrl", 17);
            put32(msg.getData(), 0, (uint32_t)Command::ackBreak);
            put32(msg.getData(), 4, it->id);
            putSimTime(msg.getData(), 8, it->thresh, false);
            push(msg);
        }
        //check if we are hitting this break
        if(it->type == typ && it->thresh <= nowAt){
            ret = true;
            if(it->thresh <= nowAt && !it->hit){
                logh("control", info) << "hitting break:" << it->id << " @:" << chomp(nowAt) <<
                " thresh:" << chomp(it->thresh) << std::endl;
                it->hit = true;
                Message msg("ctrl", 17);
                put32(msg.getData(), 0, (uint32_t)Command::hitBreak);
                put32(msg.getData(), 4, it->id);
                putSimTime(msg.getData(), 8, nowAt, false);
                push(msg);
            }
        }
    }
    return ret;
}


void Control::waitHold() {
    std::unique_lock<std::mutex> lock(breakMutex);
    while(checkBreak(BreakType::hold, false)){
        if(!breakCond.wait_for(lock, std::chrono::milliseconds(2000), [this]() {
                return !checkBreak(BreakType::hold, false); }))
            logh("control", info) << "holding..." << std::endl;
    }
}

void Control::profile() {
    time_t wall;
    time(&wall);
    double spend = difftime(wall, profileLastWall);
    if(profileCycle == 0 || profileCycle > spend)
        return;
    uint64_t cycles = nowAt - profileLastSim;
    uint64_t freq = cycles / spend;
    uint64_t tickFreq = profileTickCount / spend;
    severity sev = cycles != 0 ? info : debug;
    logh("control", sev) << "profile:" << spend << "sec"
        << " sim:" << chomp(cycles) << " (" << chomp(freq) << "/sec)"
        << " ticks:" << profileTickCount << " (" << tickFreq << "/sec)"
        << std::endl;
    for(auto it = breakList.begin(); it != breakList.end(); it++){
        logh("control", sev) << "break:" << chomp(it->thresh) << " hit:" << it->hit << " typ:"
        << it->type << std::endl;
    }
    profileLastWall = wall;
    profileLastSim = nowAt;
    profileTickCount = 0;
}

void Control::push(Message &msg) {
    connection->push(msg);
}

bits::bits(const char *raw) {
    uint16_t size = get16(raw, 0);
    for(int i = 0; i < size; i++){
        int byt = ((size-1) / 2) - (i / 2);
        char val = raw[2+byt];
        if(i % 2)
            val = val >> 4;
        push_back((logic9)(val & 0xf));
    }
}

void bits::rawDump(char *buf) {
    int s = size();
    put16(buf, 0, s);
    for(int i = 0; i < s; i++) {
        int byt = ((s-1) / 2) - (i / 2);
        if(i % 2)
            buf[2+byt] |= (at(i) << 4); 
        else
            buf[2+byt] = at(i);
    }
}

std::string bits::str(){
    std::string s;
    for(int i = size()-1; i >= 0; i--){
        s += logic9_charmap[at(i)];
    }
    return s;
}

change::change(const char *raw) :
    time(get64(raw, 0)),
    cycles(get8(raw, 8)),
    value(raw + 10),
    sync(get8(raw, 9))
{
    logh("change", debug) << "create change:" << str() << std::endl;
}

std::string change::str() {
    std::string s = value.str();
    s += "@";
    s += chomp(time, cycles);
    if(!sync)
        s += "a"; //async
    return s;
}

void change::rawDump(char *buf){
    putSimTime(buf, 0, time, cycles);
    put8(buf, 9, (char)sync);
    value.rawDump(buf + 10);
}

bool change::operator==(change &o) {
    return value == o.value && time == o.time && sync == o.sync;
}

bool change::operator!=(change &o) {
    return value != o.value || time != o.time || sync != o.sync;
}


Player::Player(std::string &chan, bits &reset, bool sync, bool cycl):
    queue(Control::getInst().getQueue(chan)),
    channel(chan),
    next(0, cycl, reset, sync),
    current(0, cycl, reset, sync),
    valid(false),
    ahead(false),
    cycles(cycl)
{
};

void Player::updateNext(bool block, int timeout) {
    bool empty = queue.empty();
    if(empty && block)
        empty = !queue.wait(timeout);
    if(!empty){
        Message msg = queue.pop();
        parseMessage(msg, 0);
    }
}

bits Player::get(simTime tme, bool *sync, simTime *until, int timeout) {
    logh(channel, trace) << "SiCo - player:" << channel << " get @" << chomp(tme)
        << " curr:" << current.str() << " next:" << next.str() << std::endl; //*/

    //do we have to roll forward?
    bool newVal = false;
    while(next.time <= tme){
        logh(channel, trace) << "player rolling forward because:" << chomp(next.time) << 
        " <= " << chomp(tme) << std::endl;
        current = next;
        if(ahead)
            newVal = true;
        ahead = false;
        updateNext(current.sync, timeout);
        //a new value arrived, so make the current sync
        if(ahead)
            current.sync = true;
        //if no new value is there we can leave
        if(!ahead){
            if(current.sync)
                throw TimedOut();
            else
                break;
        }
    }

    //did we get a new value?
    if(newVal){
        if(current.sync){
            logh(channel, debug) << "player on new value:" << current.str()
                << " until:" << chomp(next.time, next.cycles) << std::endl;
        }else{
            logh(channel, debug) << "player on new value:" << current.str()
                << " async" << std::endl;
        }
    }

    if(until){
        if(current.sync)
            *until = next.time;
        else
            *until = 0;
    }
    if(sync){
        *sync = current.sync;
    }
    return current.value;
}

bits Player::getNext(simTime tme, bool *newval, int timeout) {
    //if there is not value available, try to get one
    if(!valid){
        updateNext(current.sync, timeout);
        if(ahead){
            valid = true;
            current = next;
            ahead = false;
        }else if(current.sync)
            throw TimedOut();
    }
    //output
    if(valid && tme >= current.time){
        valid = false;
        *newval = true;
    }else
        *newval = false;
    return current.value;
}   

void Player::parseMessage(Message &msg, simTime tme) {
    next = change(msg.getData());
    ahead = true;
    if(next.cycles != cycles){
        logh(channel, error) << "player received new change of wrong time type:"
            << (next.cycles ? "cycled" : "timed") << std::endl;
    }
    SiCo::logh(channel, SiCo::debug) << "channel:" << msg.getChannel()
        << " new next value:" << next.str() << std::endl;
    if(!cycles && next.time < tme)
        SiCo::logh(channel, SiCo::warning) << "channel:" << msg.getChannel() 
            << " new value is in the past:" << chomp(next.time)
            << " < " << chomp(tme) << std::endl;
}

Recorder::Recorder(std::string chan, bits &reset, bool cycl) :
    queue(Control::getInst().getQueue(chan)),
    channel(chan),
    last(reset),
    now(0),
    cycles(cycl)
{ };

bool Recorder::put(simTime curr, bits val, bool sync, bool force) {
    now = curr;
    if(!force && val == last)
        return false;
    logh(channel, debug) << "channel:" << channel << " change:" << last.str()
        << " -> " << val.str() << " sync:" << sync
        << " @:" << chomp(now, cycles) << std::endl;
    last = val;
    change ch(now, cycles, val, sync);
    Message msg(channel, ch.rawSize());
    ch.rawDump(msg.getData());
    Control::getInst().push(msg);
    return true;
};


} //namespace SiCo