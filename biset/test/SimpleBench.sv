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

module SimpleBench ();

//clocking

logic clk;
logic rst;

SiCoCtrl control (
    .clk_o          (clk),
    .rst_o          (rst)
);

//constant

BiSet::biSetCtrl    ctrl;
BiSet::biSetData    wrte;
BiSet::biSetReply   rply;
BiSet::biSetReply   rplys[4];

BiSetConstant #(
    .ADDR   (1),
    .VALUE  ('hdeadaffe)
) constant (
    .clk_i  (clk),
    .rst_i  (rst),
    .setCtrl_i  (ctrl),
    .setReply_o (rplys[0])
);

logic [31:0] regVal;
BiSetRegister #(
    .ADDR   (2),
    .RESET  ('haffebabe)
) register (
    .clk_i      (clk),
    .rst_i      (rst),
    .val_o      (regVal),
    .event_o    (),

    .setCtrl_i  (ctrl),
    .setWrite_i (wrte),
    .setReply_o (rplys[1])
);

BiSet::biSetReply rfReply;
BiSetRegFile #(
    .ADDR       (3),
    .RESET      ('habbadead)
) regfile (
    .clk_i      (clk),
    .rst_i      (rst),
    .val_o      (),
    .event_o    (),
    .setCtrl_i  (ctrl),
    .setWrite_i (wrte),
    .setReply_o (rfReply)
);
assign rplys[2] = rfReply;

logic statusEvent;
BiSetStatus #(
    .ADDR       (5),
    .RESET      ('h1244)
) status (
    .clk_i      (clk),
    .rst_i      (rst),
    .val_i      (regVal),
    .update_i   (statusEvent),
    .event_o    (statusEvent),
    .setCtrl_i  (ctrl),
    .setReply_o (rplys[3])
);

BiSetReplyMux #(
    .LENGTH     (4)
) mux (
    .in_i       (rplys),
    .out_o      (rply)
);

SiCoBiSetDriver driver (
    .clk_i      (clk),
    .rst_i      (rst),
    .ctrl_o     (ctrl),
    .write_o    (wrte),
    .reply_i    (rply)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars();
end


endmodule