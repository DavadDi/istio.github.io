#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/tasks/security/authentication/authn-policy/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-support.sh"

snip_before_you_begin_1() {
istioctl install --set profile=default
}

snip_setup_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/curl/curl.yaml) -n foo
kubectl create ns bar
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n bar
kubectl apply -f <(istioctl kube-inject -f samples/curl/curl.yaml) -n bar
kubectl create ns legacy
kubectl apply -f samples/httpbin/httpbin.yaml -n legacy
kubectl apply -f samples/curl/curl.yaml -n legacy
}

snip_setup_2() {
kubectl exec "$(kubectl get pod -l app=curl -n bar -o jsonpath={.items..metadata.name})" -c curl -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_setup_2_out <<\ENDSNIP
200
ENDSNIP

snip_setup_3() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl -s "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! IFS=$'\n' read -r -d '' snip_setup_3_out <<\ENDSNIP
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 200
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
ENDSNIP

snip_setup_4() {
kubectl get peerauthentication --all-namespaces
}

! IFS=$'\n' read -r -d '' snip_setup_4_out <<\ENDSNIP
No resources found
ENDSNIP

snip_setup_5() {
kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
}

! IFS=$'\n' read -r -d '' snip_setup_5_out <<\ENDSNIP

ENDSNIP

snip_auto_mutual_tls_1() {
kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl -s http://httpbin.foo:8000/headers -s | jq '.headers["X-Forwarded-Client-Cert"][0]' | sed 's/Hash=[a-z0-9]*;/Hash=<redacted>;/'
}

! IFS=$'\n' read -r -d '' snip_auto_mutual_tls_1_out <<\ENDSNIP
  "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"
ENDSNIP

snip_auto_mutual_tls_2() {
kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert
}

! IFS=$'\n' read -r -d '' snip_auto_mutual_tls_2_out <<\ENDSNIP

ENDSNIP

snip_globally_enabling_istio_mutual_tls_in_strict_mode_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_globally_enabling_istio_mutual_tls_in_strict_mode_2() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! IFS=$'\n' read -r -d '' snip_globally_enabling_istio_mutual_tls_in_strict_mode_2_out <<\ENDSNIP
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
ENDSNIP

snip_cleanup_part_1_1() {
kubectl delete peerauthentication -n istio-system default
}

snip_namespacewide_policy_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_namespacewide_policy_2() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! IFS=$'\n' read -r -d '' snip_namespacewide_policy_2_out <<\ENDSNIP
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
ENDSNIP

snip_enable_mutual_tls_per_workload_1() {
cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
EOF
}

snip_enable_mutual_tls_per_workload_2() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! IFS=$'\n' read -r -d '' snip_enable_mutual_tls_per_workload_2_out <<\ENDSNIP
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
ENDSNIP

! IFS=$'\n' read -r -d '' snip_enable_mutual_tls_per_workload_3 <<\ENDSNIP
...
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
ENDSNIP

snip_enable_mutual_tls_per_workload_4() {
cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    8080:
      mode: DISABLE
EOF
}

snip_enable_mutual_tls_per_workload_5() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! IFS=$'\n' read -r -d '' snip_enable_mutual_tls_per_workload_5_out <<\ENDSNIP
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
ENDSNIP

snip_policy_precedence_1() {
cat <<EOF | kubectl apply -n foo -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "overwrite-example"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: DISABLE
EOF
}

snip_policy_precedence_2() {
kubectl exec "$(kubectl get pod -l app=curl -n legacy -o jsonpath={.items..metadata.name})" -c curl -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_policy_precedence_2_out <<\ENDSNIP
200
ENDSNIP

snip_cleanup_part_2_1() {
kubectl delete peerauthentication default overwrite-example -n foo
kubectl delete peerauthentication httpbin -n bar
}

snip_enduser_authentication_1() {
kubectl apply -f samples/httpbin/httpbin-gateway.yaml -n foo
}

snip_enduser_authentication_2() {
kubectl apply -f samples/httpbin/gateway-api/httpbin-gateway.yaml -n foo
kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
}

snip_enduser_authentication_3() {
export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
}

snip_enduser_authentication_4() {
curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_enduser_authentication_4_out <<\ENDSNIP
200
ENDSNIP

snip_enduser_authentication_5() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.27/security/tools/jwt/samples/jwks.json"
EOF
}

snip_enduser_authentication_6() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.27/security/tools/jwt/samples/jwks.json"
EOF
}

snip_enduser_authentication_7() {
curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_enduser_authentication_7_out <<\ENDSNIP
200
ENDSNIP

snip_enduser_authentication_8() {
curl --header "Authorization: Bearer deadbeef" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_enduser_authentication_8_out <<\ENDSNIP
401
ENDSNIP

snip_enduser_authentication_9() {
TOKEN=$(curl https://raw.githubusercontent.com/istio/istio/release-1.27/security/tools/jwt/samples/demo.jwt -s)
curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_enduser_authentication_9_out <<\ENDSNIP
200
ENDSNIP

snip_enduser_authentication_10() {
wget --no-verbose https://raw.githubusercontent.com/istio/istio/release-1.27/security/tools/jwt/samples/gen-jwt.py
}

snip_enduser_authentication_11() {
wget --no-verbose https://raw.githubusercontent.com/istio/istio/release-1.27/security/tools/jwt/samples/key.pem
}

snip_enduser_authentication_12() {
TOKEN=$(python3 ./gen-jwt.py ./key.pem --expire 5)
for i in $(seq 1 10); do curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"; sleep 10; done
}

! IFS=$'\n' read -r -d '' snip_enduser_authentication_12_out <<\ENDSNIP
200
200
200
200
200
200
200
401
401
401
ENDSNIP

snip_require_a_valid_token_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
}

snip_require_a_valid_token_2() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
}

snip_require_a_valid_token_3() {
curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_require_a_valid_token_3_out <<\ENDSNIP
403
ENDSNIP

snip_require_valid_tokens_perpath_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
}

snip_require_valid_tokens_perpath_2() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
}

snip_require_valid_tokens_perpath_3() {
curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_require_valid_tokens_perpath_3_out <<\ENDSNIP
403
ENDSNIP

snip_require_valid_tokens_perpath_4() {
curl "$INGRESS_HOST:$INGRESS_PORT/ip" -s -o /dev/null -w "%{http_code}\n"
}

! IFS=$'\n' read -r -d '' snip_require_valid_tokens_perpath_4_out <<\ENDSNIP
200
ENDSNIP

snip_cleanup_part_3_1() {
kubectl -n istio-system delete requestauthentication jwt-example
}

snip_cleanup_part_3_2() {
kubectl -n istio-system delete authorizationpolicy frontend-ingress
}

snip_cleanup_part_3_3() {
rm -f ./gen-jwt.py ./key.pem
}

snip_cleanup_part_3_4() {
kubectl delete ns foo bar legacy
}
