`timescale 1ns / 1ps

module lms_tb();

    reg clk;
    reg rst_btn;
    
    // Instantiate the Top Level
    top_lms_system uut (
        .clk(clk),
        .rst_btn(rst_btn)
    );

    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Reset System
        rst_btn = 1; 
        #100;
        
        // Release Reset (Start Processing)
        rst_btn = 0;
        
        // Run for enough time to see convergence
        // (1024 samples * approx 35 cycles/sample * 10ns = ~360us minimum)
        #1000000; 
        
        $finish;
    end

endmodule
