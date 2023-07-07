resource "kubectl_manifest" "PersistentVolumeClaim" {
    yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: grafana
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
YAML
}


resource "kubectl_manifest" "Deployment" {
    yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: grafana
  name: grafana
  namespace: grafana

spec:
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        fsGroup: 472
        supplementalGroups:
          - 0
      containers:
        - name: grafana
          image: grafana/grafana:9.1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
              name: http-grafana
              protocol: TCP
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /robots.txt
              port: 3000
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 2
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 3000
            timeoutSeconds: 1
          resources:
            requests:
              cpu: 250m
              memory: 750Mi
          volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-pv
      volumes:
        - name: grafana-pv
          persistentVolumeClaim:
            claimName: grafana-pvc
YAML
}

resource "kubectl_manifest" "Service" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: grafanasvc
  namespace: grafana
  annotations:
    beta.cloud.google.com/backend-config: '{"default": "config-ui-grafana"}'
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: http-grafana
  selector:
    app: grafana
  sessionAffinity: None
  type: LoadBalancer
YAML
}

resource "kubectl_manifest" "managed-cert-grafana-production" {
    yaml_body = <<YAML
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: managed-cert-grafana-production
  namespace: grafana
spec:
  domains:
    - finance-production-celero-grafana.celero.mobi
YAML
}

resource "kubectl_manifest" "IngressGrafana" {
    yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: managed-cert-ingress-grafana
  namespace: grafana
  annotations:
    kubernetes.io/ingress.global-static-ip-name: grafana-production
    networking.gke.io/managed-certificates: managed-cert-grafana-production
    ingress.kubernetes.io/https-forwarding-rule: k8s2-fs-h8n1qfoh-grafana-managed-cert-ingress-grafana-jktkrbdl
    ingress.kubernetes.io/https-target-proxy: k8s2-ts-h8n1qfoh-grafana-managed-cert-ingress-grafana-jktkrbdl
    ingress.kubernetes.io/ssl-cert: mcrt-5b75d7b2-2b64-4a17-b28f-71059a9bb351
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ssl-only: "true"
    kubernetes.io/ingress.allow-http: "false"
spec:
  defaultBackend:
    service:
      name: grafanasvc
      port:
        number: 80
YAML
}

resource "kubectl_manifest" "Secret" {
    yaml_body = <<YAML
apiVersion: v1
data:
  client_id: ODQ2OTY0Nzg0MjQ5LTVpOGVrNzV0c3B0MDZsaWN0aGhmZGhpMWg1NzRpYWVyLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29t
  client_secret: R09DU1BYLVdwU1AxdE1tUXpoWUpZQUdCRm41UXBlWXZTa0o=
kind: Secret
metadata:
  name: secrets-iap-ui-grafana
  namespace: grafana

type: Opaque

YAML
}

resource "kubectl_manifest" "BackendConfig" {
    yaml_body = <<YAML
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: config-ui-grafana
  namespace: grafana
YAML
}