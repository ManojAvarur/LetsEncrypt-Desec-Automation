#!/usr/bin/env bash

post_hook() {
    # Add custom logic here

    # restart nginx
    sudo systemctl restart nginx  
}