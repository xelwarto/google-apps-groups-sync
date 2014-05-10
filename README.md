# Google Apps Groups Sync

<dl>
  <dt>Author</dt><dd>Ted Elwartowski (<a href="mailto:xelwarto.pub@gmail.com">xelwarto.pub@gmail.com</a>)</dd>
  <dt>Copyright</dt><dd>Copyright © 2014 Ted Elwartowski</dd>
  <dt>License</dt><dd>Apache 2.0 - http://www.apache.org/licenses/LICENSE-2.0</dd>
</dl>

## Description

The Google Apps Groups Sync is an application used to sync user groups from a standard v3 LDAP directory to Google Apps. The application will manage adding and deleting members and owners from groups with in a specific Google Apps domain. The application will also create any groups which are present in the LDAP directory and not in Google Apps.

This application is not meant to be a replacement of the Google Apps Directory Sync (GADS - https://support.google.com/a/answer/106368), rather it has been designed to augment the sync process by providing additional functionality which may not be possible with the GADS. The sync of LDAP groups with the GADS can be limiting which is why this application was developed. The main purpose of this application was to provide a sync of specific (not all) groups in the LDAP directory while still allowing users to manage groups with in the Google Groups interface.

## Installation

####Installation Requirements
* Ruby - version 1.9.3 or higher
  * The application has been fully tested on Ruby 2.1.1
  * The **ruby** executable and/or Ruby bin directory must be properly defined in your shell PATH for the application to execute correctly.

####Install Required Ruby GEMS

```bash
gem install google-api-client
gem install net-ldap
gem install httparty
```

####Application Installation
The application can be cloned or downloaded directly from GitHub. Assuming you have the correct version of Ruby defined in your shell PATH and you have installed the required Ruby GEMS, you should be able to execute the **ga-gs** script located in the **bin** directory.

## Configuration
The default application configuration file is **config/application.rb**. This is the configuration file the application will attempt to load if no other configuration file is specified with a command line option. A different or alternate configuration file can be specified using the **--cfg** option described in the application usage section. The default application configuration file provides documentation on each of the available configuration options.

####Configuration Sections
The configuration file is separated in to the following sections:

* General Configuration (**config**) - Configuration options which are global to the application
* Google API Configuration (**config.google**) - Configuration options which are specific to the Google API
* LDAP Configuration (**config.ldap**) - Configuration options which are specific to the LDAP Connection
* LDAP Search Configuration (**config.ldap.search**) - Configuration options which are specific to the LDAP Searches

####Application Connectivity
* The application will need to be able to communicate with the LDAP directory server usually on ports 389/tcp or 636/tcp. Please note: connectivity via ldaps (SSL) is not available at this time.
* The application need standard web access to the internet on ports 80/tcp (HTTP) and 443/tcp (HTTPS). This is used to communicate with the Google servers when making API requests.

####Google API Setup

**Note: For all actions which require you to login to Google (Admin Console, Developer Console, Verification), you should be using the Google Apps domain admin user account or an account which has administrative rights to the Google Apps domain.**

#####Enabling API Support
API support has to be enabled in your Google Apps domain for this application to work properly. Documentation on how to enable API support can be found here https://support.google.com/a/answer/60757.

#####Client Secrets File
This application makes use of the Google API for making changes to the groups in Google Apps. The API requests require proper authentication and authorization through the use of OAuth 2.0. This requires that you first obtain a **client_secrets.json** file which contains the required API credentials. To obtain this file you must first create a project in the developer console https://console.developers.google.com. A good article of how to setup a project and generate the client secrets file can be found here https://code.google.com/p/google-apps-manager/wiki/CreatingClientSecretsFile. 

The **client_secrets.json** file is normally stored in the application **config** directory though you can choose to store it in another location by changing the **config.google.secrets_file** configuration option. The **client_secrets.json** file should be protected and the appropriate permissions should be applied to ensure the file is not accessible by anyone other than the application runtime user.

#####Authoriztion and Verification
The application requires the configuration of a refresh token used in conjunction with the **client_secrets.json** file to obtain an access token. The access token is then used to authorize API requests made by the application. The application contains a **setup** command which allows you to obtain the refresh token once you have the **client_secrets.json** file. The application setup provides the required steps to authorize the application and verify the authentication.

##Application Setup
The application setup is a run once command only required to obtain the refresh token which is then stored in the configuration file. The setup command should not need to be ran again unless the **client_secrets.json** file has changed.

* After adding the **client_secrets.json** file to the configuration run the **setup --verify** command. This will produce a website URL for the authorization and verification of the application. Using a web browser copy and paste the URL in the browser location. You will be directed to login and then accept the application authorization. Upon accepting the authorization you will be provided a verification code (temp access token).
```bash
bin/ga-gs setup --verify
```
*  Using the code provided during the authorization run the **setup --validate <code>** command. If the validation of the verification code is successful this command will produce the refresh token. The refresh token value should then be added to the **config.google.refresh_token** configuration option in the configuration file.
```bash
bin/ga-gs setup --validate CODE
```

## Application Usage

The application is executed using the **ga-gs** script located in the **bin** directory of the application root. 
```bash
bin/ga-gs COMMAND OPTIONS
```

The application has the following commands and options:
#### Commands
* **setup** - Provides function to obtain the necessary Google API authorization for the application.
  * **--verify** - Generates an authorization URI used for verification of the application authorization.
  * **--validate <code>** -  Validates the authorization code provided during the application authorization. A refresh token will be provided if the validation is successful. The refresh token should be added to the application configuration file.
* **cache** - Provides function to manage the application group cache, the following options are valid with this command:
  *   **--rebuild** - Preforms a full rebuild of the application group cache. This will remove all existing cache files from the cache directory. The rebuild option will query the LDAP and Google API for a list of groups and then rebuild the application group cache based upon the matching groups. *It is important to first run a rebuild prior to executing a sync update as the sync will try to refresh the cache. A refresh on an empty cache will take much longer than a rebuild.*
  *   **--refresh** - Performs a refresh of the application group cache. This will NOT remove the existing cache file from the cache directory. The existing cache files will be used to build the Google group list and then compare it with the list of LDAP groups, any missing Google groups will be retrieved via the Google API and then create a corresponding cache file. *Do NOT run a refresh on an empty cache directory, this will result in a much longer time to build the cache than a rebuild.*
* **sync** - Provides function to sync the LDAP group information to the Google Apps domain, the following options are valid with this command:
  * **--update** - Performs a sync update on the Google domain groups. This will query the LDAP and build of list of LDAP groups including group members and owners. Using the application group cache the update will compare the LDAP groups to the Google groups and update membership as needed via the Google API. When an update is performed on a Google domain group the associated application group cache is also updated.

#### Options
* **--help** - Display the application usage.
* **--quiet** - Executes the application in quiet mode which will suppress all output to the console except errors and fatal errors.
* **--debug** - Enables debug mode for application execution. This will provide extended logging information during the execution of the application.
* **--nocolor** - Disables the the logging out colors. This is useful when capturing the application execution output.
* **--cfg <config_file>** - Specifies to use a different application configuration file other than the default. The default application configuration file is: **config/application.rb**. If the supplied configuration file location is not an absolute path then the config file will be relative to the application root directory.

### Usage Examples
**Display application usage**
```bash
bin/ga-gs --help
```
**Rebuild the group cache**
```bash
bin/ga-gs cache --rebuild
```
**Refresh the group cache**
```bash
bin/ga-gs cache --refresh
```
**Sync the LDAP groups to Google Apps**
```bash
bin/ga-gs sync --update
```
**Execute a sync with no output**
```bash
bin/ga-gs sync --update --quiet
```
**Execute a sync in debug mode**
```bash
bin/ga-gs sync --update --debug
```
**Execute with other config file**
```bash
bin/ga-gs sync --update --cfg config/app2.rb
```
