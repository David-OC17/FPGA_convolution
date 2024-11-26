module conv_complex #(parameter QI = 3, QF = 3, NUM_ELEMS = 100, WORD_LENGTH = (QI+QF))(
   input wire clk, rst, en,
   input wire [2*3*WORD_LENGTH] kernel,
   input wire [2*WORD_LENGTH*NUM_ELEMS] signal,

   output reg[2*WORD_LENGTH*(NUM_ELEMS+2)] conv,
   output reg overflow,
   output reg done
);

localparam KERNEL_SIZE = 3; // kernel size

// ================================================== //
//                     Aux vars                       // 
// ================================================== //

reg [2*WORD_LENGTH*(NUM_ELEMS+KERNEL_SIZE-1)] padded_signal;
reg [2*WORD_LENGTH] kernel_sec1_real, kernel_sec1_imag,
                    kernel_sec2_real, kernel_sec2_imag,
                    kernel_sec3_real, kernel_sec3_imag;

// ================================================== //
//               Complex fixed mult                   // 
// ================================================== //

reg overflow_mult1, overflow_mult2, overflow_mult3;
reg bad_rep_mult1, bad_rep_mult2, bad_rep_mult3;

// Inputs to complex multiplications
reg signed [WORD_LENGTH-1:0] sig1_Re, sig1_Im, sig2_Re, sig2_Im, sig3_Re, sig3_Im;

// Results of complex multiplications
reg signed [WORD_LENGTH-1:0]  mult1_Re_tmp, mult1_Im_tmp,
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

reg signed [WORD_LENGTH-1:0] adder_Re, adder_Im;
reg overflow_adder;

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

always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        done <= 0;

        conv <= 0;
        overflow <= 0;
        conv_counter <= 0;

        mult1_Re_tmp <= 0; mult1_Im_tmp <= 0;
        mult2_Re_tmp <= 0; mult2_Im_tmp <= 0;
        mult3_Re_tmp <= 0; mult3_Im_tmp <= 0;

        adder_Re_tmp <= 0; adder_Im_tmp <= 0;

        kernel_sec1_real <= 0; kernel_sec1_imag <= 0;
        kernel_sec2_real <= 0; kernel_sec2_imag <= 0;
        kernel_sec3_real <= 0; kernel_sec3_imag <= 0;

        next_state = IDLE;
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
        conv <= 0;
        overflow <= 1;
        done <= 1;
    end
end


// States
parameter [1:0] IDLE = 0,
                CONV = 1,
                DONE = 2;

reg [2:0] curr_state, next_state;
reg [$clog2(NUM_ELEMS)] conv_counter;

always @(posedge clk)
begin
    case(curr_state)
    IDLE:
    begin
        if (en)
        begin
            padded_signal = {4*WORD_LENGTH{1'b0}, signal, 4*WORD_LENGTH{1'b0}};

            kernel_sec1_real =  kernel[2*WORD_LENGTH-1:WORD_LENGTH];
            kernel_sec1_imag =  kernel[WORD_LENGTH-1:0];

            kernel_sec2_real =  kernel[4*WORD_LENGTH-1:3*WORD_LENGTH];
            kernel_sec2_imag =  kernel[3*WORD_LENGTH-1:2*WORD_LENGTH];

            kernel_sec3_real =  kernel[6*WORD_LENGTH-1:5*WORD_LENGTH];
            kernel_sec3_imag =  kernel[5*WORD_LENGTH-1:4*WORD_LENGTH];

            next_state = CONV;
        end
        else
        begin
            done = 0;
            overflow = 0;

            next_state = IDLE;
        end
    end 

    CONV:
    begin
        if (conv_counter < NUM_ELEMS + 2)
        begin
            sig1_Im = signal[(2*conv_counter + 1)*WORD_LENGTH - 1 : 2*conv_counter*WORD_LENGTH];
            sig1_Re = signal[(2*conv_counter + 2)*WORD_LENGTH - 1 : (2*conv_counter + 1)*WORD_LENGTH];

            sig2_Im = signal[(2*conv_counter + 3)*WORD_LENGTH - 1 : (2*conv_counter + 2)*WORD_LENGTH];
            sig2_Re = signal[(2*conv_counter + 4)*WORD_LENGTH - 1 : (2*conv_counter + 3)*WORD_LENGTH];

            sig3_Im = signal[(2*conv_counter + 5)*WORD_LENGTH - 1 : (2*conv_counter + 4)*WORD_LENGTH];
            sig3_Re= signal[(2*conv_counter + 6)*WORD_LENGTH - 1 : (2*conv_counter + 5)*WORD_LENGTH];

            // Complex mult and add done with new a, b, c values
            conv[(2*conv_counter + 1)*WORD_LENGTH - 1 : 2*conv_counter*WORD_LENGTH] = adder_Re;
            conv[(2*conv_counter + 2)*WORD_LENGTH - 1 : (2*conv_counter + 1)*WORD_LENGTH] = adder_Im;

            next_state = CONV;
        end
        else
        begin
            conv_counter = 0;
            next_state = DONE;
        end
    end 

    DONE:
    begin
        done = 1;
        next_state = IDLE;
    end 

    default:
    begin
        next_state = IDLE;
        done = 0;

        conv = 0;
        overflow = 0;
        conv_counter = 0;

        mult1_Re_tmp = 0; mult1_Im_tmp = 0;
        mult2_Re_tmp = 0; mult2_Im_tmp = 0;
        mult3_Re_tmp = 0; mult3_Im_tmp = 0;

        adder_Re_tmp = 0; adder_Im_tmp = 0;

        kernel_sec1_real = 0; kernel_sec1_imag = 0;
        kernel_sec2_real = 0; kernel_sec2_imag = 0;
        kernel_sec3_real = 0; kernel_sec3_imag = 0;
    end
    endcase
    
end

endmodule