# filterpp_lib_cn

**Simplified Chinese Language Support for `filterpp_lib` (Luanti Mod)**  
This is a modified version of the original [`filterpp_lib`](https://content.luanti.org/packages/rstcxk/filterpp_lib/) by [rstcxk](https://content.luanti.org/users/rstcxk/), with added Simplified Chinese language filter support for use on Luanti servers.

---

## 🔧 What Is This?

This mod extends the original `filterpp_lib` by:
- Adding built-in support for Simplified Chinese content filtering.
- Preserving full functionality of the original code.

This is a full drop-in replacement: **just overwrite the original `filterpp_lib` folder with this one**.

---

## 📦 Installation

1. Locate the original `filterpp_lib` folder in your `mods` directory.
2. Replace all contents of that folder with the files from this repository:
   ```bash
   git clone https://github.com/javiervertedor/filterpp_lib_cn.git
   cp -r filterpp_lib_cn/* /path/to/luanti/mods/filterpp_lib/
   ```
   > 📁 Ensure the folder name remains `filterpp_lib` — not `filterpp_lib_cn`.

3. Start your Luanti server. The Chinese filters will be active automatically.

---

## 🈺 Chinese Filter Support

This version includes a comprehensive list of Simplified Chinese swear and harmful phrases, which are **automatically added to the blacklist** when the server is started and no custom list has been defined yet.

The list is defined in:

```
swear_words.cn.lua
```

This file uses `filterpp_lib.add_to_blacklist()` to register swear words, threats and bullying expressions in Chinese and their pinyin variants.

If you want to customize or expand the blacklist:
- Use the in-game command:  
  ```bash
  /manage_filters add <word>
  ```
- Or directly modify the list in the Luanti admin interface.
- You can reset the blacklist and reload the default Chinese + English terms with:  
  ```bash
  /manage_filters return_to_default
  ```

---

## ✅ Compatibility

- Works with Luanti 5.11.0+
- No additional configuration required
- Fully backward compatible with `filterpp_lib` features

---

## 🙏 Credit

**ALL credit goes to [rstcxk](https://content.luanti.org/users/rstcxk/)** for the original mod:  
🔗 [`filterpp_lib` on Luanti ContentDB](https://content.luanti.org/packages/rstcxk/filterpp_lib/)

This version was extended with Chinese support by [javiervertedor](https://github.com/javiervertedor).

---

## 📜 License

This mod follows the same license as the original.  
**Commercial use is prohibited.** Attribution to both authors is required in any distribution or derivative.
