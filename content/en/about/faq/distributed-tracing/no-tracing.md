---
title: Why are my requests not being traced?
weight: 30
---

The sampling rate for tracing is set at 1% in the `default`
[configuration profile](/docs/setup/additional-setup/config-profiles/).
This means that only 1 out of 100 trace instances captured by Istio will be reported to the tracing backend.
The sampling rate in the `demo` profile is set to 100%. See
[this section](/docs/tasks/observability/distributed-tracing/telemetry-api/#customizing-trace-sampling)
for information on how to set the sampling rate.

If you still do not see any trace data, please confirm that your ports conform to the Istio [port naming conventions](/about/faq/#naming-port-convention) and that the appropriate container port is exposed (via pod spec, for example) to enable
traffic capture by the sidecar proxy (Envoy).

If you only see trace data associated with the egress proxy, but not the ingress proxy, it may still be related to the Istio [port naming conventions](/about/faq/#naming-port-convention).
