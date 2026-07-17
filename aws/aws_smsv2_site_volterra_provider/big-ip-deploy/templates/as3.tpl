                {
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
                                        "{{ vs1_ip }}"
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
                                            "tagValue": "nginx-autoscale",
                                            "addressRealm": "private",
                                            "region": "eu-west-2"
                                        }
                                    ]
                                }
                            }
                        }
                    }
                }