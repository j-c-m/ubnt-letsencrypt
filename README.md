# Let's Encrypt with the Ubiquiti EdgeRouter

This guide uses <https://letsencrypt.org/> and <https://github.com/Neilpang/acme.sh>
to generate a valid SSL certificate for the EdgeRouter.

* Does not ever expose the admin GUI to the internet
* 100% /config driven, does not require modification to EdgeOS system files

## Install acme.sh & scripts
```
mkdir -p /config/.acme.sh /config/scripts
curl -o /config/.acme.sh/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
curl -o /config/scripts/renew.acme.sh https://raw.githubusercontent.com/j-c-m/ubnt-letsencrypt/master/scripts/renew.acme.sh
chmod 755 /config/.acme.sh/acme.sh /config/scripts/renew.acme.sh
```

## Configuration

* In the steps below replace/verify the following:
  * subdomain.example.com - FQDN
  * 192.168.1.1 - LAN IP of Router
* Configure DNS record for subdomain.example.com to your public WAN IP.
* Connect via ssh to your EdgeRouter and enter configuration mode.

1. Setup static host mapping for FQDN to the LAN IP.

    ```
    set system static-host-mapping host-name subdomain.example.com inet 192.168.1.1
    ```

2. Configure cert-file location for gui.

    ```
    set service gui cert-file /config/ssl/server.pem
    set service gui ca-file /config/ssl/ca.pem
    ```

3. Configure task scheduler to renew certificate automatically.

    ```
    set system task-scheduler task renew.acme executable path /config/scripts/renew.acme.sh
    set system task-scheduler task renew.acme interval 1d
    set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com'
    ```

    You can include additional common names for your certificate, so long as they resolve to the same WAN address:

    ```
    set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com -d subdomain2.example.com'
    ```

4. Initialize your certificate.

    ```
    sudo /config/scripts/renew.acme.sh -d subdomain.example.com
    ```

    If you included multiple names in step 4, you'll need to include any additional names here as well.

5. Commit and save your configuration.

    ```
    commit
    save
    ```

6. Accesss your router by going to <https://subdomain.example.com>

## Changelog

    20180213 - Deprecate -i <wandev> option
    20171126 - Add ca.pem for complete certificate chain
             - Temporarily disable http port forwarding during renew
    20171013 - Remove reload.acme.sh
    20170530 - Check wan ip
    20170417 - Stop gui service during challenge
    20170320 - Add multiple name support
    20170317 - Change from standalone to webroot auth using lighttpd
    20170224 - Bug fixes
    20170110 - Born
