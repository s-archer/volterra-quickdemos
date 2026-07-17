#!/bin/bash

mkdir -p /config/cloud
cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
{
    "runtime_parameters": [],
    "pre_onboard_enabled": [
        {
            "name": "provision_rest",
            "type": "inline",
            "commands": [
                "/usr/bin/setdb provision.extramb 2048"
            ]
        }
    ],
    "extension_packages": {
        "install_operations": [
            {
                "extensionType": "do",
                "extensionVersion": "1.46.0"
            },
            {
                "extensionType": "as3",
                "extensionVersion": "3.53.0"
            },
            {
                "extensionType": "cf",
                "extensionVersion": "1.9.0"
            },
            {
                "extensionType": "fast",
                "extensionVersion": "1.10.0"
            }
        ]
    },
    "extension_services": {
        "service_operations": [
            {
                "extensionType": "do",
                "type": "inline",
                "value":               {
                    "schemaVersion": "1.15.0",
                    "class": "Device",
                    "async": true,
                    "label": "my BIG-IP declaration for declarative onboarding",
                    "Common": {
                        "class": "Tenant",
                        "hostname": "${ hostname }",
                        "admin": {
                            "class": "User",
                            "userType": "regular",
                            "password": "${ admin_pass }",
                            "shell": "bash"
                        },
                        "myDns": {
                            "class": "DNS",
                            "nameServers": [
                                "8.8.8.8"
                            ]
                        },
                        "myNtp": {
                            "class": "NTP",
                            "servers": [
                                "0.pool.ntp.org"
                            ],
                            "timezone": "UTC"
                        },
                        "myProvisioning": {
                            "class": "Provision",
                            "ltm": "nominal"
                        },
                        "external": {
                            "class": "VLAN",
                            "tag": 1001,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": 1.1,
                                    "tagged": false
                                }
                            ]
                        },
                        "external-self": {
                            "class": "SelfIp",
                            "address": "${ external_ip }",
                            "vlan": "external",
                            "allowService": "none",
                            "trafficGroup": "traffic-group-local-only"
                        },
                        "internal": {
                            "class": "VLAN",
                            "tag": 1002,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": 1.2,
                                    "tagged": false
                                }
                            ]
                        },
                        "internal-self": {
                            "class": "SelfIp",
                            "address": "${ internal_ip }",
                            "vlan": "internal",
                            "allowService": "default",
                            "trafficGroup": "traffic-group-local-only"
                        },
                        "dbvars": {
                            "class": "DbVariables",
                            "provision.extramb": 2048
                        }
                    }
                }
            },
            {
                "extensionType": "as3",
                "type": "inline",
                "value":                 {
                    "class": "AS3",
                    "action": "deploy",
                    "persist": true,
                    "declaration": {
                        "class": "ADC",
                        "schemaVersion": "3.22.0",
                        "label": "Sample 1",
                        "remark": "Simple HTTP Service with Round-Robin Load Balancing",
                        "demo_tenant": {
                            "class": "Tenant",
                            "nginx_test_app": {
                                "class": "Application",
                                "nginx_test_app": {
                                    "class": "Service_HTTP",
                                    "virtualAddresses": [
                                        "${ vs1_ip }"
                                    ],
                                    "persistenceMethods": [],
                                    "profileMultiplex": {
                                        "bigip": "/Common/oneconnect"
                                    },
                                    "pool": "web_pool"
                                },
                                "web_pool": {
                                    "class": "Pool",
                                    "monitors": [
                                        "http"
                                    ],
                                    "members": [
                                        {
                                            "servicePort": 80,
                                            "addressDiscovery": "aws",
                                            "updateInterval": 1,
                                            "tagKey": "Name",
                                            "tagValue": "${ app_tag }",
                                            "addressRealm": "private",
                                            "region": "${ region }"
                                        }
                                    ]
                                }
                            }
                        }
                    }
                }
            }
        ]
    }
}
EOF

# curl https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.2.1/dist/f5-bigip-runtime-init-1.2.1-1.gz.run -o f5-bigip-runtime-init-1.2.1-1.gz.run && bash f5-bigip-runtime-init-1.2.1-1.gz.run -- '--cloud aws'

# f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml

# Download
for i in {1..30}; do
    # curl -fv --retry 1 --connect-timeout 5 -L "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.1/dist/f5-bigip-runtime-init-2.0.1-1.gz.run" -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
    curl -fv --retry 1 --connect-timeout 5 -L "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run" -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
done
# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init.gz.run -- "--cloud aws"
# Run
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml