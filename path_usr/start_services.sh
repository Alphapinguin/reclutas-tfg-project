#!/bin/sh
#This script is made for run services at the end of build docker image
service mysql start && service asterisk start && service apache2 start && /bin/bash