import pandas as pd
import subprocess
import json

# 1. загрузил и запарсим метрики из AWS
aws_metrics_df = pd.read_csv('aws_instance_metrics.csv') # CSV с колонками: InstanceID, CPUUtilization, MemoryUtilization
aws_metrics_df['Timestamp'] = pd.to_datetime(aws_metrics_df['Timestamp'])

# 2. получил список доступных машин в GCP
gcloud_command = 'gcloud compute machine-types list --filter="zone:us-central1-a" --format="json"'
proc = subprocess.run(gcloud_command, shell=True, capture_output=True, text=True)
gcp_machine_types = json.loads(proc.stdout)

gcp_df = pd.DataFrame(gcp_machine_types)
gcp_df = gcp_df[['name', 'guestCpus', 'memoryMb']]
gcp_df.sort_values(by=['guestCpus', 'memoryMb'], inplace=True)


def find_best_fit_gcp_machine(cpu_p95, mem_p95_mb, buffer=1.2):
    """
    Находим наименьшую подходящую машину в GCP с учетом 20% буфера.
    """
    required_cpu = cpu_p95 * buffer
    required_mem = mem_p95_mb * buffer

    # первая машина, которая удовлетворяет требованиям
    for index, machine in gcp_df.iterrows():
        if machine['guestCpus'] >= required_cpu and machine['memoryMb'] >= required_mem:
            return machine['name']
    return "custom-machine-needed" # или самый большой который я выбрал для машин инстанс как fallback


# 3. рассчитал 95-й персенталь и подобрал машину
results = []
for instance_id, group in aws_metrics_df.groupby('InstanceID'):
    cpu_p95 = group['CPUUtilization'].quantile(0.95)
    mem_p95 = group['MemoryUtilization'].quantile(0.95)

    # на этом этапе был известен исходный размер памяти инстанса (например, 16 ГБ)
    instance_mem_mb = 16384
    mem_p95_mb = (mem_p95 / 100) * instance_mem_mb

    best_fit = find_best_fit_gcp_machine(cpu_p95, mem_p95_mb)
    results.append({'InstanceID': instance_id, 'RecommendedGCPType': best_fit, 'CPU_p95': cpu_p95, 'Mem_p95_MB': mem_p95_mb})

result_df = pd.DataFrame(results)
print(result_df)
# result_df.to_csv('gcp_migration_plan.csv', index=False)
