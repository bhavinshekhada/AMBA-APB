`timescale 1ns / 1ps

module tb();

    // Inputs
    reg clk;
    reg [47:0] wr_data;
    reg wr_en;
    reg preset_n;
    
    // Outputs
    wire f_full;
    wire [47:0] fifo_data_frame;
    wire fifo_w_en;
    wire o_tx_active;
    wire o_tx_serial;    
    wire full;

    // Instantiate the DUT
    top dut (
        .clk(clk),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .preset_n(preset_n),
        .f_full(f_full),
        .fifo_data_frame(fifo_data_frame),
        .fifo_w_en(fifo_w_en),
        .o_tx_active(o_tx_active),
        .o_tx_serial(o_tx_serial),
        .full(full)
    );

    // Clock generation
    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        #20 preset_n = 0;
        # 10 preset_n = 1;
        // Write Data Frame
            wr_data = 48'h8108abcdef00;
        #10 wr_en =1;
        #10 wr_data = 48'h000012345670;
        #10 wr_data = 48'h000012345671;
        #10 wr_data = 48'h000012345672;
        #10 wr_data = 48'h000012345673;
        #10 wr_data = 48'h000012345674;
        #10 wr_data = 48'h000012345675;
        #10 wr_data = 48'h000012345676;
        #10 wr_data = 48'h000012345677;
        
         #5 wr_en =0;
        wr_data = 48'hx;
    end

endmodule
