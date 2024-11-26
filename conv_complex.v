module conv_complex #(parameter QI = 3, QF = 3, NUM_ELEMS = 100)(
    input wire clk, rst, en,
    input wire [2*3*(QI+QF)-1:0] kernel,
    input wire [2*(QI+QF)*NUM_ELEMS-1:0] signal,

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
reg [$clog2(NUM_ELEMS)-1:0] conv_counter;

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

always @(*)
begin
    case(curr_state)
    IDLE:
    begin
        if (en)
        begin

        $display("Staaaaaaaaaaarted");

            padded_signal = {{4*WORD_LENGTH{1'b0}}, signal, {4*WORD_LENGTH{1'b0}}};

            kernel_sec1_real =  kernel[6*WORD_LENGTH-1:5*WORD_LENGTH];
            kernel_sec1_imag =  kernel[5*WORD_LENGTH-1:4*WORD_LENGTH];

        $display("kernel_real1: %b", kernel_sec1_real);
        $display("kernel_imag1: %b", kernel_sec1_imag);

            kernel_sec2_real =  kernel[4*WORD_LENGTH-1:3*WORD_LENGTH];
            kernel_sec2_imag =  kernel[3*WORD_LENGTH-1:2*WORD_LENGTH];

        $display("kernel_real2: %b", kernel_sec2_real);
        $display("kernel_imag2: %b", kernel_sec2_imag);

            kernel_sec3_real =  kernel[2*WORD_LENGTH-1:WORD_LENGTH];
            kernel_sec3_imag =  kernel[WORD_LENGTH-1:0];

        $display("kernel_real3: %b", kernel_sec3_real);
        $display("kernel_imag3: %b", kernel_sec3_imag);

            done = 0;
            conv_counter = 0;

            next_state = CONV;
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

            next_state = IDLE;
        end
    end 

    CONV:
    begin
        if (conv_counter < NUM_ELEMS + 2)
        begin
            sig1_Im = padded_signal[WORD_LENGTH - 1 : 0];
            sig1_Re = padded_signal[2*WORD_LENGTH - 1 : WORD_LENGTH];

        $display("signal1_Im: %b", sig1_Im);
        $display("signal1_Re: %b", sig1_Re);

            sig2_Im = padded_signal[3*WORD_LENGTH - 1 : 2*WORD_LENGTH];
            sig2_Re = padded_signal[4*WORD_LENGTH - 1 : 3*WORD_LENGTH];

        $display("signal2_Im: %b", sig2_Im);
        $display("signal2_Re: %b", sig2_Re);

            sig3_Im = padded_signal[5*WORD_LENGTH - 1 : 4*WORD_LENGTH];
            sig3_Re = padded_signal[6*WORD_LENGTH - 1 : 5*WORD_LENGTH];

        $display("signal3_Im: %b", sig3_Im);
        $display("signal3_Re: %b", sig3_Re);

        $display("//////////////////////////////////////////////////////");

        $display("mult1_Re: %b", mult1_Re_tmp);
        $display("mult1_Im: %b", mult1_Im_tmp);

        $display("mult2_Re: %b", mult2_Re_tmp);
        $display("mult2_Im: %b", mult2_Im_tmp);

        $display("mult3_Re: %b", mult3_Re_tmp);
        $display("mult3_Im: %b", mult3_Im_tmp);

        $display("//////////////////////////////////////////////////////");

        $display("adder_Re: %b", adder_Re);
        $display("adder_Im: %b", adder_Im);

            conv = conv <<< (2*WORD_LENGTH);
            conv[WORD_LENGTH - 1 : 0] = adder_Re;
            conv[2*WORD_LENGTH - 1 : WORD_LENGTH] = adder_Im;

            padded_signal = padded_signal >>> (2*WORD_LENGTH);

            conv_counter = conv_counter + 1;

            next_state = CONV;
        end

        else
        begin
            next_state = DONE;
        end
    end 

    DONE:
    begin
        done = 1;
        next_state = IDLE;
        $stop;
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

        next_state = IDLE;
    end
    endcase
    
end

endmodule