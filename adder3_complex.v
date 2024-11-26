module adder3_complex #(parameter QI = 3, QF = 3)(
    input signed [QI:-QF] a_Re, a_Im, b_Re, b_Im, c_Re, c_Im,
    output signed [QI+1:-QF+1] d_Re, d_Im,
    output wire overflow
);

reg signed [QI+1:-QF+1] real_full_range;
reg signed [QI+1:-QF+1] imag_full_range;

reg overflow_real, overflow_imag;

wire overflow_ab_real, overflow_abc_real;
wire overflow_ab_imag, overflow_abc_imag;

// Partial sums
wire signed [QI+1:-QF+1] partial_sum_real = a_Re + b_Re;
wire signed [QI+1:-QF+1] partial_sum_imag = a_Im + b_Im;

// Overflow for partial sums
assign overflow_ab_real = ((a_Re[QI] == b_Re[QI]) && (partial_sum_real[QI+1] != a_Re[QI]));
assign overflow_ab_imag = ((a_Im[QI] == b_Im[QI]) && (partial_sum_imag[QI+1] != a_Im[QI]));

// Overflow for final sums
assign overflow_abc_real = ((partial_sum_real[QI+1] == c_Re[QI]) && (real_full_range[QI+2] != partial_sum_real[QI+1]));
assign overflow_abc_imag = ((partial_sum_imag[QI+1] == c_Im[QI]) && (imag_full_range[QI+2] != partial_sum_imag[QI+1]));

// Final overflow
assign overflow = overflow_ab_real || overflow_abc_real || overflow_ab_imag || overflow_abc_imag;

// Final sums
always @(*) begin
    real_full_range = partial_sum_real + c_Re;
    imag_full_range = partial_sum_imag + c_Im;
end

assign d_Re = real_full_range;
assign d_Im = imag_full_range;

endmodule
