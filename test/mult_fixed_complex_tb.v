`timescale 1ns / 1ps

// module tb_mult_fixed_complex;

//     parameter QI = 3;  // Integer part (3 bits)
//     parameter QF = 3;  // Fractional part (3 bits)

//     // Inputs
//     reg signed [QI-1:-QF] a_Re, a_Im, b_Re, b_Im;

//     // Outputs
//     wire signed [2*QI-1:-QF] y_Re, y_Im;

//     // Unit Under Test (UUT)
//     mult_fixed_complex #(QI, QF) uut (
//         .a_Re(a_Re),
//         .a_Im(a_Im),
//         .b_Re(b_Re),
//         .b_Im(b_Im),
//         .y_Re(y_Re),
//         .y_Im(y_Im)
//     );

//     // Variables to track test cases
//     integer pass_count = 0;
//     integer test_count = 0;

//     task run_test;
//         input signed [QI-1:-QF] test_a_Re, test_a_Im, test_b_Re, test_b_Im;
//         input signed [2*QI-1:-QF] expected_y_Re, expected_y_Im;
//         begin
//             a_Re = test_a_Re;
//             a_Im = test_a_Im;
//             b_Re = test_b_Re;
//             b_Im = test_b_Im;

//             #10;

//             test_count = test_count + 1;

//             if (y_Re === expected_y_Re && y_Im === expected_y_Im) begin
//                 $display("Test %0d PASSED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d -> y_Re=%0d, y_Im=%0d",
//                          test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, y_Re, y_Im);
//                 pass_count = pass_count + 1;
//             end else begin
//                 $display("Test %0d FAILED: a_Re=%0d, a_Im=%0d, b_Re=%0d, b_Im=%0d -> y_Re=%0d (expected %0d), y_Im=%0d (expected %0d)",
//                          test_count, test_a_Re, test_a_Im, test_b_Re, test_b_Im, y_Re, expected_y_Re, y_Im, expected_y_Im);
//             end
//         end
//     endtask

//     initial begin
//         // Test Case 1: Regular positive numbers
//         // (3.25 + 2.0625i) * (2.5 + 1.5i) = 3.25*2.5 - 2.0625*1.5 + (2.0625*2.5 + 3.25*1.5)i
//         // Real part: (3.25*2.5 - 2.0625*1.5) = 8.125 - 3.09375 = 5.03125
//         // Imaginary part: (2.0625*2.5 + 3.25*1.5) = 5.15625 + 4.875 = 10.03125
//         run_test(8'b0011_0100, 8'b0010_0001, 8'b0010_1000, 8'b0001_1000, 8'b00010100, 8'b00101000);

//         // Test Case 2: Zero inputs (0 + 0i) * (0 + 0i) = (0 + 0i)
//         run_test(8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000);

//         // Test Case 3: Negative inputs (-3.25 - 2.0625i) * (-2.5 + 1.5i)
//         // Real part: (-3.25*-2.5 - -2.0625*1.5) = 8.125 + 3.09375 = 11.21875
//         // Imaginary part: (-2.0625*-2.5 + -3.25*1.5) = 5.15625 - 4.875 = 0.28125
//         run_test(8'b11110100, 8'b11111000, 8'b11101000, 8'b00011000, 8'b00010101, 8'b00001000);

//         // Test Case 4: Edge Case: Max values for QI and QF
//         // Max QI-1, QF-1 values for 3-bit integer and 3-bit fractional parts.
//         run_test(8'b01111111, 8'b01111111, 8'b01111111, 8'b01111111, 8'b01111111, 8'b01111111);

//         // Test Case 5: Mixed positive and negative inputs
//         // (2.5 + 1.5i) * (-1.5 + 0.5i)
//         // Real part: (2.5*-1.5 - 1.5*0.5) = -3.75 - 0.75 = -4.5
//         // Imaginary part: (1.5*-1.5 + 2.5*0.5) = -2.25 + 1.25 = -1.0
//         run_test(8'b0010_1000, 8'b0001_1000, 8'b1110_0011, 8'b0000_1000, 8'b11111100, 8'b11111111);

//         $display("=====================================");
//         $display("Test Summary: %0d/%0d tests passed", pass_count, test_count);
//         $display("=====================================");
        
//         $stop;
//     end

// endmodule

module tb_mult_fixed_complex;

    // Parameters
    parameter QI = 4;
    parameter QF = 4;
    localparam SF = 2.0**-QF;  // Q4.4 scaling factor is 2^-4

    // Inputs
    reg signed [QI-1:-QF] a_Re, a_Im, b_Re, b_Im;

    // Outputs
    wire signed [QI-1:-QF] y_Re, y_Im;
    wire overflow_mult, overflow_add_sub;

    // Unit Under Test (UUT)
    mult_fixed_complex #(QI, QF) uut (
        .a_Re(a_Re),
        .a_Im(a_Im),

        .b_Re(b_Re),
        .b_Im(b_Im),

        .y_Re(y_Re),
        .y_Im(y_Im),

        .overflow_mult(overflow_mult),
        .overflow_add_sub(overflow_add_sub)
    );

    initial begin
        // Test Case 1: (3.25 + 2i) * (2.0625 + 3i)
        a_Re = 8'b0011_0100;  // 3.25
        a_Im = 8'b0010_0000;  // 2.0
        b_Re = 8'b0010_0001;  // 2.0625
        b_Im = 8'b0011_0000;  // 3.0

        #10;

        $display("Test Case 1:");
        $display("a = (%f + %fi), b = (%f + %fi)", $itor(a_Re*SF), $itor(a_Im*SF), $itor(b_Re*SF), $itor(b_Im*SF));
        $display("Result = (%f + %fb)", $itor(y_Re*SF), $itor(y_Im*SF));
        $display("Result = (%b + %b)", y_Re, y_Im);
        $display("Overflow in multiplication: %b", overflow_mult);
        $display("Overflow in addition/subtraction: %b", overflow_add_sub);

        $stop;
    end
endmodule
