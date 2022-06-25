# Let's Encrypt with the Ubiquiti EdgeRouter

This guide uses <https://letsencrypt.org/> and <https://github.com/Neilpang/acme.sh>
to generate a valid SSL certificate for the EdgeRouter.

* Does not ever expose the admin GUI to the internet
* 100% /config driven, does not require modification to EdgeOS system files

## Install acme.sh & scripts

* Connect via ssh to your EdgeRouter and execute the following command.
```
curl https://raw.githubusercontent.com/j-c-m/ubnt-letsencrypt/master/install.sh | sudo bash
```

## Configuration

* In the steps below replace/verify the following:
  * subdomain.example.com - FQDN
  * 192.168.1.1 - LAN IP of Router
* Configure DNS record for subdomain.example.com to your public WAN IP.
* Connect via ssh to your EdgeRouter.

1. Initialize your certificate.

    ```
    sudo /config/scripts/renew.acme.sh -d subdomain.example.com
    ```

    You can include additional common names for your certificate, so long as they resolve to the same WAN address:

    ```
    sudo /config/scripts/renew.acme.sh -d subdomain.example.com -d subdomain2.example.com
    ```

2. Enter configuration mode.

    ```
    configure
    ```

3. Setup static host mapping for FQDN to the LAN IP.

    ```
    set system static-host-mapping host-name subdomain.example.com inet 192.168.1.1
    ```

4. Configure cert-file location for gui.

    ```
    set service gui cert-file /config/ssl/server.pem
    set service gui ca-file /config/ssl/ca.pem
    ```

5. Configure task scheduler to renew certificate automatically.

    ```
    set system task-scheduler task renew.acme executable path /config/scripts/renew.acme.sh
    set system task-scheduler task renew.acme interval 1d
    set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com'
    ```

    If you included multiple names in step 1, you'll need to include any additional names here as well.

    ```
    set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com -d subdomain2.example.com'
    ```

6. Commit, save and exit configuration mode.

    ```
    commit
    save
    exit
    ```


7. Accesss your router by going to <https://subdomain.example.com>

## Changelog

    20220624 - Update acme.sh repo to https://github.com/acmesh-official/acme.sh
    20210622 - Update option handling to pass --debug and --force to acme.sh
    20210621 - Default to Let's Encrypt CA
             - Add -f to force renew
    20200419 - Use SIGTERM for GUI service stop
    20200109 - Use systemctl on 2.0 to start GUI service
    20191022 - Prevent sudo error
    20190311 - Initialize certificate first outside of configuration mode
    20180609 - Install script
    20180605 - IPv6 support
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
