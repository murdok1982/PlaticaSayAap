#include <cstring>
#include <string>
#include <vector>

#include "llama.h"

struct PlaticaLlamaCtx {
    llama_model* model;
    llama_context* ctx;
    const llama_vocab* vocab;
};

typedef void (*platica_token_cb)(const char* token, void* user_data);

extern "C" {

__attribute__((visibility("default")))
void* platica_llama_init(const char* model_path, int n_threads) {
    llama_backend_init();

    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = 0;

    llama_model* model = llama_model_load_from_file(model_path, mparams);
    if (!model) return nullptr;

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx = 1024;
    cparams.n_threads = n_threads;
    cparams.n_threads_batch = n_threads;

    llama_context* ctx = llama_init_from_model(model, cparams);
    if (!ctx) {
        llama_model_free(model);
        return nullptr;
    }

    auto* holder = new PlaticaLlamaCtx{
        model, ctx, llama_model_get_vocab(model)
    };
    return holder;
}

__attribute__((visibility("default")))
void platica_llama_free(void* ptr) {
    auto* holder = static_cast<PlaticaLlamaCtx*>(ptr);
    if (!holder) return;
    llama_free(holder->ctx);
    llama_model_free(holder->model);
    delete holder;
    llama_backend_free();
}

__attribute__((visibility("default")))
int platica_llama_generate(
    void* ptr,
    const char* prompt,
    platica_token_cb on_token,
    void* user_data
) {
    auto* holder = static_cast<PlaticaLlamaCtx*>(ptr);
    if (!holder || !prompt) return 1;

    const int n_prompt_max = 512;
    std::vector<llama_token> prompt_tokens(n_prompt_max);
    const int n_prompt = llama_tokenize(
        holder->vocab, prompt, std::strlen(prompt),
        prompt_tokens.data(), n_prompt_max, true, true
    );
    if (n_prompt < 0) return 2;
    prompt_tokens.resize(n_prompt);

    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), n_prompt);

    llama_sampler* sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.2f));
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(42));

    for (int n_pos = 0; n_pos + batch.n_tokens < 1024;) {
        if (llama_decode(holder->ctx, batch) != 0) {
            llama_sampler_free(sampler);
            return 3;
        }
        n_pos += batch.n_tokens;

        llama_token id = llama_sampler_sample(sampler, holder->ctx, -1);
        if (llama_vocab_is_eog(holder->vocab, id)) break;

        char buf[256];
        const int n = llama_token_to_piece(holder->vocab, id, buf, sizeof(buf), 0, true);
        if (n > 0 && on_token) {
            buf[n] = '\0';
            on_token(buf, user_data);
        }

        batch = llama_batch_get_one(&id, 1);
    }

    llama_sampler_free(sampler);
    return 0;
}

}
