#include "llm_wrapper.h"
#include "llama.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct LlmContext {
    struct llama_model *model;
    struct llama_context *ctx;
    const struct llama_vocab *vocab;
};

static void batch_add(struct llama_batch *batch, llama_token id, llama_pos pos, bool logits) {
    int i = batch->n_tokens;
    batch->token[i] = id;
    batch->pos[i] = pos;
    batch->n_seq_id[i] = 1;
    batch->seq_id[i][0] = 0;
    batch->logits[i] = logits;
    batch->n_tokens++;
}

LlmContext* llm_init(const char* model_path) {
    llama_backend_init();
    llama_log_set(NULL, NULL); // WYCISZAMY LOGI!

    struct llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = 0;

    struct llama_model *model = llama_model_load_from_file(model_path, mparams);
    if (!model) {
        fprintf(stderr, "Błąd ładowania modelu: %s\n", model_path);
        return NULL;
    }

    struct llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx = 2048;
    cparams.n_threads = 4;

    struct llama_context *ctx = llama_init_from_model(model, cparams);
    if (!ctx) {
        fprintf(stderr, "Błąd tworzenia kontekstu\n");
        llama_model_free(model);
        return NULL;
    }

    LlmContext *lctx = (LlmContext*)malloc(sizeof(LlmContext));
    lctx->model = model;
    lctx->ctx = ctx;
    lctx->vocab = llama_model_get_vocab(model);
    
    return lctx;
}

const char* llm_generate(LlmContext* lctx, const char* prompt, int max_tokens) {
    static char result[8192]; // Zwiększamy bufor
    result[0] = '\0';

    const int n_prompt = -llama_tokenize(lctx->vocab, prompt, strlen(prompt), NULL, 0, true, true);
    llama_token* prompt_tokens = (llama_token*)malloc(n_prompt * sizeof(llama_token));
    
    if (llama_tokenize(lctx->vocab, prompt, strlen(prompt), prompt_tokens, n_prompt, true, true) < 0) {
        free(prompt_tokens);
        return "Błąd tokenizacji";
    }

    struct llama_batch batch = llama_batch_init(n_prompt, 0, 1);
    for (int i = 0; i < n_prompt; i++) {
        batch_add(&batch, prompt_tokens[i], i, false);
    }
    batch.logits[batch.n_tokens - 1] = true;

    if (llama_decode(lctx->ctx, batch) != 0) {
        free(prompt_tokens);
        llama_batch_free(batch);
        return "Błąd dekodowania promptu";
    }
    free(prompt_tokens);

    // NOWY SAMPLER: Kara za powtórzenia, Top-K, Top-P i Temperatura
    struct llama_sampler *smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());
    // Kara za powtórzenia (ostatnie 64 tokeny, kara 1.2)
    // Top-K (40) i Top-P (0.9)
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(0.9f, 1));
    // Temperatura 0.7 (im wyższa, tym bardziej kreatywny)
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.7f));
    // Dystrybucja losowa
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    int n_cur = batch.n_tokens;
    int n_decode = 0;

    while (n_decode < max_tokens) {
        llama_token id = llama_sampler_sample(smpl, lctx->ctx, -1);
        
        if (llama_vocab_is_eog(lctx->vocab, id)) {
            break;
        }

        char buf[128];
        int n = llama_token_to_piece(lctx->vocab, id, buf, sizeof(buf), 0, true);
        if (n > 0) {
            buf[n] = '\0';
            strncat(result, buf, sizeof(result) - strlen(result) - 1);
        }
        
        batch.n_tokens = 0;
        batch_add(&batch, id, n_cur, true);
        n_cur++;
        n_decode++;

        if (llama_decode(lctx->ctx, batch) != 0) {
            break;
        }
    }

    llama_sampler_free(smpl);
    llama_batch_free(batch);
    return result;
}

void llm_free(LlmContext* lctx) {
    if (!lctx) return;
    if (lctx->ctx) llama_free(lctx->ctx);
    if (lctx->model) llama_model_free(lctx->model);
    free(lctx);
    llama_backend_free();
}
