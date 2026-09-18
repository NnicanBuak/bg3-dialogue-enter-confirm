# Dialogue Enter Confirm для Baldur's Gate 3

Маленький клиентский мод для **Baldur's Gate 3**: выделите вариант ответа стрелками ↑↓ и нажмите **Enter**, чтобы подтвердить его. Мод вызывает штатную команду диалога игры, поэтому выбор мышью и цифровыми клавишами сохраняется.

## Что меняется

В оригинальной PC-версии ответ можно выбрать мышью или клавишей с соответствующим номером. Стрелки перемещают выделение, но отдельная клавиша подтверждения для клавиатуры не назначена. Мод добавляет только это подтверждение.

Поддерживается:

- Enter и Enter на цифровом блоке;
- штатная навигация ↑↓;
- одиночная игра на Windows.

Мультиплеер, Steam Deck, контроллер и другие платформы не входят в проверенный первый релиз.

## Требования

- Baldur's Gate 3 Patch 8;
- Baldur's Gate 3 Script Extender **v32 или новее**.

Script Extender устанавливается отдельно. Мод не содержит DLL и не устанавливает его автоматически.

## Установка

После публикации релиза скачайте `DialogueEnterConfirm_v1.0.0_Install.zip` со страницы [GitHub Releases](https://github.com/NnicanBuak/bg3-dialogue-enter-confirm/releases), распакуйте `.pak` в папку модов BG3 и активируйте мод в BG3 Mod Manager или Vortex. Подробные пути, обновление и удаление описаны в [docs/INSTALL.md](docs/INSTALL.md).

Для Nexus Mods подготовлен тот же установочный архив; страницу можно создать после авторизации автора. Встроенный каталог BG3 не поддерживается.

## Использование

1. Откройте диалог.
2. Нажмите ↑ или ↓, чтобы подсветить ответ.
3. Нажмите Enter.

Цифровые клавиши продолжают работать как в оригинальной игре. Enter не срабатывает при удержании, вне доступного выбора, в чате или поверх другого видимого окна.

## Сборка

На Windows:

```powershell
pwsh -NoProfile -File .\build.ps1
```

Скрипт скачивает и проверяет закреплённый **LSLib 1.20.4**, создаёт настоящий `.pak`, установочный ZIP, архив исходников и `SHA256SUMS.txt`. Для проверки только структуры и JSON/XML:

```powershell
npm run validate
```

Для CI используются те же проверки и `luac -p`.

## Проверка релиза

Автоматически проверяются структура архива, синтаксис Lua и целостность метаданных. Игровая проверка требует запуска BG3 с установленным Script Extender; до неё релиз помечается как **не проверенный в игре**. Результаты ручной проверки должны включать первую и последующие реплики, оба варианта Enter, мышь, цифровые клавиши, чат и загрузку сохранения.

## English

**Dialogue Enter Confirm** adds one keyboard action to Baldur's Gate 3: use ↑/↓ to highlight a dialogue answer and press **Enter** to confirm it. The mod calls the game's native `SelectorEnterCommand`, so mouse and number-key selection continue to work.

Requirements: Windows PC, BG3 Patch 8, and BG3 Script Extender v32+. The first release targets single-player keyboard use. Multiplayer, Steam Deck, controller support, and in-game verification are not claimed until tested.

## License

MIT. Author: [NnicanBuak](https://github.com/NnicanBuak).
