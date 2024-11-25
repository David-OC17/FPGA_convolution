module adder_complex #(parameter QI = 3, QF = 3)(
	input signed  [QI-1:-QF] a_Re, a_Im, b_Re, b_Im,

	output signed [QI:-QF] c_Re, c_Im,
    output wire overflow
);

reg signed [QI:-QF] real_full_range;
reg signed [QI:-QF] imag_full_range;

always @(*)
begin
    real_full_range = a_Re + b_Re;
    imag_full_range = a_Im + b_Im;
end

assign overflow = (real_full_range[QI] | imag_full_range[QF]) & 1'b1;

assign c_Re = real_full_range;
assign c_Im = imag_full_range;

endmodule