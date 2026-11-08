// c/arena.h
#pragma once
#include <stddef.h>
#include <stdint.h>

typedef struct Arena {
    uint8_t* buffer;
    size_t capacity;
    size_t offset;
} Arena;

Arena arena_create(size_t capacity);
void* arena_alloc(Arena* arena, size_t size, size_t align);
void arena_reset(Arena* arena);
void arena_destroy(Arena* arena);
