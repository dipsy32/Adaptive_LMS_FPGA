import numpy as np
import matplotlib.pyplot as plt
from scipy import signal as sp_signal

# LMS Algorithm (Sign-Error)
def lms_filter_sign_error(x, d, N, mu):
    """
    Implement a Sign-Error LMS filter.
    w(n+1) = w(n) + mu * sign(e(n)) * x(n)
    """
    L = len(x)
    w = np.zeros(N)
    y = np.zeros(L)
    e = np.zeros(L)
    
    for n in range(N, L):
        # Get input vector
        x_vec = x[n : n - N : -1] 
        
        # Filtering (Inner Product)
        y[n] = np.dot(w, x_vec)
        
        # Error Calculation
        e[n] = d[n] - y[n]
        
        # Sign Error Update
        sign_e = np.sign(e[n])
        
        # Update weights
        w = w + mu * sign_e * x_vec

    return y, e, w

# Signal Generation
def create_noise_cancellation_signals(num_samples):
    t = np.arange(num_samples)
    
    # Clean Signal (S): The original input sine wave
    S = 0.8 * np.sin(2 * np.pi * 0.02 * t)
    
    # Reference Noise (NR): Wideband noise
    NR = np.random.normal(0, 0.4, num_samples)
    
    # Interference
    H_NP = [0.5, -0.3, 0.1, -0.05, 0.02, -0.01, 0.0, 0.0] 
    
    # Primary Noise (NP): Correlated noise
    NP = sp_signal.lfilter(H_NP, [1.0], NR)
    
    # Inputs to System
    x_input = NR            # Reference Noise Input (x)
    d_target = S + NP       # Primary Input (d = Signal + Noise)
    
    return x_input, d_target, S, NP

# Main Execution
if __name__ == "__main__":
    # Parameters
    N_TAPS = 8              
    MU = 0.02              
    NUM_SAMPLES = 1024      
    SCALE_FACTOR = 2**8 

    print(f"Generative LMS Model")
    x, d, S, NP = create_noise_cancellation_signals(NUM_SAMPLES)
    
    print("Running Sign-Error LMS")
    y, e, w_final = lms_filter_sign_error(x, d, N_TAPS, MU)
    
    # Verilog ROM Generation
    print("Generating rom_data.v")
    
    # Convert float to 16-bit fixed point integer
    def to_fixed(val):
        val_int = int(val * SCALE_FACTOR)
        # Saturation Logic
        if val_int > 32767: val_int = 32767
        if val_int < -32768: val_int = -32768
        return val_int & 0xFFFF # Mask to 16 bits

    with open("rom_data.v", "w") as f:
        f.write("module rom_data (\n")
        f.write("    input wire clk,\n")
        f.write("    input wire [9:0] addr,\n")
        f.write("    output reg [31:0] data\n")
        f.write(");\n\n")
        f.write("    always @(posedge clk) begin\n")
        f.write("        case(addr)\n")
        
        for i in range(NUM_SAMPLES):
            val_d = to_fixed(d[i])
            val_x = to_fixed(x[i])
            
            # Pack: D in upper 16 bits, X in lower 16 bits
            # This matches 32'hDDDDXXXX format
            packed = (val_d << 16) | val_x
            
            # Write the Verilog case line
            f.write(f"            10'd{i}: data <= 32'h{packed:08x};\n")
            
        f.write("            default: data <= 32'h00000000;\n")
        f.write("        endcase\n")
        f.write("    end\n")
        f.write("endmodule\n")

    print("'rom_data.v' created. Download it from the files tab.")
    
    # Plotting
    plt.figure(figsize=(12, 6))
    
    # Plot Cleaned Output
    plt.plot(e, label='Error (Cleaned)', linewidth=1.5)
    
    # Plot Original Signal
    plt.plot(S, label='Original Clean Signal', alpha=0.6, linewidth=1.5)
    
    plt.title("Python Model Output")
    plt.legend(loc='lower right')
    plt.tight_layout()
    plt.show()