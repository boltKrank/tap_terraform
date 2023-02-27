#!/bin/bash
cat <<'EOF' > $HOME/overlays/view/tap-gui-db.yaml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"kind":"Deployment","metadata":{"name":"server"}})
---
spec:
  #@overlay/match missing_ok=True
  template:
    spec:
      containers:
      #@overlay/match by="name"
      - name: backstage
        #@overlay/match missing_ok=True
        envFrom:
         - secretRef:
             name: tap-gui-db
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tap-gui-db
  namespace: tap-gui
  labels:
    app.kubernetes.io/part-of: tap-gui-db
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tap-gui-db
  namespace: tap-gui
  labels:
    app.kubernetes.io/part-of: tap-gui-db
spec:
  selector:
    matchLabels:
      app.kubernetes.io/part-of: tap-gui-db
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app.kubernetes.io/part-of: tap-gui-db
    spec:
      initContainers:
      - name: remove-lost-found
        image: busybox
        command:
        - sh
        - -c
        - |
          rm -fr /var/lib/postgresql/data/lost+found
        volumeMounts:
        - name: tap-gui-db
          mountPath: /var/lib/postgresql/data
      containers:
      - image: postgres:14-alpine
        name: postgres
        envFrom:
        - secretRef:
            name: tap-gui-db
        ports:
        - containerPort: 5432
          name: tap-gui-db
        volumeMounts:
        - name: tap-gui-db
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: tap-gui-db
        persistentVolumeClaim:
          claimName: tap-gui-db
---
apiVersion: v1
kind: Service
metadata:
  name: tap-gui-db
  namespace: tap-gui
  labels:
    app.kubernetes.io/part-of: tap-gui-db
spec:
  ports:
  - port: 5432
  selector:
    app.kubernetes.io/part-of: tap-gui-db
---
apiVersion: secretgen.k14s.io/v1alpha1
kind: Password
metadata:
  name: tap-gui-db
  namespace: tap-gui
  labels:
    app.kubernetes.io/part-of: tap-gui-db
spec:
  secretTemplate:
    type: Opaque
    stringData:
      POSTGRES_USER: tap-gui
      POSTGRES_PASSWORD: $(value)
EOF