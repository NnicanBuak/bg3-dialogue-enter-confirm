# Инструкция по публикации на GitHub

## 🚀 Первая публикация

### 1. Создание репозитория на GitHub
1. Перейдите на https://github.com/new
2. Название: `bg3-dialogue-enter-confirm`
3. Описание: `BG3 mod that allows confirming dialogue choices with Enter key`
4. Сделайте репозиторий публичным
5. **НЕ** добавляйте README, .gitignore, или лицензию (они уже есть)

### 2. Инициализация локального репозитория
```bash
cd bg3-dialogue-enter-confirm
git init
git add .
git commit -m "feat: начальная версия мода Dialogue Enter Confirm

- Базовая структура Script Extender мода
- Функционал подтверждения диалогов Enter
- Поддержка контроллера и клавиатуры
- Полная документация и CI/CD"
```

### 3. Связывание с удаленным репозиторием
```bash
git branch -M main
git remote add origin https://github.com/ВАШ-USERNAME/bg3-dialogue-enter-confirm.git
git push -u origin main
```

### 4. Создание первого релиза
```bash
# Создание тега для версии 1.0.0
git tag v1.0.0
git push origin v1.0.0
```

## 🔄 Workflow для разработки

### Ветки
- `main` - стабильная версия
- `develop` - разработка
- `feature/*` - новые функции
- `hotfix/*` - критические исправления

### Создание новой функции
```bash
git checkout -b feature/новая-функция
# Внесение изменений
git commit -m "feat: описание новой функции"
git push origin feature/новая-функция
# Создание Pull Request на GitHub
```

### Создание релиза
```bash
# Обновите CHANGELOG.md
# Обновите версию в package.json
git commit -m "chore: подготовка к релизу v1.1.0"
git tag v1.1.0
git push origin v1.1.0
```

## 🤖 Автоматические процессы

### CI (Continuous Integration)
- Запускается при каждом push и PR
- Проверяет синтаксис Lua, XML, JSON
- Валидирует структуру мода
- Тестирует процесс сборки

### CD (Continuous Deployment)
- Запускается при создании тега `v*`
- Автоматически создает GitHub Release
- Генерирует архив исходников
- Публикует release notes

## 📦 Релизы

### Автоматический релиз
1. Создайте тег: `git tag v1.0.0`
2. Отправьте тег: `git push origin v1.0.0`
3. GitHub Actions автоматически создаст релиз

### Ручной релиз
1. Перейдите в Actions на GitHub
2. Выберите "Build and Release"
3. Нажмите "Run workflow"
4. Введите версию релиза

## 🔧 Настройка репозитория

### Настройки Branch Protection
В настройках репозитория → Branches:
- Защитите ветку `main`
- Требуйте прохождения CI
- Требуйте обновления веток перед merge

### Issues Templates
GitHub автоматически предложит создать templates для:
- Bug reports
- Feature requests

### Project Management
Можно использовать GitHub Projects для:
- Отслеживания задач
- Планирования релизов
- Управления backlog

## 📊 Метрики и мониторинг

### GitHub Insights
- Частота коммитов
- Активность участников
- Популярность (stars, forks)

### Releases
- Количество скачиваний
- Популярные версии
- Отзывы пользователей

## 🤝 Участие сообщества

### Настройка для контрибьюторов
1. Добавьте CONTRIBUTING.md (уже создан)
2. Создайте issue templates
3. Настройте labels для issues
4. Добавьте Code of Conduct

### Популяризация
1. Добавьте topics: `baldurs-gate-3`, `bg3`, `mod`, `script-extender`
2. Создайте красивые скриншоты для README
3. Опубликуйте на r/BaldursGate3Mods
4. Создайте Discord для поддержки

---

## ✅ Чеклист первой публикации

- [ ] Создать репозиторий на GitHub
- [ ] Инициализировать git в папке проекта
- [ ] Сделать первый коммит
- [ ] Связать с удаленным репозиторием
- [ ] Отправить код на GitHub
- [ ] Создать первый тег и релиз
- [ ] Проверить работу CI/CD
- [ ] Добавить topics к репозиторию
- [ ] Настроить branch protection
- [ ] Обновить README с правильными ссылками

**Готово к публикации! 🎉**