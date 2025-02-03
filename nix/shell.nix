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

{ pkgs, pkgs2211, rr }:

let
  mypython3 = python-packages: with python-packages; [
    pyvcd
    crccheck
    lupa
    #for roadrunner
    pyyaml
  ];
  py = pkgs.python3.withPackages mypython3;
in
pkgs.mkShell {
  packages = with pkgs; [
    rr
    yosys
    gcc
    gdb
    py
    gtkwave
    verilog
    svls
    pkgs2211.haskellPackages.sv2v
  ];
  shellHook = ''
    export PATH=$PATH:$PWD/bin
    export PYTHONPATH=$PWD:${rr}/lib/python3.11/site-packages
    export PYTHONASYNCIODEBUG=1
    #create a link to the python3 that can be selected as interpreter in vscode
    if [ -d .vscode ]; then
      ln -fs ${py}/bin/python3 .vscode/py3
    fi
  '';
}  
