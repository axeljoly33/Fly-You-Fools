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
				setting_id = "show_speed_multiplier",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id      = "offset_x",
				type            = "numeric",
				default_value   = 0,
				range           = {-960, 960}
			},
			{
				setting_id      = "offset_y",
				type            = "numeric",
				default_value   = 0,
				range           = {-540, 540}
			},
			{
				setting_id = "fyf_font_size",
				type = "numeric",
				default_value = 32,
				range = {8, 128},
			}
		}
	}
}