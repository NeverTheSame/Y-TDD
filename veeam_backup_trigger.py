import requests
import json
import argparse
import os

# --- Конфигурация ---
VEEAM_SERVER_IP = os.getenv("VEEAM_SERVER_IP", "127.0.0.1")
VEEAM_API_URL = f"https://{VEEAM_SERVER_IP}:9419/api/v1/jobs"

# API ключ
API_KEY = os.getenv("VEEAM_API_KEY", "default_api_key_if_not_set")

headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json',
    'x-api-version': '1.0-rev2'
}


def start_backup_job(job_id, vm_ids_to_backup):
    """
    Отправляет команду на запуск задачи бэкапа для списка ВМ.

    Args:
        job_id (str): ID задачи бэкапа Veeam.
        vm_ids_to_backup (list): Список AWS Instance ID, которые нужно бэкапить.
    Returns:
        bool: True, если задача успешно запущена, False в противном случае.
    """
    payload = {"action": "start"}
    if vm_ids_to_backup:
        payload["objects"] = vm_ids_to_backup  # передал конкретные объекты для бэкапа

    try:
        response = requests.post(f"{VEEAM_API_URL}/{job_id}/action", headers=headers, json=payload, verify=False)
        response.raise_for_status()  # обрабатываем 4xx и 5xx ошибки

        task_id = response.json().get('taskId', 'N/A')
        vms_info = f" for VMs: {', '.join(vm_ids_to_backup)}" if vm_ids_to_backup else " (all configured VMs)"
        print(f"Successfully triggered backup job {job_id}{vms_info}. Task ID: {task_id}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error triggering backup job {job_id}: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response content: {e.response.text}")
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trigger Veeam backup job for specific VMs.")
    parser.add_argument("--job_id", required=True, help="Veeam Backup Job ID.")
    parser.add_argument("--vms", nargs='+',
                        help="Space-separated list of VM instance IDs to backup (e.g., i-123 i-456). If omitted, the entire job is triggered.")

    args = parser.parse_args()

    # пустой список означает "все", но при этом явно это передам
    vms_to_backup_list = args.vms if args.vms else []

    print(f"Using Veeam Server IP: {VEEAM_SERVER_IP}")
    print(f"Using API Key (first 5 chars): {API_KEY[:5]}...")  # частично проверяю ключ

    success = start_backup_job(args.job_id, vms_to_backup_list)

    if success:
        print("Veeam backup job initiation complete.")
    else:
        print("Veeam backup job initiation failed.")