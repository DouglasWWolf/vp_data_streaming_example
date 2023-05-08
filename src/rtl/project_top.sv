//=========================================================================================================
// This is an example/tutorial project that demonstrates two modules communicating over the NoC via "data-
// streaming".  There is a separate example that demonstrates two modules communicating over the NoC via
// AXI4.  "Data streaming" over the NoC is very similar to the way an AXI4-Stream works.
//
// In this example:
//
// The "sender" module is responsible for periodically sending 8-bit wide messages to the "recver" module.
// The "recver" module will use those 8-bit messages to drive the LEDs on the VectorPath.
//
// Unlike AXI, when two modules communicate via "Data Streaming", their NAPs (i.e., Network Access Points) 
// must be either in the same vertical column of the NoC or in the same horizontal row of the Noc.  In 
// this example, we will place them in the same horizontal row.
//
// For reference:
//   NoC rows are numbered 1 thru 8, moving from south-to-north.
//   NoC columns are numbered 1 thru 10, moving west-to-east
//
// For more information about instantiating NAPs (Network Access Points), see:
//   "Achronix Speedster7t Component Library Users Guide (UG086)"
//=========================================================================================================

// Any design that uses a NAP (Network Access Point) must include this file
`include "nap_interfaces.svh"

module project_top
( 
    input wire i_clk,

    input wire i_reg_clk,
    input wire i_eth_ts_clk,
    input wire pll_ddr_lock,
    input wire pll_eth_sys_ne_0_lock,
    input wire pll_gddr_SE_lock,
    input wire pll_gddr_SW_lock,
    input wire pll_noc_ne_1_lock,
    input wire pll_pcie_lock,

    `include "vectorpath_rev1_port_list.svh"
);

    // Create handy constants that define the size of the NAP (Network Access Point) signals
    localparam NAP_H_DATA_WIDTH = `ACX_NAP_HORIZONTAL_DATA_WIDTH;
    localparam NAP_V_DATA_WIDTH = `ACX_NAP_VERTICAL_DATA_WIDTH;
    localparam NAP_ADDR_WIDTH   = `ACX_NAP_DS_ADDR_WIDTH;

    // Both our "sender" and "recver" modules are going to be connect to row 1 of the NOC
    localparam NOC_ROW = 1;
    
    // Define the NoC columns where our sender and receiver modules tie into the network
    localparam NOC_COL_SEND = 1;
    localparam NOC_COL_RECV = 2;

    //-----------------------------------------------------------------------------------------------------
    // This block holds resetn low for a few cycles, then drives it high
    //-----------------------------------------------------------------------------------------------------
    logic resetn = 0;
    logic reset_counter[4] = 4'b1111;
    //-----------------------------------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (reset_counter)
            reset_counter <= reset_counter - 1;
        else
            resetn <= 1;
    end
    //-----------------------------------------------------------------------------------------------------


    //-----------------------------------------------------------------------------------------------------
    // Each RTL module that needs to send/receive data on the NoC will connect to the NoC via a NAP - a 
    // "Network Access Point".   Our simple example here will have two modules communicating via the NoC,
    // a "sender" module, and a "receiver" module.
    //
    // In the lines below, we are creating the tDATA_STREAM interfaces that our "sender" and "recver" 
    // modules will use to communicate with their respective NAPs.
    //-----------------------------------------------------------------------------------------------------

    // Create the data-stream interfaces that our "sender" module will use to talk to its NAP
    t_DATA_STREAM #(.DATA_WIDTH (NAP_H_DATA_WIDTH), .ADDR_WIDTH (NAP_ADDR_WIDTH)) iface_sender_rx();
    t_DATA_STREAM #(.DATA_WIDTH (NAP_H_DATA_WIDTH), .ADDR_WIDTH (NAP_ADDR_WIDTH)) iface_sender_tx();

    // Create the data-stream interfaces that our "recver" module will use to talk to its NAP
    t_DATA_STREAM #(.DATA_WIDTH (NAP_H_DATA_WIDTH), .ADDR_WIDTH (NAP_ADDR_WIDTH)) iface_recver_rx();
    t_DATA_STREAM #(.DATA_WIDTH (NAP_H_DATA_WIDTH), .ADDR_WIDTH (NAP_ADDR_WIDTH)) iface_recver_tx();


    //-----------------------------------------------------------------------------------------------------
    // Instantiate the NAP that the "sender" module will use to talk over the NoC. 
    //-----------------------------------------------------------------------------------------------------
    nap_horizontal_wrapper #
    (
        .ROW        (NOC_ROW),
        .COLUMN     (NOC_COL_SEND)        
    )
    nap_sender
    (
        .i_clk      (i_clk),
        .i_reset_n  (resetn),
        .if_ds_tx   (iface_sender_tx),
        .if_ds_rx   (iface_sender_rx)
    );


    //-----------------------------------------------------------------------------------------------------
    // Instantiate the NAP that the "recver" module will use to talk over the NoC
    //-----------------------------------------------------------------------------------------------------
    nap_horizontal_wrapper  #
    (
        .ROW        (NOC_ROW),
        .COLUMN     (NOC_COL_RECV)        
    )
    nap_recver
    (
        .i_clk      (i_clk),
        .i_reset_n  (resetn),
        .if_ds_tx   (iface_recver_tx),
        .if_ds_rx   (iface_recver_rx)
    );
    


    //-----------------------------------------------------------------------------------------------------
    // Declare an instance of our "sender" module.   Here we are both connecting the object to its NAP
    // and we are declaring the destination (i.e., the column number) where it will send its data
    //-----------------------------------------------------------------------------------------------------
    sender sender_object
    (
        .clk        (i_clk),
        .resetn     (resetn),
        .nap        (iface_sender_tx),
        .dest_addr  (NOC_COL_RECV)
    );

    //-----------------------------------------------------------------------------------------------------
    // Declare an instance of our "recver" module.  Here we both connect the object to its NAP and
    // provide the object with the output lines to the VectorPath LEDs
    //-----------------------------------------------------------------------------------------------------
    recver recvr_object
    (
        .clk        (i_clk),
        .resetn     (resetn),
        .nap        (iface_recver_rx),
        .leds       (led_l)
    );


    // Turn on the output-enables for each LED
    assign led_l_oe = 8'hff; 

    // Turn on the output-enable for the pin that drives the LED level-shifter
    assign led_oe_l_oe = 1'b1;   
    
    // That level shifter is active-low.  Active = "drives current to the LEDs"
    assign led_oe_l = 1'b0;

endmodule
