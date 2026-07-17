{
    "$schema": "https://raw.githubusercontent.com/F5Networks/f5-appsvcs-extension/master/schema/latest/as3-schema.json",
    "class": "AS3",
    "action": "deploy",
    "persist": true,
    "declaration": {
        "class": "ADC",
        "schemaVersion": "3.0.0",
        "id": "customerID",
        "label": "customerLabel",
        "remark": "Default virtual for shared services with redirect",
        "${tenant_name}": {
            "class": "Tenant",
            "MultiAppIngress": {
                "class": "Application",
                "${app_name}": {
                    "class": "Service_HTTPS",
                    "virtualAddresses": [
                    "${ virtual_ip }"
                    ],
                    "serverTLS": "sharedTls",
                    "policyEndpoint": "SniTrafficPolicy"
                },
                "sharedTls": {
                    "class": "TLS_Server",
                    "certificates": [
                        {
                            "matchToSNI": "default.namespace.internal",
                            "certificate": "default_namespace_cert"
                        }%{ for apps in app_list},
                        {
                            "matchToSNI": "${apps[1]}",
                            "certificate": "${apps[0]}Cert"
                        }%{ endfor }
                    ]
                },
                "default_namespace_cert": {
                    "class": "Certificate",
                    "remark": "default_namespace_cert_dummy_certs_used_for_demo_only",
                    "certificate": "-----BEGIN CERTIFICATE-----\nMIIDiDCCAnACCQDgnXwWSCu0rjANBgkqhkiG9w0BAQsFADCBhTELMAkGA1UEBhMCR0IxDzANBgNVBAgMBkxPTkRPTjEPMA0GA1UEBwwGTE9ORE9OMQswCQYDVQQKDAJGNTENMAsGA1UECwwEVUtTRTEYMBYGA1UEAwwPYXBwMS5mNWRlbW8uY29tMR4wHAYJKoZIhvcNAQkBFg9hcmNoQGY1ZGVtby5jb20wHhcNMjAxMDAyMTU0MTQ2WhcNMjExMDAyMTU0MTQ2WjCBhTELMAkGA1UEBhMCR0IxDzANBgNVBAgMBkxPTkRPTjEPMA0GA1UEBwwGTE9ORE9OMQswCQYDVQQKDAJGNTENMAsGA1UECwwEVUtTRTEYMBYGA1UEAwwPYXBwMS5mNWRlbW8uY29tMR4wHAYJKoZIhvcNAQkBFg9hcmNoQGY1ZGVtby5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD96QENsd6bpVmrC/YqmO5TcsMMnNYshCNqZvU8F25fxHcFdrJR+H9+c6z0yHf6d47Pm2K0fDPRTjofADUiS0U62xE4wRXgvxN7VkUMWdsTKqde8NLPdSkRqDFXIxTPtcLCk11zpSGGV/GqkY4snDaAvZWQY/qG5ozSqjMbBYAL0FC9sZl7ZSK4FaPkfN8fImR+gTAXEOja1IOyFNgfKJZ2nQW0l79kiNR4lkWgGhrTTI+twx9DHMiKdKZe/fg5Ac2rVMnByM+W4kLHxfu5+pIsp8r4J4jSmUSOUbpFpImScUbVncL5Q+ge9sIk0eaEOGV4foKcyWT5OGhLzM9pq2o7AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAOxe5A6PDt71mgBsn8OccoeLOcreeMmNz1WgNkO+tKjpQyGd2gLUufLXRPdu87MyBC7+fbV84fNtWvMS+19KkprddXNJwVEYo0XUx9o+02lUZPK6GiNK92+ztL81b+7v7/NoiDmG8vWAKDZcX7t+epQDwEOU4vqBaejSzZAkQqVHtEonrdn/IHCD0nST9yDU5z+klT4Auat7KJbdCTlnpmrt/8pZyzyEsZevPvsEl4oVNEdrTtdXEV5S7W+jE4iPQZ/PQriZWKPh5NRIPtHAc8ewxEkhyg9OW+REVR/EV43pACgqUhma0Og7BgA+jQz86je3OZOY2Sj4DXtZROAEvCM=\n-----END CERTIFICATE-----",
                    "privateKey": "-----BEGIN PRIVATE KEY-----\nMIIEwAIBADANBgkqhkiG9w0BAQEFAASCBKowggSmAgEAAoIBAQD96QENsd6bpVmr\nC/YqmO5TcsMMnNYshCNqZvU8F25fxHcFdrJR+H9+c6z0yHf6d47Pm2K0fDPRTjof\nADUiS0U62xE4wRXgvxN7VkUMWdsTKqde8NLPdSkRqDFXIxTPtcLCk11zpSGGV/Gq\nkY4snDaAvZWQY/qG5ozSqjMbBYAL0FC9sZl7ZSK4FaPkfN8fImR+gTAXEOja1IOy\nFNgfKJZ2nQW0l79kiNR4lkWgGhrTTI+twx9DHMiKdKZe/fg5Ac2rVMnByM+W4kLH\nxfu5+pIsp8r4J4jSmUSOUbpFpImScUbVncL5Q+ge9sIk0eaEOGV4foKcyWT5OGhL\nzM9pq2o7AgMBAAECggEBAKBErdSOHFwUb9gGkdhrdauYucNBT/MDaTNlT5Ahnhq2\n8QWy2XXiK9+OdnKAAzNGug8THqeb6j1IamldASznZAh1dJZlUkDteweT+buFEEI1\n3zWPPxGR+11Y0+QTkbRWH1wgFpHDfrjE1Bb9D0fbRo/Wmwxr/xuddPAYXG/G9f79\nuc19OTKxyQexJinOVlnmhWyT6jwYtedd8kcrcpBbV13TEvRpuWvYqoh8iCsUL1oM\nsqH59z1f5j3gEDfnGurZxW78+5tGq3ZsbUbwU+oTROeBBo0WJLCWno4UIUCpvdt3\ni1i8A+/MKEpODwy6qcSEKFrlUsXXPH8s0HmFxDOHIFECgYEA/1e81muSoGk5LkU2\n9XCCV5ODKAXFv1KDGAnhYKrJxm6N/msgfk/77pQxjHffAHv22uOJrnlv5pnHGx1N\npgCXyh+EkITSAgG754PJCYdtsKIl4wJqyK7/k8ziFi9NS1GHg1dfCAJcNbE+3Yfj\n1PN8L1xfpVB2KBAFVrA+/GpJSdkCgYEA/pBSjPy0wzdjFcyxksTt6x8z4P5FPWWp\n0C0emCym/0FEy6uJf7xCJp99feeTzNQhxjNCGmgQKTbvJD4vHl38iZJ4ObtLaGM3\nJ2p+00CfMWSMLb2nGsJQqkjH3L6M9/T/COIWkzxD6VFar4qrYNB1bye525B5EoeM\nkbOTiB761DMCgYEA2htrpgwFFxhKS4e7xjLwYzYRliI4I5CrgeEOrq+z4teUWnnP\nK5XOsJ/NIxtRVOyOk7JAbNQ2DVfVhwekx+NBxNjfN0L8z9IDW2JqWsVfoL0gd6Qc\n6obwsKMVi7Wj5G4jvsDm38SEVyirdjcZGVFSBnJ1EJSGGPp2VPH/G0T+jSECgYEA\nl6hbxer3tiXVPjOIxyvTonQgcDaMAZwDoyZ+R6KyivfTiJNVg2gg8Omr1cqVXz4y\nMOZwx1Kf7i3wIuN5JtpPjZZZUeunbTVOsojbrfed38tLSCTo3SRO8mQRzg0n5sFq\n/1vSnz0UKHhzUomGuFL445QDQi+8MbHXqSYXCs2KGckCgYEA35ljj09Kei2/llEw\n9Z1A0t67fZNyfsyDVEba+w1iMYsp7RAUw+jvGugbOeQX0xvgVW0+88X2mgoF11X7\nN0DjDz6mpnmDrSt3YmOOAWoudjeh/EcIcNmMPiUwNtIBqqXdX4NqZdQqhRtYFYre\nPBTinj1QkAVu3I3aiVKNQOk8vt4=\n-----END PRIVATE KEY-----"
                }%{ for apps in app_list},
                "${apps[0]}Cert": {
                    "class": "Certificate",
                    "remark": "${apps[0]}Cert",
                    "certificate": "${apps[3]}",
                    "privateKey": "${apps[4]}"
                }%{ endfor },
                "SniTrafficPolicy": {
                    "class": "Endpoint_Policy",
                    "rules": [
                        {
                            "name": "default",
                            "actions": [
                                {
                                    "type": "httpRedirect",
                                    "event": "request",
                                    "location": "https://sorrypage.internal"
                                }
                            ]
                        }%{ for apps in app_list},
                        {
                            "name": "${apps[0]}",
                            "conditions": [
                                {
                                    "type": "sslExtension",
                                    "event": "ssl-client-hello",
                                    "serverName": {
                                        "operand": "equals",
                                        "values": [
                                            "${apps[1]}"
                                        ]
                                    }
                                }
                            ],
                            "actions": [
                                {
                                    "type": "forward",
                                    "event": "request",
                                    "select": {
                                        "pool": {
                                            "use": "${apps[0]}_pool"
                                        }
                                    }
                                }
                            ]
                        }%{ endfor }
                    ]
                }%{ for apps in app_list},
                "${apps[0]}_pool": {
                    "class": "Pool",
                    "monitors": [
                        "http"
                    ],
                    "members": [
                        ${jsonencode({
                            "servicePort": 80,
                            "serverAddresses": [for members in apps[5] : "${members}"],
                        })}
                    ]
                }%{ endfor }
            }
        }
    }
}