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

#ifndef SICO_HEADER
#define SICO_HEADER

#include <string>
#include <iostream>
#include <queue>
#include <sys/un.h>
#include <arpa/inet.h>
#include <map>
#include <array>
#include <time.h>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <list>

namespace SiCo {

//simulation time in pico seconds ps
typedef uint64_t simTime;
//frequency value in Hertz Hz
typedef uint64_t simFreq;

//simTime factors
const simTime PSEC = 1;
const simTime NSEC = 1000;
const simTime USEC = 1000000;
const simTime MSEC = 1000000000;

//frequency factors
const simFreq kHz = 1000;
const simFreq MHz = 1000000;
const simFreq GHz = 1000000000;

//10^12
// can be used to convert from simTime to simFreq
const uint64_t E12 = 1000000000000;

//convert frequency to period
inline uint64_t freq2period(uint64_t f) {return E12 / f;}

//convert period to frequency
inline uint64_t period2freq(uint64_t p) {return E12 / p;}

//convert a simTime to a human readable string
// 1s023u for 1 second and 23 micro
std::string chomp(simTime num, bool cycles = false);

//get and set values of different size from a binary buffer
uint8_t  get8 (const char *data, int index);
uint16_t get16(const char *data, int index);
uint32_t get32(const char *data, int index);
uint64_t get64(const char *data, int index);
simTime  getSimTime(const char *data, int index, bool &cycles);
void put8 (char *data, int index, uint8_t val);
void put16(char *data, int index, uint16_t val);
void put32(char *data, int index, uint32_t val);
void put64(char *data, int index, uint64_t val);
void putSimTime(char *data, int index, simTime value, bool cycles);

//serverity for logging
enum severity {
    trace =     0,   
    debug =     10,
    info =      20,
    warning =   30,
    error =     40,
    fatal =     50
};

//start a log line in the given severity (and scope)
// can be used in a iostream way to log things
// example: lohg(info) << "hallo welt" << std::endl;
// example: logh(info, "aurora") << "hallo welt" << std::endl;
std::ostream& logh(severity s);
std::ostream& logh(const std::string &scope, severity s);

void        setLogLevel(const std::string &scope, severity s);
severity    getLogLevel(const std::string &scope);
severity    stringToSeverity(const std::string &str);

//function to call the notify method of a class
// used to register callbacks
template<class T>
void notifyClass(void *ptr) {
    T *obj = static_cast<T *>(ptr);
    obj->notify();
}

//Exception to be thrown to kill the simulator
struct ConnectionAbort : public std::exception {
};

struct TimedOut : public std::exception {
};

//message passed over a comm socket
class Message {
    std::string channel;    //the SiCo channel this message is for
    int         dataLength; //length of payload
    char *      data;       //payload
public:
    //create message from binary buffer
    Message(const char *raw);
    //create empty message
    Message(std::string channel, int length);
    //create empyt message with no channel
    Message(int length);
    //move constructor
    Message(Message && o);
    ~Message();
    //get the binary buffer size needed to hold this message
    size_t          getSize() { return dataLength + 8 + channel.length(); };
    //write message into binary buffer of size returned by getSize()
    void            pack(char *buffer);
    std::string &   getChannel() { return channel; };
    char *          getData() { return data; };
    void            setChannel(const std::string &chan) { channel = chan; };
};

//thread safe message queue
class MessageQueue {
    std::queue<Message>     queue;
    std::mutex              queueMutex;
    std::condition_variable availCond;

public:
    MessageQueue();
    void push(Message &msg);
    Message pop();
    bool wait(int timeout); //returns true if a message is ready in the queue, will wait <timeout> millisec if empty
    bool empty();
};

//create a socket and start listening on it. Returns the socket fd
int createSocket();
//accept a connection on a listening socket. Returns the socket fd
int acceptConnection(int listenSocket);

//Socket connection
// manages the socket connection to a peer, takes Message obeject to send and
// provides Message objects that it recevied
class Connection {
    int                     connectedSocket = 0;
    int                     connectedEst;
    int                     connectedTerm;
    bool                    running;
    bool                    draining;
    std::mutex              connectedMutex;
    std::condition_variable connectedCond;

    struct sockaddr_un  sockAddress;
    MessageQueue        sendQueue;
    MessageQueue        recvQueue;
    std::thread         connThread;
    std::thread         sendThread;
    std::thread         recvThread;

public:
                Connection();
    Message     pop();
    void        push(Message &msg);
private:
    void        runConn();
    void        runSend();
    void        runRecv();
    void        sendMessage();
    void        recvMessage();
    void        recvBytes(char *buf, int amount);
};

enum Command {
    tick = 0,       //keep alive signal
    tock = 1,       //keep alive signal answer
    exit = 2,       //request exit of the simulator
    shutdown = 3,   //request shutdown of the simulator
    set = 4,        //set a config value
    addBreak = 5,   //add a break threshold
    remBreak = 6,   //remove a break threshhold
    ackBreak = 7,   //acknowledge the break
    hitBreak = 8,   //break was hit
};

// python <---> sinmulator
// TickTock - (continuous back and forth)
//   tick ->    ()
//   <- tock    (currentTime:simTime)

// Exit - currently not used
//   exit the simulator in a brutal way

// Shutdown - Close connection (last message on a socket)

// Set - set a config value
//   set ->    (key:string, ...)
//   set ->    loglevel(scope:str, level:int)

// Breaks
//   breakTyp      (0:hold, 1:stop, 2:finish)
//   addBreak ->   (id:int,thresh:simTime,type:char,relative:char)
//   remBreak ->   (id:int)
//   <- ackBreak   (id:int,now:simTime)
//   <- hitBreak   (id:int,now:simTime)

enum BreakType {
    hold = 0,
    stop = 1,
    finish = 2
};

class Break {
public:
    Break(int uid, BreakType typ, simTime tme, bool relative) :
        id(uid), thresh(tme), type(typ), hit(false), ack(false), rel(relative) {};
    int                 id;
    simTime             thresh; //if rel is true, this will be updated at <ack> event
    BreakType           type;
    bool                hit;    //hit message sent
    bool                ack;    //ack message sent
    bool                rel;    //thresh is relative to the current time
};

//Simulation control - the simulation layer should only use with this class
class Control {
    Connection *        connection;
    static Control      inst;           //signleton
    simTime             nowAt;          //current time
    std::list<Break>    breakList;         //times where the simulation should hold
    simTime             tickPeriod;     //expected time between ticks
    time_t              wallStart;      //wall time when the simulation started
    //profiling
    double              profileCycle;   //time between two profile prints
    time_t              profileLastWall;//last time a profile was printed
    uint64_t            profileLastSim; //last time a profile was printed
    int                 profileTickCount;//number of ticks since last print
    //
    bool                inShutdown;
    std::map<std::string, MessageQueue> channels;

                        Control();
    //mutex
    std::mutex          channelMutex;
    std::mutex          breakMutex;
    std::condition_variable breakCond;

    std::thread         ctrlThread;
    std::thread         dispatchThread;
public:
    //thread
    void                ctrlRun();
    void                ctrlProcess(Message &msg);
    void                dispatchRun();

    //set things
    void                setConnection(Connection *conn) { connection = conn; };
    void                setTickPeriod(simTime period) { tickPeriod = period; };
    void                setConfig(Message &msg);

    //get things
    MessageQueue &      getQueue(const std::string &chan);
    simTime             getTime(){ return nowAt; };
    double              getWall();
    static simTime      getClock(){ return getInst().getTime(); };
    bool                checkBreak(BreakType typ, bool lock = true); 
    bool                isShutdown() { return inShutdown; };

    //do things
    void                addBreak(int id, BreakType typ, simTime tme, bool relative);
    void                remBreak(int id);
    void                reportTime(uint64_t tme);   //simulation update time
    void                shutdown();
    void                waitHold();
    void                profile(); //if enabled print profiling information
    void                push(Message &msg);

    //class managent
    static Control &    getInst(){ return inst; };
                        Control(Control const&) = delete;
    void                operator=(Control const &) = delete;

    //simultation reports to the control
};

/*
V virtual
W weak 
U unknown
V value
H hex
                 | V | W | U | V || H 
0 zero           | 0 | 0 | 0 | 0 || 0
1 one            | 0 | 0 | 0 | 1 || 1
Z high impedance | 0 | 0 | 1 | 0 || 2
X strong unknown | 0 | 0 | 1 | 1 || 3
L weak0          | 0 | 1 | 0 | 0 || 4
H weak1          | 0 | 1 | 0 | 1 || 5
W weak unknown   | 0 | 1 | 1 | 0 || 6
U uninitilized   | 1 | 0 | 1 | 0 || a
- don't care     | 1 | 1 | 1 | 0 || e
*/

enum logic9 {
    zero = 0,
    one = 1,
    high = 2,       //Z
    unknown = 3,    //X
    weak0 = 4,      //L
    weak1 = 5,      //H
    weakunknown = 6,//x
    uninitialized = 0xa,
    dontcare = 0xe
};

const char logic9_charmap[] = {
    '0',
    '1',
    'Z',
    'X',
    'L',
    'H',
    'Y',
    ' ',
    ' ',
    ' ',
    'U',
    ' ',
    ' ',
    ' ',
    '_'
};

struct bits : std::vector<logic9> {
    bits(const char * raw);
    bits() { };
    size_t rawSize() { return 2 + ((size()+1) / 2); };
    void rawDump(char *buf);
    //bool operator==(bits &o) { return b == o.b;
    std::string str();
};

struct change {
    simTime     time;        //activation time
    bool        cycles;      //time is in cycles
    bits        value;       //values
    bool        sync;        //wait for next change
    change(const char *raw);
    change(simTime tme, bool cycl, bits val, bool syc) :
        time(tme), cycles(cycl), value(val), sync(syc) {};
    change() : time(0), value(), sync(false) {};
    std::string str();
    size_t rawSize(){ return value.rawSize() + 10; };
    void rawDump(char *buf);
    bool operator==(change &o);
    bool operator!=(change &o);
};

class Player {
    MessageQueue &          queue;
    std::string             channel;
    change                  next;
    change                  current;
    bool                    valid;      //for interface-queue: is current valid
    bool                    ahead;      //is the next change a different value than current     
    bool                    cycles;     //player is supposed to receive cycled changes
    void    parseMessage(Message &msg, simTime now);
public:
    Player(std::string &chan, bits &reset, bool sync, bool cycl);
    void notify();
    //get the valid change for a given time
    bits get(simTime now, bool *sync, simTime *until, int timeout);
    //get the next change, that might be in the past but never in the future
    // vaild indicates if a new change is given, if it is false, there is not change waiting
    bits getNext(simTime tme, bool *valid, int timeout);
private:
    //get a new change from the queue assigning 'current' = 'next' = the new change
    // returns true if a new change was received
    // if block is true, wait <timeout> millisec for a new change
    void updateNext(bool block, int timeout);
};

class Recorder {
    MessageQueue &          queue;
    std::string             channel;
    bits                    last;
    simTime                 now;
    bool                    cycles;
public:
    Recorder(std::string chan, bits &reset, bool cycl);
    //returns if the value changed
    // when force is set, will push the value even if the last one was the same, and return true
    bool put(simTime curr, bits val, bool sync, bool force=false);
};

}//namespace SiCo

#endif
