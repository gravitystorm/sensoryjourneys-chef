This is a collection of chef recipies that set up the server for Sensory Journeys.
You might need to customise them for your own situation, and pull requests
are very welcome.

# Setup

This is designed to use chef-solo. First we need to grab this repository and
prep the cookbooks, then install chef-solo, then chef can take care of the rest.
The base system is ubuntu-server 11.04 so there's not much installed already.

    $ sudo apt-get install git
    $ git clone https://github.com/gravitystorm/sensoryjourneys-chef.git
    $ cd sensoryjourneys-chef/

(From this point on, we could just make a magic script to do the rest.)

Now, we need to install chef. We're using chef 0.10 from the Opscode apt
repository.

    echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
    sudo mkdir -p /etc/apt/trusted.gpg.d
    gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
    gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
    sudo apt-get update
    sudo apt-get install opscode-keyring # permanent upgradeable keyring
    sudo apt-get upgrade
    sudo apt-get install chef

When you are prompted for the server url, enter "none"

# Running chef

At this point, chef can take care of everything else.

    $ cd ~
    $ sudo chef-solo -c sensoryjourneys-chef/solo.rb -j sensoryjourneys-chef/node.json

It's easy to run chef again - for example, in order to deploy the latest version.

# Updating the cookbooks

If the cookbooks themselves change - for example, if you add another package,
or change the contents of one of the templates, you'll need to update and rebundle
the cookbooks, then run chef-solo

    $ cd sensoryjourneys-chef
    $ git pull
    $ cd ~
    $ sudo chef-solo -c sensoryjourneys-chef/solo.rb -j sensoryjourneys-chef/node.json
