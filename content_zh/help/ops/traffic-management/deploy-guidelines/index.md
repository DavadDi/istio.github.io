---
title: 部署和配置指南
description: 提供特定的部署和配置指南。
weight: 5
---

本节提供了特定的部署或配置指南，以避免网络或流量管理问题。

## 重新配置服务路由时出现 503 错误

在设置路由规则以将流量定向到服务的特定版本（子集）时，必须注意确保子集在路由使用之前可用。 否则，对服务的调用可能在重新配置期间返回 503 错误。

使用单个 `kubectl` 调用创建定义相应子集的 `VirtualServices` 和 `DestinationRule`（例如，`kubectl apply -f myVirtualServiceAndDestinationRule.yaml`是不够的，因为配置（从配置服务器，即 Kubernetes API 服务器）传播到 Pilot 实例是以最终一致的方式进行的。 如果使用子集的 `VirtualService` 在定义子集的 `DestinationRule` 之前生效，Pilot 生成的 Envoy 配置将引用不存在的上游服务池。这将导致 HTTP 503 错误，直至所有配置对象都可用于 Pilot。

要确保在使用子集配置路由时服务的停机时间为零，请按照 “make-before-break” 过程进行操作，如下所述：

- 添加新子集时：

     1. 在更新使用它的任何 `VirtualServices` 之前，更新 `DestinationRules` 首先添加新子集。 使用 `kubectl` 或任何特定于平台的工具应用规则。
     2. 等待几秒钟，使 `DestinationRule`配置传播到 Envoy sidecar。

        3. 更新 `VirtualService以`引用新添加的子集。

- 删除子集时：

     1. 在从 `DestinationRule` 中删除子集之前，更新 `VirtualServices` 以删除对子集的任何引用。
     2. 等待几秒钟，以便 `VirtualService` 配置传播到 Envoy sidecar。
     3. 更新 `DestinationRule` 以删除未使用的子集。

## 路由规则对入口网关请求不生效

假设正在使用入口网关和相应的 `VirtualSerive` 来访问内部服务。

例如， `VirtualService` 看起来像这样：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # or maybe "*" if you are testing without DNS using the ingress-gateway IP (e.g., http://1.2.3.4/hello)
    gateways:
  - myapp-gateway
    http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

还有一个 `VirtualService`，它将 helloworld 服务的流量路由到特定子集：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.default.svc.cluster.local
    http:
  - route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

在这种情况下，您会注意到通过入口网关向 helloworld 服务发出的请求不会被定向到子集 v1，而是继续使用默认的轮询路由。

入口请求正在使用网关主机（例如，`myapp.com`），该主机将使用 myapp `VirtualService` 中的规则，路由请求到 helloworld 服务中的任一端点。 主机 `helloworld.default.svc.cluster.local` 的内部请求将使用 helloworld `VirtualService`，它将流量专门定向到子集 v1。

要控制来自网关的流量，您需要在myapp `VirtualService` 中包含子集规则：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # or maybe "*" if you are testing without DNS using the ingress-gateway IP (e.g., http://1.2.3.4/hello)
    gateways:
  - myapp-gateway
    http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    ...
{{< /text >}}

或者，如果可能，可以将两个 `VirtualServices` 组合到一个单元中：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # cannot use "*" here since this is being combined with the mesh services
  - helloworld.default.svc.cluster.local
    gateways:
  - mesh # applies internally as well as externally
  - myapp-gateway
    http:
  - match:
    - uri:
        prefix: /hello
        gateways:
      - myapp-gateway #restricts this rule to apply only to ingress gateway
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # applies to all services inside the mesh
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

## 路由规则对我的应用程序不生效

如果路径规则对 [Bookinfo](/zh/docs/examples/bookinfo/) 示例正常运行，但类似的版本路由规则对自己的应用程序没有影响，则可能需要更改 Kubernetes 服务。

Kubernetes 服务必须遵守某些限制才能利用 Istio 的 L7 路由功能。 有关详细信息，请参阅 [Pod 和服务的要求](/zh/docs/setup/kubernetes/spec-requirements)。

## Envoy 无法连接到 HTTP/1.0 服务

Envoy 需要使用 `HTTP/1.1` 或 `HTTP/2` 与上游服务通信。 例如，当使用 [NGINX](https://www.nginx.com/)  为 Envoy 后端提供流量服务时，需要将 NGINX 配置中的  [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version)  指令设置为 “1.1”，因为 NGINX 默认值为 1.0。

配置样例如下：

{{< text plain >}}
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
{{< /text >}}

## Headless TCP 服务失去连接

如果部署了 `istio-citadel`，则 Envoy 每 15 分钟重新启动一次以刷新证书。 这会导致断开 TCP 连接或服务之间长连接。

在应用程序中应该为此类断开连接进行容错处理，但如果仍希望防止断开连接，则需要禁用双向 TLS 和 `istio-citadel` 部署。

首先，编辑 `istio` 配置以禁用双向 TLS：

{{< text bash >}}
$ kubectl edit configmap -n istio-system istio
$ kubectl delete pods -n istio-system -l istio=pilot
{{< /text >}}

接着，缩小 `istio-citadel` 部署以禁用 Envoy 重启：

{{< text bash >}}
$ kubectl scale --replicas=0 deploy/istio-citadel -n istio-system
{{< /text >}}

以上则可以防止 Istio 重新启动 Envoy 并断开 TCP 连接。