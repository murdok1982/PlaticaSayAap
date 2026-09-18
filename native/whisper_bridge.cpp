#include <cstring>
#include <string>
#include <vector>

#include "whisper.h"

extern "C" {

__attribute__((visibility("default")))
void* platica_whisper_init(const char* model_path) {
    whisper_context_params cparams = whisper_context_default_params();
    cparams.use_gpu = true;
    return whisper_init_from_file_with_params(model_path, cparams);
}

__attribute__((visibility("default")))
void platica_whisper_free(void* ctx) {
    if (ctx) whisper_free(static_cast<whisper_context*>(ctx));
}

__attribute__((visibility("default")))
char* platica_whisper_transcribe(
    void* ctx_ptr,
    const float* samples,
    int n_samples,
    char* out_lang
) {
    auto* ctx = static_cast<whisper_context*>(ctx_ptr);
    if (!ctx) return nullptr;

    whisper_full_params params = whisper_full_default_params(
        WHISPER_SAMPLING_GREEDY
    );
    params.print_progress = false;
    params.print_special = false;
    params.print_realtime = false;
    params.print_timestamps = false;
    params.single_segment = true;
    params.no_context = true;
    params.n_threads = 4;
    params.language = nullptr;
    params.detect_language = true;

    if (whisper_full(ctx, params, samples, n_samples) != 0) {
        return nullptr;
    }

    const int lang_id = whisper_full_lang_id(ctx);
    const char* lang = whisper_lang_str(lang_id);
    if (out_lang) {
        std::strncpy(out_lang, lang ? lang : "es", 7);
        out_lang[7] = '\0';
    }

    std::string result;
    const int n_segments = whisper_full_n_segments(ctx);
    for (int i = 0; i < n_segments; i++) {
        result += whisper_full_get_segment_text(ctx, i);
    }

    char* out = static_cast<char*>(malloc(result.size() + 1));
    std::memcpy(out, result.c_str(), result.size() + 1);
    return out;
}

}
