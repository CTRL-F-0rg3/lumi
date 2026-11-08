#include "math.h"

void matmul_cpu(Matrix* a, Matrix* b, Matrix* out) {
    // Prosta, naiwna implementacja (później zrobimy SIMD i block-tiling)
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < b->cols; j++) {
            float sum = 0.0f;
            for (int k = 0; k < a->cols; k++) {
                sum += a->data[i * a->cols + k] * b->data[k * b->cols + j];
            }
            out->data[i * out->cols + j] = sum;
        }
    }
}
