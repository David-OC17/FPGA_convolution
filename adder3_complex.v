module adder3_complex #(parameter QI = 3, QF = 3)(
	input signed [QI:-QF] a_Re, a_Im, b_Re, b_Im, c_Re, c_Im,

	output signed [QI+1:-QF+1] d_Re, d_Im,
    output wire overflow
);

reg signed [QI+1:-QF+1] real_full_range;
reg signed [QI+1:-QF+1] imag_full_range;

always @(*)
begin
    real_full_range = a_Re + b_Re + c_Re;
    imag_full_range = a_Im + b_Im + c_Im;
end

assign overflow = ((a_Re[QI] & b_Re[QI] & ~real_full_range[QI+1]) | 
                   (~a_Re[QI] & ~b_Re[QI] & real_full_range[QI+1])) |
                  ((a_Im[QI] & b_Im[QI] & ~imag_full_range[QI+1]) | 
                   (~a_Im[QI] & ~b_Im[QI] & imag_full_range[QI+1]));

assign d_Re = real_full_range;
assign d_Im = imag_full_range;

endmodule
