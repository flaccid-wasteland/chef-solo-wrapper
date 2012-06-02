# Description

A basic wrapper for chef-solo with RightScale integration.

# Requirements

* Linux, Mac OS X or a flavour of *nix (untested on Microsoft Windows)
* Ruby
* RubyGems
* Trollop RubyGem
* Chef (latest 0.10 recommended)
* RestConnection (optional, for RightScale API support)

# Installation

See Quick Start below. More install methods coming.

# Usage

	Usage:
		   cs [options]
	where [options] are:
		--server, -s <s>:   Use attribute data from a RightScale server by nickname or ID.
		   --sandbox, -a:   Use the Ruby environment in the local RightLink sandbox.
		    --config, -c:   Use alternate Chef Solo configuration (default used, ~/solo.rb.)
		  --json, -j <s>:   Use alternate Chef Solo JSON data (default used, ~/node.json.)
		       --dry, -d:   Dry run only, don't run chef-solo.
		   --run, -r <s>:   Use alernative run_list for chef-solo run.
		     --write, -w:   Write back to local JSON file.
	  --loglevel, -l <s>:   The Chef log level to use: debug, info, warn, error, fatal (default: info)
		   --verbose, -v:   Verbose mode.
		     --debug, -e:   Debug mode.
		      --help, -h:   Print usage info and exit.
		   --version, -i:   Print version and exit

# Quick Start

This demonstrates how to prepare a node for testing cookbooks with chef-solo. Skip any steps not required on your host.

## Prepare host machine

Launch a RightScale server, cloud instance, virtual machine (such as VirtualBox) or simply use your desktop computer.
For RightScale integration, an active RightScale user account is required.

## Install Prerequisites

If your Ruby/Chef environment is not yet setup or your are using a fresh virtual machine or instance, follow the generic steps below.

### Install Ruby & RubyGems

Ensure your system has both Ruby and RubyGems available. If starting fresh, they can be installed easily:

#### Debian/Ubuntu

    sudo apt-get -y install ruby rubygems

#### RHEL/EL/CentOS

    sudo yum -y install ruby rubygems

#### Arch Linux

	pacman -S ruby

For more info see https://wiki.archlinux.org/index.php/Ruby

#### Mac OS X

Ruby and RubyGems are preinstalled.

### Install chef_solo_wrapper

Installation by RubyGem is recommended.

#### RubyGem

	sudo gem install chef-solo-wrapper

You may need to action this before hand:

	sudo gem install rdoc-data
	sudo rdoc-data --install

Or, just install with these options:

	sudo gem install chef-solo-wrapper --no-rdoc --no-ri
	
#### Using Git (devel)

	mkdir -p "$HOME/src" && cd "$HOME/src"
	git clone git://github.com/flaccid/chef-solo-wrapper.git
	chmod +x "$HOME/src/chef-solo-wrapper/bin/cs.rb"
	sudo ln -fsv "$HOME/src/chef-solo-wrapper/bin/cs.rb" /usr/local/bin/cs

Ensure that `/usr/local/bin` is in your `PATH`. When using Bash, this can be done on most platforms if not already set: `( grep PATH ~/.bashrc | grep /usr/local/bin ) || echo 'PATH=$PATH:/usr/local/bin' >> ~/.bashrc`
	
### chef-solo-wrapper Quick Setup

Next, you can use chef-solo-wrapper to install Chef and RestConnection.

	sudo cs --setup all --defaults

Or, if you already have a configuration ready to input and/or prefer to not install any gems by default:

	sudo cs --setup all

Show the new configuration:

	cs --setup show

Now you can skip on down to "Checkout Chef Cookbooks" or do a first run without any.

### Install Chef

Skip this section if Chef is already installed (see above).
If the Chef packaged in your distribution is considered old e.g. Ubuntu 10.04 uses Chef 0.7, use the RubyGem install method (below).

#### RHEL/EL/CentOS

    sudo yum -y install chef

#### Debian

	codename=`lsb_release -cs`
	#	codename=squeeze    # or the appropriate code name for your release
	echo "deb http://apt.opscode.com/ $codename main" > /etc/apt/sources.list.d/opscode.list
    mkdir -p /etc/apt/trusted.gpg.d 
    gpg --keyserver keys.gnupg.net --recv-keys 83EF826A 
    gpg --export packages@opscode.com | tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
    apt-get -y update 
    apt-get -y install opscode-keyring # permanent upgradeable keyring
    apt-get -y install chef
	
#### Ubuntu

    sudo apt-get -y install chef

Note: Ubuntu 10.04 LTS uses Chef 0.7.10 so install via Opscode Apt or RubyGem (below) is recommended.

#### Opscode Apt

This is particularly recommended for Debian-based distributions that don't have the chef package available in the particular release (or the chef version of the package is too old).

	DEBIAN_FRONTEND=noninteractive
	sudo mkdir -p /etc/apt/trusted.gpg.d
	gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
	gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
	echo "deb http://apt.opscode.com/ $(lsb_release -cs)-0.10 main" > /etc/apt/sources.list.d/opscode.list
	sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install chef
	
For more information see http://wiki.opscode.com/display/chef/Installing+Chef+Client+on+Ubuntu+or+Debian#InstallingChefClientonUbuntuorDebian-PackageInstallation
	
#### RubyGem (Mac OS X other supported platforms)

Recommended when an OS/distribution does not supply a Chef binary package with its native package management (or you want the latest chef version by rubygem).

    sudo gem install chef --no-rdoc --no-ri

### Install Git

	If needing to check out cookbooks using Git, ensure it is installed on your system.

#### RHEL/EL/CentOS

    sudo yum -y install git

#### Debian/Ubuntu

    sudo apt-get -y install git

#### Mac OS X

Use http://code.google.com/p/git-osx-installer/

#### Arch Linux

    pacman -S git
    
Also ensure that `inetutils` is installed so the hostname command is available to Ohai:

	pacman -S inetutils

### Install RestConnection

This is can be skipped when not using with RightScale (or if RestConnection is already installed from the chef-solo-wrapper Quick Setup).

A RightScript is available for easy install on running RightScale servers (http://www.rightscale.com/library/right_scripts/Install-configure-RestConnecti/lineage/7495).

Ensure you have configured `~/.rest_connection/rest_api_config.yaml` for use with your RightScale account.
For more information, see http://support.rightscale.com/12-Guides/03-RightScale_API/Ruby_RestConnection_Helper

    mkdir -p "$HOME/.rest_connection"
    sudo gem install rest_connection trollop --no-rdoc --no-ri

Note, you may need to install dependencies to build the native extensions on install, e.g.:

	# on centos/el/redhat
	sudo yum -y install libxml2 libxml2-devel libxslt-devel
	
	# on ubuntu|debian
	sudo apt-get -y install libxml2 libxml2-dev libxslt-dev
	
### Test installed RubyGems

    ( ruby -e "require 'rubygems'; require 'chef'; require 'rest_connection'; require 'trollop'" && echo 'RubyGems test passed.' ) || echo 'RubyGems test failed!'

### Chef Solo Configuration

## Setup Chef Solo

Configure Chef and Chef Solo as required, see http://wiki.opscode.com/display/chef/Chef+Solo
Run the below commands (as `root` or using `sudo -i`) to ensure the required directories and files exist:

    mkdir -p /etc/chef /var/chef/cache /var/chef/cookbooks /var/chef/site-cookbooks /var/chef-solo
    touch /etc/chef/solo.rb
    [ -e /etc/chef/node.json ] || echo "{}" > /etc/chef/node.json     # empty json
    touch /var/chef-solo/chef-stacktrace.out

### Checkout Chef Cookbooks

Don't have any cookbooks on your host to play cook with? Check some out quickly (using root):

	src_dest="/usr/src/chef-cookbooks"
	mkdir -p "$src_dest"
	cd "$src_dest"
	[ -e "$src_dest/cookbooks_public/.git" ] && ( cd "$src_dest/cookbooks_public" && git pull ) || git clone git://github.com/flaccid/cookbooks_public.git
	[ -e "$src_dest/cookbooks/.git" ] && ( cd "$src_dest/cookbooks" && git pull ) || git clone git://github.com/flaccid/cookbooks.git
	
These are the same cookbook repositories used with the RightScale Linux Server RL 5.7 ServerTemplate (http://www.rightscale.com/library/server_templates/RightScale-Linux-Server-RL-5-7/lineage/13544).


### Configure cookbooks for Chef Solo

Next, setup the `solo.rb` to be used with `chef-solo`. Modify `/etc/chef/solo.rb` as required for your configuration. Requires root.

This command setups up`solo.rb` for use with the cookbooks from the RightScale Linux Server RL 5.7 ServerTemplate installed above:

	cat <<EOF> /etc/chef/solo.rb
	file_cache_path "/var/chef-solo"
	cookbook_path [ "/usr/src/chef-cookbooks/cookbooks_public/cookbooks", "/usr/src/chef-cookbooks/cookbooks/cookbooks" ]
	json_attribs "/etc/chef/node.json"
	EOF

For RightScale Servers, its easy to just use the cookbooks in the cache created from the RightLink boot:

	#!/bin/bash -e
	
	mkdir -p /etc/chef
	unset cookbook_path
	rs_cookbook_cache_path=/var/cache/rightscale/cookbooks/default		# RL 5.8
	#rs_cookbook_cache_path=/var/cache/rightscale/cookbooks				# RL =< 5.7
	
	for file in "$rs_cookbook_cache_path"/*
	do
	    cookbook_path="$cookbook_path${cookbook_path:+, }\"$file\""
	done

	cat <<EOF > /etc/chef/solo.rb
	file_cache_path "/var/chef-solo"
	cookbook_path [ $cookbook_path ]
	json_attribs "/etc/chef/node.json"
	EOF

and/or modify by hand

	# edit with a text editor
	sudo nano /etc/chef/solo.rb

For more information see http://wiki.opscode.com/display/chef/Chef+Solo

### Configure node.json for Chef Solo

By default, when setting up Chef Solo above, `/etc/chef/node.json` is created with empty json.
The command line options of chef-solo-wrapper (see usage examples below) can be used to provide this file, a run_list or override attributes, however do feel free to configure this file as required.

Example `node.json`:

	{
	  "rs_utils": {
	    "short_hostname":"reddwarf"
	  },
	  "run_list": [ "recipe[rs_utils::default]" ]
	}


## First Chef Solo Run

### Test chef-solo-wrapper

This prints the chef-solo-wrapper usage info only which is handy for testing the stack:

    sudo cs -v
    
You should see a run similar to:

	chef-solo-wrapper 0.0.1.
	options: {"sandbox":false,"run":null,"debug":false,"version":false,"config":false,"json":null,"write":false,"help":false,"dry":false,"server":null,"loglevel":"info","verbose_given":true,"verbose":true}
	Importing Chef RubyGem.
	Starting Chef Solo.
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: *** Chef 0.10.4 ***
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: Run List is []
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: Run List expands to []
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: Starting Chef Run for 01-3m8hh9j.localdomain
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: Chef Run complete in 0.071469 seconds
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: Running report handlers
	[Thu, 01 Dec 2011 07:34:05 +0000] INFO: Report handlers complete

See the examples for practical usage.

### Test chef-solo

You may also like to test chef-solo by itself:

	sudo chef-solo

## Usage Examples

Chef/Solo is intended to be run under root. When chef-solo-wrapper is run without root, sudo will automatically be prepended to the chef-solo command (ensure sudo is configured correctly if not using root directly).
Note: Some of these examples still require testing and may be subject to change.

### Standard chef-solo-wrapper run

    cs

alternate Chef run_list:

    cs --run "recipe[foo::bar]"

alternate Chef config file:

    cs --config /etc/chef/solo-dev.rb

alternate Chef JSON data:

	cs --json /etc/chef/node-dev.json
	
### With the Ruby and Chef in the RightLink sandbox

	cs --sandbox
	
with debug,verbose and Chef debug log_level:

    cs -v --debug --sandbox --loglevel debug

Note: The host system must have RightScale RightLink installed.

### Using a RightScale Server's inputs for attributes

	cs --server 1234

and with the RightLink sandbox:

	cs --server 1234 --sandbox

and then also saving the attributes locally:

	cs --server 1234 --sandbox --write

then with the system's chef-solo and the saved attributes:

	cs

then also with the rightlink sandbox:

	cs --sandbox

### Run chef-solo-wrapper with verbose

	cs -v

with verbose and debug:

    cs -v --debug
	
### Run chef-solo-wrapper as a dry run

    cs --dry

Including verbose and debug modes with a chef debug log_level:

    cs --dry --debug --verbose --loglevel debug

### Print usage info and exit

	cs -h

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
