module mult_fixed_complex #(parameter QI = 3, QF = 3)(
    input signed [QI+QF-1:0] a_Re, a_Im, b_Re, b_Im, // Fixed-point inputs
    output signed [QI+QF-1:0] y_Re, y_Im,           // Fixed-point outputs
    output reg overflow,                            // Overflow flag for addition/subtraction
    output reg bad_rep                              // Bad representation: result does not fit in QI+QF
);

localparam TOTAL_BITS = 2 * (QI + QF);  // Total bit width for intermediate results

// ================================================== //
//                 Intermediate Signals               //
// ================================================== //
reg signed [TOTAL_BITS-1:0] mult_aux_1, mult_aux_2, mult_aux_3, mult_aux_4;
reg signed [TOTAL_BITS-1:0] real_sum, imag_sum;

reg overflow_real;
reg overflow_imag;

// ================================================== //
//                     Main Logic                     //
// ================================================== //
always @(*) begin
    mult_aux_1 = a_Re * b_Re;
    mult_aux_2 = a_Re * b_Im;
    mult_aux_3 = a_Im * b_Re;
    mult_aux_4 = a_Im * b_Im;

    mult_aux_4 = mult_aux_4 * -1;

    $display("mult1: %b", mult_aux_1);
    $display("mult2: %b", mult_aux_2);
    $display("mult3: %b", mult_aux_3);
    $display("mult4: %b", mult_aux_4);

    
    real_sum = mult_aux_1 + mult_aux_4; // y_Re = (a_Re * b_Re - a_Im * b_Im)
    imag_sum = mult_aux_2 + mult_aux_3; // y_Im = (a_Re * b_Im + a_Im * b_Re)

    $display("real_sum: %b", real_sum);
    $display("imag_sum: %b", imag_sum);

    overflow_real = (mult_aux_1[TOTAL_BITS-1] == mult_aux_4[TOTAL_BITS-1]) && (real_sum[TOTAL_BITS-1] != mult_aux_1[TOTAL_BITS-1]);
    overflow_imag = (mult_aux_2[TOTAL_BITS-1] == mult_aux_3[TOTAL_BITS-1]) && (imag_sum[TOTAL_BITS-1] != mult_aux_2[TOTAL_BITS-1]);
end

assign overflow = overflow_real | overflow_imag;

assign bad_rep = (real_sum[QI+QF+QF-1:2*QF] != real_sum[2*QI+2*QF-1:2*QF]) | (imag_sum[QI+QF+QF-1:QF] != imag_sum[2*QI+2*QF-1:2*QF]);

assign y_Re = real_sum[QI+QF+QF-1:QF];
assign y_Im = imag_sum[QI+QF+QF-1:QF];

endmodule
