// c/arena.c
#include "arena.h"
#include <stdlib.h>

Arena arena_create(size_t capacity) {
    return (Arena){
        .buffer = (uint8_t*)malloc(capacity),
        .capacity = capacity,
        .offset = 0
    };
}

void* arena_alloc(Arena* arena, size_t size, size_t align) {
    uintptr_t current_ptr = (uintptr_t)(arena->buffer + arena->offset);
    uintptr_t aligned_ptr = (current_ptr + align - 1) & ~(align - 1);
    size_t new_offset = (aligned_ptr - (uintptr_t)arena->buffer) + size;
    
    if (new_offset > arena->capacity) {
        return NULL; // Out of memory
    }
    
    arena->offset = new_offset;
    return (void*)aligned_ptr;
}

void arena_reset(Arena* arena) {
    arena->offset = 0;
}

void arena_destroy(Arena* arena) {
    free(arena->buffer);
    arena->buffer = NULL;
    arena->capacity = 0;
    arena->offset = 0;
}
