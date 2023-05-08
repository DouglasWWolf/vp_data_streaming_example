//=========================================================================================================
// recver.sv
//
// This module waits for messages to data to arrive via the NoC and drives the lower 8-bits of those
// messages to the LEDs.
//
// A valid data-transfer (with the NAP) occurs on any clock cycle in which "ready" and "valid" are both
// high.
//=========================================================================================================

`include "nap_interfaces.svh"


module recver
(
    input wire          clk,
    input wire          resetn,
    output wire[7:0]    leds,
    t_DATA_STREAM.rx    nap
);

    // When a data-cycle arrives from the NAP, we'll store the lower 8 bits here
    reg[7:0] led_bits;

    // The physical LEDs are active-low
    assign leds = ~led_bits;

    always @(posedge clk) begin
        
        // If we're in reset, turn all the LEDs off and tell the NAP we're not ready
        if (resetn == 0) begin
            led_bits  <= 0;
            nap.ready <= 0;
        end 

        // Otherwise, we're always ready to receive, and any time we receive valid
        // data from the NAP, we'll drive it out to the LEDs
        else begin
            nap.ready <= 1;
            if (nap.ready & nap.valid) led_bits <= nap.data[7:0];
        end
    end

endmodule
