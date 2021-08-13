#!bin/bash
#### Updating Repositories ####

apt-get -y update
apt-get -y upgrade

#### Create MySQL User ####

echo "Let's create a login user on the phpMyAdmin page."
echo "Username: "
read name
if [ -z "$name" ]
then
echo "You have not entered a user!"
else
echo "Success!"
fi

echo "Password: "
read password
if [ -z "$password" ]
then
echo "You have not entered a password!"
else
echo "Success!"
fi
