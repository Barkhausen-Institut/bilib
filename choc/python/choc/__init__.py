####    ############    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
####    ############    
####                    This source describes Open Hardware and is licensed under the
####                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
############    ####    
############    ####    
####    ####    ####    
####    ####    ####    
############            Authors:
############            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)


                ####                                          
                ####                                          
                ####                                          
                ####                                          
############    ############    ############    ############
############    ############    ############    ############
####            ####    ####    ####    ####            ####
####            ####    ####    ####    ####            ####
############    ####    ####    ############    ############
############    ####    ####    ############    ############

# choↄ - CHip COntrol

from __future__ import annotations
from abc import ABC, abstractmethod
import threading
import asyncio
import logging
from concurrent.futures import Future
import time
from typing import Coroutine

from bilib.fn import etype

class Daemon:
    instance:Daemon = None
    logName = "ChocDaemon"

    @classmethod
    def inst(cls) -> Daemon:
        if cls.instance is None:#
            cls.instance = Daemon()
        return cls.instance

    def __init__(self):
        self.loop = asyncio.new_event_loop()
        self.running = True
        self.thread = threading.Thread(target=self.run, name="ChocDaemon")
        self.thread.start()
        self.watchdog = threading.Thread(
            target=self.watch, name="ChocDog",
            args=(threading.current_thread(),), daemon=True
        )
        self.watchDogTick = time.time()
        self.watchdog.start()

    def watch(self, main:threading.Thread):
        log = logging.getLogger(self.logName)
        logging.getLogger(self.logName).debug("watch dog started")
        while main.is_alive():
            main.join(0.5)
            if self.watchDogTick + 5 < time.time():
                current = asyncio.current_task(self.loop)
                log.warning(f"async watch dog did not tick for 5 seconds - coroutine runing amok? maybe this one:{current}")
                self.watchDogTick = time.time()
        logging.getLogger(self.logName).debug("main thread stopped - stopping choc also")
        self.stop()

    async def watchAsync(self):
        try:
            while self.running:
                await asyncio.sleep(1)
                self.watchDogTick = time.time()
        except asyncio.CancelledError:
            pass

    def run(self):
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self.watchAsync())
        logging.getLogger(self.logName).debug("loop shutdown async")
        self.loop.run_until_complete(self.loop.shutdown_asyncgens())
        logging.getLogger(self.logName).debug("loop stop")
        self.loop.stop()
        logging.getLogger(self.logName).debug("loop close")
        self.loop.close()
        logging.getLogger(self.logName).debug("stopping daemon thread")
    
    def stop(self):
        self.running = False
        fut = asyncio.run_coroutine_threadsafe(self.cancelall(), self.loop)
        fut.result()
        #logging.getLogger(self.logName).debug("loop stop")
        #self.loop.call_soon_threadsafe(self.loop.stop)

    async def cancelall(self):
        log = logging.getLogger(self.logName)
        log.debug("canceling everything")
        for task in asyncio.all_tasks(self.loop):
            if task == asyncio.current_task() or task.cancelling():
                continue
            log.debug(f"canceling task:{task}")
            task.cancel()
        log.debug(f"canceled tasks done!")

class TimedOut(Exception):
    pass

class Task():
    store = set()

    def __init__(self, coro:Coroutine, name:str, weak:bool=False):
        etype((coro, Coroutine), (name, str), (weak, bool))
        self.coro = coro
        self.name = name
        self.task = None
        self.waiting = False
        self.weak = weak
        self.created = threading.Event()
        Daemon.inst().loop.call_soon_threadsafe(self._ccCreate)

    async def _ccGuard(self):
        if not self.weak:
            self.store.add(self)
        await self.task
        if not self.weak:
            self.store.remove(self)

    #create the task - this has to be run in the Choc Deamon thread
    def _ccCreate(self):
        self.task = asyncio.create_task(self.coro, name=self.name)
        self.task.add_done_callback(dumpTaskException)
        self.guard = asyncio.run_coroutine_threadsafe(self._ccGuard(), Daemon.inst().loop)
        self.created.set()

    def __call__(self, timeout:float=None) -> any:
        self.created.wait(timeout)
        self.guard.result()
        return self.task.result()
    
    async def ccCancel(self):    
        self.task.cancel()
        await self.task


def dumpTaskException(tsk:asyncio.Task):
    if not Daemon.inst().running:
        return
    exc = tsk.exception()
    if exc is not None and not isinstance(exc, asyncio.CancelledError):
        log = logging.getLogger("choc")
        log.error(f"Exception in Task:{tsk.get_name()}", exc_info=exc)

#submits a coroutine to the daemon thread
# returns a handle to wait for the return value
def submit(coro:asyncio.coroutine, name:str=None) -> Task:
    etype((name, str))
    th = Task(coro, name)
    return th

#submits a coroutine to the daemon thread
# and waits for it to finish
# returns the return value of the coroutine
def call(coro:asyncio.coroutine, name:str=None, timeout:float=None) -> any:
    hndl = submit(coro, name)
    return hndl(timeout)

#submits a coroutine that calls a function with given arguments
# waits for the function to finish and returns its return value
def do(fn:callable, *args, name:str, **kwargs):
    async def coroWrapper():
        return fn(*args, **kwargs)
    return call(coroWrapper(), name)

def stop():
    Daemon.inst().stop()

def timer(delay:float) -> Task:
    return submit(asyncio.sleep(delay), "timer")

def isShuttingDown() -> bool:
    return False if Daemon.inst().running else True
