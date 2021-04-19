--  AI决定雷击的目标  --
--  返回是否发动、目标  --
function ai_judge_leiji_mubiao(ID_s, ID_laiyuan)
	if ai_judge_same_identity(ID_s, ID_laiyuan, true) ~= 1 then
		return true, ID_laiyuan
	end

	local attack_mubiao = ai_basic_judge_mubiao(ID_s, 1, false, true, true)
	if #attack_mubiao == 0 then
		return false, 0
	else
		return true, attack_mubiao[1]
	end
end

--  AI决定崩坏选择  --
--  true减体力，false减上限  --
function ai_judge_benghuai(ID)
	if char_juese[ID].tili == char_juese[ID].tili_max then
		return true
	else
		if char_juese[ID].tili_max <= 1 then
			return true
		else
			return false
		end
	end
end

--  AI决定是否响应暴虐  --
function ai_judge_baonue(ID, ID_zhugong)
	if ai_judge_same_identity(ID, ID_zhugong, true) == 1 then
		return true
	else
		return false
	end
end

--  AI决定是否发动闭月  --
--  true发动，false不发动  --
function ai_judge_biyue(ID)
	return true
end

--  AI决定是否发动新生  --
--  true发动，false不发动  --
function ai_judge_xinsheng(ID)
	return true
end

--  AI决定是否发动焚心  --
--  1发动，2不发动  --
function ai_judge_fenxin(ID)
	local left, lord_blood = {1,2,1}, 0
	for i = 1, 5 do
		if char_juese[i].siwang == true then
			if char_juese[i].shenfen == "忠臣" then
				left[1] = left[1] - 1
			elseif char_juese[i].shenfen == "反贼" then
				left[2] = left[2] - 1
			elseif char_juese[i].shenfen == "内奸" then
				left[3] = left[3] - 1
			end
		elseif char_juese[i].shenfen == "主公" then
			lord_blood = char_juese[i].tili
		end
	end
	if char_juese[ID] == "忠臣" and left[2] <= 1 and left[3] == 0 and lord_blood <= 2 then
		return ai_judge_random_percent(20) + 1
	elseif char_juese[ID] == "反贼" and left[2] == 1 and left[3] == 0 then
		return 1
	elseif char_juese[ID] == "内奸" and left[2] == 0 and left[1] == 1 then
		return 1
	elseif char_juese[ID] == "内奸" then
		return ai_judge_random_percent(50) + 1
	else
		return ai_judge_random_percent(70) + 1
	end
end

--  AI决定是否发动离间  --
--  返回是否发动、手牌ID、目标  --
function ai_judge_lijian(ID)
	local possible_targets = {1, 2, 3, 4, 5}
	for i = #possible_targets, 1, -1 do
		if char_juese[possible_targets[i]].xingbie ~= "男" or possible_targets[i] == ID then
			table.remove(possible_targets, i)
		end
	end

	local attack_mubiao = ai_basic_judge_mubiao(ID, 2, false, true, true, possible_targets)
	if #attack_mubiao < 2 then
		char_juese[ID].skill["离间"] = "locked"
		return false, 0, 0
	end
	
	local cards = ai_card_search(ID, "随意", #char_juese[ID].shoupai)
	local s = char_juese[ID].shoupai

	local percent = 100
	for i = #cards, 1, -1 do
		if card_judge_if_shan(ID, cards[i]) then
			if ai_judge_random_percent(percent) == 1 then
				table.remove(cards, i)
				percent = 30
			end
		end
	end
	if #cards == 0 then
		char_juese[ID].skill["离间"] = "locked"
		return false, 0, 0
	end
	cards = random_pick(cards, 1)

	if #char_juese[attack_mubiao[1]].shoupai > #char_juese[attack_mubiao[2]].shoupai then
		local _attack_mubiao = {attack_mubiao[1], attack_mubiao[2]}
		attack_mubiao = _attack_mubiao
	else
		local _attack_mubiao = {attack_mubiao[2], attack_mubiao[1]}
		attack_mubiao = _attack_mubiao
	end

	if #cards == 0 then
		char_juese[ID].skill["离间"] = "locked"
		return false, 0, 0
	else
		return true, cards[1], attack_mubiao
	end
end

--  AI决定是否发动青囊  --
--  返回是否发动、手牌ID、目标  --
function ai_judge_qingnang(ID)
	local cards = ai_card_search(ID, "随意", #char_juese[ID].shoupai)
	local shan_removed = false
	local sha_removed = false

	for i = #cards, 1, -1 do
		if card_judge_if_shan(ID, cards[i]) and shan_removed == false then
			table.remove(cards, i)
			shan_removed = true
		elseif card_judge_if_sha(ID, cards[i]) and sha_removed == false then
			if ai_judge_random_percent(30) == 1 then
				table.remove(cards, i)
			end
			sha_removed = true
		end
	end

	cards = random_pick(cards, 1)
	if #cards == 0 then
		char_juese[ID].skill["青囊"] = "locked"
		return false, 0, 0
	end

	if char_juese[ID].tili < char_juese[ID].tili_max - 1 and ai_judge_random_percent(80) == 1 then
		return true, cards[1], ID
	end

	local help_mubiao = ai_basic_judge_mubiao(ID, 4, true, false, true)

	for i = #help_mubiao, 1, -1 do
		if char_juese[help_mubiao[i]].tili == char_juese[help_mubiao[i]].tili_max then
			table.remove(help_mubiao, i)
		end
	end
	if #help_mubiao == 0 then
		char_juese[ID].skill["青囊"] = "locked"
		return false, 0, 0
	end

	if #help_mubiao == 1 then
		return true, cards[1], help_mubiao[1]
	else
		local mindef_ID = help_mubiao[1]
		for i = 2, #help_mubiao do
			if ai_judge_def(help_mubiao[i], false, false) < ai_judge_def(mindef_ID, false, false) then
				mindef_ID = help_mubiao[i]
			end
		end
		return true, cards[1], mindef_ID
	end
end

--  AI决定是否发动乱击  --
--  返回是否发动、手牌列表  --
function ai_judge_luanji(ID)
	local cards = ai_card_search(ID, "黑桃", 2)
	if #cards < 2 then
		cards = ai_card_search(ID, "草花", 2)
	end
	if #cards < 2 then
		cards = ai_card_search(ID, "红桃", 2)
	end
	if #cards < 2 then
		cards = ai_card_search(ID, "方块", 2)
	end

	if #cards < 2 then
		return false, {}
	end
	table.sort(cards)

	if ai_judge_AOE(ID, "万箭齐发") >= 0.5 then
		return true, cards
	else
		return false, {}
	end
end

--  AI决定是否发动竭缘  --
--  返回是否发动、手牌ID  --
function ai_judge_jieyuan(ID, ID_counterpart, dianshu, shuxing, mode)
	if mode == "造成伤害" then
		if ai_judge_same_identity(ID, ID_counterpart, true) ~= 2 then
			return false, 0
		end
	end
 
	local cards
	local percent
	if mode == "造成伤害" then
		percent = 20
		cards = ai_card_search(ID, "黑色", 1)
	else
		percent = 0
		cards = ai_card_search(ID, "红色", #char_juese[ID].shoupai)
		for i = #cards, 1, -1 do
			if card_judge_if_shan(ID, cards[i]) then
				table.remove(cards, i)
				break
			end
		end
	end
	while #cards > 1 do
		table.remove(cards, math.random(#cards))
	end

	if #cards == 0 or ai_judge_random_percent(percent) == 1 then
		return false, 0
	else
		return true, cards[1]
	end
end

--  AI决定是否发动悲歌  --
--  返回是否发动、手牌ID  --
function ai_judge_beige(ID, ID_mubiao, ID_laiyuan)
	if #char_juese[ID].shoupai == 0 then
		return false, 0
	end

	if ai_judge_same_identity(ID, ID_mubiao, true) ~= 1 then
		return false, 0
	end

	if ai_judge_same_identity(ID, ID_laiyuan, true) == 1 and ID_mubiao ~= ID then
		return false, 0
	end

	local cards = ai_card_search(ID, "随意", #char_juese[ID].shoupai)
	for i = #cards, 1, -1 do
		if card_judge_if_shan(ID, cards[i]) then
			table.remove(cards, i)
			break
		end
	end
	while #cards > 1 do
		table.remove(cards, math.random(#cards))
	end

	if #cards == 0 then
		return false, 0
	end

	local percent = (25 * #char_juese[ID].shoupai) - 10
	if char_juese[ID_mubiao].tili <= 1 or ID_mubiao == ID then
		percent = 100
	end

	if ai_judge_random_percent(percent) == 1 then
		return true, cards[1]
	else
		return false, 0
	end
end

--  AI决定是否发动双雄  --
function ai_judge_shuangxiong(ID)
	if game_skip_chupai == true or char_juese[ID].tili <= 1 then
		return false
	end

	if #char_juese[ID].shoupai == 0 then
		return false
	end

	local attack_mubiao = ai_basic_judge_mubiao(ID, 4, false, true, true)
	if #attack_mubiao == 0 then
		return false
	end

	local n_sha = 0
	local n_shan = 0
	for i = 1, #char_juese[ID].shoupai do
		if card_judge_if_sha(ID, i) then
			n_sha = n_sha + 1
		elseif card_judge_if_shan(ID, i) and n_shan < 1 then
			n_shan = n_shan + 1
		end
	end

	local percent = 0
	for i = 1, #attack_mubiao do
		if card_if_d_limit("决斗", ID, attack_mubiao[i], nil) and #char_juese[attack_mubiao[i]].shoupai <= 2 + math.max(n_sha - 1, 0) then
			if #char_juese[attack_mubiao[i]].shoupai == 0 then
				percent = 100
			elseif n_sha + n_shan == #char_juese[ID].shoupai then
				percent = 0
			elseif n_sha >= 2 then
				percent = 100
			elseif #char_juese[ID].shoupai == 1 then
				percent = 0
			else
				percent = 80
			end
			break
		end
	end

	if ai_judge_random_percent(percent) == 1 then
		return true
	else
		return false
	end
end

--  AI决定双雄的使用目标  --
--  返回是否发动、手牌ID、目标  --
function ai_judge_shuangxiong_mubiao(ID)
	if char_shuangxiong == nil then
		return false, 0, 0
	end

	local attack_mubiao = ai_basic_judge_mubiao(ID, 4, false, true, true)
	if #attack_mubiao == 0 then
		return false, 0, 0
	end

	local mindef_ID = attack_mubiao[1]
	for i = 2, #attack_mubiao do
		if #char_juese[attack_mubiao[i]].shoupai < #char_juese[mindef_ID].shoupai then
			mindef_ID = attack_mubiao[i]
		end
	end

	local cards = ai_card_search(ID, "随意", #char_juese[ID].shoupai)
	local has_shan = false
	local n_sha = 0

	for i = #cards, 1, -1 do
		local yanse, huase, dianshu = ai_judge_cardinfo(ID, {char_juese[ID].shoupai[cards[i]]})
		if huase == char_shuangxiong then
			if card_judge_if_sha(ID, cards[i]) == true then
				n_sha = n_sha + 1
			end
			table.remove(cards, i)
		elseif card_judge_if_shan(ID, cards[i]) == true and has_shan == false then
			table.remove(cards, i)
			has_shan = true
		elseif card_judge_if_sha(ID, cards[i]) == true and n_sha < #char_juese[mindef_ID].shoupai - 1 then
			table.remove(cards, i)
			n_sha = n_sha + 1
		end
	end
	while #cards > 1 do
		table.remove(cards, math.random(#cards))
	end
	if #cards == 0 then
		return false, 0, 0
	end

	return true, cards[1], mindef_ID
end
