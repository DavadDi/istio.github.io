---
title: "Introducing Istio v1 APIs"
description: Reflecting the stability of Istio's features, our networking, security and telemetry APIs are promoted to v1 in 1.22. 
publishdate: 2024-05-13
attribution: Whitney Griffith - Microsoft
keywords: [istio, traffic, security, telemetry, API]
target_release: 1.22
---

Istio provides [networking](/docs/reference/config/networking/), [security](/docs/reference/config/security/) and [telemetry](/docs/reference/config/telemetry/) APIs that are crucial for ensuring the robust security, seamless connectivity, and effective observability of services within the service mesh. These APIs are used on thousands of clusters across the world, securing and enhancing critical infrastructure.

Most of the features powered by these APIs have been [considered stable](/docs/releases/feature-stages/) for some time, but the API version has remained at `v1beta1`. As a reflection of the stability, adoption, and value of these resources, the Istio community has decided to promote these APIs to `v1` in Istio 1.22.

In Istio 1.22 we are happy to announce that a concerted effort has been made to graduate the below APIs to `v1`:
* [Destination Rule](/docs/reference/config/networking/destination-rule/)
* [Gateway](/docs/reference/config/networking/gateway/)
* [Service Entry](/docs/reference/config/networking/service-entry/)
* [Sidecar](/docs/reference/config/networking/sidecar/)
* [Virtual Service](/docs/reference/config/networking/virtual-service/)
* [Workload Entry](/docs/reference/config/networking/workload-entry/)
* [Workload Group](/docs/reference/config/networking/workload-group/)
* [Telemetry API](/docs/reference/config/telemetry/)*
* [Peer Authentication](/docs/reference/config/security/peer_authentication/)

## Feature stability and API versions

Declarative APIs, such as those used by Kubernetes and Istio, decouple the _description_ of a resource from the _implementation_ that acts on it.

[Istio's feature phase definitions](/docs/releases/feature-stages/) describe how a stable feature — one that is deemed ready for production use at any scale, and comes with a formal deprecation policy — should be matched with a `v1` API. We are now making good on that promise, with our API versions matching our feature stability for both features that have been stable for some time, and those which are being newly designated as stable in this release.

Although there are currently no plans to discontinue support for the previous `v1beta1` and `v1alpha1` API versions, users are encouraged to manually transition to utilizing the `v1` APIs by updating their existing YAML files.

## Telemetry API

The `v1` Telemetry API is the only API that was promoted that had changes from its previous API version. The following `v1alpha1` features weren’t promoted to `v1`:
* `metrics.reportingInterval`
    * Reporting interval allows configuration of the time between calls out to for metrics reporting. This currently only supports TCP metrics but we may use this for long duration HTTP streams in the future.

      _At this time, Istio lacks usage data to support the need for this feature._
* `accessLogging.filter`
    * If specified, this filter will be used to select specific requests/connections for logging.

      _This feature is based on a relatively new feature in Envoy, and Istio needs to further develop the use case and implementation before graduating it to `v1`._
* `tracing.useRequestIdForTraceSampling`
    * This value is true by default. The format of this Request ID is specific to Envoy, and if the Request ID generated by the proxy that receives user traffic first is not specific to Envoy, Envoy will break the trace because it cannot interpret the Request ID. By setting this value to false, we can prevent [Envoy from sampling based on the Request ID](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing#trace-context-propagation).

      _There is not a strong use case for making this configurable through the Telemetry API._

Please share any feedback on these fields by [creating issues on GitHub](https://github.com/istio/istio/issues).

## Overview of Istio CRDs

This is the full list of supported API versions:

| Category | API | Versions |
| ---------|-----|----------|
| Networking | [Destination Rule](/docs/reference/config/networking/destination-rule/) |  `v1`, `v1beta1`, `v1alpha3` |
| | Istio [Gateway](/docs/reference/config/networking/gateway/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Service Entry](/docs/reference/config/networking/service-entry/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Sidecar](/docs/reference/config/networking/sidecar/) scope |  `v1`, `v1beta1`, `v1alpha3` |
| | [Virtual Service](/docs/reference/config/networking/virtual-service/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Workload Entry](/docs/reference/config/networking/workload-entry/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Workload Group](/docs/reference/config/networking/workload-group/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Proxy Config](/docs/reference/config/networking/proxy-config/) |  `v1beta1` |
| | [Envoy Filter](/docs/reference/config/networking/envoy-filter/) |  `v1alpha3` |
| Security  | [Authorization Policy](/docs/reference/config/security/authorization-policy/) |  `v1`, `v1beta1` |
| | [Peer Authentication](/docs/reference/config/security/peer_authentication/) |  `v1`, `v1beta1` |
| | [Request Authentication](/docs/reference/config/security/request_authentication/) |  `v1`, `v1beta1` |
| Telemetry | [Telemetry](/docs/reference/config/telemetry/) |  `v1`, `v1alpha1` |
| Extension | [Wasm Plugin](/docs/reference/config/proxy_extensions/wasm-plugin/) |  `v1alpha1` |

Istio can also be configured [using the Kubernetes Gateway API](/docs/setup/getting-started/).

## Using the `v1` Istio APIs

There are some APIs in Istio that are still under active development and are subject to potential changes between releases. For instance, the Envoy Filter, Proxy Config and Wasm Plugin APIs.

Furthermore, Istio maintains a strictly identical schema across all versions of an API due to limitations in [CRD versioning](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/). Therefore, even though there is a `v1` Telemetry API, the three `v1alpha1` fields mentioned [above](#telemetry-api) can still be utilized when declaring a `v1` Telemetry API resource.

For risk-averse environments, we have added a **stable validation policy**, a [validating admission policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) which can ensure that only `v1` APIs and fields are used with Istio APIs.

In new environments, selecting the stable validation policy upon installing Istio will guarantee that all future Custom Resources created or updated are `v1` and contain only `v1` features.

If the policy is deployed into an existing Istio installation that has Custom Resources that do not comply with it, the only allowed action is to delete the resource or remove the usage of the offending fields.

To install Istio with the stable validation policy:

{{< text bash >}}
$ helm install istio-base -n istio-system --set experimental.stableValidationPolicy=true
{{< /text >}}

To set a specific revision when installing Istio with the policy:

{{< text bash >}}
$ helm install istio-base -n istio-system --set experimental.stableValidationPolicy=true -set revision=x
{{< /text >}}

This feature is compatible with [Kubernetes 1.30](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) and higher. The validations are created using [CEL](https://github.com/google/cel-spec) expressions, and users can modify the validations for their specific needs.

## Summary

The Istio project is committed to delivering stable APIs and features essential for the successful operation of your service mesh. We would love to receive your feedback to help guide us in making the right decisions as we continue to refine relevant use cases and stability blockers for our features. Please share your feedback by creating [issues](https://github.com/istio/istio/issues), posting in the relevant [Istio Slack channel](https://slack.istio.io/), or by joining us in our weekly [working group meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings).
