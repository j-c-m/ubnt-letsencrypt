# Let's Encrypt with the Ubiquiti EdgeRouter

This guide uses <https://letsencrypt.org/> and <https://github.com/Neilpang/acme.sh>
to generate a valid SSL certificate for the EdgeRouter.

* Does not ever expose the admin GUI to the internet
* 100% /config driven, does not require modification to EdgeOS system files

## Install acme.sh & scripts

* Connect via ssh to your EdgeRouter and execute the following command.
```
curl https://raw.githubusercontent.com/dotsam/ubnt-letsencrypt/use-hooks/install.sh | sudo bash
```

## Configuration

* In the steps below replace/verify the following:
  * subdomain.example.com - FQDN
  * 192.168.1.1 - LAN IP of Router
* Configure DNS record for subdomain.example.com to your public WAN IP.
* Connect via ssh to your EdgeRouter and enter configuration mode.

1. Initialize your certificate.

    ```
    sudo /config/scripts/acme/setup.sh -d subdomain.example.com
    ```

    You can include additional common names for your certificate, so long as they resolve to the same WAN address:
    
    ```
    sudo /config/scripts/acme/setup.sh -d subdomain.example.com -d subdomain2.example.com
    ```

    The script will issue a certificate and prepare it for use, and then output a set of configuration commands.

3. Enter congiguration commands

    Enter configuration mode
    
    ```
    configure
    ```
    
    And copy and past the commands that were output by the setup script

2. Setup static host mapping for FQDN to the LAN IP.

    If you (wisely) haven't exposed your web interface to the internet at large, you'll need to set a static host mapping so you can access the GUI using your shiny new certificate.

    ```
    set system static-host-mapping host-name subdomain.example.com inet 192.168.1.1
    ```

5. Commit and save your configuration.

    ```
    commit
    save
    ```

6. Accesss your router by going to <https://subdomain.example.com>

## Changelog

    20180915 - Convert script to use acme.sh hooks/commands and built-in --cron command so GUI isn't stopped/started when certs aren't being renewed (dotsam)
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
