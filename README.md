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

* In the steps below replace/verify the following:
  * subdomain.example.com - FQDN
  * 192.168.1.1 - LAN IP of Router
  * eth0 - WAN device
* Configure DNS record for subdomain.example.com to your public WAN IP.
* Connect via ssh to your EdgeRouter and enter configuration mode.

1. Set listen address for gui to LAN IP.

    ```
    set service gui listen-address 192.168.1.1
    ```

2. Setup static host mapping for FQDN to the LAN IP.

    ```
    set system static-host-mapping host-name subdomain.example.com inet 192.168.1.1
    ```

3. Configure cert-file location for gui.

    ```
    set service gui cert-file /config/ssl/server.pem
    ```

4. Configure task scheduler to renew certificate automatically.

    ```
    set system task-scheduler task renew.acme executable path /config/scripts/renew.acme.sh
    set system task-scheduler task renew.acme interval 1d
    set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com -i eth0'
    ```

If you'd prefer, you can additional common names for your certificate, so long as they resolve to the same WAN address:

    ```
    set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com -d subdomain2.example.com -i eth0'
    ```

5. Initialize your certificate.

    ```
    sudo /config/scripts/renew.acme.sh -d subdomain.example.com -i eth0
    ```

If you included multiple names in step 4, you'll need to include any additional names here as well.

6. Commit and save your configuration.

    ```
    commit
    save
    ```

7. Accesss your router by going to <https://subdomain.example.com>
