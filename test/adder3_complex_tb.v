module tb_adder3_complex;

    parameter QI = 4;  // Integer part (3 bits)
    parameter QF = 4;  // Fractional part (3 bits)

    reg signed [7:0] a_Re, a_Im, b_Re, b_Im, c_Re, c_Im;
    wire signed [9:0] d_Re, d_Im;
    wire overflow;

    adder3_complex #(QI, QF) uut (
        .a_Re(a_Re),
        .a_Im(a_Im),
        .b_Re(b_Re),
        .b_Im(b_Im),
        .c_Re(c_Re),
        .c_Im(c_Im),
        .d_Re(d_Re),
        .d_Im(d_Im),
        .overflow(overflow)
    );

    integer test_count = 0;
    integer pass_count = 0;
    reg signed [7:0] test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im;
    reg signed [9:0] expected_d_Re, expected_d_Im;
    reg expected_overflow;

    task run_test(
        input signed [7:0] a_Re_in, a_Im_in, b_Re_in, b_Im_in, c_Re_in, c_Im_in,
        input signed [9:0] expected_d_Re_in, expected_d_Im_in,
        input expected_overflow_in
    );
        begin
            a_Re = a_Re_in;
            a_Im = a_Im_in;
            b_Re = b_Re_in;
            b_Im = b_Im_in;
            c_Re = c_Re_in;
            c_Im = c_Im_in;

            #10;

            test_count = test_count + 1;

            if (d_Re === expected_d_Re_in && d_Im === expected_d_Im_in && overflow === expected_overflow_in) begin
                $display("Test %0d PASSED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d, c_Re=%0d, c_Im=%0d -> d_Re=%0d, d_Im=%0d, overflow=%b",
                         test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im, d_Re, d_Im, overflow);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %0d FAILED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d, c_Re=%0d, c_Im=%0d -> d_Re=%0d (expected %0d), d_Im=%0d (expected %0d), overflow=%b (expected %b)",
                         test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im, d_Re, expected_d_Re_in, d_Im, expected_d_Im_in, overflow, expected_overflow_in);
            end
        end
    endtask

    initial begin
        // Initialize test count
        test_count = 0;

        // Test Case 1: Simple addition (No overflow)
        run_test(8'b00001001, 8'b00000011, 8'b00000001, 8'b00000110, 8'b00000100, 8'b00000011, 10'b00001110, 10'b00001100, 1'b0);

        // Test Case 2: Negative inputs / mixed (No overflow)
        run_test(8'b11111101, 8'b11111110, 8'b00000001, 8'b00000001, 8'b11111111, 8'b11111111, 10'b11111101, 10'b11111110, 1'b0);

        // Test Case 3: Zero inputs (No overflow)
        run_test(8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 10'b00000000, 10'b00000000, 1'b0);

        $display("=====================================");
        $display("Test Summary: %0d/%0d tests passed", pass_count, test_count);
        $display("=====================================");

        $stop;
    end

endmodule
