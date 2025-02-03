# bilib

Barkhausen Institut Hardware Design buoöding Blocks.

Bilib is a collection of building blocks for hardware design to ease the composition of complex systems.
The featured components encapsule recurring block in hardware designs.
It strives make development faster and and prevent typical errors by providing clear and unmisstankenable interfaces.
There are several componemt categories, organized in an directory tree

## choc

The Chip Controller (choc) toolkit is used by most other components, thus moved to the top of the list, out of alphabetical order.
It provides an intuitive communication to help connect hardware tests, more specifically the module driver written in Pyhton, to the hardware module.
The hardware can be in any stage: RTL sim, netlist sim, lab configuration.
Choc is built to handle any  communication labyrith seperating the unit from the driver

## sico

Very closely connected to choc, the Simulation controller (sico) connects a Python application running a choc environment to a simulator supporting the DPI or VPI interface.
Sico provides bridges that transport hardware signals from the Python world to a simulator and the other way around.

## axi

converters between AXI4 and bilib's simple memory interface, see [memory](#memory)

## biset

Collection of blocks implementing a hierarchical config register network.

## cdc

Clock Domain Crossing blocks. Transfer signals, events, vectors, data streams

## cdr

Clock Data recovery. recover a single wire signal with the help of oversampling and a recover module

## clock

Clock signal blocks. Multiplexers, gates, buffer, inverter, etc. 
Also reset generators

## coding

Block for en/de coding of very simple codes, like 8b10b or grey

## fifo

simple FIFO implementation, with clear interfaces

## generator

generating signals. e.g. pseudo random numbers

## hash

simple hash implementations. e.g. CRC32

## memory

Simple memory blocks to decouple memory block usage and implementation. The memory blocks define a clear and easy interface. There are several variants for two port, double port, with byte (or arbitrary mask) select.
Internally the block redirects the memory to an `*Impl` variant that is usually defined project global in accordance with available memory macros.

The advantage is that soft IP blocks don't have to care about the memory implementation. On the other side, the project does not have to tinker in the IP to adapt the memory blocks.

### ByteMemories

The general memories are bit precise and addresses select a memory lines. Converting between different addresses is error prone. Many memory interfaces actually byte aligned. That is why the ByteMemory modules provide a wrapper around the general memory modules making sure that adresses are always refering to bytes and masks are always byte masks.

## sim

This category contains modules that are in general not synthesizable, but provide very simple to use implementation for common tasks like, generating a clock or implementing a memory.

## stdcell

Stdcell modules like NAND, OR, XOR, ...
Similar to memory modules, the idea is to redirect the implementation to project level, where an situation appropriate implementation can be provided.


