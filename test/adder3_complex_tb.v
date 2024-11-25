`timescale 1ns / 1ps

module tb_adder3_complex;

    // Parameters
    parameter QI = 3;
    parameter QF = 3;

    // Inputs
    reg signed [QI:-QF] a_Re_tb, a_Im_tb,
                        b_Re_tb, b_Im_tb,
                        c_Re_tb, c_Im_tb;

    // Outputs
    wire signed [QI+1:-QF+1] d_Re_tb, d_Im_tb;
    wire overflow;

    // Unit Under Test (UUT)
    adder3_complex #(QI, QF) ADDER (
        .a_Re(a_Re_tb),
        .a_Im(a_Im_tb),

        .b_Re(b_Re_tb),
        .b_Im(b_Im_tb),

        .c_Re(c_Re_tb),
        .c_Im(c_Im_tb),

        .d_Re(d_Re_tb),
        .d_Im(d_Im_tb),

        .overflow(overflow)
    );

    integer pass_count = 0;
    integer test_count = 0;

    task run_test;
        input signed [QI:-QF] test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im;
        input signed [QI+1:-QF+1] expected_d_Re, expected_d_Im;
        input expected_overflow;

        begin
            a_Re_tb = test_a_Re;
            a_Im_tb = test_a_Im;
            b_Re_tb = test_b_Re;
            b_Im_tb = test_b_Im;
            c_Re_tb = test_c_Re;
            c_Im_tb = test_c_Im;

            #10;

            test_count = test_count + 1;
            if (d_Re_tb === expected_d_Re && d_Im_tb === expected_d_Im && overflow === expected_overflow) begin
                $display("Test %0d PASSED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d, c_Re=%0d, c_Im=%0d -> d_Re=%0d, d_Im=%0d, overflow=%b",
                         test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im, d_Re_tb, d_Im_tb, overflow);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %0d FAILED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d, c_Re=%0d, c_Im=%0d -> d_Re=%0d (expected %0d), d_Im=%0d (expected %0d), overflow=%b (expected %b)",
                         test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im, d_Re_tb, expected_d_Re, d_Im_tb, expected_d_Im, overflow, expected_overflow);
            end
        end
    endtask

    initial begin
        // Test Case 1: Simple addition
        run_test(9, 3, 1, 6, 4, 3, 14, 12, 1'b0);

        // Test Case 2: Negative inputs / mixed
        run_test(-3, -2, 1, 1, -1, -1, -3, -2, 1'b0);

        // Test Case 3: Zero inputs
        run_test(0, 0, 0, 0, 0, 0, 0, 0, 1'b0);

        $display("=====================================");
        $display("Test Summary: %0d/%0d tests passed", pass_count, test_count);
        $display("=====================================");

        $stop;
    end
endmodule
