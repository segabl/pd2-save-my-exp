if Network:is_server() then
	return
end

local data_file = SavePath .. "SaveMyExp.json"
if not Global.save_my_exp then
	Global.save_my_exp = io.file_is_readable(data_file) and io.load_as_json(data_file) or {}
end

if RequiredScript == "lib/managers/experiencemanager" then

	Hooks:PostHook(ExperienceManager, "mission_xp_award", "mission_xp_award_save_my_exp", function (self)
		local current_exp = self._global.mission_xp_current
		if not current_exp then
			return
		end

		Global.save_my_exp.t = managers.game_play_central:get_heist_timer()
		Global.save_my_exp.data = { current_exp:byte(1, current_exp:len()) }
		io.save_as_json(Global.save_my_exp, data_file)

		BLT:Log(LogLevel.INFO, "[SaveMyExp] Mission EXP awarded")
	end)

	Hooks:PostHook(ExperienceManager, "mission_xp_process", "mission_xp_process_save_my_exp", function ()
		Global.save_my_exp = {}
		if io.file_is_readable(data_file) then
			os.remove(data_file)
		end

		BLT:Log(LogLevel.INFO, "[SaveMyExp] Mission EXP processed")
	end)

elseif RequiredScript == "lib/managers/gameplaycentralmanager" then

	Hooks:PostHook(GamePlayCentralManager, "load", "load_save_my_exp", function (self)
		local host = managers.network:session():peer(1):rpc():ip_at_index(0)
		local id = host .. "_" .. tostring(managers.job:current_job_id()) .. "_" .. tostring(managers.job:current_level_id()) .. "_" .. Global.game_settings.difficulty

		if not self._restored_exp and Global.save_my_exp.data then
			if Global.save_my_exp.id == id and Global.save_my_exp.t and self:get_heist_timer() > Global.save_my_exp.t then
				local exp = Application:digest_value(string.char(unpack(Global.save_my_exp.data)), false)
				managers.experience:mission_xp_award(exp)
				self._restored_exp = true

				BLT:Log(LogLevel.INFO, "[SaveMyExp] Restored " .. tostring(exp) .. " previously earned EXP")
			else
				Global.save_my_exp = {}
				if io.file_is_readable(data_file) then
					os.remove(data_file)
				end

				BLT:Log(LogLevel.INFO, "[SaveMyExp] Cleared non matching EXP data")
			end
		end

		Global.save_my_exp.id = id
	end)

end
