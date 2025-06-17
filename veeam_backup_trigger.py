import requests
import json

VEEAM_API_URL = "https://<veeam-server-ip>:9419/api/v1/jobs"
API_KEY = "very_secret_api_key"  # из Veeam консоли
VM_TO_BACKUP = "i-0123456789abcdef0" # AWS Instance ID

headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json',
    'x-api-version': '1.0-rev2'
}

# тело запроса для запуска задачи бэкапа для конкретной ВМ
payload = {
  "action": "start",
  "objects": [VM_TO_BACKUP]
}

def start_backup_job(job_id):
    """
    Отправляет команду на запуск задачи бэкапа
    """
    try:
        response = requests.post(f"{VEEAM_API_URL}/{job_id}/action", headers=headers, json=payload, verify=False)
        response.raise_for_status()
        print(f"Successfully triggered backup job {job_id} for VM {VM_TO_BACKUP}. Task ID: {response.json()['taskId']}")
    except requests.exceptions.RequestException as e:
        print(f"Error triggering backup job {job_id}: {e}")

if __name__ == "__main__":
    # ID задачи, которая настроена на бэкап нужных машин
    target_job_id = "a1b2c3d4-e5f6-7890-1234-567890abcdef"
    start_backup_job(target_job_id)
