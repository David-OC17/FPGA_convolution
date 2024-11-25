module conv_complex #(parameter QI = 3, QF = 3, NUM_ELEMS = 100, WORD_LENGTH = (QI+QF))(
   input wire clk, rst, en,
   input wire [2*3*WORD_LENGTH] input_kernel,
   input wire [2*WORD_LENGTH*NUM_ELEMS] input_signal,

   output reg[2*WORD_LENGTH*(NUM_ELEMS+4)] res,
   output reg overflow,
   output reg done
)

// ================================================== //
//                     Aux vars                       // 
// ================================================== //

reg [2*WORD_LENGTH*(NUM_ELEMS-3)] signal;
reg [2*3*WORD_LENGTH] kernel;

// ================================================== //
//                   Complex mult                     // 
// ================================================== //

reg overflow_mult;

// Inputs to complex multiplications
reg signed  [QI-1:-QF] a_Re_tmp, a_Im_tmp, b_Re_tmp, b_Im_tmp, c_Re_tmp, c_Im_tmp;

// Results of complex multiplications
reg signed [2*QI:-2*QF] mult1_Re_tmp, mult1_Im_tmp;
reg signed [2*QI:-2*QF] mult3_Re_tmp, mult3_Im_tmp;
reg signed [2*QI:-2*QF] mult3_Re_tmp, mult3_Im_tmp;

mult_complex #(
    .QI(QI),
    .QF(QF)
) MULT_KERNEL1 (
    .a_Im(kernel[WORD_LENGTH:0]),
    .a_Re(kernel[2*WORD_LENGTH:WORD_LENGTH+1]),

    .b_Re(a_Re_tmp),
    .b_Im(a_Im_tmp),

    .b_Re(mult1_Re_tmp),
    .b_Im(mult1_Im_tmp),

    // TODO fix overflow condition and add second signal to modules
    .overflow(overflow_mult)
);

mult_complex #(
    .QI(QI),
    .QF(QF)
) MULT_KERNEL2 (
    .a_Im(3*WORD_LENGTH:2*WORD_LENGTH+1),
    .a_Re(4*WORD_LENGTH:3*WORD_LENGTH+1),

    .b_Re(b_Re_tmp),
    .b_Im(b_Im_tmp),

    .b_Re(mult2_Re_tmp),
    .b_Im(mult2_Im_tmp),

    .overflow(overflow_mult)
);

mult_complex #(
    .QI(QI),
    .QF(QF)
) MULT_KERNEL3 (
    .a_Im(5*WORD_LENGTH:4*WORD_LENGTH+1),
    .a_Re(6*WORD_LENGTH:5*WORD_LENGTH+1),

    .b_Re(c_Re_tmp),
    .b_Im(c_Im_tmp),

    .b_Re(mult3_Re_tmp),
    .b_Im(mult3_Im_tmp),

    .overflow(overflow_mult)
);


// ================================================== //
//                   3 Complex adder                  // 
// ================================================== //

reg signed [QI+1:-QF+1] adder_Re, adder_Im;
reg overflow_adder;

adder3_complex #(
    .QI(QI),
    .QF(QF)
) ADDER1 (
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

        res <= 0;
        overflow <= 0;
        conv_counter <= 0;

        adder_Re_tmp <= 0;
        adder_Im_tmp <= 0;

        mult1_Re_tmp <= 0;
        mult1_Im_tmp <= 0;

        mult2_Re_tmp <= 0;
        mult2_Im_tmp <= 0;

        mult3_Re_tmp <= 0;
        mult3_Im_tmp <= 0;
    end
    else
    begin
        curr_state <= next_state;
    end
end

always @(posedge clk)
begin
    if (overflow_adder or overflow_mult)
    begin
        res <= 0;
        overflow <= 1;
        done <= 1;
    end
end


// States
parameter [1:0]  IDLE = 0,
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
            signal = {2'b00, input_signal, 2'b00};
            kernel = input_kernel;
            next_state = CONV;
        end
        else
        begin
            done = 0;
            res = 0;
            overflow = 0

            next_state = IDLE;
        end
    end 

    CONV:
    begin
        if (conv_counter < NUM_ELEMS + 2)
        begin
            a_Re_tmp = signal[(2*conv_counter + 1)*WORD_LENGTH - 1 : 2*conv_counter*WORD_LENGTH];
            a_Im_tmp = signal[(2*conv_counter + 2)*WORD_LENGTH - 1 : (2*conv_counter + 1)*WORD_LENGTH];


            b_Re_tmp = signal[(2*conv_counter + 3)*WORD_LENGTH - 1 : (2*conv_counter + 2)*WORD_LENGTH];
            b_Im_tmp = signal[(2*conv_counter + 4)*WORD_LENGTH - 1 : (2*conv_counter + 3)*WORD_LENGTH];


            c_Re_tmp = signal[(2*conv_counter + 5)*WORD_LENGTH - 1 : (2*conv_counter + 4)*WORD_LENGTH];
            c_Im_tmp = signal[(2*conv_counter + 6)*WORD_LENGTH - 1 : (2*conv_counter + 5)*WORD_LENGTH];


            // Complex mult and add done with new a, b, c values
            // TODO determine index where to save the values in the output vector
            res[] = adder_Im;
            res[] = adder_Re;
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

    endcase
    
end

endmodule

// TODO create module to invert what the loader puts into mem OR make the loader save values reversed