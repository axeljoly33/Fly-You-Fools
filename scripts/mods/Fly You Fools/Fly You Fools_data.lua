local mod = get_mod("Fly You Fools")

return {
	name 			 = "Fly You Fools",
	description 	 = "First person flight mod.",
	is_togglable 	 = true,
	is_mutator 		 = false,
	mutator_settings = {},

	options = {
		widgets = {
			{
				setting_id    	= "fyf_activation_var",
				type          	= "keybind",
				keybind_trigger = "pressed",
				default_value 	= {},
				title         	= "activation_var_title_id",
				tooltip       	= "activation_var_tooltip_id",
				keybind_type    = "function_call",
				function_name   = "toggle_flight_mode"
			},
			{
				setting_id  = "speed_group",
				type        = "group",
				sub_widgets = {
					{
						setting_id      = "min_speed",
						type            = "numeric",
						default_value   = 5,
						range           = {0, 200}
					},
					{
						setting_id      = "max_speed",
						type            = "numeric",
						default_value   = 100,
						range           = {0, 200}
					},
					{
						setting_id    = "step_speed",
						type          = "dropdown",
						default_value = 5,
						options = {
						  {text = "step_speed_1", value = 1},
						  {text = "step_speed_2", value = 2},
						  {text = "step_speed_5", value = 5},
						  {text = "step_speed_10", value = 10},
						  {text = "step_speed_25", value = 25},
						  {text = "step_speed_50", value = 50}
						}
					}
				}
			},
			{
				setting_id  = "hide_group",
				type        = "group",
				sub_widgets = {
					{
						setting_id    = "hide_ui",
						type          = "checkbox",
						default_value = false
					},
					{
						setting_id      = "hide_arms",
						type            = "checkbox",
						default_value   = false
					},
					{
						setting_id      = "hide_weapon",
						type            = "checkbox",
						default_value   = false
					}
				}
			},
			-- {
			-- 	setting_id  = "walls_group",
			-- 	type        = "group",
			-- 	sub_widgets = {
			-- 		{
			-- 			setting_id      = "fyf_show_walls",
			-- 			type            = "keybind",
			-- 			default_value   = { },
			-- 			keybind_global  = true,
			-- 			keybind_trigger = "pressed",
			-- 			keybind_type    = "function_call",
			-- 			function_name   = "draw_invisible_walls"
			-- 		},
			-- 		{
			-- 			setting_id  = "walls_color_group",
			-- 			type        = "group",
			-- 			sub_widgets = {
			-- 				{
			-- 					setting_id      = "fyf_walls_color_alpha",
			-- 					type            = "numeric",
			-- 					default_value   = 255,
			-- 					range           = {0, 255}
			-- 				},
			-- 				{
			-- 					setting_id      = "fyf_walls_color_red",
			-- 					type            = "numeric",
			-- 					default_value   = 255,
			-- 					range           = {0, 255}
			-- 				},
			-- 				{
			-- 					setting_id      = "fyf_walls_color_green",
			-- 					type            = "numeric",
			-- 					default_value   = 0,
			-- 					range           = {0, 255}
			-- 				},
			-- 				{
			-- 					setting_id      = "fyf_walls_color_blue",
			-- 					type            = "numeric",
			-- 					default_value   = 0,
			-- 					range           = {0, 255}
			-- 				}
			-- 			}
			-- 		}
			-- 	}
			-- },
			{
				setting_id    = "fyf_custom_fov",
				type          = "checkbox",
				default_value = false,
				sub_widgets   = {
					{
						setting_id      = "fyf_custom_fov_row",
						type            = "numeric",
						default_value   = 105,
						range           = {10, 160}
					}
				}
			},
			{
				setting_id    = "show_ui_widget",
				type          = "checkbox",
				default_value = false,
				sub_widgets   = {
					{
						setting_id      = "show_speed_multiplier",
						type            = "checkbox",
						default_value   = false
					},
					{
						setting_id      = "offset_x",
						type            = "numeric",
						default_value   = 0,
						range           = {-3840, 3840}
					},
					{
						setting_id      = "offset_y",
						type            = "numeric",
						default_value   = 0,
						range           = {-2160, 2160}
					},
					{
						setting_id    = "fyf_font_size",
						type          = "numeric",
						default_value = 32,
						range         = {0, 128}
					}
				}
			}
		}
	}
}