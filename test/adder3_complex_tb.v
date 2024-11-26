module tb_adder3_complex;

    parameter QI = 4;  // Integer part
    parameter QF = 4;  // Fractional part
    parameter WIDTH = QI + QF; // Total bit width

    reg signed [WIDTH-1:0] a_Re, a_Im, b_Re, b_Im, c_Re, c_Im;
    wire signed [WIDTH-1:0] d_Re, d_Im;
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

    task run_test;
        input signed [WIDTH-1:0] test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im;
        input signed [WIDTH-1:0] expected_d_Re, expected_d_Im;
        input expected_overflow;
        begin
            a_Re = test_a_Re;
            a_Im = test_a_Im;
            b_Re = test_b_Re;
            b_Im = test_b_Im;
            c_Re = test_c_Re;
            c_Im = test_c_Im;

            #10; // Wait for computation

            test_count = test_count + 1;

            if (d_Re === expected_d_Re && d_Im === expected_d_Im && overflow === expected_overflow) begin
                $display("Test %0d PASSED:", test_count);
                $display("Inputs:  a_Re=%b, a_Im=%b, b_Re=%b, b_Im=%b, c_Re=%b, c_Im=%b", 
                         test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im);
                $display("Outputs: d_Re=%b, d_Im=%b, Overflow=%b", d_Re, d_Im, overflow);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %0d FAILED:", test_count);
                $display("Inputs:  a_Re=%b, a_Im=%b, b_Re=%b, b_Im=%b, c_Re=%b, c_Im=%b", 
                         test_a_Re, test_a_Im, test_b_Re, test_b_Im, test_c_Re, test_c_Im);
                $display("Outputs: d_Re=%b (expected %b), d_Im=%b (expected %b), Overflow=%b (expected %b)", 
                         d_Re, expected_d_Re, d_Im, expected_d_Im, overflow, expected_overflow);
            end
        end
    endtask

    initial begin
        test_count = 0;

        // Test Case 1: Simple addition (No overflow)
        run_test(8'b0001_0010, 8'b0000_0011, // a = 1.125 + 0.1875i
                 8'b0000_0001, 8'b0000_0110, // b = 0.0625 + 0.375i
                 8'b0000_0100, 8'b0000_0011, // c = 0.25 + 0.1875i
                 8'b0001_0111, 8'b0000_1100, // d = 1.4375 + 0.75i
                 1'b0);                    // No overflow

        // Test Case 2: Negative inputs / mixed (No overflow)
        run_test(8'b11111101, 8'b11111110, // a = -0.1875 - 0.125i
                 8'b00000001, 8'b00000001, // b = 0.0625 + 0.0625i
                 8'b11111111, 8'b11111111, // c = -0.0625 - 0.0625i
                 8'b11111101, 8'b11111110, // d = -0.1875 - 0.125i
                 1'b0);                    // No overflow

        // Test Case 3: Zero inputs (No overflow)
        run_test(8'b00000000, 8'b00000000, // a = 0 + 0i
                 8'b00000000, 8'b00000000, // b = 0 + 0i
                 8'b00000000, 8'b00000000, // c = 0 + 0i
                 8'b00000000, 8'b00000000, // d = 0 + 0i
                 1'b0);                    // No overflow

        $display("=====================================");
        $display("Test Summary: %0d/%0d tests passed", pass_count, test_count);
        $display("=====================================");

        $stop; // End simulation
    end

endmodule
