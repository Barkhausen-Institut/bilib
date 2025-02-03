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

`timescale 1ps/1ps

module SiCoCtrl #(
    parameter CTRL_CHAN = "ctrl",
    parameter UPDATE_FREQ = SimHelper::MHZ,
    parameter HOLD_TIME = 0,
    parameter CLOCK_FREQUENCY = 100 * SimHelper::MHZ,
    parameter RESET_LENGTH = 100 * SimHelper::NSEC,
    parameter LOGLEVEL = "info"
) (
    output  wire logic  clk_o,
    output  wire logic  rst_o
);

import SimHelper::*;

SimTime stime();

initial begin
    setLoglevel("", LOGLEVEL);
    setConfigI("tickFreq", UPDATE_FREQ);
    if(HOLD_TIME != 0)
        setConfigI("holdTime", HOLD_TIME);
end

initial forever begin
    longint now;
    now = stime.now(1'b1);
    $SiCoVpiTick(now[32+:32], now[0+:32]);
    stime.waitTime(freq2Period(UPDATE_FREQ));
end

SimClock #(
    .FREQUENCY(CLOCK_FREQUENCY)
) clock (
    .clk_o(clk_o)
);

SimReset #(
    .LENGTH(RESET_LENGTH)
) reset (
    .rst_o(rst_o)
);

task setLoglevel(string scope, string level);
    setConfigSS("loglevel", scope, level);
endtask

task setConfigSS(string key, string value1, string value2);
    $SiCoVpiConfig(key, value1, value2);
endtask

task setConfigI(string key, int value1);
    $SiCoVpiConfig(key, value1);
endtask

endmodule