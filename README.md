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

This version includes curated filtering rules for Simplified Chinese, found in:

```
filters/zh_cn.lua
```

You can customize or expand the list by editing this file or adding new ones.

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
