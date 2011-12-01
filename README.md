# Description

A basic wrapper for chef-solo with RightScale integration.

# Requirements

* Linux, OS X or a flavour of *nix (untested on Microsoft Windows)
* Ruby
* RubyGems
* Trollop RubyGem
* Chef (latest 0.10 recommended)
* RestConnection (optional, for RightScale API support)

# Quick Start

This demonstrates how to prepare a node for testing cookbooks with chef-solo. Skip any steps not required on your host.

## Prepare host machine

Launch a RightScale server, cloud instance, virtual machine (such as VirtualBox) or simply use your desktop computer.
For RightScale integration, an active RightScale user account is required.

## Install Prerequisites

If your Ruby/Chef environment is not yet setup or your are using a fresh virtual machine or instance, follow the generic steps below.

### Install Ruby & RubyGems

#### Debian/Ubuntu

    sudo apt-get -y install ruby rubygems

#### RHEL/EL/CentOS

    sudo yum -y install ruby rubygems

#### Arch Linux

	pacman -S ruby

For more info see https://wiki.archlinux.org/index.php/Ruby

#### Mac OS X

Ruby and RubyGems is preinstalled.

### Install Chef

#### RHEL/EL/CentOS

    sudo yum -y install chef

#### Debian

    codename=squeeze    # or the appropriate code name for your release
    echo "deb http://apt.opscode.com/ $codename main" > /etc/apt/sources.list.d/opscode.list
    mkdir -p /etc/apt/trusted.gpg.d 
    gpg --keyserver keys.gnupg.net --recv-keys 83EF826A 
    gpg --export packages@opscode.com | tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
    apt-get -y update 
    apt-get -y install opscode-keyring # permanent upgradeable keyring
    apt-get -y install chef
	
#### Ubuntu

    sudo apt-get -y install chef

#### Mac OS X

    sudo gem install chef --no-rdoc --no-ri
	
#### RubyGem (other supported platforms)

    gem install chef --no-rdoc --no-ri

### Create chef folders	

    mkdir -p /etc/chef
    mkdir -p /var/chef/cache

### Install Git

#### RHEL/EL/CentOS

    sudo yum -y install git

#### Debian/Ubuntu

    sudo apt-get -y install git

#### Mac OS X

Use http://code.google.com/p/git-osx-installer/

### Install RestConnection && Trollop

    gem install rest_connection trollop --no-rdoc --no-ri

Ensure you have configured ~/.rest_connection for use with your RightScale account.
	
### Test installed RubyGems

    ( ruby -e "require 'rubygems'; require 'chef'; require 'rest_connection'; require 'trollop'" && echo 'RubyGems test passed.' ) || echo 'RubyGems test failed!'

### Setup Chef Solo
 
    mkdir -p /etc/chef /var/chef/cookbooks /var/chef/site-cookbooks /var/chef-solo
    touch /etc/chef/solo.rb
    echo "{}" > /etc/chef/node.json     # empty json
    touch /var/chef-solo/chef-stacktrace.out
	
### Install chef_solo_wrapper

    mkdir -p ~/src && cd ~/src
    git clone git://github.com/flaccid/chef-solo-wrapper.git
    chmod +x ~/src/chef-solo-wrapper/bin/cs.rb
    ln -fsv ~/src/chef-solo-wrapper/bin/cs.rb /usr/local/bin/cs

### Checkout Chef Cookbooks

Don't have any cookbooks on your host to play cook with? Check some out quickly:

    mkdir -p ~/src/cookbooks
    cd ~/src/cookbooks
    git clone git://github.com/flaccid/cookbooks_public.git

### Configure cookbooks for Chef Solo

    cat <<EOF> /etc/chef/solo.rb
    file_cache_path "/var/chef-solo"
    cookbook_path "/root/src/cookbooks/cookbooks_public/cookbooks"
    json_attribs "/etc/chef/node.json"
    EOF

	# edit with a text editor
	nano /etc/chef/solo.rb

## First Chef Solo Run

### Test chef_solo_wrapper (print version only)

    cs -v
    
### Test chef-solo

	chef-solo
	
# License and Author

Author:: [Chris Fordham][flaccid] (<chris@xhost.com.au>)

Copyright:: 2011, Chris Fordham

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
