import numpy as np

def complex_convolution(signal, kernel):
    """
    Perform complex convolution between two arrays.
    
    Parameters:
        signal (np.ndarray): Array of complex numbers representing the signal.
        kernel (np.ndarray): Array of complex numbers representing the kernel.

    Returns:
        np.ndarray: Result of the complex convolution.
    """
    # Flip the kernel for convolution
    kernel_flipped = np.flip(kernel)
    
    # Perform convolution using numpy's built-in method
    result = np.convolve(signal, kernel_flipped, mode='full')
    
    return result

kernel = np.array([1.0625 - 2j, -0.375 + 1j*1.25, 2.5 - 1j*0.25], dtype=complex)  # Example complex signal
signal = np.array([0.25 + 1j*2.0, 1.125 - 1j, 0 - 1j*0.75], dtype=complex)       # Example complex kernel

conv_result = complex_convolution(signal, kernel)

print("Complex Convolution Result:")
for idx, val in enumerate(conv_result):
    print(f"Index {idx}: {val.real:.2f} + {val.imag:.2f}j")
