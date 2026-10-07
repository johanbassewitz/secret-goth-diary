# Secret Goth Diary

A gothic diary for Windows 10 and 11. Dark roses, candlelight, and a black cat guard your thoughts.

## Install

1. [Download SecretGothDiary-Setup.exe](https://github.com/johanbassewitz/secret-goth-diary/releases/latest/download/SecretGothDiary-Setup.exe).
2. Double-click it. Setup needs no administrator password, terminal commands, or ZIP extraction.
3. Open **Secret Goth Diary** using the icon on your desktop, and choose your diary password.

Only the app shortcut is added to your desktop. App files live in `%LOCALAPPDATA%\Programs\Secret Goth Diary`. After installation you can delete the downloaded installer.

The diary opens in its own window using Microsoft Edge, which must be installed. It works offline. The installer is unsigned, so Windows or your browser may show a security warning or block it according to your device's settings.

## Your notes

Notes and your password hash stay in your local Edge profile; they are never uploaded to GitHub or a server. Each person gets their own empty diary. The password lock is not encryption. Clearing Edge site data or deleting the browser profile can remove your notes.

Reinstalling uses the same app location. The desktop installer does not migrate notes from other browser profiles or from a different copy of `index.html`.

## Development

Open `index.html` in a browser to run the original diary. No npm dependencies or build step are required for the diary itself.

On Windows, build the installer with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File packaging\Build.ps1
```

The build uses the Windows .NET Framework compiler and produces `dist\SecretGothDiary-Setup.exe` and `dist\SHA256SUMS.txt`. The installer requests ordinary user permissions, installs the bundled offline assets into AppData, and creates the desktop shortcut.

Run the installation checks with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\installer.test.ps1
```

The checks use isolated directories inside this project. They verify installed files, desktop contents, app-mode launch arguments, paths containing spaces, and safe reinstall behavior.
