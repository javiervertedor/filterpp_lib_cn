# API
filter++ lib provides the following API

## `filterpp_lib.blacklist`

Array of blacklisted words. Words in this array mustn't have any whitespace, pipe, hyphens or underscores
See `filterpp_lib.initialize_blacklist`

## `filterpp_lib.filter_text(text, whole_word)`

This function checks the text for any blacklisted words

### Parameters

- `text` - string
- `whole_word` - bool

### Return value

Returns two values:
- violating - bool - true if filter++ lib found any blacklisted words
- blacklisted_words - a list of number pairs that indicate where each blacklisted word begins and ends

```lua
-- assume "oat" and "lunch" are a blacklisted word
local violating, blacklisted_words = filterpp_lib.filter_text("i had oatmeal for lunch")
-- violating = true
-- blacklisted_words = 
-- {
--  {7, 9},   -- oat   starts at position 7  and ends at 9
--  {19, 23}, -- lunch starts at position 19 and ends at 23
-- }
```

`whole_word` flag is true, `filterpp_lib.filter_text` will capture the whole word that the blacklisted phrase is a part of

```lua
-- assume "oat" and "lunch" are a blacklisted word
local violating, blacklisted_words = filterpp_lib.filter_text("i had oatmeal for lunch", true) -- whole_word is set to true
-- violating = true
-- blacklisted_words = 
-- {
--  {7, 13},  -- this time ends at 13 instead of 9, which captures the word "oatmeal"
--  {19, 23}, 
-- }
```

## `filterpp_lib.add_to_blacklist(word, reinitialize, dont_save)`

adds a word to the blacklist, handles illegal characters and saves to mod storage.
Note: that the blacklist needs to be reinitialized to take effect
see [`filterpp_lib.initialize_blacklist`]()

### Parameters

- `word` - string - word to add to the blacklist
- `reinitialize` - bool - if true, blacklist is reinitialized after adding the word [default: `false`]
- `dont_save` - bool - if true then the changes aren't saved to mod storage, useful when you add a lot of words to the blacklist at once [default: `false`]

### Return value
Returns nil

## `filterpp_lib.remove_from_blacklist(word, reinitialize, dont_save)`

Removes a word from the blacklist, handles saving to mod storage
Note: blacklist needs to be reinitialized to take effect
see [`filterpp_lib.initialize_blacklist`]()

### Parameters

- `word` - word to be removed from the blacklist
- `reinitialize` - bool - if true, blacklist is reinitialized after removing the word [default: `false`]
- `dont_save` - bool - if true then the changes aren't saved to mod storage, useful when you add a lot of words to the blacklist at once [default: `false`]

### Return value

Returns a boolean value that indicates whether the word was in the blacklist in the first place.
if so, returns `true`, `false` otherwise

## `filterpp_lib.initialize_blacklist()`

Function that rebuilds the blacklist patterns according to the value of `filterpp_lib.blacklist`.
This function is very expensive, beware of this pattern:

```lua
new_words = {"word1", "word2", "word3"}

-- WRONG
-- unnecessary `filterpp_lib.initialize_blacklist` calls
for _, word in pairs(new_words) do
    filterpp_lib.add_to_blacklist(word)
    filterpp_lib.initialize_blacklist()
end

-- CORRECT
for _, word in pairs(new_words) do
    filterpp_lib.add_to_blacklist(word)
end
filterpp_lib.initialize_blacklist()
```

when adding a single word, you can use this shorthand
```lua
-- second argument is true, which reinitialize the blacklist automatically
filterpp_lib.add_to_blacklist("word", true)
```

### Return value
Returns `nil`

## `filterpp_lib.save_blacklist()`

saves the blacklist to mod storage, only ever useful if you use `filterpp_lib.remove_from_blacklist` or `filterpp_lib.add_to_blacklist`
with the `dont_save` flag

## Return value
`nil`

## `filterpp_lib.register_on_violation(func)`
registers a function to be called whenever a player violates and tries to send a blacklisted word

### Parameters

- `func` - function that takes the following arguments: \
         - `name` - name of player who violated \
         - `text` - offending text \
         - `violations` - list of number pairs that contain the end and starting position of naughty words. \
         see return value of `filterpp_lib.filter_text` \

### Return value
`nil`

## `filter_text.report_violation(name, text, violations)`
calls appropriate callback functions

### Parameters
all parameters correspond to each callback argument

- `name` - name of player who violated
- `text` - offending text
- `violations` - list of number pairs that contain the end and starting position of naughty words,
see return value of `filterpp_lib.filter_text`

### Return value
`nil`

## `filter_text.register_similar_characters(base_char, chars)`

Registers characters that should be considered "similar", which means they have the same meaning as the `base_char`.
all characters can be considered similar to only one `base_char` at most, 
trying to set another similarity overrides the previous one

see the "inner working" section for details

Generally you shouldn't touch this unless you know what you're doing

### Tetrameters

`base_char` - string - the base character
`chars` - string or list - characters that should be considered similar

### Return value
`nil`

# Inner working

everything in filter++ lib revolves around how the data is stored. 
The blacklisted words are stored in `filterpp_lib.blacklist`, to be useful though, it needs to be converted into a usable data structure.
this data structure is a table that looks like this:

- key - character
- value - another table with the same format

example
```lua
filterpp_lib.blacklist = {"frick", "fricking", "friday"}
filterpp_lib.initialize_blacklist()

-- blacklist patterns have been initialized and look like this:
--{
--	["f"] =
--	{
--		["r"] = 
--		{
--			["i"] =
--			{
--				["c"] = 
--				{
--					["k"] = {true}
--				},
--				["d"] = 
--				{
--					[a] =
--					{
--						["y"] = {true}
--					}
--				}
--       	}
--		}
--  }
--}

```

Notice that some tables have a true value. These indicate that the blacklisted word is complete

Overall this creates a chain of characters that allows access in constant time and can be iterated over with this pseudo code:
- if at the end of a string, stop
- Get character
- Check if character belongs in "head", head at the start equals to the blacklist patterns table
think of it like the head in a turing machine
- If it dosent belong in the head:
- Set the head to the blacklist patterns table and repeat, starting the searching from the beginning
- Otherwise:
- Set the head to the table associated with that character
- Check if the new head terminates the blacklisted word (aka has a `true` at the first index). If so, remember where that word began and ends
- Repeat with the new head

this is roughly what filter++ lib does, here are some additional things filter++ lib does
- every time a character is extracted from the string, it first is decoded into a *base character* if applicable

```lua
filter_text.add_to_blacklist("lol", true)

-- characters passed are: l, o, l
-- correctly finds the blacklisted word
filterpp_lib.filter_text("lol")

-- characters passed are: !, o, |
-- dosent find the blacklisted word
filterpp_lib.filter_text("!o|")

-- signaling that ! and | are "similar" to l
filterpp_lib.register_similar_characters("l", {"!", "|"})

-- same as before, characters are: l, o, l
-- correctly finds the blacklisted word
filterpp_lib.filter_text("lol")

-- each character in this string is converted into its "base" counterpart before checking if its a part of a blacklisted word
-- this time characters passed are: l, o, l
-- correctly finds the blacklisted word
filterpp_lib.filter_text("!o|")

filterpp_lib.register_similar_characters("/", {"!", "|"})

-- each character in this string is converted into its "base" counterpart before checking if its a part of a blacklisted word
-- this time characters passed are: /, o, /
-- dosent find the blacklisted word anymore
-- this is because a character can only have one base character, and it was overridden
filterpp_lib.filter_text("!o|")
```

- filter++ lib skips past some characters

```lua
filter_text.add_to_blacklist("lol", true)

-- characters passed are: l, o, l
-- correctly finds the blacklisted word
filterpp_lib.filter_text("lol")

-- the whitespaces are completely skipped over
-- characters passed are: l, o, l
-- correctly finds the blacklisted word
filterpp_lib.filter_text("l    o    l")

-- Ignored characters are stored in `ignored_characters`
-- words in `filterpp_lib.blacklist` mustn't contain any of those characters,
-- otherwise the word wont ever get matched

```

- when iterating over the string, the last processed character of a blacklisted word
is remembered. if the next character dosent match the head, it checks whether the character equals the last character.
In such a case it determines that the letter repeats and iterates again with the same head.
here are the steps it would take to match "friick" with blacklist being just "frick"

- starting head {["f"] = <another head>} \
  char: f, last_char = nil \
  char correctly matches with head \

- new head {["r"] = <another head>} \
  char: r, last_char = f \
  char correctly matches with head \

- new head {["i"] = <another head>} \
 char: i, last_char = r \
 char correctly matches with head \

- new head {["c"] = <another head>} \
 char: i, last_char = i \
 mismatch between the head and the character \
 checking whether last_char is the same as the current char: \
 it is, therefore continuing with the same head instead of resetting \

- head is preserved and still equals {["c"] = <another head>} \
  char: c, last_char = i \
  char correctly matches with head \
 
- head is preserved and still equals {["k"] = {true}} \
  char: k, last_char = c \
  char correctly matches with head, the true value indicates the end
  of a blacklisted word\ 

- filter++ dosent use `string.sub()`, instead it has its own `iterate_characters` function which iterates over the bytes
and recognizes UTF-8 characters
