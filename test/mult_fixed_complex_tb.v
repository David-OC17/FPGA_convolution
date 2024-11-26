`timescale 1ns / 1ps

module tb_mult_fixed_complex;

    parameter QI = 4;  // Integer part (3 bits)
    parameter QF = 4;  // Fractional part (3 bits)
    parameter WIDTH = QI + QF; // Total bit width

    // Inputs
    reg signed [WIDTH-1:0] a_Re, a_Im, b_Re, b_Im;

    // Outputs
    wire signed [WIDTH-1:0] y_Re, y_Im;
    wire overflow;

    mult_fixed_complex #(QI, QF) uut (
        .a_Re(a_Re),
        .a_Im(a_Im),
        .b_Re(b_Re),
        .b_Im(b_Im),
        .y_Re(y_Re),
        .y_Im(y_Im),
        .overflow(overflow)
    );

    integer pass_count = 0;
    integer test_count = 0;

    task run_test;
        input signed [QI-1:-QF] test_a_Re, test_a_Im, test_b_Re, test_b_Im;
        input signed [QI-1:-QF] expected_y_Re, expected_y_Im;
        input expected_overflow;
        begin
            a_Re = test_a_Re;
            a_Im = test_a_Im;
            b_Re = test_b_Re;
            b_Im = test_b_Im;

            #10;

            test_count = test_count + 1;

            if (y_Re === expected_y_Re && y_Im === expected_y_Im && overflow === expected_overflow) begin
                $display("Test %0d PASSED:", test_count);
                $display("Inputs:  a_Re=%b, a_Im=%b, b_Re=%b, b_Im=%b", test_a_Re, test_a_Im, test_b_Re, test_b_Im);
                $display("Outputs: y_Re=%b, y_Im=%b, Overflow=%b", y_Re, y_Im, overflow);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %0d FAILED:", test_count);
                $display("Inputs:  a_Re=%b, a_Im=%b, b_Re=%b, b_Im=%b", test_a_Re, test_a_Im, test_b_Re, test_b_Im);
                $display("Outputs: y_Re=%b (expected %b), y_Im=%b (expected %b), Overflow=%b (expected %b)", 
                        y_Re, expected_y_Re, y_Im, expected_y_Im, overflow, expected_overflow);
            end
        end
    endtask


    initial begin
        // Test Case 1: Positive numbers
        // Inputs: a_Re = 3.25, a_Im = 2.0625, b_Re = 2.5, b_Im = 1.5
        run_test(8'b0011_0100, 8'b0010_0001, 8'b0010_1000, 8'b0001_1000, 8'b0101_0000, 8'b1010_0000, 1'b0);

        // Test Case 2: Zero inputs
        run_test(8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 1'b0);

        // Test Case 3: Negative inputs
        // Inputs: (-1.5 - 0.5i) * (-3.5 + 0.75i)
        // Real part: (-1.5*-3.5 - -0.5*0.75) = 5.25 + 0.375 = 5.625
        // Imaginary part: (-0.5*-3.5 + -1.5*0.75) = 1.75 - 1.125 = 0.625
        run_test(8'b1110_1000, 8'b1111_1000, 8'b1100_1000, 8'b0000_1100, 8'b0101_1010, 8'b0000_1010, 1'b0);

        // Test Case 6: Mixed positive and negative inputs
        // Inputs: (-1.75 + 2.125i) * (1.5 - 2.75i)
        // Real part: (-1.75*1.5 - 2.125*-2.75) = -2.625 + 5.84375 = 3.21875
        // Imaginary part: (-1.75*-2.75 + 2.125*1.5) = 4.8125 + 3.1875 = 8.0
        run_test(8'b1110_0100, 8'b0010_0010, 8'b0001_1000, 8'b1101_0100, 8'b0011_0011, 8'b1000_0000, 1'b0);


        $display("=====================================");
        $display("Test Summary: %0d/%0d tests passed", pass_count, test_count);
        $display("=====================================");
        
        $stop;
    end

endmodule
