module conv_complex #(parameter QI = 3, QF = 3, NUM_ELEMS = 100)(
    input wire clk, rst, en,
    input wire [2*3*(QI+QF)-1:0] kernel,
    input wire [2*(QI+QF)*NUM_ELEMS-1:0] signal,
	input wire [4:0] counter,

    output reg [2*(QI+QF)*(NUM_ELEMS+2)-1:0] conv,
    output reg overflow,
    output reg done
);

localparam WORD_LENGTH = QI + QF;
localparam KERNEL_SIZE = 3; // kernel size
localparam WAIT_TIME_OP = 10; // Time to wait before performing next convolution step

// ================================================== //
//                     Aux vars                       // 
// ================================================== //

reg [2*WORD_LENGTH*(NUM_ELEMS+2*(KERNEL_SIZE-1))-1:0] padded_signal;

reg [WORD_LENGTH-1:0]   kernel_sec1_real, kernel_sec1_imag,
                        kernel_sec2_real, kernel_sec2_imag,
                        kernel_sec3_real, kernel_sec3_imag;

// ================================================== //
//               Complex fixed mult                   // 
// ================================================== //

wire overflow_mult1, overflow_mult2, overflow_mult3;
wire bad_rep_mult1, bad_rep_mult2, bad_rep_mult3;

// Inputs to complex multiplications
reg signed [WORD_LENGTH-1:0] sig1_Re, sig1_Im, sig2_Re, sig2_Im, sig3_Re, sig3_Im;

// Results of complex multiplications
wire signed [WORD_LENGTH-1:0] mult1_Re_tmp, mult1_Im_tmp,
                              mult2_Re_tmp, mult2_Im_tmp,
                              mult3_Re_tmp, mult3_Im_tmp;

mult_fixed_complex #(
    .QI(QI),
    .QF(QF)
) MULT_KERNEL1 (
    .a_Re(kernel_sec1_real),
    .a_Im(kernel_sec1_imag),

    .b_Re(sig1_Re),
    .b_Im(sig1_Im),

    .y_Re(mult1_Re_tmp),
    .y_Im(mult1_Im_tmp),

    .overflow(overflow_mult1),
    .bad_rep(bad_rep_mult1)
);

mult_fixed_complex #(
    .QI(QI),
    .QF(QF)
) MULT_KERNEL2 (
    .a_Re(kernel_sec2_real),
    .a_Im(kernel_sec2_imag),

    .b_Re(sig2_Re),
    .b_Im(sig2_Im),

    .y_Re(mult2_Re_tmp),
    .y_Im(mult2_Im_tmp),

    .overflow(overflow_mult2),
    .bad_rep(bad_rep_mult2)
);

mult_fixed_complex #(
    .QI(QI),
    .QF(QF)
) MULT_KERNEL3 (
    .a_Re(kernel_sec3_real),
    .a_Im(kernel_sec3_imag),

    .b_Re(sig3_Re),
    .b_Im(sig3_Im),

    .y_Re(mult3_Re_tmp),
    .y_Im(mult3_Im_tmp),

    .overflow(overflow_mult3),
    .bad_rep(bad_rep_mult3)
);

// ================================================== //
//                   3 Complex adder                  // 
// ================================================== //

wire signed [WORD_LENGTH-1:0] adder_Re, adder_Im;
wire overflow_adder;

adder3_complex #(
    .QI(QI),
    .QF(QF)
) ADDER (
    .a_Re(mult1_Re_tmp),
    .a_Im(mult1_Im_tmp),

    .b_Re(mult2_Re_tmp),
    .b_Im(mult2_Im_tmp),

    .c_Re(mult3_Re_tmp),
    .c_Im(mult3_Im_tmp),

    .d_Re(adder_Re),
    .d_Im(adder_Im),

    .overflow(overflow_adder)
);


// ================================================== //
//                   State machine                    // 
// ================================================== //

// States
parameter   IDLE = 2'b00,
            CONV = 2'b01,
            DONE = 2'b10;

reg [2:0] curr_state, next_state;
reg [$clog2(NUM_ELEMS+2)-1:0] conv_counter;

always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        curr_state <= IDLE;
    end
    else
    begin
        curr_state <= next_state;
    end
end

always @(posedge clk)
begin
    if (overflow_adder || overflow_mult1 || overflow_mult2 || overflow_mult3)
    begin
        overflow <= 1;
    end
end



always @(clk, en, done, conv_counter)
begin
    case(curr_state)
    IDLE:
    begin
        if (en)
        begin
            padded_signal = {{4*WORD_LENGTH{1'b0}}, signal, {4*WORD_LENGTH{1'b0}}};

            kernel_sec1_real =  kernel[6*WORD_LENGTH-1:5*WORD_LENGTH];
            kernel_sec1_imag =  kernel[5*WORD_LENGTH-1:4*WORD_LENGTH];

            kernel_sec2_real =  kernel[4*WORD_LENGTH-1:3*WORD_LENGTH];
            kernel_sec2_imag =  kernel[3*WORD_LENGTH-1:2*WORD_LENGTH];

            kernel_sec3_real =  kernel[2*WORD_LENGTH-1:WORD_LENGTH];
            kernel_sec3_imag =  kernel[WORD_LENGTH-1:0];

            done = 0;
            conv_counter = 0;

            next_state <= CONV;
        end

        else
        begin
            done = 0;
            conv = 0;
            conv_counter = 0;
            padded_signal = 0;

            kernel_sec1_real = 0; kernel_sec1_imag = 0;
            kernel_sec2_real = 0; kernel_sec2_imag = 0;
            kernel_sec3_real = 0; kernel_sec3_imag = 0;

            next_state <= IDLE;
        end
    end 

    CONV:
    begin
        if (conv_counter < NUM_ELEMS + 2)
        begin
            sig1_Im = padded_signal[WORD_LENGTH - 1 : 0];
            sig1_Re = padded_signal[2*WORD_LENGTH - 1 : WORD_LENGTH];

            sig2_Im = padded_signal[3*WORD_LENGTH - 1 : 2*WORD_LENGTH];
            sig2_Re = padded_signal[4*WORD_LENGTH - 1 : 3*WORD_LENGTH];

            sig3_Im = padded_signal[5*WORD_LENGTH - 1 : 4*WORD_LENGTH];
            sig3_Re = padded_signal[6*WORD_LENGTH - 1 : 5*WORD_LENGTH];

            padded_signal = padded_signal >>> (2*WORD_LENGTH);
				
				conv = conv <<< (2*WORD_LENGTH);
            conv[WORD_LENGTH - 1 : 0] = adder_Re;
            conv[2*WORD_LENGTH - 1 : WORD_LENGTH] = adder_Im;

            conv_counter = conv_counter + 1;

            next_state <= CONV;
        end

        else
        begin
            next_state <= DONE;
			conv_counter  = conv_counter;
        end
    end 

    DONE:
    begin
			
        done = 1;
		  conv = conv <<< (2*WORD_LENGTH);
		  conv[WORD_LENGTH - 1 : 0] = adder_Re;
		  conv[2*WORD_LENGTH - 1 : WORD_LENGTH] = adder_Im;
        next_state <= IDLE;
    end 

    default:
    begin
        done = 0;

        conv = 0;
        overflow = 0;
        conv_counter = 0;

        kernel_sec1_real = 0; kernel_sec1_imag = 0;
        kernel_sec2_real = 0; kernel_sec2_imag = 0;
        kernel_sec3_real = 0; kernel_sec3_imag = 0;

        next_state <= IDLE;
    end
    endcase
	 
end

endmodule

// module conv_complex #(parameter QI = 3, QF = 3, NUM_ELEMS = 100)(
//     input wire clk,
//     input wire rst,
//     input wire en,
//     input wire [2*3*(QI+QF)-1:0] kernel,
//     input wire [2*(QI+QF)*NUM_ELEMS-1:0] signal,

//     output reg [2*(QI+QF)*(NUM_ELEMS+2)-1:0] conv,
//     output reg overflow,
//     output reg done
// );

// localparam WORD_LENGTH = QI + QF;
// localparam KERNEL_SIZE = 3; // kernel size

// // ================================================== //
// //                     Aux vars                       // 
// // ================================================== //

// reg [2*WORD_LENGTH*(NUM_ELEMS+2*(KERNEL_SIZE-1))-1:0] padded_signal;

// reg [WORD_LENGTH-1:0]   kernel_sec1_real, kernel_sec1_imag,
//                         kernel_sec2_real, kernel_sec2_imag,
//                         kernel_sec3_real, kernel_sec3_imag;

// // ================================================== //
// //               Complex fixed mult                   // 
// // ================================================== //

// wire overflow_mult1, overflow_mult2, overflow_mult3;

// // Inputs to complex multiplications
// reg signed [WORD_LENGTH-1:0] sig1_Re, sig1_Im, sig2_Re, sig2_Im, sig3_Re, sig3_Im;

// // Results of complex multiplications
// wire signed [WORD_LENGTH-1:0] mult1_Re_tmp, mult1_Im_tmp,
//                               mult2_Re_tmp, mult2_Im_tmp,
//                               mult3_Re_tmp, mult3_Im_tmp;

// mult_fixed_complex #(
//     .QI(QI),
//     .QF(QF)
// ) MULT_KERNEL1 (
//     .a_Re(kernel_sec1_real),
//     .a_Im(kernel_sec1_imag),
//     .b_Re(sig1_Re),
//     .b_Im(sig1_Im),
//     .y_Re(mult1_Re_tmp),
//     .y_Im(mult1_Im_tmp),
//     .overflow(overflow_mult1)
// );

// mult_fixed_complex #(
//     .QI(QI),
//     .QF(QF)
// ) MULT_KERNEL2 (
//     .a_Re(kernel_sec2_real),
//     .a_Im(kernel_sec2_imag),
//     .b_Re(sig2_Re),
//     .b_Im(sig2_Im),
//     .y_Re(mult2_Re_tmp),
//     .y_Im(mult2_Im_tmp),
//     .overflow(overflow_mult2)
// );

// mult_fixed_complex #(
//     .QI(QI),
//     .QF(QF)
// ) MULT_KERNEL3 (
//     .a_Re(kernel_sec3_real),
//     .a_Im(kernel_sec3_imag),
//     .b_Re(sig3_Re),
//     .b_Im(sig3_Im),
//     .y_Re(mult3_Re_tmp),
//     .y_Im(mult3_Im_tmp),
//     .overflow(overflow_mult3)
// );

// // ================================================== //
// //                   3 Complex adder                  // 
// // ================================================== //

// wire signed [WORD_LENGTH-1:0] adder_Re, adder_Im;
// wire overflow_adder;

// adder3_complex #(
//     .QI(QI),
//     .QF(QF)
// ) ADDER (
//     .a_Re(mult1_Re_tmp),
//     .a_Im(mult1_Im_tmp),
//     .b_Re(mult2_Re_tmp),
//     .b_Im(mult2_Im_tmp),
//     .c_Re(mult3_Re_tmp),
//     .c_Im(mult3_Im_tmp),
//     .d_Re(adder_Re),
//     .d_Im(adder_Im),
//     .overflow(overflow_adder)
// );

// // ================================================== //
// //                   State machine                    // 
// // ================================================== //

// parameter   IDLE = 2'b00,
//             CONV = 2'b01,
//             DONE = 2'b10;

// reg [1:0] curr_state, next_state;
// reg [$clog2(NUM_ELEMS+3)-1:0] conv_counter;

// always @(posedge clk or negedge rst) begin
//     if (!rst) begin
//         curr_state <= IDLE;
//         overflow <= 0;
//     end else begin
//         curr_state <= next_state;
//         if (overflow_adder || overflow_mult1 || overflow_mult2 || overflow_mult3)
//             overflow <= 1;
//     end
// end

// always @(*) begin
//     // next_state = curr_state;
//     done = 0;
//     conv_counter = conv_counter;
//     conv = conv;
//     // kernel_sec1_real = 0; kernel_sec1_imag = 0;
//     // kernel_sec2_real = 0; kernel_sec2_imag = 0;
//     // kernel_sec3_real = 0; kernel_sec3_imag = 0;
//     // sig1_Re = 0; sig1_Im = 0;
//     // sig2_Re = 0; sig2_Im = 0;
//     // sig3_Re = 0; sig3_Im = 0;

//     case (curr_state)
//         IDLE: begin
//             $display("idle:");
//             if (en) begin
//             $display("enable idle:");
//                 padded_signal = {{2*WORD_LENGTH{1'b0}}, signal, {2*WORD_LENGTH{1'b0}}};

//                 {kernel_sec3_real, kernel_sec3_imag,
//                  kernel_sec2_real, kernel_sec2_imag,
//                  kernel_sec1_real, kernel_sec1_imag} = kernel;

//                 conv = 0;
//                 conv_counter = 0;
//                 next_state = CONV;
//             end
//         end

//         CONV: begin
//             if (conv_counter < NUM_ELEMS + 2) begin
//                 {sig3_Re, sig3_Im,
//                  sig2_Re, sig2_Im,
//                  sig1_Re, sig1_Im} = padded_signal[6*WORD_LENGTH-1:0];

//                 conv = (conv << (2*WORD_LENGTH)) | {adder_Re, adder_Im};
//                 $display("conv_counter: ", conv_counter);
//                 $display("conv: ", conv);

//                 padded_signal = padded_signal >> (2*WORD_LENGTH);
//                 conv_counter = conv_counter + 1;
//                 next_state = CONV;
//             end else begin
//                 next_state = DONE;
//             end
//         end

//         DONE: begin
//             $display("done");
//             done = 1;
//             next_state = IDLE;
//         end
//     endcase
// end


// endmodule
