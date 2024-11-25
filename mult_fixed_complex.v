module mult_fixed_complex #(parameter QI = 3, QF = 3)(
    input signed [QI+QF-1:0] a_Re, a_Im, b_Re, b_Im, // Fixed-point inputs
    output signed [QI+QF-1:0] y_Re, y_Im,           // Fixed-point outputs
    output reg overflow_mult,    // Overflow flag for multiplication
    output reg overflow_add_sub  // Overflow flag for addition/subtraction
);

localparam TOTAL_BITS = 2 * (QI + QF);  // Total bit width of intermediate results

reg signed [TOTAL_BITS-1:0] mult_aux_1, mult_aux_2, mult_aux_3, mult_aux_4;

// Intermediate addition/subtraction results
reg signed [TOTAL_BITS-1:0] mult_result_real, mult_result_imag;

// Scaled final results
reg signed [QI+QF-1:0] real_scaled, imag_scaled;

always @(*) begin
    overflow_mult = 0;
    overflow_add_sub = 0;

    mult_aux_1 = a_Re * b_Re;
    mult_aux_2 = a_Re * b_Im;
    mult_aux_3 = a_Im * b_Re;
    mult_aux_4 = a_Im * b_Im;

    // Check for overflow in multiplications
    if (|mult_aux_1[TOTAL_BITS-1:QI+QF] || |mult_aux_2[TOTAL_BITS-1:QI+QF] ||
        |mult_aux_3[TOTAL_BITS-1:QI+QF] || |mult_aux_4[TOTAL_BITS-1:QI+QF]) begin
        overflow_mult = 1;
    end

    mult_result_real = mult_aux_1 - mult_aux_4; // (a_Re * b_Re - a_Im * b_Im)
    mult_result_imag = mult_aux_2 + mult_aux_3; // (a_Re * b_Im + a_Im * b_Re)

    // Check for overflow in addition/subtraction
    if (mult_result_real[TOTAL_BITS-1] != mult_result_real[QI+QF]) begin
        overflow_add_sub = 1;
    end
    if (mult_result_imag[TOTAL_BITS-1] != mult_result_imag[QI+QF]) begin
        overflow_add_sub = 1;
    end

    real_scaled = mult_result_real[QI+QF+QF-1:QF];
    imag_scaled = mult_result_imag[QI+QF+QF-1:QF];
end

assign y_Re = real_scaled;
assign y_Im = imag_scaled;

endmodule
