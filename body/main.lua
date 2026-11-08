-- body/main.lua
local pipe_path = "/tmp/lumi_pipe"

-- ===== MENORI (render 3D) =====
local menori = require 'menori'
local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

local camera, environment, root_node, animations, scene

function love.load()
-- 1. Inicjalizacja sceny 3D
local w, h = love.graphics.getDimensions()
camera = menori.PerspectiveCamera(60, w / h, 0.1, 100)
environment = menori.Environment(camera)
root_node = menori.Node()
scene = menori.Scene()

-- 2. Ładowanie modelu VRM (zmień na 'lumi.glb' jeśli Menori nie czyta .vrm)
local gltf = menori.glTFLoader.load('lumi.glb')
local scenes = menori.NodeTreeBuilder.create(gltf, function(scene_builder, builder)
if builder.animations then
	animations = menori.glTFAnimations(builder.animations)
	animations:set_action(1)   -- odtwarzaj pierwszą animację (np. idle)
end
end)
root_node:attach(scenes[1])

-- 3. Ustawienie kamery (patrzy na model)
local q = quat.from_euler_angles(0, math.rad(20), math.rad(10))
local v = vec3(0, 1, 3)            -- odległość kamery (dostosuj w razie potrzeby)
camera.center = vec3(0, 1, 0)      -- punkt, na który patrzy (środek modelu)
camera.eye = q * v + camera.center
camera:update_view_matrix()

-- 4. Inicjalizacja pipe'a (BEZ ZMIAN)
pipe = io.open(pipe_path, "r")
if not pipe then
	print("Błąd: Nie znaleziono pipe'a /tmp/lumi_pipe")
	love.event.quit()
	end
	pipe:setvbuf("no")

	current_text = "Czekam na Lumi..."
	current_emotion = "neutral"
	end

	function love.update(dt)
	-- Aktualizacja animacji i sceny 3D
	scene:update_nodes(root_node, environment)
	if animations then
		animations:update(dt)
		end

		-- ===== ODBIÓR DANYCH Z PIPE'A (bez zmian) =====
		if pipe then
			local line = pipe:read("*l")
			if line then
				-- Format: "emotion|text"
				local emotion, text = line:match("([^|]+)|(.+)")
				if emotion and text then
					current_emotion = emotion
					current_text = text
					print("[LUA] Odebrano:", current_emotion, current_text)

					-- Tutaj można dodać TTS lub animację ust
					-- os.execute("aplay output.wav")
					end
					end
					end
					end

					function love.draw()
					-- Tło (ciemne, żeby model był widoczny)
					love.graphics.clear(0.1, 0.1, 0.1)

					-- ===== RENDEROWANIE MODELU 3D =====
					scene:render_nodes(root_node, environment, {
						node_sort_comp = menori.Scene.alpha_mode_comp
					})

					-- ===== NAKŁADKA 2D (tekst, emocje) =====
					love.graphics.setColor(1, 1, 1)
					love.graphics.print("Lumi Engine - Frontend", 10, 10)
					love.graphics.print("Emocja: " .. current_emotion, 10, 40)
					love.graphics.printf("Mówi: " .. current_text, 10, 80, 600)
					end
