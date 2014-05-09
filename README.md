# Google Apps Groups Sync

<dl>
  <dt>Author</dt><dd>Ted Elwartowski (<a href="mailto:xelwarto.pub@gmail.com">xelwarto.pub@gmail.com</a>)</dd>
  <dt>Copyright</dt><dd>Copyright © 2014 Ted Elwartowski</dd>
  <dt>License</dt><dd>Apache 2.0 - http://www.apache.org/licenses/LICENSE-2.0</dd>
</dl>

## Description

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
