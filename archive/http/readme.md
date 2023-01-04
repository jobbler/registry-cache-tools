# Using this Caching and Registry Server

This server is IPv4 and IPv6 enabled.

This registry server contains this readme file as well as files in the following directories:
- [/cache](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache)

    This directory contains the rhcos images
- [/registry](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry)

    This directory contains the server certificate, registry authenticate file, and trust bundle/mirrors file.

The directory hierarchy of this server is as follows:
```bash
/registry
    se-cache.crt                      # Certificate or server
    se-cache-auths.json               # Registry credentials
    se-cache-trust-bundle.yml        # Trust bundle and mirrors configuration

/cache
    rhcos-*-openstack.x86_64.qcow2.gz
    rhcos-*-qemu.x86_64.qcow2.gz
    4.3.8
        openshift-client-linux.tar.gz
        rhcos.json
        oc
        openshift-baremetal-install
        release.txt
    4.3.9
        openshift-client-linux.tar.gz
        rhcos.json
        oc
        openshift-baremetal-install
        release.txt
    4.3.10
        openshift-client-linux.tar.gz
        rhcos.json
        oc
        openshift-baremetal-install
        release.txt
    latest-4.3 -> 4.3.10         # This is a link to the 4.3.10 (or latest) directory
```

## Fully Disconnect Installs

To perform a fully disconnected installation, you must perform steps from both the `Using the Registry` and `Using the Cache`


## Using the Registry

To use this registry, you must import its certificate into the CA Trusts of
of your system.

The files needed to use this registry are located in the [/registry](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry) directory.

### CA Trusts
Add the certificate to the CA Trusts on any server that will be accessing the registry. The following commands will add the certificate to the servers local CA Trusts.
```bash
  sudo wget http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache.crt \
       -O /etc/pki/ca-trust/source/anchors/se-cache.crt

  sudo update-ca-trust extract
```

### Installing Systems from this registry

#### Installing Using the [`Ansible-IPI-Install Playbook`](https://github.com/openshift-kni/baremetal-deploy/tree/master/ansible-ipi-install)

To install OCP using this registry and the playbooks, you must download the
[se-cache-auths.json](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache-auths.json)
and
[se-cache-trust-bundle.yml](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache-trust-bundle.yml)
files.

You must define the following in your inventory file when using the playbooks.
Make sure to change the paths to point to the files you just downloaded.
```bash
[registry_host]
se-cache.cloud.lab.eng.bos.redhat.commit

[registry_host:vars]
disconnected_registry_auths_file=/path/to/se-cache-auths.json
disconnected_registry_mirrors_file=/path/to/se-cache-trust-bundle.yml
```

You must also make sure to have installed the registry servers certificate into the CA Trusts of the `[provisioner]` host that is defined in the inventory file.


#### Installing Without Using the Ansible-IPI-Install playbooks

##### Authentication Credentials
The authentication credentials on this server are in the file named
[`se-cache-auths.json`](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache-auths.json)
The user name and password, if needed, are `dummy:dummy`

The credentials must be added to the pull secret file that is being used to install OCP.
Adding the credentials to your existing pull secret can be easily done using if the `jq` command is installed on your system. Run the following command, making sure you change the appropriate pieces as follows:

> Change `PULLSECRET_FILE` to be the filename of your current pull secret file.

> Change `NEW_PULLSECRET_FILE` to be the filename to write the combined pull secret to.

```bash
 curl http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache-auths.json \
  | sed "s/^.*$/cat PULLSECRET_FILE \
  | jq '.auths += &'/" \
  | bash > NEW_PULLSECRET_FILE
```

Use the NEW_PULLSECRET_FILE when installing OCP.

##### Trust Bundle and Mirror Information
The [`se-cache-trust-bundle.yml`](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache-trust-bundle.yml)
must be appended to the contents of the `install-config.yml` file.
This file contains the servers certificate and mirror information

```bash
  curl -sS http://se-cache.cloud.lab.eng.bos.redhat.com:8080/registry/se-cache-trust-bundle.yml \
      >> install-config.yml
```





## Using the Cache

The caching server hosts files such as the RHCOS images needed for installation.
The files are available under the [/cache](http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache) directory.

### Installing Systems using this Cache

#### Installing Using the [`Ansible-IPI-Install Playbook`](https://github.com/openshift-kni/baremetal-deploy/tree/master/ansible-ipi-install)

To use this cache to deploy OCP, you must set cache_enabled to True in your inventory file and also set values for bootstraposimage and clusterosimage.

Setting these will pull the RHCOS images from this cache server. But it will still access the external sites to get some versioning information.

To have your installation get all its files and information from this server, you must also set the `webserver_url` value to point to this cache server. This is recommended.

The values for bootstraposimage and clusterosimage should point to the URL of the images on the cache server and include their sha256 checksums.

The sha256 checksums are in the `rhcos.json` files.

The `bootstraposimage` is the `qemu` image listed in the `rhcos.json` file.
The sha256 checksum is the `uncompressed_sha` field in the file for the `qemu` image.

The `clusterosimage` is the `openstack` images listed in the `rhcos.json` file.
The sha256 checksum is the `sha256` field in the file for the `openstack` image.

The following, when added to the inventory file, will get all the files it needs from this server. Change the values as needed.
```bash
[all:vars]
cache_enabled=True

webserver_url=http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache

bootstraposimage=http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache/rhcos-44.81.2
02004250133-0-qemu.x86_64.qcow2.gz?sha256=7d884b46ee54fe87bbc3893bf2aa99af3b2d31f2e19a
b5529c60636fbd0f1ce7
clusterosimage=http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache/rhcos-44.81.202
004250133-0-openstack.x86_64.qcow2.gz?sha256=370a5abf8486d2656b38eb596bf4b2103f8d3b1fa
aca8bfb2f086a16185c2d1b
```


#### Installing Without Using the `Ansible-IPI-Install Playbook`

All the files needed to perform an installation are available under the /cache directory of this server.

Use the `rhcos.json` file under the `/cache/`**`version`** directory to determine which rhcos images are needed for the OCP version you are installing.

Under the `platform: -> baremetal:` section of the `install-config.yaml` file, the `bootstrapOSImage` and `clusterOSImage` values must be set.

The values are determined the same as `bootstraposimage` and `clusterosimage` from the section "Installing Using the Ansible-IPI-Install Playbook" section.

```bash
platform:
  baremetal:
    bootstrapOSImage: http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache/rhcos-44.81.202004250133-0-qemu.x86_64.qcow2.gz?sha256=7d884b46ee54fe87bbc3893bf2aa99af3b2d31f2e19ab5529c60636fbd0f1ce7
    clusterOSImage: http://se-cache.cloud.lab.eng.bos.redhat.com:8080/cache/rhcos-44.81.202004250133-0-openstack.x86_64.qcow2.gz?sha256=370a5abf8486d2656b38eb596bf4b2103f8d3b1faaca8bfb2f086a16185c2d1b
```
