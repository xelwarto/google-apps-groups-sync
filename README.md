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
  *   **--rebuild** - Preforms a full rebuild of the application group cache. This will remove all existing cache files from the cache directory. The rebuild option will query the LDAP and Google API for a list of groups and then rebuild the application group cache based upon th matching groups.
  *   **--refresh** - Performs a refresh of the application group cache. This will NOT remove the existing cache file from the cache directory. The existing cache files will be used to build the Google group list and then compare it with the list of LDAP groups, any missing Google groups will be retrieved via the Google API and then create a corresponding cache file.
* **sync** - Provides function to sync the LDAP group information to the Google Apps domain, the following options are valid with this command:
  * **--update** - Updates

#### Options


### Usage Examples
**Display application usage**
```bash
bin/gags --help
```
