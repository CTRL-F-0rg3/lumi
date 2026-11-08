package lumi

import "core:fmt"

// Tensor operujący na pamięci z areny
Tensor :: struct {
    data:   [^]f32,
    shape:  []uint,
    strides: []uint,
}

// Importujemy matematykę z C
foreign import lumi_c "../build/liblumi_c.a"

foreign lumi_c {
    matmul_cpu :: proc(a: ^Tensor, b: ^Tensor, out: ^Tensor) ---
    // Później dodamy tutaj matmul_vulkan
}
