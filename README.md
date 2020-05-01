BigBlueButton Saltstack Customizations
======================================

This repository contains customizations we used for our BBB server. Most of the modifications came from the [Customizing BBB](https://docs.bigbluebutton.org/2.2/customize.html) and [Configure Firewall](https://docs.bigbluebutton.org/2.2/configure-firewall.html) pages. 


They take the form of [SaltStack](https://docs.saltstack.com/en/latest/) configuration files. 

Our primary motivation in releasing them is as examples you can study and implement for your own installation. You will NOT be able to run the scripts without customization (you will need to change the `top.sls` and `pillar` files at the very least.) 



Environment Details
----------------------

These scripts were developed using the following environment: 

- Ubuntu 16.04 (amd64) 
- behind a NAT firewall
- BigBlueButton 2.2.2
- Salt 2017.7.4 using the following repo: `deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7 xenial main`


Running the configuration states
--------------------------------

We recommend NOT attempting to run these configurations as-is, but rather to use them as documentation for your own installations. 

If you really want to run them, here are some deliberately-vague instructions: 

- If you have a SaltStack server then you should know where to put the files.
- If you do not have a SaltStack server then you can use [Masterless Salt](https://docs.saltstack.com/en/latest/topics/tutorials/quickstart.html) . Note that we install Salt from an APT repository, not using the install script.

- Install BBB using the `bbb-install.sh` script. Install Let's Encrypt and Greenlight. If you are running behind a firewall you will need to modify the BBB install script by commenting out the check for IP: 

  ```
  if [ "$DIG_IP" != "$IP" ]; then err "DNS lookup for $1 resolved to $DIG_IP but didn't match local $IP."; fi
  ```

  You will also have to ignore the Node 8.x warnings.

- Set up SSH and your firewall rules according to the BBB documentation.

- Edit the pillar data. The `pillar/secrets` folder contains sample files for confidential information that end in `.example` (eg `bigbluebutton-conf.sls.example`). Copy these files to regular `.sls` files (eg `bigbluebutton-conf.sls`) in the `secrets` folder and modify as desired. You will also need to edit the non-secret pillar data.

- Look through the salt states and comment out the ones you do not want. 

- Run `state.highstate` on the files and it will change your installation.


More Disclaimers
----------------

Unfortunately, this is not a support forum for your installation problems. We are releasing these configurations to put more examples on the Internet, not with the offer of endless (unpaid) support in this repo. A better place to seek support is the [BigBlueButton-Setup](https://groups.google.com/forum/#!forum/bigbluebutton-setup) Google Group. 
