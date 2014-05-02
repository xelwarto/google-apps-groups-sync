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

require 'singleton'
require 'rubygems'
require 'yaml'
require 'json'
require 'net-ldap'
require 'google/api_client'
require 'google/api_client/client_secrets'

module Google
  module GroupSync
    autoload :App, "GroupSync/app"
    autoload :Config, "GroupSync/config"
    autoload :Log, "GroupSync/log"
    autoload :Util, "GroupSync/util/util"
    autoload :Constants, "GroupSync/util/constants"
    autoload :GapiHandler, "GroupSync/gapi_handler"
    autoload :LdapHandler, "GroupSync/ldap_handler"
    autoload :CacheHandler, "GroupSync/cache_handler"
  end
end
