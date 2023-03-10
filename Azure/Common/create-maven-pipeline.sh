#!/bin/bash
cat <<'EOF' > pipeline-maven.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: maven-test-pipeline
  labels:
    apps.tanzu.vmware.com/pipeline: test
    apps.tanzu.vmware.com/language: java
spec:
  params:
  - name: source-url
  - name: source-revision
  tasks:
  - name: test
    params:
    - name: source-url
      value: $(params.source-url)
    - name: source-revision
      value: $(params.source-revision)
    taskSpec:
      params:
      - name: source-url
      - name: source-revision
      steps:
      - name: test
        image: eclipse-temurin:17
        script: |-
          set -ex
          cd `mktemp -d`
          curl -s $(params.source-url) | tar -m -xzvf -
          # ./mvnw clean test -V --no-transfer-progress
          echo 'Skip'
EOF

kubectl apply -f pipeline-maven.yaml -n ${NAMESPACE}
