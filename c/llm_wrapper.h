#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct LlmContext LlmContext;

LlmContext* llm_init(const char* model_path);
const char* llm_generate(LlmContext* ctx, const char* prompt, int max_tokens);
void llm_free(LlmContext* ctx);

#ifdef __cplusplus
}
#endif
