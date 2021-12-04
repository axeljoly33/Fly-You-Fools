--[[
	author: Uganda (Axel Joly)
	-----
	Copyright © 2021, Uganda
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	The Software is provided “as is”, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders X be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the Software.
	Except as contained in this notice, the name of the <copyright holders> shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from the <copyright holders>. »
	-----
--]]


--[[
	author: (base mod) Aussiemon
	-----
	Copyright 2018 Aussiemon
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	-----
	Allows the user to fly freely around the map. Num+ and Num- to change fov. Use command again to toggle.
--]]

-- ##########################################
-- ##########################################

-------------------
-- LUA UTILITIES --

-- for key,value in pairs(input_manager.stored_keymaps_data) do
	-- print(key, value)
-- end
-- for key,value in pairs(getmetatable(input_manager.stored_keymaps_data)) do
	-- print(key, value)
-- end

-- for i,v in pairs(input_manager) do print(i,v) end

-- print("x = " .. tostring(x))

-- LUA UTILITIES --
-------------------

---------------
-- START MOD --
---------------

local mod = get_mod("Fly You Fools")

---------------
-- VARIABLES --
---------------

-- General settings mod variables
local fyf_activation_status = false
local compteur = true -- Debug variable
local fyf_echo_string = "[Fly You Fools] "
local SCREEN_WIDTH = 1920
local SCREEN_HEIGHT = 1080
local always_on = true
local speed = 0.0
local test_cpt = 0

-- VT2 source variables
local Camera = Camera
local FreeFlightManager = FreeFlightManager
local GameSettingsDevelopment = GameSettingsDevelopment
local PlayerUnitMovementSettings = PlayerUnitMovementSettings
local Managers = Managers
local Matrix4x4 = Matrix4x4
local Quaternion = Quaternion
local ScatterSystem = ScatterSystem
local ScriptCamera = ScriptCamera
local ScriptViewport = ScriptViewport
local ScriptWorld = ScriptWorld
local TerrainDecoration = TerrainDecoration
local Vector3 = Vector3
local World = World
local WwiseWorld = WwiseWorld
local InputManager = InputManager
local CharacterStateHelper = CharacterStateHelper
local PlayerUnitHealthExtension = PlayerUnitHealthExtension
local table = table
Managers.free_flight = Managers.free_flight or FreeFlightManager:new()

-- Backup movement variables
mod.backup_move_acceleration_down = mod.backup_move_acceleration_down or PlayerUnitMovementSettings.move_acceleration_down or 5
mod.backup_gravity_acceleration = mod.backup_gravity_acceleration or PlayerUnitMovementSettings.gravity_acceleration or 11
mod.backup_MAX_FALL_DAMAGE = mod.backup_MAX_FALL_DAMAGE or PlayerUnitMovementSettings.fall.heights.MAX_FALL_DAMAGE or 150
mod.backup_MIN_FALL_DAMAGE_HEIGHT = mod.backup_MIN_FALL_DAMAGE_HEIGHT or PlayerUnitMovementSettings.fall.heights.MIN_FALL_DAMAGE_HEIGHT or 7
mod.backup_HARD_LANDING_FALL_HEIGHT = mod.backup_HARD_LANDING_FALL_HEIGHT or PlayerUnitMovementSettings.fall.heights.HARD_LANDING_FALL_HEIGHT or 7
mod.first_run_fov_changed = false

-- Command call
mod:command("fyf", " First-person flight mode", function() mod:toggle_flight_mode(compteur) end)

---------------
-- FUNCTIONS --
---------------

-----------------------------
-- ACTIVE MOD UI FUNCTIONS --
local function get_x()
	local x =  mod:get("offset_x")
	local x_limit = SCREEN_WIDTH / 2
	local max_x = math.min(mod:get("offset_x"), x_limit)
	local min_x = math.max(mod:get("offset_x"), -x_limit)
	if x == 0 then
		return 0
	end
	local clamped_x =  x > 0 and max_x or min_x
	return clamped_x
end

local function get_y()
	local y =  mod:get("offset_y")
	local y_limit = SCREEN_HEIGHT / 2
	local max_y = math.min(mod:get("offset_y"), y_limit)
	local min_y = math.max(mod:get("offset_y"), -y_limit)
	if y == 0 then
		return 0
	end
	local clamped_y = -(y > 0 and max_y or min_y)
	return clamped_y
end

local fake_input_service = {
	get = function ()
	 	return
	end,
	has = function ()
		return
	end
}

local scenegraph_definition = {
	root = {
	  	scale = "fit",
	  	size = {
			1920,
			1080
	  	},
	  	position = {
			0,
			0,
			UILayer.hud
	  	}
	}
}

local fyf_ui_definition = {
	scenegraph_id = "root",
	element = {
	  	passes = {
			{
				style_id = "fyf_text",
				pass_type = "text",
				text_id = "fyf_text",
				retained_mode = false,
				fade_out_duration = 5,
				content_check_function = function(content)
					if not compteur then
						return true
					end
					return false
				end
			},
			{
				style_id = "fyf_speed_text",
				pass_type = "text",
				text_id = "fyf_speed_text",
				retained_mode = false,
				content_check_function = function(content)
					if mod:get("show_speed_multiplier") then
						return true
					end
					return false
				end
			}
	  	}
	},
	content = {
		fyf_text = "",
		fyf_speed_text = ""
	},
	style = {
		fyf_text = {
			font_type = "hell_shark",
			font_size = mod:get("fyf_font_size"),
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				get_x(),
				get_y(),
				0
			}
		},
		fyf_speed_text = {
			font_type = "hell_shark",
			font_size = mod:get("fyf_font_size"),
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				get_x(),
				get_y() - mod:get("fyf_font_size"),
				0
			}
		}
	},
	offset = {
		0,
		0,
		0
	},
}

function mod:on_disabled()
	mod.ui_renderer = nil
	mod.ui_scenegraph = nil
	mod.ui_widget = nil
end

function mod:on_setting_changed()
	if not mod.ui_widget then
	  	return
	end
	mod.ui_widget.style.fyf_text.offset[1] = get_x()
	mod.ui_widget.style.fyf_text.offset[2] = get_y()
	mod.ui_widget.style.fyf_text.font_size = mod:get("fyf_font_size")
	mod.ui_widget.style.fyf_speed_text.offset[1] = get_x()
	mod.ui_widget.style.fyf_speed_text.offset[2] = get_y() - mod:get("fyf_font_size")
	mod.ui_widget.style.fyf_speed_text.font_size = mod:get("fyf_font_size")
end

function mod:init()
	if mod.ui_widget then
	  	return
	end

	local world = Managers.world:world("top_ingame_view")
	mod.ui_renderer = UIRenderer.create(world, "material", "materials/fonts/gw_fonts")
	mod.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
	mod.ui_widget = UIWidget.init(fyf_ui_definition)
end

mod:hook_safe(IngameHud, "update", function(self)
	-- If the the player is dead then let's not show the FYF UI
	if self:is_own_player_dead() then
		return
	end

	if compteur then
		return
	end

	if not mod.ui_widget then
	  	mod.init()
	end

	local widget = mod.ui_widget
	local ui_renderer = mod.ui_renderer
	local ui_scenegraph = mod.ui_scenegraph

	widget.content.fyf_text = "Flight ON"
	widget.content.fyf_speed_text = string.format("Flight speed: %0.1f", speed)

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
	UIRenderer.draw_widget(ui_renderer, widget)
	UIRenderer.end_pass(ui_renderer)
end)

-- ACTIVE MOD UI FUNCTIONS --
-----------------------------

-- Set up spawning the chosen unit
mod.toggle_flight_mode = function(self, compteur)
	local free_flight_manager = Managers.free_flight
	if free_flight_manager then
		if not free_flight_manager.data or not free_flight_manager:active(1) then
			fyf_activation_status = true
			mod:enable_freeflight(free_flight_manager)
		else
			fyf_activation_status = false
			mod:disable_freeflight(free_flight_manager, compteur)
			local health_extension = ScriptUnit.extension(Managers.player:local_player().player_unit, "health_system")
			local status_extension = ScriptUnit.extension(Managers.player:local_player().player_unit, "status_system")
			health_extension.is_invincible = false
		end
	end
end

mod.enable_freeflight = function (self, free_flight_manager, compteur)
	local local_player = Managers.player:local_player()

	if local_player then

		mod:enable_all_hooks()

		-- Remove player gravity
		local local_player = Managers.player:local_player()
		if local_player then
			local player_unit = local_player.player_unit
			if player_unit then
			local health_extension = ScriptUnit.extension(Managers.player:local_player().player_unit, "health_system")
			health_extension.is_invincible = true
			Unit.set_unit_visibility(player_unit, true)

				local movement_table = PlayerUnitMovementSettings.get_movement_settings_table(player_unit)
				if movement_table then
					movement_table.move_acceleration_down = 0
					movement_table.gravity_acceleration = 0
					movement_table.fall.heights.MAX_FALL_DAMAGE = 0
					movement_table.fall.heights.MIN_FALL_DAMAGE_HEIGHT = math.huge
					movement_table.fall.heights.HARD_LANDING_FALL_HEIGHT = math.huge
				end
			end
		end

		-- Disable dev setting that prevents free flight
		GameSettingsDevelopment.disable_free_flight = false
		mod:set_compteur(false)

		-- Register free flight input manager/service
		local input_manager = Managers.input

		-- Attempt to remove problematic keymaps
		if input_manager.stored_keymaps_data["FreeFlightKeymaps"] then
			mod.FreeFlightKeymaps = mod.FreeFlightKeymaps or table.clone(input_manager.stored_keymaps_data["FreeFlightKeymaps"])

			local input_ffk_w32_k = input_manager.stored_keymaps_data["FreeFlightKeymaps"].win32.keymaps
			local input_pck_w32_k = input_manager.stored_keymaps_data["PlayerControllerKeymaps"].win32.keymaps

			input_ffk_w32_k.mark[2] = 36
			input_ffk_w32_k.decrease_frame_step_1[2] = 36
			input_ffk_w32_k.decrease_frame_step_2[2] = 36
			input_ffk_w32_k.set_drop_position[2] = 36
			input_ffk_w32_k.step_frame_1[2] = 36
			input_ffk_w32_k.step_frame_2[2] = 36
			input_ffk_w32_k.ray[2] = 36
			input_ffk_w32_k.toggle_control_points[2] = 36
			input_ffk_w32_k.play_pause_1[2] = 36
			input_ffk_w32_k.play_pause_2[2] = 36
			input_ffk_w32_k.toggle_mouse_focus[2] = 36
			input_ffk_w32_k.increase_frame_step_1[2] = 36
			input_ffk_w32_k.increase_frame_step_2[2] = 36
			input_ffk_w32_k.toggle_debug_info[2] = 36
			input_ffk_w32_k.projection_mode[2] = 36
			input_ffk_w32_k.free_flight_toggle[2] = 36
			input_ffk_w32_k.toggle_dof[2] = 36
			input_ffk_w32_k.inc_dof_distance[2] = 36
			input_ffk_w32_k.dec_dof_distance[2] = 36
			input_ffk_w32_k.inc_dof_region[2] = 36
			input_ffk_w32_k.dec_dof_region[2] = 36
			input_ffk_w32_k.inc_dof_padding[2] = 36
			input_ffk_w32_k.dec_dof_padding[2] = 36
			input_ffk_w32_k.inc_dof_scale[2] = 36
			input_ffk_w32_k.dec_dof_scale[2] = 36
			input_ffk_w32_k.increase_fov[2] = 36
			input_ffk_w32_k.decrease_fov[2] = 36

			input_ffk_w32_k.move_forward[2] = input_pck_w32_k.move_forward[2]
			input_ffk_w32_k.move_left[2] = input_pck_w32_k.move_left[2]
			input_ffk_w32_k.move_right[2] = input_pck_w32_k.move_right[2]
			input_ffk_w32_k.move_back[2] = input_pck_w32_k.move_back[2]

			if input_pck_w32_k.crouch[2] then
				input_ffk_w32_k.move_down[2] = input_pck_w32_k.crouch[2]
			elseif input_pck_w32_k.crouching[2] then
				input_ffk_w32_k.move_down[2] = input_pck_w32_k.crouching[2]
			else
				input_ffk_w32_k.move_down[2] = 36
			end

			if input_pck_w32_k.jump_1[2] then
				input_ffk_w32_k.move_up[2] = input_pck_w32_k.jump_1[2]
			elseif input_pck_w32_k.jump_2[2] then
				input_ffk_w32_k.move_up[2] = input_pck_w32_k.jump_2[2]
			elseif input_pck_w32_k.jump_only[2] then
				input_ffk_w32_k.move_up[2] = input_pck_w32_k.jump_only[2]
			else
				input_ffk_w32_k.move_up[2] = 36
			end
		end

		--
		-----------
		-- two_handed_cog_hammers_template_1	units/weapons/player/wpn_empire_short_sword/wpn_empire_short_sword
		-- beer_barrel							units/weapons/player/wpn_explosive_barrel/wpn_explosive_barrel_01
		-- magic_barrel							units/weapons/player/pup_magic_barrel/wpn_magic_barrel_01
		-- explosive_barrel						units/weapons/player/wpn_explosive_barrel/wpn_explosive_barrel_01
		-- explosive_barrel_objective			units/weapons/player/wpn_explosive_barrel/wpn_gun_powder_barrel_01
		-- lamp_oil								units/weapons/player/wpn_oil_jug_01/wpn_oil_jug_01

		-- getmetatable())
		-----------
		-- test
		local Weapons = Weapons
		-- for key,value in pairs(Weapons.two_handed_cog_hammers_template_1) do
		-- 	print(key, value)
		-- end

		Weapons.explosive_barrel.actions.action_one.default.alert_sound_range_hit = 1 -- = 10
		Weapons.explosive_barrel.actions.action_two.default.alert_sound_range_hit = 1
		Weapons.explosive_barrel.actions.action_dropped.default.alert_sound_range_hit = 1

		-- weapon_template_barrel.actions.action_one.default.alert_sound_range_hit
		--

		test_cpt = 1

		free_flight_manager.register_input_manager(free_flight_manager, input_manager)

		-- Enable free flight
		self.first_person_mode = true
		free_flight_manager.register_player(free_flight_manager, 1)
		free_flight_manager._enter_free_flight(free_flight_manager, local_player, free_flight_manager.data[1])

		input_manager:device_unblock_all_services("keyboard")
		input_manager:device_unblock_all_services("mouse")
		input_manager:device_unblock_all_services("gamepad")
	end
end

mod.disable_freeflight = function (self, free_flight_manager, compteur)
	-- Reset variables to normal values
	local local_player = Managers.player:local_player()
	if local_player then

		-- Restore movement settings (should be reset upon map reset anyway)
		local local_player_unit = local_player.player_unit
		if local_player_unit then
			local health_extension = ScriptUnit.extension(Managers.player:local_player().player_unit, "health_system")
			health_extension.is_invincible = false
			local status_extension = ScriptUnit.extension(local_player_unit, "status_system")

			-- Clear fall damage for next fall
			if status_extension and status_extension.fall_height then
				status_extension.fall_height = -1 * math.huge
			end

			-- Restore movement settings (should be reset upon map reset anyway)
			local movement_table = PlayerUnitMovementSettings.get_movement_settings_table(local_player_unit)
			if movement_table then
				movement_table.move_acceleration_down = mod.backup_move_acceleration_down
				movement_table.gravity_acceleration = mod.backup_gravity_acceleration
				movement_table.fall.heights.MAX_FALL_DAMAGE = mod.backup_MAX_FALL_DAMAGE
				movement_table.fall.heights.MIN_FALL_DAMAGE_HEIGHT = mod.backup_MIN_FALL_DAMAGE_HEIGHT
				movement_table.fall.heights.HARD_LANDING_FALL_HEIGHT = mod.backup_HARD_LANDING_FALL_HEIGHT
			end
		end

		-- Disable free flight and input service
		free_flight_manager._exit_free_flight(free_flight_manager, local_player, free_flight_manager.data[1])
		free_flight_manager.unregister_input_manager(free_flight_manager)

		-- Re-add keymaps
		local input_manager = Managers.input
		if input_manager.stored_keymaps_data["FreeFlightKeymaps"] then
			input_manager.stored_keymaps_data["FreeFlightKeymaps"] = mod.FreeFlightKeymaps
		end
	end

	GameSettingsDevelopment.disable_free_flight = true
	mod:set_compteur(true)
	mod.first_run_fov_changed = false

	local player_unit = Managers.player:local_player().player_unit
	local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")
	first_person_extension.MAX_MIN_PITCH = (math.pi / 2 - (math.pi / 15))

	mod:disable_all_hooks()
end

mod.get_compteur = function (self)
	return compteur
end

mod.set_compteur = function (self, compteur_tmp)
	compteur = compteur_tmp
	return compteur
end

-- HOOKS --
-----------

-- PlayerUnitFirstPerson --

mod:hook_origin(PlayerUnitFirstPerson, "calculate_look_rotation", function (self, current_rotation, look_delta, ...)
	local yaw = Quaternion.yaw(current_rotation) - look_delta.x

	if not GameSettingsDevelopment.disable_free_flight then
		-- Disable the pitch "look" limiter: you can rotate your head wherever you want
		self.MAX_MIN_PITCH = math.pi
	end

	if self.restrict_rotation_angle then
		yaw = math.clamp(yaw, -self.restrict_rotation_angle, self.restrict_rotation_angle)
	end

	local pitch = math.clamp(Quaternion.pitch(current_rotation) + look_delta.y, -self.MAX_MIN_PITCH, self.MAX_MIN_PITCH)
	local yaw_rotation = Quaternion(Vector3.up(), yaw)
	local pitch_rotation = Quaternion(Vector3.right(), pitch)
	local look_rotation = Quaternion.multiply(yaw_rotation, pitch_rotation)

	return look_rotation
end)

mod:hook_origin(PlayerUnitFirstPerson, "update", function (self, unit, input, dt, context, t)
	if Managers.input:is_device_active("gamepad") then
		self:update_aim_assist_multiplier(dt)
	end

	self.first_person_mode = true;

	self:update_player_height(t)
	self:update_rotation(t, dt)
	self:update_position()

	local player = Managers.player:owner(unit)
	local head_bob = Application.user_setting("head_bob")

	-- Manage if head bob is activated or not and some cases linked to it
	if not self._head_bob and head_bob then
		Unit.animation_event(self.first_person_unit, "enable_headbob")

		self._head_bob = true
	elseif self._head_bob and not head_bob then
		Unit.animation_event(self.first_person_unit, "disable_headbob")

		self._head_bob = false
	end

	if self.toggle_visibility_timer and self.toggle_visibility_timer <= t then
		self.toggle_visibility_timer = nil
		self:set_first_person_mode(false)
		self:set_first_person_mode(true)
	end

	-- Update the first person model from third person model and some variables linked to it
	-- if player and Managers.state.debug.free_flight_manager:active(player:local_player_id()) and self.first_person_mode then
	-- 	self:set_first_person_mode(true)
	-- 	self.free_flight_changed_fp_mode = true
	-- elseif player and not Managers.state.debug.free_flight_manager:active(player:local_player_id()) and self.free_flight_changed_fp_mode then
	-- 	self:set_first_person_mode(true)
	-- 	self.free_flight_changed_fp_mode = false
	-- end

	-- Idem, just a case when camera is zooming in from 3rd to 1st
	-- mod:echo("t = " .. tostring(math.floor(t+0.5)) .. " and toggle_visibility_timer = " .. tostring(self.toggle_visibility_timer))
	-- mod:echo(test_cpt)

	--if self.toggle_visibility_timer and test_cpt then -- and self.toggle_visibility_timer <= t then
	-- mod:echo(test_cpt)
	-- if test_cpt then
	-- 	self.toggle_visibility_timer = t
	-- end
	

	-- local was_in_third_person = self._was_in_first_person
	-- self._was_in_first_person = Development.parameter("third_person_mode")

	-- if Development.parameter("third_person_mode") and not was_in_third_person then
	-- 	CharacterStateHelper.change_camera_state(Managers.player:local_player(), "follow_third_person_over_shoulder")
	-- 	self:set_first_person_mode(false, true)
	-- elseif not Development.parameter("third_person_mode") and was_in_third_person then
	-- 	CharacterStateHelper.change_camera_state(Managers.player:local_player(), "follow")
	-- 	self:set_first_person_mode(true)
	-- end

	-- if script_data.attract_mode_spectate and self.first_person_mode then
	-- 	CharacterStateHelper.change_camera_state(Managers.player:local_player(), "attract")
	-- 	self:set_first_person_mode(false, true)
	-- end
end)

-- Freeflight Manager --

mod:hook_origin(FreeFlightManager, "_enter_free_flight", function (self, player, data, ...)
	local world_name = player.viewport_world_name
	local viewport_name = player.viewport_name
	local world = Managers.world:world(world_name)
	local viewports = World.get_data(world, "viewports")
	local cam = ScriptViewport.camera(viewports[viewport_name])
	local cam_fov = Camera.vertical_fov(cam)

	data.active = true
	data.viewport_name = player.viewport_name
	data.viewport_world_name = world_name

	local viewport = ScriptWorld.create_free_flight_viewport(world, viewport_name, "default")
	local cam = ScriptViewport.camera(viewport)
	local tm = Camera.local_pose(cam)
	local position = Matrix4x4.translation(tm)
	local rotation = Matrix4x4.rotation(tm)

	Camera.set_vertical_fov(cam, cam_fov)

	if self._has_terrain then
		data.terrain_decoration_observer = TerrainDecoration.create_observer(world, position)
	end

	data.scatter_system_observer = ScatterSystem.make_observer(World.scatter_system(world), position, rotation)

	self.input_manager:block_device_except_service("FreeFlight", "keyboard", nil, "free_flight")
	self.input_manager:block_device_except_service("FreeFlight", "mouse", nil, "free_flight")
	self.input_manager:block_device_except_service("FreeFlight", "gamepad", nil, "free_flight")
end)

mod:hook_origin(ScriptWorld, "create_free_flight_viewport", function (world, overridden_viewport_name, template, ...)

	local overridden_viewport = ScriptWorld.viewport(world, overridden_viewport_name)
	local free_flight_viewport = Application.create_viewport(world, template)

	Viewport.set_data(free_flight_viewport, "layer", Viewport.get_data(overridden_viewport, "layer"))

	local free_flight_viewports = World.get_data(world, "free_flight_viewports")

	fassert(free_flight_viewports[overridden_viewport_name] == nil, "Free flight viewport %q already exists", overridden_viewport_name)

	free_flight_viewports[overridden_viewport_name] = free_flight_viewport
	local camera_unit = World.spawn_unit(world, "core/units/camera")
	local camera = Unit.camera(camera_unit, "camera")

	Camera.set_data(camera, "unit", camera_unit)

	local overridden_viewport_camera = ScriptViewport.camera(overridden_viewport)
	local pose = Camera.local_pose(overridden_viewport_camera)

	ScriptCamera.set_local_pose(camera, pose)
	Viewport.set_data(free_flight_viewport, "camera", camera)
	Viewport.set_data(free_flight_viewport, "overridden_viewport", overridden_viewport)
	ScriptWorld._update_render_queue(world)

	return free_flight_viewport
end)

mod:hook_origin(FreeFlightManager, "_exit_free_flight", function (self, player, data, ...)
	local world = Managers.world:world(data.viewport_world_name)

	if data.frustum_freeze_camera then
		self:_exit_frustum_freeze(data, world, ScriptWorld.viewport(world, data.viewport_name))
	end

	local viewport_name = data.viewport_name
	data.active = false
	data.viewport_name = nil
	data.viewport_world_name = nil

	if self._has_terrain then
		TerrainDecoration.destroy_observer(world, data.terrain_decoration_observer)
	end

	ScatterSystem.destroy_observer(World.scatter_system(world), data.scatter_system_observer)

	data.terrain_decoration_observer = nil
	data.scatter_system_observer = nil

	ScriptWorld.destroy_free_flight_viewport(world, viewport_name)
	self.input_manager:device_unblock_all_services("keyboard")
	self.input_manager:device_unblock_all_services("mouse")
	self.input_manager:device_unblock_all_services("gamepad")
end)

-- Update player position when updating free flight
mod:hook_origin(FreeFlightManager, "_update_free_flight", function (self, dt, player, data, ...)
	local world = Managers.world:world(data.viewport_world_name)							

	local viewport = ScriptWorld.free_flight_viewport(world, data.viewport_name)
	local cam = data.frustum_freeze_camera or ScriptViewport.camera(viewport)
	local input = self.input_manager:get_service("FreeFlight")

	-- Modify the player flight speed with mouse scroll. Max speed = 100.0, min speed = 1.0
	local translation_change_speed = data.current_translation_max_speed * 0.5
	local speed_change = Vector3.y(input:get("speed_change") or Vector3(0, 0, 0))
	data.current_translation_max_speed = math.max(data.current_translation_max_speed + speed_change * 5, 0.01)
	if data.current_translation_max_speed > 100.0 then
		data.current_translation_max_speed = 100.0
	elseif data.current_translation_max_speed < 5.0 then
		data.current_translation_max_speed = 5.0
	end
	speed = data.current_translation_max_speed

	local cm = Camera.local_pose(cam)
	local trans = Matrix4x4.translation(cm)
	Matrix4x4.set_translation(cm, Vector3(0, 0, 0))

	local mouse = input:get("look")
	local rotation_accumulation = data.rotation_accumulation:unbox() + mouse
	local rotation = rotation_accumulation * math.min(dt, 1) * 15
	data.rotation_accumulation:store(rotation_accumulation - rotation)

	local q1 = Quaternion(Vector3(0, 0, 1), -Vector3.x(rotation) * data.rotation_speed)
	local q2 = Quaternion(Matrix4x4.x(cm), -Vector3.y(rotation) * data.rotation_speed)
	local q = Quaternion.multiply(q1, q2)
	cm = Matrix4x4.multiply(cm, Matrix4x4.from_quaternion(q))

	local wanted_speed = input:get("move") * data.current_translation_max_speed
	local current_speed = data.current_translation_speed:unbox()
	local speed_difference = wanted_speed - current_speed
	local speed_distance = Vector3.length(speed_difference)
	local speed_difference_direction = Vector3.normalize(speed_difference)
	data.acceleration = 10 * Vector3.length(speed_difference)
	local acceleration = data.acceleration
	local new_speed = current_speed + speed_difference_direction * math.min(speed_distance, acceleration * dt)
	data.current_translation_speed:store(new_speed)

	local rot = Matrix4x4.rotation(cm)
	local offset = (Quaternion.forward(rot) * new_speed.y + Quaternion.right(rot) * new_speed.x + Quaternion.up(rot) * new_speed.z) * dt
	trans = Vector3.add(trans, offset)

	Matrix4x4.set_translation(cm, trans)
	ScriptCamera.set_local_pose(cam, cm)

	local wwise_world = Managers.world:wwise_world(world)

	WwiseWorld.set_listener(wwise_world, 0, cm)

	if self._has_terrain then
		TerrainDecoration.move_observer(world, data.terrain_decoration_observer, trans)
	end

	ScatterSystem.move_observer(World.scatter_system(world), data.scatter_system_observer, trans, rot)

	local player_unit = Managers.player:local_player().player_unit
	local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")

	local num_actors = Unit.num_actors(first_person_extension.unit)
	for i = 1, num_actors, 1 do
		local actor = Unit.actor(first_person_extension.unit, i)
	  	if actor then
	  		Actor.set_collision_enabled(actor, false)
	   	end
	end

	-- Always change player position while flying
	self.drop_player_at_camera_pos(self, cam, player)
end)

-- Keep player model in sight of camera
mod:hook_origin(FreeFlightManager, "drop_player_at_camera_pos", function (self, cam, player, ...)

	local pos = Camera.local_position(cam)
	local rot = Camera.local_rotation(cam)

	local offset = { x = 0, y = 0, z = -1.54 }

	local player_unit = Managers.player:local_player().player_unit
	local talent_extension = ScriptUnit.extension(player_unit, "talent_system")
	local talent_extension = talent_extension
	local current_hero_index = talent_extension._profile_index
	local current_hero = SPProfiles[current_hero_index]
	local hero_name = current_hero.display_name

	if hero_name == "empire_soldier" then
		-- Kruber
		offset.z = -1.65
	elseif hero_name == "dwarf_ranger" then
		-- Dwarf
		offset.z = -1.3
	elseif hero_name == "wood_elf" then
		-- Kerillian
		offset.z = -1.5
	elseif hero_name == "witch_hunter" then
		-- Saltz
		offset.z = -1.7
	elseif hero_name == "bright_wizard" then
		-- Sienna
		offset.z = -1.55
	else
		-- Average
		offset.z = -1.54
	end

	-- Apply offset to get final player position
	local x = offset.x * Quaternion.right(rot)
	local y = offset.y * Quaternion.forward(rot)
	local z = Vector3(0, 0, offset.z)

	pos = pos + x + y + z

	if self._teleport_override then
		self._teleport_override(pos, rot)
	elseif player and player.camera_follow_unit then
		Unit.set_local_position(player.camera_follow_unit, 0, pos)

		local mover = Unit.mover(player.camera_follow_unit)

		if mover then
			Mover.set_position(mover, pos)
		end
	end
end)

-- Prevent global free flight toggle
mod:hook_origin(FreeFlightManager, "_enter_global_free_flight", function (...) return end)

-- Prevent crash when trying to freeze camera frustum
mod:hook_origin(FreeFlightManager, "_exit_frustum_freeze", function (...) return end)
mod:hook_origin(FreeFlightManager, "_enter_frustum_freeze", function (...) return end)

-- Input Manager --

mod:hook_safe(InputManager, "update", function (func, dt, ...) -- 1.2 Disabled Free Flight Manager Update, it needs to be re-injected after input update to work properly.
	Managers.free_flight:update(dt)
end)

-- Prevent error when taking control of devices without debug console active
mod:hook(InputManager, "device_unblock_service", function (func, self, device_type, device_index, service_name, ...)

	if service_name == "Debug" or service_name == "DebugMenu" then
		return
	end

	-- Original Function
	local result = func(self, device_type, device_index, service_name, ...)
	return result
end)

-- Player Related --

-- Prevent just the flying player from sticking to ledges
mod:hook(CharacterStateHelper, "is_ledge_hanging", function (func, world, unit, ...)

	local local_player = Managers.player:local_player()
	local player_unit = local_player.player_unit
	if unit == player_unit then
		return false
	end

	-- Original Function
	local result = func(world, unit, ...)
	return result
end)

-- Prevent death walls during flight
mod:hook(PlayerUnitHealthExtension, "add_damage", function (func, self, attacker_unit, damage_amount, hit_zone_name, damage_type, damage_direction, damage_source_name, ...)

	-- Test for suicide damage source
	if damage_source_name == "suicide" then

		-- Test for existence of player
		local local_player = Managers.player:local_player()
		if local_player then

			-- Prevent suicide in the local player unit
			local extension_unit = self.unit
			if extension_unit and extension_unit == local_player.player_unit then
				damage_amount = 0
			end
		end

	end

	-- Original Function
	local result = func(self, attacker_unit, damage_amount, hit_zone_name, damage_type, damage_direction, damage_source_name, ...)
	return result
end)

-- Prevent death walls during flight
mod:hook(PlayerUnitHealthExtension, "die", function (func, self, damage_type, ...)

	-- Test for existence of player
	local local_player = Managers.player:local_player()
	if local_player then

		-- Test that local player's unit is the unit of this health extension
		local extension_unit = self.unit
		if extension_unit and extension_unit == local_player.player_unit then
			return
		end
	end

	-- Original Function
	local result = func(self, damage_type, ...)
	return result
end)

-- CALLBACK --
--------------

-- Call when game state changes (e.g. StateLoading -> StateIngame)
mod.on_game_state_changed = function(status, state)
	if state == "StateLoading" and status == "enter" then
		local free_flight_manager = Managers.free_flight
		if free_flight_manager and free_flight_manager.data and free_flight_manager:active(1) then	
			mod:disable_freeflight(free_flight_manager)
		end
	end
end
