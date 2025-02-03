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

//The panic module is a pseudo module that is used to create a error condition when for example
// an if generator chain does not hit any cases and should fail in that case.
// if(PARAM == IMPL1) begin
//   ...
// end else if(PARAM == IMPL2) begin
//   ...
// end else begin
//   PanicModule pm();
// end

//However, some tools will find the PanicModule even if it is in an unused else branch and fail
// if they don't find it. This is where this file comes in to provide an empty module.

// ...at the cost of silencing precious errors, only use in Synthesis

module PanicModule;

//if this makes it into a simulation against all warnings at least spit an error
`ifdef SIMULATION
initial $fatal("Panic Module was instanciated at %m");
`endif

endmodule

