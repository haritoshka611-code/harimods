#!/bin/bash

# Функция для отображения меню
show_menu() {
    clear
    echo "=================================================="
    echo "       МЕГА-СКРИПТ: ВЫБЕРИТЕ НУЖНУЮ ФУНКЦИЮ       "
    echo "=================================================="
    echo "1)  Очистка загрузок (сортировка файлов)"
    echo "2)  Пакетное переименование (замена пробелов на _)"
    echo "3)  Поиск дубликатов файлов (по MD5)"
    echo "4)  Умный бэкап папки (с удалением старых)"
    echo "5)  Мониторинг логов (неудачные попытки SSH)"
    echo "6)  Контроль свободного места на диске"
    echo "7)  Быстрый апдейт системы (APT/Debian/Ubuntu)"
    echo "8)  Пинг-чекер (проверка доступности сайтов)"
    echo "9)  Парсер погоды (через wttr.in)"
    echo "10) Выход"
    echo "=================================================="
    echo -n "Введите номер функции (1-10): "
}

# 1. Очистка загрузок
clean_downloads() {
    echo "Сортировка папки Загрузки..."
    # Создаем папки, если их нет
    mkdir -p ~/Downloads/{Documents,Images,Archives}
    # Раскладываем файлы (регистронезависимо)
    find ~/Downloads -maxdepth 1 -iname "*.pdf" -o -iname "*.docx" -o -iname "*.txt" -exec mv {} ~/Downloads/Documents/ \; 2>/dev/null
    find ~/Downloads -maxdepth 1 -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -exec mv {} ~/Downloads/Images/ \; 2>/dev/null
    find ~/Downloads -maxdepth 1 -iname "*.zip" -o -iname "*.tar.gz" -o -iname "*.rar" -exec mv {} ~/Downloads/Archives/ \; 2>/dev/null
    echo "Готово! Файлы отсортированы в ~/Downloads."
}

# 2. Пакетное переименование
rename_files() {
    read -p "Введите путь к папке для переименования: " target_dir
    if [ -d "$target_dir" ]; then
        cd "$target_dir" || return
        for file in *; do
            if [[ "$file" == *" "* ]]; then
                mv "$file" "${file// /_}" 2>/dev/null
            fi
        done
        echo "Все пробелы в именах файлов заменены на нижнее подчеркивание."
    else
        echo "Папка не найдена!"
    fi
}

# 3. Поиск дубликатов
find_duplicates() {
    read -p "Введите путь к папке для поиска дубликатов: " target_dir
    if [ -d "$target_dir" ]; then
        echo "Поиск дубликатов по контрольным суммам (это может занять время)..."
        find "$target_dir" -type f -exec md5sum {} + | sort | uniq -w32 -dD
    else
        echo "Папка не найдена!"
    fi
}

# 4. Умный бэкап
smart_backup() {
    read -p "Какую папку бэкапить? (полный путь): " src_dir
    read -p "Куда сохранять бэкап? (полный путь): " backup_dir
    if [ -d "$src_dir" ]; then
        mkdir -p "$backup_dir"
        DATE=$(date +%Y-%m-%d_%H-%M-%S)
        tar -czf "$backup_dir/backup_$DATE.tar.gz" -C "$src_dir" . 2>/dev/null
        echo "Бэкап создан: $backup_dir/backup_$DATE.tar.gz"
        # Удаляем бэкапы старше 14 дней в этой папке
        find "$backup_dir" -name "backup_*.tar.gz" -mtime +14 -delete
        echo "Старые бэкапы (старше 14 дней) удалены."
    else
        echo "Исходная папка не найдена!"
    fi
}

# 5. Мониторинг логов
monitor_logs() {
    LOG_FILE="/var/log/auth.log"
    if [ -f "$LOG_FILE" ]; then
        echo "Последние 10 неудачных попыток входа по SSH:"
        grep "Failed password" "$LOG_FILE" | tail -n 10
    else
        echo "Файл логов $LOG_FILE не найден. Возможно, у вас другая ОС или нужны права sudo."
    fi
}

# 6. Контроль свободного места
check_disk() {
    echo "Проверка места на диске..."
    df -h | grep '^/dev/'
    USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$USAGE" -gt 90 ]; then
        echo "ВНИМАНИЕ: На системном диске осталось меньше 10% места! ($USAGE% занято)"
    else
        echo "Места достаточно. Системный диск занят на $USAGE%."
    fi
}

# 7. Быстрый апдейт
system_update() {
    echo "Запуск обновления системы (потребуется пароль sudo)..."
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean
}

# 8. Пинг-чекер
ping_checker() {
    echo "Проверка доступности серверов..."
    servers=("google.com" "yandex.ru" "github.com")
    for server in "${servers[@]}"; do
        if ping -c 1 "$server" &>/dev/null; then
            echo "[ OK ] $server доступен"
        else
            echo "[FAIL] $server НЕ доступен! Запись в ping_errors.log"
            echo "$(date): $server недоступен" >> ping_errors.log
        fi
    done
}

# 9. Парсер погоды
get_weather() {
    echo "Получение прогноза погоды..."
    curl -s "wttr.in/?0m" || echo "Не удалось подключиться к сервису погоды."
}

# Основной цикл программы
while true; do
    show_menu
    read -r choice
    case $choice in
        1)  clean_downloads ;;
        2)  rename_files ;;
        3)  find_duplicates ;;
        4)  smart_backup ;;
        5)  monitor_logs ;;
        6)  check_disk ;;
        7)  system_update ;;
        8)  ping_checker ;;
        9)  get_weather ;;
        10) echo "Выход из программы. Пока!"; exit 0 ;;
        *)  echo "Неверный ввод! Пожалуйста, выберите пункт от 1 до 10." ;;
    esac
    echo ""
    read -p "Нажмите Enter, чтобы вернуться в меню..." -r
done
