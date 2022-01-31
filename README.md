# volterra-quickdemos

There are two separate deployments in this repository.

The first deploys a Volterra AWS site and within creates OWASP Juice Shop (on an NGINX autoscale group) and Hashi Consul for Service Discovery.  In addition, a Volterra Service Discovery integration with Consul provides the OWASP application instance IP/ports to a Volterra Origin.  A Volterra LB publishes the Origin to the public Internet with WAF protection.  The Consul web console is also exposed to the Internet with a Volterra LB.

The second deploys a Volterra AWS site and within creates an Ubuntu Web VDI, which is published via a Volterra LB to the public Internet.  The Ubuntu Web VDI can be used to demo access to an internal facing Volterra LB.