# GPLv3 Licensing Setup Guide

This guide outlines the step-by-step process to officially license the **PiShock Serial Controller** project under the **GNU General Public License v3.0 (GPLv3)**. Applying this license ensures the codebase remains open-source, guarantees attribution to you (**Nagisa**), and protects it from being integrated into proprietary, closed-source software.

---

## 📅 1. Create the `LICENSE` File

In the root directory of your project, create a file named exactly `LICENSE` (with no file extension). Copy and paste the official, unaltered text of the GNU GPLv3 into it.

* You can fetch the full text directly from the Free Software Foundation: [https://www.gnu.org/licenses/gpl-3.0.txt](https://www.gnu.org/licenses/gpl-3.0.txt)

---

## 📝 2. Add the License Header to Delphi Units (`.pas`)

Every source file should contain a brief copyright notice and a pointer to the full license text. Insert this block at the very top of each of your Pascal units (e.g., `piserial.pas`, `uPiShockDevice.pas`, `uHdsTrigger.pas`, etc.), right above the `unit` declaration:

```pascal
{
  PiShock Serial Controller
  Copyright (C) 2026 NagisaCybercat

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
}
unit uPiShockDevice; // (Or your respective unit name)

interface
...
```

### Files to update in your project:
* `piserial.pas`
* `uPiShockDevice.pas`
* `uWebSocketServer.pas`
* `uHdsTrigger.pas`
* `uHdsForm.pas`
* `uAddHdsTrigger.pas`
* `uAddMapping.pas`
* `uSettingsForm.pas`
* `uLogForm.pas`
* `uLanguage.pas`

---

## 📖 3. Update your `README.md`

Append a dedicated licensing section to the bottom of your project's English `README.md` to inform visitors and contributors immediately about their rights and restrictions.

```markdown
## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

Copyright (C) 2026 NagisaCybercat
```

---

## 🛡️ 4. What this means for your Code (Quick Summary)

By using the GPLv3, you establish the following legal boundaries:

1. **Attribution:** Anyone modifying or redistributing this code *must* retain your copyright notice (`Copyright (C) 2026 Nagisa`). They cannot claim authorship of the core application.
2. **Copyleft Protection:** If a developer forks your repository or utilizes your Delphi units to create a new program, and they decide to distribute that program, **they are legally required to make their entire source code public under the same GPLv3 license**.
3. **No Closed-Source Commercialization:** Nobody can grab your hardware communications stack, lock it behind a paywall, hide the source code, and sell it as proprietary software.

---
*Guide generated for Nagisa — May 2026*
