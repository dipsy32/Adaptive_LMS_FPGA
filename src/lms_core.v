`timescale 1ns / 1ps

module lms_core #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [WIDTH-1:0] x_in,
    input wire signed [WIDTH-1:0] d_in,
    
    output reg signed [WIDTH-1:0] y_out,
    output reg signed [WIDTH-1:0] e_out,
    output reg done
);

    // MU = 2 (Learning Rate)
    localparam signed [WIDTH-1:0] MU_FIXED = 16'd2; 

    reg signed [WIDTH-1:0] w0, w1, w2, w3, w4, w5, w6, w7;
    reg signed [WIDTH-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
    
    reg [4:0] bit_idx;       
    reg signed [31:0] acc;       
    reg signed [WIDTH-1:0] w_sum;  
    
    // Pipeline Registers which are critical for timing and simulation accuracy
    reg signed [WIDTH-1:0] slice_reg; 
    reg signed [31:0] slice_shifted;

    reg signed [WIDTH-1:0] term0, term1, term2, term3, term4, term5, term6, term7;

    reg [2:0] state;
    localparam IDLE = 0, CALC_OFFSET = 1, CALC_SLICE = 2, CALC_ACC = 3, CALC_E = 4, UPDATE_W = 5;

    function signed [WIDTH-1:0] fixed_mul;
        input signed [WIDTH-1:0] a, b;
        reg signed [2*WIDTH-1:0] res;
        begin
            res = a * b;
            fixed_mul = res >>> FRAC;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            w0<=0; w1<=0; w2<=0; w3<=0; w4<=0; w5<=0; w6<=0; w7<=0;
            x0<=0; x1<=0; x2<=0; x3<=0; x4<=0; x5<=0; x6<=0; x7<=0;
            y_out <= 0; e_out <= 0; done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        x7<=x6; x6<=x5; x5<=x4; x4<=x3; x3<=x2; x2<=x1; x1<=x0;
                        x0 <= x_in;
                        state <= CALC_OFFSET;
                    end
                end

                CALC_OFFSET: begin
                    w_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7;
                    acc <= -w_sum; 
                    bit_idx <= 0; 
                    state <= CALC_SLICE;
                end

                // Pipeline Step 1: Logic (Fixed)
                CALC_SLICE: begin
                    if (bit_idx == WIDTH-1) begin
                         // MSB Logic (Flipped)
                         slice_reg <= (x0[bit_idx] ? -w0 : w0) + 
                                      (x1[bit_idx] ? -w1 : w1) + 
                                      (x2[bit_idx] ? -w2 : w2) + 
                                      (x3[bit_idx] ? -w3 : w3) + 
                                      (x4[bit_idx] ? -w4 : w4) + 
                                      (x5[bit_idx] ? -w5 : w5) + 
                                      (x6[bit_idx] ? -w6 : w6) + 
                                      (x7[bit_idx] ? -w7 : w7);
                    end else begin
                         // Normal Logic
                         slice_reg <= (x0[bit_idx] ? w0 : -w0) + 
                                      (x1[bit_idx] ? w1 : -w1) + 
                                      (x2[bit_idx] ? w2 : -w2) + 
                                      (x3[bit_idx] ? w3 : -w3) + 
                                      (x4[bit_idx] ? w4 : -w4) + 
                                      (x5[bit_idx] ? w5 : -w5) + 
                                      (x6[bit_idx] ? w6 : -w6) + 
                                      (x7[bit_idx] ? w7 : -w7);
                    end
                    state <= CALC_ACC;
                end

                // Pipeline Step 2: Accumulate
                CALC_ACC: begin
                    // Sign extend to 32 bits
                    slice_shifted = {{16{slice_reg[15]}}, slice_reg};
                    
                    acc <= acc + (slice_shifted <<< bit_idx);

                    if (bit_idx == WIDTH-1)
                        state <= CALC_E;
                    else begin
                        bit_idx <= bit_idx + 1;
                        state <= CALC_SLICE;
                    end
                end

                CALC_E: begin
                    y_out <= acc >>> 9;
                    e_out <= d_in - (acc >>> 9);
                    state <= UPDATE_W;
                end

                UPDATE_W: begin
                    term0 = fixed_mul(MU_FIXED, x0);
                    term1 = fixed_mul(MU_FIXED, x1);
                    term2 = fixed_mul(MU_FIXED, x2);
                    term3 = fixed_mul(MU_FIXED, x3);
                    term4 = fixed_mul(MU_FIXED, x4);
                    term5 = fixed_mul(MU_FIXED, x5);
                    term6 = fixed_mul(MU_FIXED, x6);
                    term7 = fixed_mul(MU_FIXED, x7);

                    if (e_out > 0) begin
                        w0 <= w0 + term0; w1 <= w1 + term1; w2 <= w2 + term2; w3 <= w3 + term3;
                        w4 <= w4 + term4; w5 <= w5 + term5; w6 <= w6 + term6; w7 <= w7 + term7;
                    end else if (e_out < 0) begin
                        w0 <= w0 - term0; w1 <= w1 - term1; w2 <= w2 - term2; w3 <= w3 - term3;
                        w4 <= w4 - term4; w5 <= w5 - term5; w6 <= w6 - term6; w7 <= w7 - term7;
                    end
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule