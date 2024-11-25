module binary_file_reader #(
    parameter N = 12,          // Bit-width of each chunk
    parameter MEM_DEPTH = 1000  // Maximum number of chunks in the file
) (
    input wire clk,           // Clock signal
    input wire reset,         // Reset signal

    output reg [N-1:0] out,   // Output wire for N-bit chunks
    output reg done           // Reached end of file 
);
    // Memory to store file data
    reg [N-1:0] memory [0:MEM_DEPTH-1]; 

    // Address pointer
    reg [$clog2(MEM_DEPTH)-1:0] addr; 

    initial begin
        $readmemb("data.bin", memory);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addr <= 0;        // Reset address pointer
            out <= 0;         // Reset output
        end else begin
            out <= memory[addr];  // Assign the current chunk to the output
            addr <= addr + 1;     // Increment the address pointer
            if (addr == MEM_DEPTH - 1)
                done <= 1;
        end
    end
endmodule
