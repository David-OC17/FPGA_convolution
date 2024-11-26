module adder3_complex #(parameter QI = 3, QF = 3)(
    input wire signed [QI+QF-1:0] a_Re, a_Im, b_Re, b_Im, c_Re, c_Im,
    output reg signed [QI+QF-1:0] d_Re, d_Im,

    output reg overflow
);

parameter WIDTH = QI + QF; // Total bit width

reg overflow_ab_real, overflow_abc_real;
reg overflow_ab_imag, overflow_abc_imag;

reg signed [WIDTH-1:0] partial_sum_real, partial_sum_imag;
reg signed [WIDTH-1:0] real_full_range, imag_full_range;

always @(*) begin
    partial_sum_real = a_Re + b_Re;
    partial_sum_imag = a_Im + b_Im;

    // Overflow for partial sums
    overflow_ab_real = ((a_Re[WIDTH-1] == b_Re[WIDTH-1]) &&
                        (partial_sum_real[WIDTH-1] != a_Re[WIDTH-1]));
    overflow_ab_imag = ((a_Im[WIDTH-1] == b_Im[WIDTH-1]) &&
                        (partial_sum_imag[WIDTH-1] != a_Im[WIDTH-1]));

    real_full_range = partial_sum_real + c_Re;
    imag_full_range = partial_sum_imag + c_Im;

    overflow_abc_real = ((partial_sum_real[WIDTH-1] == c_Re[WIDTH-1]) &&
                        (real_full_range[WIDTH-1] != partial_sum_real[WIDTH-1]));
    overflow_abc_imag = ((partial_sum_imag[WIDTH-1] == c_Im[WIDTH-1]) &&
                        (imag_full_range[WIDTH-1] != partial_sum_imag[WIDTH-1]));

    // Final assignments
    overflow = overflow_ab_real || overflow_abc_real || overflow_ab_imag || overflow_abc_imag;

    d_Re = real_full_range;
    d_Im = imag_full_range;
end

endmodule
