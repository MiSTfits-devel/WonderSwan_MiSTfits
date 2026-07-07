# Headless Quartus builds on kubernetes

Compiles the core with Quartus Prime 17.0 (the version this project pins)
inside [`raetro/quartus:17.0`](https://hub.docker.com/r/raetro/quartus), the
image the MiSTer core CI ecosystem uses. Needs an amd64 node and a working
kubectl context - no registry, no pushed branch, no license (Lite covers the
Cyclone V here).

```sh
build/remote-build.sh                 # builds HEAD
build/remote-build.sh mybranch        # builds any committed ref
PARALLEL=ALL build/remote-build.sh    # match the upstream qsf setting
```

How it works: a pod (see `quartus-pod.yaml`) waits for source, the script
streams the committed tree in with `git archive | kubectl exec tar`, the flow
runs, and `WonderSwan.rbf` plus the fit/timing summaries are copied back to
`build/artifacts/` before the pod is deleted.

Only committed files are built - commit before building.

For quick syntax/elaboration checks without a full fit, use
`sim/run_analyze_all.sh` locally (nvc), or run inside the pod:
`quartus_map WonderSwan --analysis_and_elaboration`.
