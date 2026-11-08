package lumi

import "core:fmt"
import "core:c"
import "core:os"
import "core:strings"

// --- INTEROP Z C ---
Arena :: struct {
    buffer: [^]u8,
    capacity: uint,
    offset: uint,
}

foreign import lumi_c "../build/liblumi_c.a"

foreign lumi_c {
    arena_create :: proc(capacity: uint) -> Arena ---
    arena_alloc :: proc(arena: ^Arena, size: uint, align: uint) -> rawptr ---
    arena_reset :: proc(arena: ^Arena) ---
    arena_destroy :: proc(arena: ^Arena) ---
    
    llm_init :: proc(model_path: cstring) -> rawptr ---
    llm_generate :: proc(ctx: rawptr, prompt: cstring, max_tokens: c.int) -> cstring ---
    llm_free :: proc(ctx: rawptr) ---
}

// --- FUNKCJA WYSYŁAJĄCA DO LUA ---
send_to_body :: proc(emotion: string, text: string) {
    // Otwieramy pipe do zapisu. Jeśli Lua nie działa, program się tu zatrzyma (zablokuje).
    fd, err := os.open("/tmp/lumi_pipe", os.O_WRONLY)
    if err != nil {
        fmt.println("[BŁĄD] Nie można otworzyć pipe'a /tmp/lumi_pipe.")
        fmt.println("Upewnij się, że najpierw utworzyłeś go komendą: mkfifo /tmp/lumi_pipe")
        fmt.println("Oraz że uruchomiłeś ciałko: love body")
        return
    }
    defer os.close(fd)

    // Formatujemy wiadomość jako "emocja|tekst\n"
    sb := strings.builder_make()
    defer strings.builder_destroy(&sb)
    
    strings.write_string(&sb, emotion)
    strings.write_string(&sb, "|")
    strings.write_string(&sb, text)
    strings.write_string(&sb, "\n")
    
    msg := strings.to_string(sb)
    
    // Zapisujemy do pipe'a
    os.write(fd, transmute([]byte)msg)
}

main :: proc() {
    fmt.println("--- Lumi Engine Boot ---")
    
    // 1. Inicjalizacja areny pamięci (1 GB)
    arena := arena_create(1024 * 1024 * 1024)
    defer arena_destroy(&arena)

    // 2. Inicjalizacja rdzenia decyzyjnego (z pliku brain.odin)
    fmt.println("[SYSTEM] Inicjalizacja rdzenia decyzyjnego...")
    core := core_init(&arena)

    // 3. Ładowanie modelu językowego
    model_path := cstring("models/qwen2.5-1.5b-instruct-q4_k_m.gguf")
    
    fmt.println("[SYSTEM] Ładowanie modelu językowego...")
    llm_ctx := llm_init(model_path)
    if llm_ctx == nil {
        fmt.println("[BŁĄD] Nie udało się załadować modelu!")
        return
    }
    defer llm_free(llm_ctx)

    // 4. Symulacja wejścia od użytkownika
    user_input := "Hej Lumi, co myślisz o systemach operacyjnych pisanych w Rust?"
    
    // 5. Rdzeń decyzyjny modyfikuje neurony i podejmuje decyzję
    core_decide(&core, user_input)
    fmt.printf("[BRAIN] Wykryta intencja: %s, Nastrój: %s\n", core.intent, core.mood)
    
    // 6. Budowanie promptu dla LLM
    prompt := build_prompt(&core, user_input)
    
    // 7. Generowanie tekstu
    fmt.println("[SYSTEM] Generowanie odpowiedzi przez LLM...")
    response_c := llm_generate(llm_ctx, prompt, 100)
    
    // Konwersja z cstring na string (Odin)
    response := string(response_c)
    
    fmt.println("\n--- ODPOWIEDŹ LUMI ---")
    fmt.println(response)
    fmt.println("----------------------\n")
    
    // 8. Wysyłanie do ciałka (Lua)
    fmt.println("[SYSTEM] Wysyłanie do ciałka (Lua)...")
    send_to_body(core.mood, response)
    
    fmt.println("--- Lumi Engine Shutdown ---")
}
