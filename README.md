# Let's Encrypt with the Ubiquiti EdgeRouter

This guide uses <https://letsencrypt.org/> and <https://github.com/Neilpang/acme.sh>
to generate a valid SSL certificate for the EdgeRouter.

* Does not ever expose the admin GUI to the internet
* 100% /config driven, does not require modification to EdgeOS system files

## Install acme.sh & scripts
```
mkdir -p /config/.acme.sh
curl -o /config/.acme.sh/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
curl -o /config/scripts/reload.acme.sh https://raw.githubusercontent.com/j-c-m/ubnt-letsencrypt/master/scripts/reload.acme.sh
curl -o /config/scripts/renew.acme.sh https://raw.githubusercontent.com/j-c-m/ubnt-letsencrypt/master/scripts/renew.acme.sh
chmod 755 /config/.acme.sh/acme.sh /config/scripts/reload.acme.sh /config/scripts/renew.acme.sh
```

## Configuration

* Connect via ssh to your EdgeRouter and enter configuration mode.
* In the steps below replace/verify the following:
  * subdomain.example.com - FQDN
  * 192.168.1.1 - LAN IP of Router
  * eth0 - WAN device

1. Set DNS record for subdomain.example.com to your public WAN IP.

2. Set listen address for gui to LAN IP.

    ```
    set service gui listen-address 192.168.1.1
    ```

3. Setup static host mapping for FQDN to the LAN IP.

    ```
    set system static-host-mapping host-name subdomain.example.com inet 192.168.1.1
    ```

4. Configure cert-file location for gui.

    ```
    set service gui cert-file /config/ssl/server.pem
    ```

5. Configure task scheduler to renew certificate automatically.

    ```
    set system task-scheduler task renew.acme executable path /config/scripts/renew.acme.sh
    set system task-scheduler task renew.acme interval 1d
    set system task-scheduler task renew.acme executable arguments 'subdomain.example.com eth0'
    ```

6. Initialize your certificate.

    ```
    sudo /config/scripts/renew.acme.sh subdomain.example.com eth0
    ```
7. Commit and save your configuration.

    ```
    commit
    save
    ```

8. Accesss your router by going to <https://subdomain.example.com>