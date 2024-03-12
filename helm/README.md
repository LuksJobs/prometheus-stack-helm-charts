# kube-prometheus-stack
```
  1.2 hr  ┼                               ╭╮                                 
  1.1 hr  ┤                               ││                              ╭╮ 
   56 min ┤                               ││                     ╭──╮ ╭╮  ││ 
   49 min ┤                               ││                     │  │ ││ ╭╯│ 
   42 min ┤                               ││                    ╭╯  │ │╰─╯ ╰ 
   35 min ┤                              ╭╯╰╮                   │   ╰─╯      
   28 min ┤                      ╭╮      │  │                   │            
   21 min ┤                     ╭╯│  ╭─╮ │  │                   │            
   14 min ┤                     │ │  │ ╰╮│  │                  ╭╯            
    7 min ┤                    ╭╯ ╰╮╭╯  ╰╯  │                  │             
    0 ms  ┼────────────────────╯   ╰╯       ╰──────────────────╯             
         sum(increase(more_devops_life[1h]))
```
Instala o [stack kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), uma coleção de manifestos Kubernetes, dashboards [Grafana](http://grafana.com/) e regras [Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) combinados com documentação e scripts para fornecer monitoramento de cluster Kubernetes de ponta a ponta com facilidade de operação usando o [Prometheus](https://prometheus.io/) com o [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).

Veja o [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) README para detalhes sobre componentes, dashboards e alertas.

_Nota: Este chart anteriormente era chamado de chart `prometheus-operator`, agora renomeado para refletir mais claramente que ele instala o stack do projeto `kube-prometheus`, dentro do qual o Prometheus Operator é apenas um componente._

## Pré-requisitos

- Kubernetes 1.19+
- Helm 3+

## Obter Informações do Repositório Helm

```console
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Instalar Chart Helm

```console
helm install [NOME_DO_RELEASE] prometheus-community/kube-prometheus-stack
```
Veja configuração abaixo.

### Dependências

Por padrão, este chart instala charts adicionais dependentes:

* prometheus-community/kube-state-metrics
* prometheus-community/prometheus-node-exporter
* grafana/grafana

Para desativar dependências durante a instalação, veja múltiplos releases abaixo.

Veja helm dependency para documentação de comando.

## Para desinstalar os Chart Helm
```console
helm uninstall [NOME_DO_RELEASE]
```
Isso remove todos os componentes Kubernetes associados ao chart e exclui o release.

Veja helm uninstall para documentação de comando.

Os CRDs criados por este chart não são removidos por padrão e devem ser limpos manualmente:

```console
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheusagents.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd scrapeconfigs.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

Para atualizar os Chart
```console
helm upgrade --install [NOME_DO_RELEASE] prometheus-community/kube-prometheus-stack
```

Com o Helm v3, os CRDs criados por este chart não são atualizados por padrão e devem ser atualizados manualmente.

## Atualizando um Release Existente para uma nova versão principal

Uma mudança de versão principal do **chart** (como v1.2.3 -> v2.0.0) indica que há uma mudança incompatível que requer ações manuais.

### Adicionando Targets

Para adicionar os targets a serem exportados para o Prometheus, basta editar o arquivo "`value.yaml`" do Helm, na linha 3715, basta adicionar os scrapes ao atributo: "`additionalScrapeConfigs`", exemplo:

```yaml
    additionalScrapeConfigs:
      - job_name: "Celero v2 Model" #Nome do job que vai coletar as métricas do primeiro exporter.
        static_configs:
          - targets: ["10.180.14.182:80/health/"] #Endereço do alvo monitorado, ou seja, "Celerov2Model".
```
Depois de adicionado o novo scrap, basta atualizar o deployment do helm chart.

## Templates de Alertas do Alertmanager

Diretório onde encontra-se os templates dos alertas do Alertmanager: "kube-prometheus-stack/templates/prometheus/rules-1.14".

No arquivo `values.yaml` na linha: "342" está a referência dos templates utilizados:

```console
    templates:
    - '/etc/alertmanager/config/*.tmpl' 
```

Exemplo de um template de alerta: 

```yaml
{{- /*
Generated from 'k8s.rules.container-cpu-usage-seconds-total' group from https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/a8ba97a150c75be42010c75d10b720c55e182f1a/manifests/kubernetesControlPlane-prometheusRule.yaml
Do not change in-place! In order to change this file first read following link:
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/hack
*/ -}}
{{- $kubeTargetVersion := default .Capabilities.KubeVersion.GitVersion .Values.kubeTargetVersionOverride }}
{{- if and (semverCompare ">=1.14.0-0" $kubeTargetVersion) (semverCompare "<9.9.9-9" $kubeTargetVersion) .Values.defaultRules.create .Values.defaultRules.rules.k8sContainerCpuUsageSecondsTotal }}
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: {{ printf "%s-%s" (include "kube-prometheus-stack.fullname" .) "k8s.rules.container-cpu-usage-seconds-total" | trunc 63 | trimSuffix "-" }}
  namespace: {{ template "kube-prometheus-stack.namespace" . }}
  labels:
    app: {{ template "kube-prometheus-stack.name" . }}
{{ include "kube-prometheus-stack.labels" . | indent 4 }}
{{- if .Values.defaultRules.labels }}
{{ toYaml .Values.defaultRules.labels | indent 4 }}
{{- end }}
{{- if .Values.defaultRules.annotations }}
  annotations:
{{ toYaml .Values.defaultRules.annotations | indent 4 }}
{{- end }}
spec:
  groups:
  - name: k8s.rules.container_cpu_usage_seconds_total
    rules:
    - expr: |-
        sum by ({{ range $.Values.defaultRules.additionalAggregationLabels }}{{ . }},{{ end }}cluster, namespace, pod, container) (
          irate(container_cpu_usage_seconds_total{job="kubelet", metrics_path="/metrics/cadvisor", image!=""}[5m])
        ) * on ({{ range $.Values.defaultRules.additionalAggregationLabels }}{{ . }},{{ end }}cluster, namespace, pod) group_left(node) topk by ({{ range $.Values.defaultRules.additionalAggregationLabels }}{{ . }},{{ end }}cluster, namespace, pod) (
          1, max by ({{ range $.Values.defaultRules.additionalAggregationLabels }}{{ . }},{{ end }}cluster, namespace, pod, node) (kube_pod_info{node!=""})
        )
      record: node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate
      {{- if or .Values.defaultRules.additionalRuleLabels .Values.defaultRules.additionalRuleGroupLabels.k8sContainerCpuUsageSecondsTotal }}
      labels:
        {{- with .Values.defaultRules.additionalRuleLabels }}
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .Values.defaultRules.additionalRuleGroupLabels.k8sContainerCpuUsageSecondsTotal }}
          {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- end }}
{{- end }}
```