# Sausage Store

![image](https://user-images.githubusercontent.com/9394918/121517767-69db8a80-c9f8-11eb-835a-e98ca07fd995.png)


## Technologies used

* Frontend – TypeScript, Angular.
* Backend  – Java 16, Spring Boot, Spring Data.
* Database – H2.

## Installation guide
### Backend

Install Java 16 and maven and run:

```bash
cd backend
mvn package
cd target
java -jar sausage-store-0.0.1-SNAPSHOT.jar
```

Обновил + подтверждение применения миграций

```bash
cd ~/store/backend
set -a
source .env
set +a
mvn package
java -jar target/sausage-store-${VERSION}.jar \
  --spring.datasource.url=jdbc:postgresql://${PSQL_HOST}:${PSQL_PORT}/${PSQL_DBNAME} \
  --spring.datasource.username=${PSQL_USER} \
  --spring.datasource.password=${PSQL_PASSWORD}
```

### Frontend

Install NodeJS and npm on your computer and run:

```bash
cd frontend
npm install
npm run build
npm install -g http-server
sudo http-server ./dist/frontend/ -p 80 --proxy http://localhost:8080
```

Then open your browser and go to [http://localhost](http://localhost)

## Kubernetes deployment

Верхнеуровневый Helm-чарт включает четыре компонента:

* `frontend`;
* `backend`;
* `backend-report`;
* `infra`.

В `infra` входят:

* PostgreSQL
* MongoDB
* Job для инициализации MongoDB
* HashiCorp Vault

### Адрес приложения

```text
https://front-r-devops-magistracy-project-2sem-1766404076.2sem.students-projects.ru
```

### Namespace

```text
r-devops-magistracy-project-2sem-1766404076
```

### Проверка Helm-чарта

```bash
helm lint ./sausage-store-chart
```

### GitHub Actions Secrets

```text
NEXUS_HELM_REPO
NEXUS_HELM_REPO_USER
NEXUS_HELM_REPO_PASSWORD
NAMESPACE
KUBE_CONFIG
VAULT_TOKEN
```

## HashiCorp Vault

Vault разворачивается внутри Kubernetes как StatefulSet:

```text
vault-0
```

Для хранения данных Vault используется PVC:

```text
vault-data-vault-0
```

Backend обращается к Vault внутри кластера:

```text
http://vault:8200
```

В Vault хранятся параметры:

```text
spring.datasource.username
spring.datasource.password
spring.data.mongodb.uri
```

### Проверка состояния Vault

```bash
kubectl exec vault-0 -- \
  env VAULT_ADDR=http://127.0.0.1:8200 \
  vault status
```

Рабочее состояние:

```text
Initialized    true
Sealed         false
```

После перезапуска Vault может перейти в состояние Sealed. Для повторного unseal:

```bash
UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' "$HOME/vault-init.json")

kubectl exec vault-0 -- \
  env VAULT_ADDR=http://127.0.0.1:8200 \
  vault operator unseal "$UNSEAL_KEY"
```

## Проверка развёртывания

Проверка Pod:

```bash
kubectl get pods
```

Ожидаемый результат:

```text
└─$ kubectl get pods                                         
NAME                                            READY   STATUS    RESTARTS          AGE
mongodb-0                                       1/1     Running   0                 26h
postgresql-0                                    1/1     Running   0                 26h
sausage-store-backend-66866fbf66-hnq78          1/1     Running   229 (6m39s ago)   19h
sausage-store-backend-report-5dcf7bf587-bkzsw   1/1     Running   61 (23h ago)      28h
sausage-store-frontend-958c66ffc-ljsf2          1/1     Running   0                 26h
vault-0                                         1/1     Running   0                 20h
                                                                                           
```

Проверка Helm-релиза:

```bash
helm list
```

Статус:

```text
deployed
```

Проверка Ingress:

```bash
kubectl get ingress
```

Проверка backend:

```bash
kubectl rollout status deployment/sausage-store-backend \
  --timeout=5m

kubectl logs deployment/sausage-store-backend \
  --tail=200
```

Проверка frontend:

```bash
kubectl rollout status deployment/sausage-store-frontend \
  --timeout=5m
```

Проверка backend-report:

```bash
kubectl rollout status deployment/sausage-store-backend-report \
  --timeout=5m
```

## Масштабирование

Для backend настроен VPA:

```bash
kubectl describe vpa sausage-store-backend-vpa
```

Корректная работа подтверждается условием:

```text
Type: RecommendationProvided
Status: True
```

Для backend-report настроен HPA:

```bash
kubectl describe hpa sausage-store-backend-report-hpa
```

Текущие параметры:

```text
Min replicas: 1
Max replicas: 3
Target CPU utilization: 75%
```

## Стратегии развёртывания

Для backend используется:

```yaml
strategy:
  type: RollingUpdate
```

Для backend-report используется:

```yaml
strategy:
  type: Recreate
```

## Хранилища данных

Для PostgreSQL и MongoDB используются PersistentVolumeClaim:

```text
postgresql-data-postgresql-0
mongodb-data-mongodb-0
```

Проверка:

```bash
kubectl get pvc
```

Статус:

```text
Bound
```

## Диагностика

Проверка количества реплик backend:

```bash
kubectl get deployment sausage-store-backend
```

```text
READY   1/1
```

При необходимости:

```bash
kubectl scale deployment sausage-store-backend \
  --replicas=1
```

Проверка ошибок Vault:

```bash
kubectl logs deployment/sausage-store-backend \
  --tail=300 2>&1 |
grep -E "Vault|Caused by:|ERROR|Exception|FATAL"
```

Проверка всех ресурсов:

```bash
kubectl get all
kubectl get pvc
kubectl get ingress
helm list
```

## Resource quotas

В namespace установлены ограничения:

```bash
kubectl describe resourcequota
```
