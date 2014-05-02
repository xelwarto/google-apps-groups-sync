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
  
  # config.cache_dir
  # Directory used to store the group cache files - a non-absolute path will
  # be relative to the base application path
  config.cache_dir = 'cache'
  
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

end
