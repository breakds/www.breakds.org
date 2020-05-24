---

title: "Declarative Docker Container Service in NixOS"
subtitle: "Replace docker-compose with Nix Using Filerun as An Example"
summary: ""
authors: [breakds]
tags: ["docker", "service", "filerun", "nixos"]
categories: ["nixos", "docker"]
date: 2020-02-08T14:10:04-08:00
lastmod: 2020-05-24T09:37:04-08:00
featured: false
draft: false

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
# Focal points: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight.
image:
  caption: ""
  focal_point: ""
  preview_only: false

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
---

## Important Update 2020.05.24

After upgrading to 20.03 version of NixOS, the docker container starts
to use the container's actual name instead of its systemd service's
name to address the container. This means that to specify the database
container from the filerun web server's container, you need to change
the value of `FR_DB_HOST` from `docker-filerun-mariadb.service` to
`filerun-mariadb`.

## The Problem

One of the biggest convenience you have in NixOS is that many of the
services you want to run are already coded as a "service". This means
that you can easily spin up a service like openssh with

```nix
services.openssh.enable = true;
```

In fact, you can find a whole lot of such predefined services with
`services.` prefix in the [NixOS
Options](https://nixos.org/nixos/options.html#services.) site.

I also run [FileRun](https://www.filerun.com/) as my NAS server
(similar to [NextCloud](https://nextcloud.com/) but I found FileRun to
be more user friendly and hassle-free). The official [setup
guide](https://docs.filerun.com/docker) illustrated how to use [Docker
Compose](https://docs.docker.com/compose/) to run the service. I found
it ok to run the services with docker containers, but having to use
`docker-compose` to manage the containers make it **less consistent**
and **less automatic** comparing with my other services. 

1. Since the service is not managed in the NixOS configuration, I have
   to manually bring it up and down with `docker-compose`.
2. All the other services are managed automatically, and the
   declarative configuration makes them easier to manage. I want my
   FileRun instance to enjoy that as well.
3. In the future I might want to have more container-based services.
   Experimenting with nix-native docker container-based services can
   be helpful for that purpose.

Therefore, I decided to write a nix service to replace the
`docker-compose` based solution, which is then documentated in this
post.

## The Original Docker-Compose

The docker compose (slightly adapted from the online doc provided by
FileRun) looks like below:

```
version: '2'

services:
  db:
    image: mariadb:10.1
    environment:
      MYSQL_ROOT_PASSWORD: filerunpasswd
      MYSQL_USER: filerun
      MYSQL_PASSWORD: filerunpasswd
      MYSQL_DATABASE: filerundb
    volumes:
      - /home/delegator/filerun/db:/var/lib/mysql

  web:
    image: afian/filerun
    environment:
      FR_DB_HOST: db
      FR_DB_PORT: 3306
      FR_DB_NAME: filerundb
      FR_DB_USER: filerun
      FR_DB_PASS: filerunpasswd
      APACHE_RUN_USER: delegator
      APACHE_RUN_USER_ID: 600
      APACHE_RUN_GROUP: delegator
      APACHE_RUN_GROUP_ID: 600
    depends_on:
      - db
    links:
      - db:db
    ports:
      - "6000:80"
    volumes:
      - /home/delegator/filerun/web:/var/www/html
      - /home/delegator/filerun/user-files:/user-files
```

It basically defines 2 docker containers, one for the databse and one
for the FileRun web server itself, which is based on PHP and Apache. I
know little about both technologies (part of the reason why I left
them managed by docker containers with official images).

One thing that worths emphasizing is that in order to setup the
communication between those two containers, a **link** is configured
for the web server container.

## The Database Container

With the new `docker-containers` option in NixOS configuration, bring
up the MariaDB docker container is as simple as

```nix
docker-containers."filerun-mariadb" = {
  image = "mariadb:10.1";
  environment = {
    "MYSQL_ROOT_PASSWORD" = "randompasswd";
    "MYSQL_USER" = "filerun";
    "MYSQL_PASSWORD" = "randompasswd";
    "MYSQL_DATABASE" = "filerundb";
  };
  volumes = [ "/home/delegator/filerun/db:/var/lib/mysql" ];
};
```

This is basically a direct translation of the first half in the
previous docker-compose file. Nothing intresting yet.

To verify that it actually works, let's run `docker ps`, and it will
show the container with name `docker-filerun-mariadb.service` (note
the naming convention). We can get into the docker container with

```bash
$ docker exec -it docker-filerun-mariadb.service /bin/bash
```

And once you are in the docker, the command

```
mysql -u filerun -prandompasswd filerundb
```

should get you connected to the database.

## Setting up the Bridge Networks

By reading the documentation on [docker
network](https://docs.docker.com/network/bridge/), it becomes clear to
me that I need to create an user-defined bridge network to put the two
docker containers in it, so that they can communicate with each other.
This is to replicate the behavior "link" in the docker compose setup.

Bridge network can be created with the command `docker network
create`. In order to ensure that such bridge network is up, I am using
a trick that I learned from [KJ](https://kj.orbekk.com/) - write a
oneshot systemd service do that.

```nix
systemd.services.init-filerun-network-and-files = {
  description = "Create the network bridge filerun-br for filerun.";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  
  serviceConfig.Type = "oneshot";
   script = let dockercli = "${config.virtualisation.docker.package}/bin/docker";
           in ''
             # Put a true at the end to prevent getting non-zero return code, which will
             # crash the whole service.
             check=$(${dockercli} network ls | grep "filerun-br" || true)
             if [ -z "$check" ]; then
               ${dockercli} network create filerun-br
             else
               echo "filerun-br already exists in docker"
             fi
           '';
};
```

This makes sure that the network will always be there when it is
needed. To add the db into the bridge network, one extra line would
solve the problem (see the last line).

```nix
docker-containers."filerun-mariadb" = {
  image = "mariadb:10.1";
  environment = {
    "MYSQL_ROOT_PASSWORD" = "randompasswd";
    "MYSQL_USER" = "filerun";
    "MYSQL_PASSWORD" = "randompasswd";
    "MYSQL_DATABASE" = "filerundb";
  };
  volumes = [ "/home/delegator/filerun/db:/var/lib/mysql" ];
  extraDockerOptions = [ "--network=filerun-br" ];
};
```

## The Web Server Container

The web server then follows pretty much the same way as the Database
container.

```nix
docker-containers."filerun" = {
  image = "afian/filerun";
  environment = {
    "FR_DB_HOST" = "filerun-mariadb";  # !! IMPORTANT
    "FR_DB_PORT" = "3306";
    "FR_DB_NAME" = "filerundb";
    "FR_DB_USER" = "filerun";
    "FR_DB_PASS" = "randompasswd";
    "APACHE_RUN_USER" = "delegator";
    "APACHE_RUN_USER_ID" = "600";
    "APACHE_RUN_GROUP" = "delegator";
    "APACHE_RUN_GROUP_ID" = "600";
  };
  ports = [ "6000:80" ];
  volumes = [
    "/home/delegator/filerun/web:/var/www/html"
    "/home/delegator/filerun/user-files:/user-files"
  ];
  extraDockerOptions = [ "--network=filerun-br" ];
};
```

It is in the same bridge network. The most important line (marked
above) here is to set up the value for the environment variable
`"FR_DB_HOST"`. I did some experiment and found that within the same
bridge network, one container uses the other container's name as the
hostname. Since NixOS's `docker-containers` modules make the
convention of naming the container in such a way, I will just put the
other container's name there [^1].

**Important Notes**: If you are using 19.09 or older version of NixOS,
the naming convention is actually different for docker containers.
Nothing more needs to be changed, just make sure your `FR_DB_HOST` is
set to `docker-filerun-mariadb.service` inated.

[^1]: It would be much better if I can directly read the container's
    name from `config.docker-containers.filerun-mariadb`, so that it
    would still work even if the naming convention changes. I could
    not find such interface in `docker-containers` module though.
    
With those, everything should be up and running!    

## Conclusion

A more comprehensive service for FileRun as demonstrated in this
article can be found
[here](https://git.breakds.org/breakds/nixvital/src/branch/master/modules/services/filerun.nix).
I omitted the details about how to add options and various
flexibilities to the service module in this article as those might be
distracting.

I found it to be very simple to spin up docker container based
services with the `docker-containers` module. Hope this can help you
as well.
