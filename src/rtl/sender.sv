//=========================================================================================================
// sender.sv
//
// This module will periodically send an 8-bit value to the "recver" module.
//=========================================================================================================

`include "nap_interfaces.svh"

module sender
(
    input wire          clk,
    input wire          resetn,
    input wire[3:0]     dest_addr,
    t_DATA_STREAM.tx    nap
);

    // We're assuming the clock speed is 100 Mhz
    localparam CLOCK_HZ = 100000000;

    // This counter serves as a countdown timer
    logic[31:0] counter;

    // A '1' in any of these bits turns the corresponding LED on
    logic[7:0] led_bits;

    // This keeps track of the current state of the state-machine
    reg fsm_state;

    always @(posedge clk) begin
    
        if (resetn == 0) begin
            fsm_state <= 0;
            counter   <= 0;
            led_bits  <= 1;

        end else case (fsm_state)

            //----------------------------------------------------------------------
            // In this state, we are counting down until our counter reaches zero.
            // When it does, we will change the pattern of bits we wish to drive to
            // the LEDs and transition to the next state.
            //----------------------------------------------------------------------
            0:  if (counter)
                    counter <= counter - 1;
                else begin
                    fsm_state <= 1;
                end

            //----------------------------------------------------------------------
            // Here, we place our led_bits onto the data-bus of the NAP and raise
            // the 'valid' signal.  We keep 'valid" raised until the NAP raises
            // 'ready'.   Once the "valid and ready" handshake has occured, we lower
            // the valid signal, reset the counter, and go back to FSM state 0
            //----------------------------------------------------------------------
            1:  begin
                    nap.data  <= led_bits;
                    nap.addr  <= dest_addr;
                    nap.valid <= 1;
                    if (nap.valid && nap.ready) begin
                        nap.valid <= 0;
                        counter   <= CLOCK_HZ / 5;
                        led_bits  <= {led_bits[6:0], led_bits[7]};
                        fsm_state <= 0;
                    end
                end

        endcase
    end

endmodule
