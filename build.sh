#!/bin/bash

# Скрипт сборки мода Dialogue Enter Confirm для BG3
# Создает релизные файлы для публикации

set -e

MOD_NAME="DialogueEnterConfirm"
VERSION=${1:-"1.0.0"}
BUILD_DIR="build"
RELEASE_DIR="releases"

echo "🔨 Сборка мода ${MOD_NAME} версии ${VERSION}..."

# Очистка предыдущих сборок
rm -rf "${BUILD_DIR}"
rm -rf "${RELEASE_DIR}"

# Создание директорий
mkdir -p "${BUILD_DIR}"
mkdir -p "${RELEASE_DIR}"

echo "📁 Копирование исходных файлов..."
cp -r src/Mods "${BUILD_DIR}/"

# Создание архива исходников
echo "📦 Создание архива исходников..."
cd "${BUILD_DIR}"
zip -r "../${RELEASE_DIR}/${MOD_NAME}_v${VERSION}_Source.zip" Mods/
cd ..

# Информация для ручной упаковки в .pak
echo "📋 Создание инструкций для упаковки..."
cat > "${RELEASE_DIR}/BUILD_INSTRUCTIONS.txt" << EOF
Инструкции по созданию .pak файла:

1. Используйте BG3 Mod Manager:
   - Импортируйте папку build/Mods/
   - Экспортируйте как .pak файл

2. Или используйте Divine Tool (из Divinity Engine 2):
   divine.exe -g bg3 -a create-package -s build/Mods -d ${MOD_NAME}_v${VERSION}.pak

3. Или используйте lslib (если доступно):
   Попробуйте автоматическую упаковку через GitHub Actions

Файлы для упаковки находятся в папке build/Mods/
EOF

# Создание информации о релизе
echo "📄 Создание информации о релизе..."
cat > "${RELEASE_DIR}/RELEASE_NOTES_v${VERSION}.md" << EOF
# Dialogue Enter Confirm v${VERSION}

## Что нового
- Первый стабильный релиз
- Подтверждение диалогов клавишей Enter
- Поддержка контроллера (кнопка A)
- Совместимость с навигацией стрелками BG3

## Установка
1. Скачайте .pak файл (будет добавлен после сборки)
2. Поместите в папку модов BG3
3. Активируйте через мод-менеджер

## Требования
- BG3 Script Extender v18+
- Baldur's Gate 3 Patch 8+

## Файлы в релизе
- \`${MOD_NAME}_v${VERSION}.pak\` - Готовый к установке мод
- \`${MOD_NAME}_v${VERSION}_Source.zip\` - Исходные файлы

EOF

echo "✅ Сборка завершена!"
echo "📁 Файлы созданы в папке ${RELEASE_DIR}/"
echo ""
echo "Следующие шаги:"
echo "1. Создайте .pak файл используя инструкции в BUILD_INSTRUCTIONS.txt"
echo "2. Создайте GitHub Release с тегом v${VERSION}"
echo "3. Загрузите .pak файл и архив исходников"
echo ""
echo "Для автоматической сборки .pak используйте GitHub Actions"