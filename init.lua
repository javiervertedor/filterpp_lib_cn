-- local inspect = require("inspect")
local storage = minetest.get_mod_storage()

filterpp_lib = {}

-- simple list of banned words
filterpp_lib.blacklist = minetest.deserialize(storage:get_string("blacklist")) or {}

-- list of callback functions
-- @see register_on_violation
filterpp_lib.registered_on_violation = {}

-- a table with format
-- key - string character
-- value - string character - base character that the key character is similar to
local similar_characters = {}

-- characters that are totally ignored during filtering
local ignored_characters =
{
	["\t"] = true,
	["\n"] = true,
	[" "] = true,
	["-"] = true,
	["_"] = true,
}

-- a table of recursive tables that have a format:
-- key - character
-- value - another table like this one
--
-- this basically creates a chain of characters that make up the swear word
-- to flag a node as "completed" swear word, the table has its first index set to true
local blacklist_patterns = {}

local function get_word_boundries(text, t)
	-- t is a pair of two numbers, offending word start position and its end
	local new_start = t[1]
	local new_end = t[2]

	while new_start >= 1 do
		if text:sub(new_start, new_start) == " " then
			break
		end

		new_start = new_start - 1
	end

	t[1] = new_start + 1

	while new_end <= #text do
		if text:sub(new_end, new_end) == " " then
			break
		end

		new_end = new_end + 1
	end

	t[2] = new_end - 1
end


--- iterate over individual characters in UTF-8
--	this function is very important in performance
--	the return value is: what byte the characer begins, what byte it ends at, and the chracter
local function iterate_characters(str)
	local byte_idx = 1
	return function()
		local code_point = str:byte(byte_idx, byte_idx)

		if not code_point then
			return nil
		elseif code_point >= 128 then
			local old_pos = byte_idx

			repeat
				byte_idx = byte_idx + 1
				code_point = str:byte(byte_idx, byte_idx)
			until not code_point or code_point < 128 or code_point > 191

			return old_pos, byte_idx - 1, str:sub(old_pos, byte_idx - 1)
		else
			byte_idx = byte_idx + 1

			return byte_idx - 1, byte_idx - 1, string.char(code_point)
		end
	end
end


--- initializes the blacklist_patterns table according to the current blacklist
function filterpp_lib.initialize_blacklist()
	blacklist_patterns = {}
	local char
	local head
	for idx, word in pairs(filterpp_lib.blacklist) do
		head = blacklist_patterns
		for _, _, char in iterate_characters(word) do
			char = similar_characters[char] or char
		
			head[char] = head[char] or {}
		
			head = head[char]
		end

		head[1] = true
	end
end

-- registers characters that should be considered similar
-- note: if any of the characters are already similar to another character, it will error
-- its best if you dont touch this
-- @string base_char a character that the other characters are similar to
-- @ptparam tab|string list of characters or a string
function filterpp_lib.register_similar_characters(base_char, chars)
	local chars_table = {}
	if type(chars) == "string" then
		for _, _, char in iterate_characters(chars) do
			table.insert(chars_table, char)
		end
	else
		chars_table = chars
	end

	for _, char in pairs(chars_table) do
		similar_characters[char] = base_char
	end
end

--- filters text
--	@string text
--	@bool whole_word if the offending word is a part of another word, return that whole word
--	@treturns bool true if any word causes a violation
--	@treturns tab list of number pairs that mean the star and end position of a violating word
function filterpp_lib.filter_text(text, whole_word)
	local bad_word_start = 1
	local bad_word_end = 1
	local bad_words = {}

	local blacklist_head = blacklist_patterns[text:sub(1, 1)] or {}
	local previous_char = ""

	for char_idx, char_idx_end, char in iterate_characters(text) do
		char = similar_characters[char] or char
		-- skipping past ignored characters
		if not ignored_characters[char] then

			if blacklist_head[char] and blacklist_head[char][1] == true then
				-- if the end of a bad word
				bad_word_end = char_idx_end
			end

			if not blacklist_head[char] then
				-- if isnt a part of a bad word
				if previous_char ~= char then
					-- if isnt a repeat of last word, terminate the illegal word

					-- if the there is a unterminated blacklisted word
					if bad_word_start ~= bad_word_end then
						table.insert(bad_words, {bad_word_start, bad_word_end})
					end

					bad_word_start = char_idx
					bad_word_end = char_idx_end
					blacklist_head = blacklist_patterns[char] or {}
				end
			else
				-- if is a part of bad word
				previous_char = char
				blacklist_head = blacklist_head[char]
			end
		end
	end

	-- if there is a last unterminated blacklisted word, terminate it
	if bad_word_start ~= bad_word_end then
		table.insert(bad_words, {bad_word_start, bad_word_end})
	end

	if whole_word then
		for i, v in pairs(bad_words) do
			get_word_boundries(text, v)
		end
	end

	return #bad_words ~= 0, bad_words
end

--- saves the blacklist to mod storage
--	only use it if you used add_to_blacklist() or remove_from_blacklist() with the dont_save flag
function filterpp_lib.save_blacklist()
	storage:set_string("blacklist", minetest.serialize(filterpp_lib.blacklist))
end

--- adds a word to the blacklist, note that the blacklist needs to be reinitialized to take effect
--	@string word
--	@bool reinitialize if true, reinitializes the blacklist afterwards
--	@bool dont_save if true then the mod storage isnt updated, useful when adding a lot of words to the blacklist at once 
--	@see filterpp_lib.initialize_blacklist()
function filterpp_lib.add_to_blacklist(word, reinitialize, dont_save)
	local chars = {}
	-- ensuring that no ignored characters are in the word
	for i = 1, #word do
		if not ignored_characters[word:sub(i, i)] then
			table.insert(chars, similar_characters[word:sub(i, i)] or word:sub(i, i))
		end
	end

	table.insert(filterpp_lib.blacklist, table.concat(chars))

	if not dont_save then
		storage:set_string("blacklist", minetest.serialize(filterpp_lib.blacklist))
	end

	if reinitialize then
		filterpp_lib.initialize_blacklist()
	end
end

--- removes a word from the blacklist, needs the blacklist to be reinitialized to take effect
--	@string word
--	@bool reinitialize if true, reinitializes the blacklist afterwards
--	@bool dont_save if true then the mod storage isnt updated, useful when adding a lot of words to the blacklist at once 
--	@treturn bool true if succeeded, aka the word was in the blacklist
--	@see filterpp_lib.initialize_blacklist()
function filterpp_lib.remove_from_blacklist(word, reinitialize, dont_save)
	local idx
	for i, v in pairs(filterpp_lib.blacklist) do
		if v == word then
			idx = i
		end
	end

	if not idx then
		return false
	end

	table.remove(filterpp_lib.blacklist, idx)

	if not dont_save then
		storage:set_string("blacklist", minetest.serialize(filterpp_lib.blacklist))
	end

	if reinitialize then
		filterpp_lib.initialize_blacklist()
	end

	return true
end

-- registers a callback to be called whenever someone tries to say a blacklisted word
-- @func func function that takes the following arguments:
--		name - name of player who violated
--		message - message that violated
function filterpp_lib.register_on_violation(func)
	table.insert(filterpp_lib.registered_on_violation, func)
end

-- report a violation
-- @string name name of player who violated
-- @string text text that violated the filter
-- @tab violations list of number pairs that idicate end and begining of violations, see filter_text()
function filterpp_lib.report_violation(name, text, violations)
	for _, func in pairs(filterpp_lib.registered_on_violation) do
		func(name, text, violations)
	end
end

minetest.register_privilege("filter++",
{
	description = "can add/remove words from the blacklist",
	give_to_admin = true
})

minetest.register_chatcommand("manage_filters",
{
	privs = "filter++",
	description = "add/remove words from the blacklist",
	params = "add <word> | remove <word> | list | return_to_default",
	func = function(name, param)
		args = string.split(param, " ")

		action = args[1] and args[1]:trim()
		word = args[2] and args[2]:trim()

		if action == "add" then
			if not word then
				return false
			end

			filterpp_lib.add_to_blacklist(word, true)
		elseif action == "remove" then
			if not word then
				return false
			end

			if not filterpp_lib.remove_from_blacklist(word) then
				-- the word was never blacklisted
				return false, word .. " was never blacklisted"
			end

			filterpp_lib.initialize_blacklist()
		elseif action == "list" then
			return false, table.concat(filterpp_lib.blacklist, ", ")
		elseif action == "return_to_default" then
			filterpp_lib.blacklist = {}
			dofile(minetest.get_modpath("filterpp_lib") .. "/swear_words.en.lua")

			filterpp_lib.initialize_blacklist()
		else
			return false, "unknown action"
		end
	end
})

dofile(minetest.get_modpath("filterpp_lib") .. "/similar_characters.lua")

if #filterpp_lib.blacklist == 0 then
	dofile(minetest.get_modpath("filterpp_lib") .. "/swear_words.en.lua")
	dofile(minetest.get_modpath("filterpp_lib").."/swear_words.cn.lua")
end

filterpp_lib.initialize_blacklist()
