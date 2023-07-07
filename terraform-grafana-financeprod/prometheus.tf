resource "kubectl_manifest" "DeploymentPrometheus" {
    yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-tf
  namespace: grafana
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend-tf
  template:
    metadata:
      labels:
        app: frontend-tf
    spec:
      automountServiceAccountToken: true
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
      containers:
      - name: frontend-tf
        image: "gke.gcr.io/prometheus-engine/frontend:v0.5.0-gke.0"
        args:
        - "--web.listen-address=:9090"
        - "--query.project-id=celero-finance-production"
        ports:
        - name: web
          containerPort: 9090
        readinessProbe:
          httpGet:
            path: /-/ready
            port: web
        livenessProbe:
          httpGet:
            path: /-/healthy
            port: web
YAML
}

resource "kubectl_manifest" "ServicePrometheus" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: frontend-tf
  namespace: grafana
spec:
  clusterIP: None
  selector:
    app: frontend-tf
  ports:
  - name: web
    port: 9090
YAML
}
