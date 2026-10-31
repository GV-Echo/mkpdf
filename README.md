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

Needs macOS 15 or later and the Xcode 16 command line tools (`xcode-select --install`).
macOS menus below are quoted in Russian, as they appear on a Russian system, with English in
brackets.

1. Get the code and build it. This installs the program to `~/.local/bin/mkpdf`:

   ```bash
   git clone <repository URL> mkpdf
   cd mkpdf
   Scripts/install.sh
   ```

2. Add the Quick Action:

   ```bash
   Scripts/install-shortcut.sh
   ```

   The «Команды» (Shortcuts) app opens a card «В PDF». Click «Добавить» (Add Shortcut).
   If it asks about an existing «В PDF», click «Заменить» (Replace).

3. Allow shortcuts to run scripts: in the «Команды» (Shortcuts) app, open the menu
   «Команды» → «Настройки…» (Settings…) → tab «Дополнительно» (Advanced) → turn on
   «Разрешить запуск скриптов» (Allow Running Scripts). If a button «Открыть Системные
   настройки» (Open System Settings) is shown there, click it and allow it in the window
   that opens.

4. Show the action in Finder: right-click any file → «Быстрые действия» (Quick Actions) →
   «Настроить…» (Customize…) → tick «В PDF».

## First run

Select a `.md`, a `.docx` and a `.pptx` file, right-click → «Быстрые действия» (Quick
Actions) → «В PDF». The first time, macOS and Office ask a few questions, once each:

| Question | Answer |
|---|---|
| «Разрешить быстрой команде «В PDF» использовать … в скрипте оболочки?» (Allow «В PDF» to share … with a shell script?) | «Разрешать всегда» (Always Allow) |
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

Run `Scripts/install.sh` again. A new build is a new program for macOS, so it may ask once
more to control Word and PowerPoint.

## Инструкция на русском

**Что нужно:** macOS 15 или новее, инструменты разработчика Xcode (`xcode-select --install`).
Word и PowerPoint нужны только для docx и pptx.

**1. Установить программу.** В Терминале, в папке проекта:

```bash
Scripts/install.sh
```

**2. Добавить быстрое действие:**

```bash
Scripts/install-shortcut.sh
```

Откроются «Команды» с карточкой «В PDF». Нажмите **«Добавить»**. Если спросит про
существующую «В PDF», нажмите **«Заменить»**.

**3. Разрешить скрипты.** Приложение «Команды» → меню **«Команды» → «Настройки…» → вкладка
«Дополнительно»** → включить **«Разрешить запуск скриптов»**. Если там есть кнопка
**«Открыть Системные настройки»**, нажмите её и разрешите в открывшемся окне.

**4. Включить действие в Finder.** ПКМ на любом файле → **«Быстрые действия» →
«Настроить…»** → поставить галочку **«В PDF»**.

**5. Первый запуск.** Выделите файлы `.md`, `.docx`, `.pptx` → ПКМ → **«Быстрые действия» →
«В PDF»**. Один раз появятся вопросы:

- «Разрешить быстрой команде «В PDF» использовать … в скрипте оболочки?» →
  **«Разрешать всегда»**.
- «“mkpdf” хочет управлять «Microsoft Word»», и то же для PowerPoint → **«Разрешить»**.
- Word: «Предоставить доступ к файлам» для папки
  `…/Library/Application Support/mkpdf/Office` → **«Выбрать…»**. Папка уже выбрана, никуда
  не переходите, сразу **«Предоставить доступ»**.
- То же в PowerPoint.

**6. Дальше** вопросов нет: ПКМ → «Быстрые действия» → «В PDF», и PDF появляется рядом с
файлом под тем же именем.

**Если что-то не так:**

- Ошибка приходит уведомлением с именем файла и причиной; остальные файлы всё равно
  конвертируются. Значения сообщений — в таблице [Errors](#errors).
- Если отказали в управлении Office: **Системные настройки → Конфиденциальность и
  безопасность → Автоматизация → mkpdf** → включить Microsoft Word и PowerPoint.
- Обновление: снова `Scripts/install.sh`. macOS может один раз переспросить про управление
  Word и PowerPoint.

## Development

- `swift build`, `swift test`; one test: `swift test --filter <name>`.
- Office tests start Word and PowerPoint, so they run only on request, with both apps closed:
  `MKPDF_OFFICE_TESTS=1 swift test --filter OfficeConverterTests`.
- Formatting: `swift format lint -r Sources Tests Plugins Package.swift` (`-i` to fix).
- The Markdown renderer is HTML + JS in `Assets/`, compiled into the binary by a build
  plugin. Third-party libraries are in `Assets/vendor` with their licenses; refresh them from
  the versions pinned in `Scripts/vendor/package-lock.json` with `Scripts/update-vendor.sh`
  (needs npm).
- The Quick Action is `Shortcut/to-pdf.plist`, signed and opened by
  `Scripts/install-shortcut.sh`.
