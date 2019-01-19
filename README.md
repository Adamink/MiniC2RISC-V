# MiniC2RISC-V

This repository implements a simple compiler that turns MiniC code, whose grammar is a subset of ISO C, to RISC-V assembly code.

The code was written by Xiao Wu.

## Prerequisites

- Linux
- Flex, Bison

## Installation

- Clone this repo:

  ```txt
  git clone https://github.com/Adamink/MiniC2RISC-V.git
  ```

- Compile and install: For Linux shell users, type command

  ```txt
  make clean
  make
  ```

## Run

- The executable file is `g--`, to compile a MiniC file, type

  ```txt
  ./g-- example/1.c -o example/1.o 
  ```

  or simply

  ```txt
  ./g-- example/1.c
  ```

- To run the compiler on examples, type

  ```txt
  make example
  ```












