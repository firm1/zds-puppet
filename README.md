# zds

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with zds](#setup)
    * [What zds affects](#what-zds-affects)
4. [Usage - Configuration options and additional functionality](#usage)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module allows to deploy the ZDS project in production environnement. 
This is a community website opensource engine made with django.

This project supports the following OS:
- Debian
- Ubuntu

It should run on Centos, but not yet tested

## Module Description

This project includes the following tools necessary for the operation of ZDS.

- back-end:
     - django: virtualenv, gunicorn (WSGI)
     - solr
     - pandoc
- front-end
     - nodejs
     - npm
- database:
     - mysql
- Web server
     - nginx

Each tool is installed, configured and the services are started

## Setup

### What zds affects

ZDS exposes on port 80 the web service and on port 8983 Solr program.
An entry is reserved in the crontab for automatic indexing (every 20 minutes)

New users are created : nginx, cabal

## Usage

The best way to use ZDS is to use hiera, like this.

```yaml
zds:
    repo:
        author: "zestedesavoir"
        branch: "dev"
    site:
        url: "zestedesavoir.com"
        id: "daily"
    database:
        host: "localhost"
        name: "bdd"
        user: "root"
        password: "SuperPassword"
    front:
        node_version: "v0.10.36"
        logo_url: ""
        color:
            primary: "#F39539"
            secondary: "#C21936"
            body_bg: "#FFF"
            header_hv: "#B03712"
            side_bg: "#F6F6F6"
            side_hv: "#FFF"
    settings:
        name: ""
        litteral_name: ""
        slogan: ""
        abbr: "OC"
        email_contact: ""
        email_noreply: ""
        forum_feedback_users: ""
        long_description: ""
        cnil: ""
        social:
            facebook: "https://www.facebook.com/"
            twitter: "https://twitter.com/"
            google: "https://plus.google.com/"
```


## Development

