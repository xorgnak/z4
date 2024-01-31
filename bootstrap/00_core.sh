#!/bin/bash

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list

sudo apt update

sudo apt upgrade -q

sudo apt install -q gum $Z4_PKGS

gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable --ruby

echo "source $HOME/.rvm/scripts/rvm" >> ~/.bashrc

cat <<EOF>~/.screenrc
shell -/bin/bash
caption always "[ %H ] %w"
defscrollback 1024
startup_message off
hardstatus on
hardstatus alwayslastline
screen -t '#' 0 emacs -nw --funcall erc --visit ~/index.org
screen -t '>' 1 /bin/bash
select 1
EOF

exit 0;
