# mkpdf

Right-click files in Finder → Quick Actions → «В PDF». A PDF appears next to each file, with
the same name. Several files can be selected at once.

Инструкция на русском: [ниже](#инструкция-на-русском).

| Format | How |
|---|---|
| `.md` | Built in, offline: tables, task lists, footnotes, code highlighting, Obsidian and GitHub callouts, `[[wiki links]]`, local images and `![[image]]`, KaTeX math, Mermaid diagrams; frontmatter is hidden. A4 pages. |
| `.docx` | Microsoft Word saves it as PDF: the layout is Word's own. |
| `.pptx` | Microsoft PowerPoint saves it as PDF, one slide per page. |

Word and PowerPoint are needed only for their formats. If an app was not running, mkpdf
starts it in the background and quits it afterwards; documents you have open stay open.

## Install

Needs macOS 15 or later. macOS menus below are quoted in Russian, as they appear on a Russian
system, with English in brackets.

1. In Terminal, run:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/GV-Echo/mkpdf/main/install.sh | zsh
   ```

   This puts the program in `~/.local/bin/mkpdf` and opens the «Быстрые команды»
   (Shortcuts) app with a card «В PDF». Click «Добавить» (Add Shortcut). If it asks about an
   existing one, click «Заменить» (Replace).

   For an English name, add `-s -- --english` at the end: the action is then called
   «To PDF» instead of «В PDF» everywhere below.

2. Allow shortcuts to run scripts: in the «Быстрые команды» (Shortcuts) app, open the menu
   «Быстрые команды» (top left) → «Настройки…» (Settings…) → tab «Дополнительно» (Advanced)
   → turn on «Запуск скриптов» (Allow Running Scripts).

3. Show the action in Finder: right-click any file → «Быстрые действия» (Quick Actions) →
   «Настроить…» (Customize…) → tick «В PDF».

## First run

Select a `.md`, a `.docx` and a `.pptx` file, right-click → «Быстрые действия» (Quick
Actions) → «В PDF». The first time, macOS and Office ask a few questions, once each:

| Question | Answer |
|---|---|
| «Разрешить быстрой команде «В PDF» использовать … в скрипте оболочки?» (Allow «В PDF» to share … with a shell script?) | «Разрешать всегда» (Always Allow) |
| «Приложение «mkpdf» запрашивает доступ к файлам на Вашем Рабочем столе» (wants to access files on your Desktop); the same for «Документы» (Documents), «Загрузки» (Downloads) when files are there | «Разрешить» (Allow) |
| «“mkpdf” хочет управлять «Microsoft Word»» (wants to control Microsoft Word), and the same for PowerPoint | «Разрешить» (Allow) |
| Word: «Предоставить доступ к файлам» (Grant File Access) for the folder `…/Library/Application Support/mkpdf/Office` | «Выбрать…» (Select…). The folder is already chosen: do not go anywhere else, just click «Предоставить доступ» (Grant Access) |
| The same in PowerPoint | The same |

After that, conversions run without questions.

Why the Office folder: Word and PowerPoint are sandboxed and ask for access to every new
folder they write to, but remember a folder once granted. So they always save into that one
folder, and mkpdf moves the PDF next to your file.

## Errors

A failed file shows a notification with its name and the reason; the other selected files
are still converted.

| Message | Meaning |
|---|---|
| `".txt" files are not supported` | Only `.md`, `.docx`, `.pptx`. |
| `another selected file also becomes "X.pdf"` | Two selected files share a name (e.g. `X.md` and `X.docx`); the first one is converted. |
| `cannot write to the folder "…"` | The folder is read-only. |
| `the file is not UTF-8 text` | A Markdown file in another encoding (e.g. Windows-1251): save it as UTF-8. |
| `not allowed to control Microsoft Word: …` | The control permission was denied: «Системные настройки» (System Settings) → «Конфиденциальность и безопасность» (Privacy & Security) → «Автоматизация» (Automation) → mkpdf → turn on Microsoft Word / PowerPoint. |
| `Microsoft Word was not given access to mkpdf's exchange folder; run again and grant it` | The Office question was cancelled: run again and grant it. |
| `… did not respond in time; it may be waiting in a dialog` | Office shows a dialog, for example a password for a protected file. |

## Update

Run the install command again and click «Заменить» (Replace) on the card. A new build is a
new program for macOS, so it may ask once more for the questions above.

## Uninstall

1. In Terminal:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/GV-Echo/mkpdf/main/install.sh | zsh -s -- --uninstall
   ```

   This removes the program and the Office exchange folder.

2. Delete the shortcut: in the «Быстрые команды» (Shortcuts) app, right-click «В PDF» →
   «Удалить» (Delete).

The Automation switches for mkpdf stay in «Системные настройки» (System Settings) →
«Конфиденциальность и безопасность» (Privacy & Security) → «Автоматизация» (Automation);
macOS keeps them and they do nothing without the program.

## Инструкция на русском

**Что нужно:** macOS 15 или новее. Word и PowerPoint нужны только для docx и pptx.

**1. Установить.** В Терминале:

```bash
curl -fsSL https://raw.githubusercontent.com/GV-Echo/mkpdf/main/install.sh | zsh
```

Откроются «Быстрые команды» с карточкой «В PDF». Нажмите **«Добавить»**. Если спросит про
существующую, нажмите **«Заменить»**.

Английское название: добавьте в конец команды `-s -- --english`. Тогда действие называется
«To PDF», и во всех шагах ниже вместо «В PDF» будет «To PDF».

**2. Разрешить скрипты.** Приложение «Быстрые команды» → меню **«Быстрые команды»** слева
сверху → **«Настройки…» → вкладка «Дополнительно»** → включить **«Запуск скриптов»**.

**3. Включить действие в Finder.** ПКМ на любом файле → **«Быстрые действия» →
«Настроить…»** → поставить галочку **«В PDF»**.

**4. Первый запуск.** Выделите файлы `.md`, `.docx`, `.pptx` → ПКМ → **«Быстрые действия» →
«В PDF»**. Один раз появятся вопросы:

- «Разрешить быстрой команде «В PDF» использовать … в скрипте оболочки?» →
  **«Разрешать всегда»**.
- «Приложение «mkpdf» запрашивает доступ к файлам на Вашем Рабочем столе», и то же для
  «Документов» и «Загрузок», если файлы там → **«Разрешить»**.
- «“mkpdf” хочет управлять «Microsoft Word»», и то же для PowerPoint → **«Разрешить»**.
- Word: «Предоставить доступ к файлам» для папки
  `…/Library/Application Support/mkpdf/Office` → **«Выбрать…»**. Папка уже выбрана, никуда
  не переходите, сразу **«Предоставить доступ»**.
- То же в PowerPoint.

**5. Дальше** вопросов нет: ПКМ → «Быстрые действия» → «В PDF», и PDF появляется рядом с
файлом под тем же именем.

**Если что-то не так:**

- Ошибка приходит уведомлением с именем файла и причиной; остальные файлы всё равно
  конвертируются. Значения сообщений — в таблице [Errors](#errors).
- Если отказали в управлении Office: **Системные настройки → Конфиденциальность и
  безопасность → Автоматизация → mkpdf** → включить Microsoft Word и PowerPoint.
- Обновление: снова команда установки, на карточке **«Заменить»**. macOS может один раз
  переспросить разрешения из шага 4.

**Удаление:**

1. В Терминале:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/GV-Echo/mkpdf/main/install.sh | zsh -s -- --uninstall
   ```

   Удаляет программу и папку обмена Office.
2. В «Быстрых командах» ПКМ на «В PDF» → **«Удалить»**.

Переключатели mkpdf в «Автоматизации» macOS оставляет; без программы они ничего не делают.

## Development

- `swift build`, `swift test`; one test: `swift test --filter <name>`.
- Office tests start Word and PowerPoint, so they run only on request, with both apps closed:
  `MKPDF_OFFICE_TESTS=1 swift test --filter OfficeConverterTests`.
- Formatting: `swift format lint -r Sources Tests Plugins Package.swift` (`-i` to fix).
- The Markdown renderer is HTML + JS in `Assets/`, compiled into the binary by a build
  plugin. Third-party libraries are in `Assets/vendor` with their licenses; refresh them from
  the versions pinned in `Scripts/vendor/package-lock.json` with `Scripts/update-vendor.sh`
  (needs npm).
- Install from source (needs the Xcode 16 command line tools): `Scripts/install.sh` builds and
  installs the program, `Scripts/install-shortcut.sh [--english]` signs
  `Shortcut/to-pdf.plist` and opens it for import.
- Release: `Scripts/release.sh` puts a universal ad-hoc signed `mkpdf` and the signed
  `to-pdf.shortcut` into `dist/`; upload both to a GitHub release. `install.sh` downloads them
  from the latest release with curl, which does not quarantine them, so Gatekeeper lets the
  program run.
