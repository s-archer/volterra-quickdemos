{
    "f5-tenants:tenant": [
        {
            "name": "${tenant_name}",
            "config": {
                "type": "GENERIC",
                "image": "${f5xc_sw_bundle}",
                "nodes": [
                    1
                ],
                "dhcp-enabled": true,
                "dag-ipv6-prefix-length": 128,
                "vlans": [
                    3030,
                    3206
                ],
                "cryptos": "enabled",
                "vcpu-cores-per-node": 4,
                "memory": "16384",
                "storage": {
                    "size": 100
                },
                "running-state": "deployed",
                "mac-data": {
                    "f5-tenant-l2-inline:mac-block-size": "small"
                },
                "appliance-mode": {
                    "enabled": false
                },
                "f5-tenant-metadata:metadata": ${metadata}
            }
        }
    ]
}