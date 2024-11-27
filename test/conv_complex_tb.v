`timescale 1ns / 1ps

module tb_conv_complex;

    parameter QI = 4;
    parameter QF = 4;
    parameter NUM_ELEMS = 3;
    parameter WORD_LENGTH = QI + QF;

    // Inputs
    reg clk;
    reg rst;
    reg en;
    reg [2*3*(QI+QF)-1:0] kernel;
    reg [2*(QI+QF)*NUM_ELEMS-1:0] signal;

    // Outputs
    wire [2*(QI+QF)*(NUM_ELEMS+2)-1:0] conv;
    wire overflow;
    wire done;

    conv_complex #(
        .QI(QI),
        .QF(QF),
        .NUM_ELEMS(NUM_ELEMS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .en(en),

        .kernel(kernel),
        .signal(signal),

        .conv(conv),
        .overflow(overflow),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        en = 0;
        kernel = 0;
        signal = 0;

        // Reset sequence
        rst = 0;
        #10;
        rst = 1;

        // Test Case 1: Simple convolution with known values
        #10;
        en = 1;
        clk = 1;
        clk = 0;

        kernel = { 8'b0000_0100, 8'b0010_0000, 8'b0001_0010, 8'b1111_0000, 8'b0000_0000, 8'b1111_0100 }; // not reversed
        signal = { 8'b0001_0001, 8'b1101_0000, 8'b1111_1010, 8'b0001_0100, 8'b0010_1000, 8'b1111_1100 }; // reversed


        kernel = { 
            8'b0000_0100, // 0.25
            8'b0010_0000, // 2.0
            8'b0001_0010, // 1.125
            8'b1111_0000, // -1.0
            8'b0000_0000, // 0.0
            8'b1111_0100  // -0.75
        }; // not reversed

        signal = { 
            8'b0001_0001, // 1.0625
            8'b1101_0000, // -2.0
            8'b1111_1010, // -0.375
            8'b0001_0100, // 1.25 
            8'b0010_1000, // 2.5
            8'b1111_1100  // -0.25
        }; // reversed

        #10;
        clk = 1;
        clk = 0;

        wait(done);
        #10;

        clk = 1;
        clk = 0;

        $display("//////////////////////////////////////////////////////");
        $display("Convolution Output: %b", conv);
        $display("Overflow: %b", overflow);

        $stop;
    end

endmodule
