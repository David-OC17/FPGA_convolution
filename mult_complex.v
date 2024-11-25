module mult_complex #(parameter QI = 3, QF = 3)(
	input signed  [QI-1:-QF] a_Re, a_Im, b_Re, b_Im,

	output signed [2*QI:-2*QF] y_Re, y_Im
);

reg signed [2*QI:-2*QF] mult_aux_1,
						mult_aux_2,
						mult_aux_3,
						mult_aux_4;

reg signed [2*QI:-2*QF] real_full_range;
reg signed [2*QI:-2*QF] imag_full_range;

always @(*)
begin
	mult_aux_1 = a_Re * b_Re;
	mult_aux_2 = a_Re * b_Im;
	mult_aux_3 = a_Im * b_Re;
	mult_aux_4 = a_Im * b_Im;
	
	real_full_range = mult_aux_1 - mult_aux_4;
	imag_full_range = mult_aux_3 + mult_aux_2;
end

assign y_Re = real_full_range;
assign y_Im = imag_full_range;

endmodule 
