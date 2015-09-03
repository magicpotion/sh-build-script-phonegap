#!/bin/bash

# The purpose of this script is to automate uploads to PhoneGap Build
# with API on multiple development/deployment servers.

# It needs to be configured with the correct phonegap project id, username and 
# app name, id and API hosts.

# This script should live in project main directory, where the config.xml is.
# you should have a config file with api hostname and app version in your project.


# CONFIGURATION
PHONEGAP_APP_ID= # int
USERNAME=''
# WARNING!! if you specify password, don't commit build file into repository!!!
# if password is not configured it will be asked for every time the script is run
PASSWORD='' 
JS_CONFIG_FILE='www/js/appConfig.js' # specify your js config file with path 


if [ "$1" = "local" ]; then
    echo "  initializing for "$1
    # TODO if local builds are required you have to write it on your own


elif [ "$1" = "phonegap" ]; then
    # define required fields for each server
    if [ "$2" = "host1_live" ]; then
        HOST='var HOST = "http://hostname.live.com/api";'
        APP_ID='com.app.live'
        APP_NAME='App Live'

    elif [ "$2" = "host2_uat" ]; then
        HOST='var HOST = "http://hostname.uat.com/api";'
        APP_ID='com.app.uat'
        APP_NAME='App UAT'

    elif [ "$2" = "host3_staging" ]; then
        HOST='var HOST = "http://hostname.staging.com/api";'
        APP_ID='com.app.staging'
        APP_NAME='App Staging'

    else
        echo " host name should follow phonegap argument, eg. phonegap live"
        echo " use one of the following:"
        echo " host1_live"
        echo " host2_uat"
        echo " host3_staging"
        exit
    fi

    # update version (optional)
    if [ "$3" != "" ]; then
        VERSION="$3"
    fi

    # if passsword is not configured it will be asked for
    if [ "$PASSWORD" == "" ]; then
        read -p "Please enter password for your PhoneGap account : " PASSWORD
    fi


    ORGINAL_HOST=$(head -1 $JS_CONFIG_FILE | tail -1)                   # read orginal host value
    sed -i "1s#.*#$HOST#" $JS_CONFIG_FILE                               # write target host to file

    APP_NAME_NR=$(awk '/<name>/{ print NR; exit}' config.xml)           # finding name line
    APP_ID_NR=$(awk '/id=/{ print NR; exit}' config.xml)                # finding id line
    
    sed -i $APP_ID_NR"s#.*#    id='$APP_ID'#" config.xml                # write target app id
    sed -i $APP_NAME_NR"s#.*#    <name>$APP_NAME</name>#" config.xml    # write target app name 

    if [ $VERSION ]; then
        VERSION_VAR="var APP_VERSION = \"${VERSION//[a-zA-Z= \"]/}\";"
        sed -i "2s#.*#$VERSION_VAR#" $JS_CONFIG_FILE                    # write version to app config
    fi

    echo "  initializing for "$1
    cp -v config.xml www/config.xml       # include correct config
    echo "  tar -czf $2.tar.gz www/"      # pack
    tar -czf "$2".tar.gz www/
    rm -v www/config.xml          


    # PHONEGAP BUILD DEPLOYMENT
    APP_DETAILS='data={"package":"'$APP_ID'","create_method":"file"}'
    echo "  SENDING APP TO PHONEGAP BUILD, PLEASE WAIT ..."
    echo "  curl -F file=@$2.tar.gz -u $USERNAME:$PASSWORD -F $APP_DETAILS https://build.phonegap.com/api/v1/apps/$PHONEGAP_APP_ID"
    curl -X PUT -F file=@"$2".tar.gz -u $USERNAME:$PASSWORD -F $APP_DETAILS https://build.phonegap.com/api/v1/apps/$PHONEGAP_APP_ID
    echo -e "\n\n"
    rm -v "$2".tar.gz                                   # cleanup

    sed -i "1s#.*#$ORGINAL_HOST#" $JS_CONFIG_FILE       # write orginal host back to file


else [ "$1" = "" ]
    echo "  Missing Arguments: Use script with first argument 'local' or 'phonegap'"
    exit
fi
