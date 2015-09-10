# Docker container deployment tools

**First install?**  Please refer to http://github.com/digitalrebar/doc

## Steps to Use:
  * Make sure docker and docker-compose are installed on the system.
    * https://docs.docker.com/installation/
    * https://docs.docker.com/compose/install/
  * git clone this repo into compose
    * git clone https://github.com/rackn/digitalrebar-deploy deploy
  * Setup the parts
    * cd deploy
    * ./setup
  * docker-compose up
 
## Publish Containers
  * Steps above except `./build_it.sh`

## Config Changes

Some configuration can be changed through the config-dir/api/config
directory.  This gets mapped into the admin container as it boots to 
set the initial configuration.  Users and networks can altered here.

Domain name is set in the common.env file

## ToDo:
  * Convert the logging server to a service.
  * Convert DHCP style to new API-based DHCP server
  * Convert Prov to cobbler.
  * Cobbler Container: Create volume/mountpoints for isos and files
    * Provisioner container maps the existing ~/.cache/digitalrebar/tftproot
      directory into place in the provisioner

