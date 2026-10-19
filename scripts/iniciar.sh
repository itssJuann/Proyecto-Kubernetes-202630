#!/usr/bin/env bash
# Prepara todo y abre el gestor. Equivalente en Mac/Linux de la seccion
# "Preparacion" del README (y de preparar-imagenes.ps1). Se puede repetir
# las veces que haga falta: solo hace lo que falta.
#
# Uso (desde cualquier carpeta):   bash scripts/iniciar.sh
set -e
cd "$(dirname "$0")/.."

echo "==> 1/5 Clúster de Minikube"
if ! minikube status >/dev/null 2>&1 || ! kubectl get nodes >/dev/null 2>&1; then
  # El motor tiene que ser docker: 'minikube docker-env' no funciona con containerd.
  minikube start --driver=docker --container-runtime=docker --memory=4096 --cpus=2
fi

echo "==> 2/5 Namespace"
kubectl apply -f k8s/00-namespace.yaml

echo "==> 3/5 Imágenes (se construyen dentro de Minikube)"
eval "$(minikube -p minikube docker-env)"
for lenguaje in python java c; do
  docker build -q -t "kubernates-202630-$lenguaje:1.0" "imagenes/$lenguaje"
done
docker images --filter 'reference=kubernates-202630-*'

echo "==> 4/5 Entorno virtual de Python"
if [ ! -d .venv ]; then python3 -m venv .venv; fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r entrega/requirements.txt

echo "==> 5/5 Gestor"
exec python entrega/gestor_jobs.py
