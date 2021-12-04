return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Fly You Fools` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Fly You Fools", {
			mod_script       = "scripts/mods/Fly You Fools/Fly You Fools",
			mod_data         = "scripts/mods/Fly You Fools/Fly You Fools_data",
			mod_localization = "scripts/mods/Fly You Fools/Fly You Fools_localization",
		})
	end,
	packages = {
		"resource_packages/Fly You Fools/Fly You Fools",
	},
}
