#!/usr/bin/env bash
# Package and push a Helm chart to GHCR (standalone OCI artifact + optional
# oras attach on an app image manifest). Call from feat/rafaelgaspar publish
# workflows after resolve-integration-tag.
#
# Usage:
#   publish-helm-chart-ghcr.sh \
#     --chart-dir charts/keda-add-ons-http \
#     --version 0.16.0-rafaelgaspar.2 \
#     --oci oci://ghcr.io/rafaelgaspar/http-add-on/charts \
#     [--image-ref ghcr.io/rafaelgaspar/http-add-on-interceptor@sha256:...]
#
# Requires: helm, oras (when --image-ref set), helm registry login already done.
set -euo pipefail

chart_dir=""
version=""
oci_registry=""
image_ref=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chart-dir)
      chart_dir=${2:?}
      shift 2
      ;;
    --version)
      version=${2:?}
      shift 2
      ;;
    --oci)
      oci_registry=${2:?}
      shift 2
      ;;
    --image-ref)
      image_ref=${2:?}
      shift 2
      ;;
    -h|--help)
      sed -n '1,16p' "$0"
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

[[ -n $chart_dir && -n $version && -n $oci_registry ]] \
  || { echo "missing --chart-dir, --version, or --oci" >&2; exit 2; }
[[ -d $chart_dir ]] || { echo "chart dir not found: $chart_dir" >&2; exit 2; }

chart_name=$(awk '/^name:/ {print $2; exit}' "$chart_dir/Chart.yaml")
[[ -n $chart_name ]] || { echo "Chart.yaml missing name:" >&2; exit 2; }

tgz="${chart_name}-${version}.tgz"
helm package "$chart_dir" --version "$version" --app-version "$version"
[[ -f $tgz ]] || { echo "helm package did not create $tgz" >&2; exit 2; }

helm push "$tgz" "$oci_registry"
oras tag "${oci_registry%/}/${chart_name}:${version}" latest

if [[ -n $image_ref ]]; then
  oras attach --artifact-type application/vnd.cncf.helm.chart.content.v1.tar+gzip \
    "$image_ref" \
    "${tgz}:application/vnd.cncf.helm.chart.content.v1.tar+gzip"
fi

rm -f "$tgz"