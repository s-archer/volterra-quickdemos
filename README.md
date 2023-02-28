# volterra-quickdemos

There are multiple separate Terraform deployments within this repository.

`aws_site_juice_consul` deploys a Volterra AWS site and within creates OWASP Juice Shop (on an NGINX autoscale group) and Hashicorp Consul for Service Discovery.  In addition, a Volterra Service Discovery integration with Consul provides the OWASP application instance IP/ports to a Volterra Origin.  A Volterra LB publishes the Origin to the public Internet with WAF protection.  The Consul web console is also exposed to the Internet with a Volterra LB.

`aws_site_ubuntu_desktop` deploys a Volterra AWS site and within creates an Ubuntu Web VDI, which is published via a Volterra Websocket LB to the public Internet.  The Ubuntu Web VDI can be used to demo access to an internal facing Volterra LB.