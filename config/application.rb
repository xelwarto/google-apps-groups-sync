# Copyright 2014 Ted Elwartowski <xelwarto.pub@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Google::GroupSync::Config.configure do
  # Default Google Apps Groups Sync Configuration File
  # This is default application configuration file which is loaded when the
  # application is started. The default configuration file can be changed
  # using the --cfg command line option.
  
  
  ### General Application Configuration ###
  
  # config.cache_dir
  # Directory used to store the group cache files - a non-absolute path will
  # be relative to the base application path
  config.cache_dir = 'cache'
  
  
  ### Google API Client Configuration ###
  
  # config.goolge.app_name
  # Application named used to initialize the Google API Client
  config.google.app_name = 'Google Apps Groups Sync'
  
  # config.goolge.app_version
  # Application version used to initialize the Google API Client
  config.google.app_version = Google::GroupSync::Constants.instance.version
  
  # config.goolge.timeout
  # Application timeout (in seconds) when executing Google API client requests,
  # the API request will produce an error if the timeout is exceeded
  config.google.timeout = 20
  
  # config.goolge.secrets_file
  # Google API client authentication secrets file - The client authentication
  # file can be obtained after creating a project and setting up the auth
  # credentials in the Google Developers Console (https://cloud.google.com/console)
  # A non-absolute path will be relative to the base application path
  config.google.secrets_file = 'config/client_secrets.json'
  
  # config.goolge.refresh_token
  # Google API client refresh token - used to fetch an access token for the client
  # authorization
  # The refresh token will be provided when you first run the application setup
  config.google.refresh_token = ''
  
  # config.goolge.domain
  # The Google Apps domain name where the groups will be synced to - this is primary
  # domain for your Google Apps configuration
  config.google.domain = 'goolge.com'
  
  
  ### LDAP Configuration ###
  
  # config.ldap.timeout
  # LDAP server connection timeout - the LDAP connection will produce an error if the
  # connection timeout is exceeded
  config.ldap.timeout = 10
  
  # config.ldap.server
  # LDAP server hostname or IP address
  config.ldap.server = ''
  
  # config.ldap.port
  # Port number which the LDAP server is listening
  config.ldap.port = '389'
  
  # config.ldap.secure
  # Configure LDAPS - configure the LDAP server connection to use encrypted connection
  # This feature currently does not exist in the application and thus only non-secure
  # connections can be made to the LDAP server
  # Open Issue - https://github.com/xelwarto/google-apps-groups-sync/issues/2
  config.ldap.secure = false
  
  # config.ldap.bind_dn
  # The LDAP account Distinguished Name (DN) used to bind to the LDAP server
  # If no account DB is supplied or the LDAP bind fails the application will
  # revert to using an anonymous LDAP bind to connect to the LDAP server
  config.ldap.bind_dn = ''
  
  # config.ldap.bind_pass
  # Password of the account Distinguished Name (DN) used to bind to the LDAP server
  config.ldap.bind_pass = ''
  
  
  ### LDAP Search Configuration ###
  
  # config.ldap.search.timeout
  # LDAP search connection timeout - the LDAP search will produce an error if the
  # search timeout is exceeded
  config.ldap.search.timeout = 60
  
  # config.ldap.search.groups_base
  # The LDAP search base used to retrieving groups from the LDAP server
  config.ldap.search.groups_base = 'ou=groups, dc=google, dc=com'
  
  # config.ldap.search.groups_filter
  # LDAP search filter used to retrieve groups from the LDAP server
  config.ldap.search.groups_filter = '(objectClass=groupOfUniqueNames)'
  
  # config.ldap.search.groups_obj_class
  # LDAP objectClass used to verify groups in LDAP search results
  config.ldap.search.groups_obj_class = 'groupOfUniqueNames'
  
  # config.ldap.search.groups_name_attr
  # LDAP attribute for the group name - this is a required field for Google groups
  config.ldap.search.groups_name_attr = 'cn'
  
  # config.ldap.search.groups_mail_attr
  # LDAP attribute for the group email address - The email address is used as one
  # type of the Google API groupKey and must be present to create or manage Goolge
  # Apps groups
  config.ldap.search.groups_mail_attr = 'mail'
  
  # config.ldap.search.groups_member_attr
  # LDAP attribute for the group members - currently the application only supports
  # group members stored using the LDAP DN
  config.ldap.search.groups_member_attr = 'uniqueMember'
  
  # config.ldap.search.groups_owner_attr
  # LDAP attribute for the group owners - currently the application only supports
  # group owners stored using the LDAP DN
  config.ldap.search.groups_owner_attr = 'owner'
  
  # config.ldap.search.groups_manager_attr
  # LDAP attribute for the group managers - currently the application does not support
  # managing Google group members of the type MANAGER
  # Open Issue - https://github.com/xelwarto/google-apps-groups-sync/issues/3
  config.ldap.search.groups_manager_attr = ''
  
  # config.ldap.search.groups_descr_attr
  # LDAP attribute for the group description - If no group description is present, the
  # group name will be used as the description
  config.ldap.search.groups_descr_attr = 'description'
  
  # config.ldap.search.groups_alias_attr
  # LDAP attribute for the group alias email addresses - currently the application does not
  # support manging group alias email addresses
  # open Issue - https://github.com/xelwarto/google-apps-groups-sync/issues/4
  config.ldap.search.groups_alias_attr = 'mailAlternateAddress'
  
  # config.ldap.search.users_base
  # The LDAP search base used to retrieving users from the LDAP server
  config.ldap.search.users_base = 'ou=users, dc=google, dc=com'
  
  # config.ldap.search.users_filter
  # LDAP search filter used to retrieve users from the LDAP server
  config.ldap.search.users_filter = '(objectClass=person)'
  
  # config.ldap.search.users_obj_class
  # LDAP objectClass used to verify users in LDAP search results
  config.ldap.search.users_obj_class = 'person'
  
  # config.ldap.search.users_mail_attr
  # LDAP attribute for the user email address - The email address is used as one
  # type of the Google API memberKey and must be present to manage Goolge Apps users
  config.ldap.search.users_mail_attr = 'mail'

end
