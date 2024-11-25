`timescale 1ns / 1ps

module tb_mult_complex;

    // Parameters
    parameter QI = 3;
    parameter QF = 3;

    // Inputs
    reg signed [QI-1:-QF] a_Re, a_Im, b_Re, b_Im;

    // Outputs
    wire signed [2*QI:-2*QF] y_Re, y_Im;

    // Unit Under Test (UUT)
    mult_complex #(QI, QF) uut (
        .a_Re(a_Re),
        .a_Im(a_Im),
        .b_Re(b_Re),
        .b_Im(b_Im),
        .y_Re(y_Re),
        .y_Im(y_Im)
    );

    integer pass_count = 0;
    integer test_count = 0;

    task run_test;
        input signed [QI-1:-QF] test_a_Re, test_a_Im, test_b_Re, test_b_Im;
        input signed [2*QI:-2*QF] expected_y_Re, expected_y_Im;

        begin
            // Apply inputs
            a_Re = test_a_Re;
            a_Im = test_a_Im;
            b_Re = test_b_Re;
            b_Im = test_b_Im;

            #10;

            test_count = test_count + 1;
            if (y_Re === expected_y_Re && y_Im === expected_y_Im) begin
                $display("Test %0d PASSED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d -> y_Re=%0d, y_Im=%0d",
                         test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, y_Re, y_Im);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %0d FAILED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d -> y_Re=%0d (expected %0d), y_Im=%0d (expected %0d)",
                         test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, y_Re, expected_y_Re, y_Im, expected_y_Im);
            end
        end
    endtask

    initial begin
        // Test Case 1
        // (3 + i)(2 + 3i) = 3 + 11i
        run_test(6'sb000011, 6'sb000001, 6'sb000010, 6'sb000011, 6'sb000011, 6'sb001011);

        // Test Case 2 (Edge Case: Zero inputs)
        // (0 + 0)(0 + 0) = 0 + 0 
        run_test(6'sb000000, 6'sb000000, 6'sb000000, 6'sb000000, 6'sb000000, 6'sb000000);

        // Test Case 3 (Negative Inputs)
        // (-3 - i)(-2 + 3i) = 9 - 7i
        run_test(6'sb111101, 6'sb111111, 6'sb111110, 6'sb000011, 6'sb001001, 6'sb111001);

        $display("=====================================");
        $display("Test Summary: %0d/%0d tests passed", pass_count, test_count);
        $display("=====================================");

        $stop;
    end
endmodule
