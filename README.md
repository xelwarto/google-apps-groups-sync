# Google Apps Groups Sync (GAGS)

<dl>
  <dt>Author</dt><dd>Ted Elwartowski (<a href="mailto:xelwarto.pub@gmail.com">xelwarto.pub@gmail.com</a>)</dd>
  <dt>Copyright</dt><dd>Copyright © 2014 Ted Elwartowski</dd>
  <dt>License</dt><dd>Apache 2.0 - http://www.apache.org/licenses/LICENSE-2.0</dd>
</dl>

## Description

## Installation

## Configuration

## Application Usage

The application is executed using the **gags** script located in the **bin** directory of the application root. 
```bash
bin/gags COMMAND OPTIONS
```

The application has the following commands and options:
#### Commands
* **cache** - Provides function to manage the application group cache, the following options are valid with this command:
  *   **--rebuild** - Preforms a full rebuild of the application group cache. This will remove all existing cache files from the cache directory. The rebuild option will query the LDAP and Google API for a list of groups and then rebuild the application group cache based upon th matching groups. *It is important to first run a rebuild prior to executing a sync update as the sync will try to refresh the cache. A refresh on an empty cache will take much longer than a rebuild.*
  *   **--refresh** - Performs a refresh of the application group cache. This will NOT remove the existing cache file from the cache directory. The existing cache files will be used to build the Google group list and then compare it with the list of LDAP groups, any missing Google groups will be retrieved via the Google API and then create a corresponding cache file. *Do NOT run a refresh on an empty cache directory, this will result in a much longer time to build the cache than a rebuild.*
* **sync** - Provides function to sync the LDAP group information to the Google Apps domain, the following options are valid with this command:
  * **--update** - Performs a sync update on the Google domain groups. This will query the LDAP and build of list of LDAP groups including group memebrs and owners. Using the application group cache the update will compare the LDAP groups to the Google groups and update membership as needed via the Google API. When an update is performed on a Google domain group the associated application group cache is also updated.

#### Options
* **--help** - Display the application usage.
* **--quiet** - Executes the application in quiet mode which will surpress all output to the console except errors and fatal errors.
* **--debug** - Enables debug mode for application execution. This will provide extended logging information during the execution of the application.
* **--nocolor** - Disables the the logging out colors. This is useful when capturing the application execution output.
* **--cfg <config_file>** - Specfies to use a different application configuration file other than the default. The default application configuration file is: **config/application.rb**. If the supplied configuration file location is not an absolute path then the config file will be relative to the application root directory.

### Usage Examples
**Display application usage**
```bash
bin/gags --help
```
**Rebuild the group cache**
```bash
bin/gags cache --rebuild
```
**Refresh the group cache**
```bash
bin/gags cache --refresh
```
**Sync the LDAP groups to Google Apps**
```bash
bin/gags sync --update
```
**Execute a sync with no output**
```bash
bin/gags sync --update --quiet
```
**Execute a sync in debug mode**
```bash
bin/gags sync --update --debug
```
**Execute with other config file**
```bash
bin/gags sync --update --cfg config/app2.rb
```
