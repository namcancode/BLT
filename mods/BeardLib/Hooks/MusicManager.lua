if not MusicManager.playlist then
	return
end

function MusicManager:check_playlist(is_menu)
    local playlist = is_menu and self:playlist_menu() or self:playlist()
    local tracklist = is_menu and tweak_data.music.track_menu_list or tweak_data.music.track_list
    for i, track in pairs(playlist) do
        local exists
        for _, v in pairs(tracklist) do
            if v.track == track then
                exists = true
            end
        end
        if not exists then
            playlist[i] = nil
            managers.savefile:setting_changed()
        end
    end
    if not is_menu then
        self:check_playlist(true)
    end
end

function MusicManager:stop_custom()
	local source = self._xa_source
	self._xa_source = nil
	if source then
		source:close()
	end
	if alive(self._player) then
		self._player:parent():remove(self._player)
	end
end

local orig_post = MusicManager.post_event
function MusicManager:post_event(name, ...)
	if name and Global.music_manager.current_event ~= name then
		if not self._skip_play then
			if not self:attempt_play(nil, name, true) then
				return orig_post(self, name, ...) 
			end
		end
		Global.music_manager.current_event = name
	end
end

local orig_check = MusicManager.check_music_switch
function MusicManager:check_music_switch(...)
	local switches = tweak_data.levels:get_music_switches()
	if switches and #switches > 0 then
		Global.music_manager.current_track = switches[math.random(#switches)]		
		if not self:attempt_play(Global.music_manager.current_track) then
			return orig_check(self, ...)
		end
	end
end

local orig_stop = MusicManager.track_listen_stop
function MusicManager:track_listen_stop(...)
	local current_event = self._current_event
	local current_track = self._current_track
	orig_stop(self, ...)
	local success
	if current_event then
		self:stop_custom()
		if Global.music_manager.current_event then
			if self:attempt_play(nil, Global.music_manager.current_event) then
				success = true
			end
		end
	end
	if current_track and Global.music_manager.current_track then
		if self:attempt_play(Global.music_manager.current_track) then
			success = true
		end
	end
	if success then
		Global.music_manager.source:stop()
	end
end

local movie_ids = Idstring("movie")
function MusicManager:attempt_play(track, event, stop)
	if stop then
		self:stop_custom()
	end
	local next_music
	local next_event
	if track and track ~= self._current_custom_track then
		self._current_custom_track = nil
	end
	for id, music in pairs(BeardLib.MusicMods) do
		if next_music then
			break
		end
		if event == id or track == id or self._current_custom_track == id then
			if music.source and (self._current_custom_track ~= id or id == event) then
				next_music = music
				self._current_custom_track = id
			end
			if music.events and event then
				local event_tbl = music.events[string.split(event, "_")[3]]
				if event_tbl then
					next_music = music
					next_event = event_tbl
					self._current_custom_track = id
				end
			end
		end
	end
	if next_music then
		local next = next_event or next_music
		local use_alt_source = next.alt_source and math.random() < next.alt_chance
		local source = use_alt_source and (next.alt_start_source or next.start_source or next.alt_source) or next.start_source or next.source
		if next_music.xaudio then
			if not source then
				BeardLib:log("[ERROR] No buffer found to play for music '%s'", tostring(self._current_custom_track))
			end
		else
			if not source or not DB:has(movie_ids, source:id()) then
				BeardLib:log("[ERROR] Source file '%s' is not loaded, music id '%s'", tostring(source), tostring(self._current_custom_track))
				return true
			end
		end
		local volume = next.volume or next_music.volume
		self._switch_at_end = (next.start_source or next.alt_source) and {
			source = (next.allow_switch or not use_alt_source) and next.source or next.alt_source,
			alt_source = next.allow_switch and next.alt_source,
			alt_chance = next.allow_switch and next.alt_chance,
			xaudio = next_music.xaudio,
			volume = volume
		}
		self:play(source, next_music.xaudio, volume)
		return true
	end
	return next_music ~= nil
end

function MusicManager:play(src, use_xaudio, custom_volume)
	self:stop_custom()
	Global.music_manager.source:post_event("stop_all_music")
	if use_xaudio then
		if XAudio then
			self._xa_source = XAudio.Source:new(src)
			self._xa_source:set_type("music")
			self._xa_source:set_relative(true)
			self._xa_source:set_looping(not self._switch_at_end)
			if custom_volume then
				self._xa_source:set_volume(custom_volume)
			end
		else
			BeardLib:log("XAduio was not found, cannot play music.")
		end
	elseif managers.menu_component._main_panel then
		self._player = managers.menu_component._main_panel:video({
			name = "music",
			video = src,
			visible = false,
			loop = not self._switch_at_end,
		})
		self._player:set_volume_gain(Global.music_manager.volume)
	end
end

function MusicManager:custom_update(t, dt, paused)
	local gui_ply = alive(self._player) and self._player or nil
	if gui_ply then
		gui_ply:set_volume_gain(Global.music_manager.volume)
	end
	if paused then
		--xaudio already pauses itself.
		if gui_ply then
			gui_ply:set_volume_gain(0)
			gui_ply:goto_frame(gui_ply:current_frame()) --Force because the pause function is kinda broken :/
		end
	elseif self._switch_at_end then
		if (self._xa_source and self._xa_source:is_closed()) or (gui_ply and gui_ply:current_frame() >= gui_ply:frames()) then
			local switch = self._switch_at_end
			self._switch_at_end = switch.alt_source and switch or nil
			local source = switch.alt_source and math.random() < switch.alt_chance and switch.alt_source or switch.source
			self:play(source, switch.xaudio, switch.volume)
		end
	end
end

--Hooks
Hooks:PostHook(MusicManager, "init", "BeardLibMusicManagerInit", function(self)
	for id, music in pairs(BeardLib.MusicMods) do
		if music.heist then
			table.insert(tweak_data.music.track_list, {track = id})
		end
		if music.menu then
			table.insert(tweak_data.music.track_menu_list, {track = id})
		end
	end
end)

Hooks:PostHook(MusicManager, "load_settings", "BeardLibMusicManagerLoadSettings", function(self)
	self:check_playlist()
end)

Hooks:PostHook(MusicManager, "track_listen_start", "BeardLibMusicManagerTrackListenStart", function(self, event, track)
	self:stop_custom()
	local success
	if track and self:attempt_play(track) then
		success = true
	end
	if self:attempt_play(nil, event) then
		success = true
	end
	if success then
		Global.music_manager.source:stop()
	end
end)

Hooks:PostHook(MusicManager, "set_volume", "BeardLibMusicManagerSetVolume", function(self, volume)
	--xaudio sets its own volume
	if alive(self._player) then
		self._player:set_volume_gain(volume)
	end	
end)

Hooks:Add("MenuUpdate", "BeardLibMusicMenuUpdate", function(t, dt)
	if managers.music then
		managers.music:custom_update(t, dt)
	end
end)

Hooks:Add("GameSetupUpdate", "BeardLibMusicUpdate", function(t, dt)
	if managers.music then
		managers.music:custom_update(t, dt)
	end
end)

Hooks:Add("GameSetupPauseUpdate", "BeardLibMusicPausedUpdate", function(t, dt)
	if managers.music then
		managers.music:custom_update(t, dt, true)
	end
end)