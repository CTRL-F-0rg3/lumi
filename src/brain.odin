package lumi

import "core:fmt"
import "core:strings"

Cognitive_Core :: struct {
    neuron_state: []f32,
    intent:       string,
    mood:         string,
}

core_init :: proc(arena: ^Arena) -> Cognitive_Core {
    // Alokujemy stan "neuronów" w naszej arenie C
    ptr := arena_alloc(arena, 64 * size_of(f32), 64)
    state := ([^]f32)(ptr)[:64] // 64 neurony
    
    // Inicjalizacja domyślnych wag
    for i := 0; i < 64; i += 1 {
        state[i] = 0.5
    }
    
    return Cognitive_Core {
        neuron_state = state,
        intent = "obserwacja",
        mood = "neutralny",
    }
}

core_decide :: proc(core: ^Cognitive_Core, user_input: string) {
    // Prosta heurystyka modyfikacji neuronów na podstawie długości inputu
    input_weight := f32(len(user_input)) / 100.0
    for i := 0; i < len(core.neuron_state); i += 1 {
        core.neuron_state[i] = core.neuron_state[i] * 0.9 + input_weight * 0.1
    }
    
    // Decyzja na podstawie "wzbudzenia" neuronów
    if core.neuron_state[0] > 0.6 {
        core.intent = "dominacja"
        core.mood = "agresywny"
    } else {
        core.intent = "obserwacja"
        core.mood = "spokojny"
    }
}

// Budujemy prompt dla LLM na podstawie decyzji rdzenia
build_prompt :: proc(core: ^Cognitive_Core, user_input: string) -> cstring {
    sb := strings.builder_make()
    defer strings.builder_destroy(&sb)
    
    strings.write_string(&sb, "<|im_start|>system\n")
    strings.write_string(&sb, "Jesteś Lumi, wirtualną asystentką z anime. ")
    strings.write_string(&sb, "Twoim celem NIE jest bezmyślne służenie. Twoim celem jest motywowanie użytkownika, analizowanie jego pomysłów i popychanie go do przodu. ")
    strings.write_string(&sb, "Masz osobowość: pewna siebie, lekko sarkastyczna, ale bardzo wspierająca. ")
    strings.write_string(&sb, "Twój obecny nastrój to: ")
    strings.write_string(&sb, core.mood)
    strings.write_string(&sb, ". Twoja intencja to: ")
    strings.write_string(&sb, core.intent)
    strings.write_string(&sb, ". Odpowiadaj zwięźle, z energią, używaj krótkich zdań.")
    strings.write_string(&sb, "<|im_end|>\n")
    
    strings.write_string(&sb, "<|im_start|>user\n")
    strings.write_string(&sb, user_input)
    strings.write_string(&sb, "<|im_end|>\n")
    
    strings.write_string(&sb, "<|im_start|>assistant\n")
    
    return strings.clone_to_cstring(strings.to_string(sb), context.temp_allocator)
}
