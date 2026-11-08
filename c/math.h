#pragma once
#include "arena.h"

// Prosta struktura tensora dla C
typedef struct {
    float* data;
    int rows;
    int cols;
} Matrix;

void matmul_cpu(Matrix* a, Matrix* b, Matrix* out);
