local mod = get_mod("Fly You Fools")

--[[ _data.lua ]]
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
				setting_id    = "hide_ui",
				type          = "checkbox",
				default_value = false,
				sub_widgets   = {
					{
						setting_id      = "hide_arms",
						type            = "checkbox",
						default_value   = false,
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
						default_value   = false,
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
						range         = {0, 128},
					}
				}
			}
		}
	}
}