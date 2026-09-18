# Публикация Dialogue Enter Confirm

Репозиторий: <https://github.com/NnicanBuak/bg3-dialogue-enter-confirm>.

## Проверка перед стабильной публикацией

1. Запустите `npm run validate` и `npm run build`.
2. Пройдите [игровой чеклист](docs/TEST_CHECKLIST.md) в BG3 Patch 8 с BG3SE v32+.
3. Зафиксируйте версию игры, BG3SE, список модов и результат ручной проверки.

## GitHub Release

После автоматических проверок создайте тег:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions соберёт `.pak`, установочный архив, исходники и SHA-256 и создаст **черновик prerelease**. Опубликуйте его как стабильный только после прохождения игрового чеклиста; в описании укажите фактические версии игры и BG3SE.

## Nexus Mods

Создайте страницу для Baldur's Gate 3 через `Upload a mod`, используйте текст из [docs/NEXUS_DESCRIPTION.md](docs/NEXUS_DESCRIPTION.md), добавьте `DialogueEnterConfirm_v1.0.0_Install.zip` из GitHub Release и укажите BG3SE v32+ как требование. После загрузки проверьте, что файл доступен без авторизации и его SHA-256 совпадает с `SHA256SUMS.txt`.

Nexus Mods требует отдельную авторизацию автора; токены и пароль в репозитории не хранятся.
