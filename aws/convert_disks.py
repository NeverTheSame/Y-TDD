import os
import subprocess
from multiprocessing import Pool, cpu_count
import time

# --- Конфигурация ---
# уже монтированная NFS шара с .vmdk файлами
SOURCE_VMDK_DIR = "Z:"

# Google Cloud Storage bucket уже смонтирован
# Mount-GcsBucket -BucketName "gcs-bucket-name" -DriveLetter "Y:" -ServiceAccountKeyPath "C:\service-account-key.json"
TARGET_RAW_DIR = "Y:"

# процессов использую cpu_count() для параллельных процессов
NUM_PROCESSES = cpu_count()

# --- хелпер для конвертации ---
def _simulate_convert(vmdk_path, raw_path):
    """
    Имитирует процесс конвертации с помощью qemu-img.
    """
    file_name = os.path.basename(vmdk_path)
    print(f"[{os.getpid()}] Начинаю конвертацию: {file_name} -> {os.path.basename(raw_path)}")

    # задал случайное время от 2 до 10 секунд
    time.sleep(2 + (hash(vmdk_path) % 9))

    # --- Оборачиваю вызов QEMU-IMG ---
    command = ["qemu-img", "convert", "-f", "vmdk", "-O", "raw", vmdk_path, raw_path]
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    print(f"[{os.getpid()}] Успешно сконвертировано: {file_name}. Вывод: {result.stdout.strip()}")

    return True  # Возвращаем True при успехе имитации


def convert_disk(vmdk_file):
    """
    Функция, которая будет выполняться каждым процессом.
    Принимает имя файла .vmdk и возвращает результат конвертации.
    """
    vmdk_path = os.path.join(SOURCE_VMDK_DIR, vmdk_file)
    raw_file = os.path.splitext(vmdk_file)[0] + ".raw"
    raw_path = os.path.join(TARGET_RAW_DIR, raw_file)

    if not os.path.exists(vmdk_path):
        print(f"[{os.getpid()}] Ошибка: Файл {vmdk_path} не найден. Пропускаю.")
        return False

    if os.path.exists(raw_path):
        print(f"[{os.getpid()}] Файл {raw_path} уже существует в целевой директории. Пропускаю.")
        return True  # считаю, что уже сконвертировано

    return _simulate_convert(vmdk_path, raw_path)


if __name__ == "__main__":
    print(f"Запускаю скрипт параллельной конвертации дисков...")
    print(f"Источник VMDK (смонтированная шара Z:): {SOURCE_VMDK_DIR}")
    print(f"Целевая RAW (смонтированный GCS bucket через Y:): {TARGET_RAW_DIR}")
    print(f"Будет использоваться {NUM_PROCESSES} параллельных процессов для конвертации.")

    # создал целевую директорию, если она не существует
    os.makedirs(TARGET_RAW_DIR, exist_ok=True)

    # получил список всех .vmdk файлов в исходной директории
    try:
        vmdk_files = [f for f in os.listdir(SOURCE_VMDK_DIR) if f.endswith(".vmdk")]
    except FileNotFoundError:
        print(f"Ошибка: Директория '{SOURCE_VMDK_DIR}' не найдена. Убедитесь, что шара Z: корректно смонтирована.")
        exit(1)
    except PermissionError:
        print(f"Ошибка доступа: Нет прав для чтения директории '{SOURCE_VMDK_DIR}'. Проверьте разрешения.")
        exit(1)

    if not vmdk_files:
        print("В исходной директории не найдено файлов .vmdk. Завершаю.")
        exit(0)

    print(f"Найдено {len(vmdk_files)} файлов .vmdk для конвертации.")

    start_time = time.time()

    # создал пул процессов через 'with' чтобы пул корректно закрылся
    with Pool(processes=NUM_PROCESSES) as pool:
        # map() распределяет элементы из vmdk_files по процессам в пуле
        results = pool.map(convert_disk, vmdk_files)

    end_time = time.time()

    successful_conversions = sum(1 for r in results if r)
    failed_conversions = len(results) - successful_conversions

    print("\n--- Отчет о конвертации ---")
    print(f"Всего файлов .vmdk: {len(vmdk_files)}")
    print(f"Успешно сконвертировано: {successful_conversions}")
    print(f"Ошибок/пропусков: {failed_conversions}")
    print(f"Общее время конвертации: {end_time - start_time:.2f} секунд.")

    if failed_conversions > 0:
        print("Некоторые файлы не были сконвертированы успешно. Проверьте логи выше.")
        exit(1)
    else:
        print("Все файлы успешно обработаны.")
        exit(0)