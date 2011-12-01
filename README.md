# Description

A basic wrapper for chef-solo with RightScale integration.

# Requirements

* Linux, OS X or a flavour of *nix (untested on Microsoft Windows)
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

If the Chef packaged in your distribution is considered old e.g. Ubuntu 10.04 uses Chef 0.7, use the RubyGem install method (below).

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

### Install Git

#### RHEL/EL/CentOS

    sudo yum -y install git

#### Debian

    sudo apt-get -y install git git-core

#### Ubuntu

    sudo apt-get -y install git-core

#### Mac OS X

Use http://code.google.com/p/git-osx-installer/

### Install RestConnection && Trollop

    gem install rest_connection trollop --no-rdoc --no-ri

Ensure you have configured `~/.rest_connection` for use with your RightScale account.
For more information, see http://support.rightscale.com/12-Guides/03-RightScale_API/Ruby_RestConnection_Helper
	
### Test installed RubyGems

    ( ruby -e "require 'rubygems'; require 'chef'; require 'rest_connection'; require 'trollop'" && echo 'RubyGems test passed.' ) || echo 'RubyGems test failed!'

### Setup Chef Solo

Configure Chef and Chef Solo as required, see http://wiki.opscode.com/display/chef/Chef+Solo
Run the below commands to ensure the required directorys and files exist.

    mkdir -p /etc/chef /var/chef/cache /var/chef/cookbooks /var/chef/site-cookbooks /var/chef-solo
    touch /etc/chef/solo.rb
    [ -e /etc/chef/node.json ] || echo "{}" > /etc/chef/node.json     # empty json
    touch /var/chef-solo/chef-stacktrace.out
	
### Install chef_solo_wrapper

#### Using Git

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

This example uses the cookbooks_public repository from above. Modify as required for your configuration.

    cat <<EOF> /etc/chef/solo.rb
    file_cache_path "/var/chef-solo"
    cookbook_path "/root/src/cookbooks/cookbooks_public/cookbooks"
    json_attribs "/etc/chef/node.json"
    EOF

	# edit with a text editor
	nano /etc/chef/solo.rb

## First Chef Solo Run

### Test chef_solo_wrapper

This prints the chef-solo-wrapper usage info only which is handy for testing the stack:

    cs -v
    
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

	chef-solo

## Usage Examples

Note: Some of these examples still require testing and may be subject to change.

### Standard chef-solo-wrapper run

    cs

alternate Chef run_list:

    cs --run "recipe[foo::bar]"

alternate Chef config file:

    cs --config /etc/chef/solo-dev.rb

alternate Chef JSON data:

	cs --json /etc/chef/node-dev.json
	
### Using the Ruby and Chef in the RightLink sandbox

	cs --sandbox

### Using a RightScale Server's inputs for attributes

	cs --server 1234
	
### Using a RightScale Server's inputs for attributes

With the RightLink sandbox:

	cs --server 1234 --sandbox

and then saving the attributes:

	cs --server 1234 --sandbox --write

and then locally with the saved attributes:

	cs

and then locally with the rightlink sandbox:

	cs --sandbox

### Run chef-solo-wrapper with verbose

	cs -v

with verbose and debug:

    cs --v --debug
	
### Run chef-solo-wrapper with a dry run

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
