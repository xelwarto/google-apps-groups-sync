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

module Google::GroupSync
  class Config
    include Singleton

    def initialize(cfg=nil)
      @c = Google::GroupSync::Constants.instance
      @log = Google::GroupSync::Log.instance
      @log.info 'Config:Initializing Application Configuration'
    end
    
    def load!
      @log.debug 'Config(load_cfg):Loading Configuration File'
      config.cfg_file ||= @c.cfg_file
      
      cfg = config.cfg_file
      if cfg !~ /^\//
        if !config.app_dir.nil?
          cfg = "#{config.app_dir}/#{config.cfg_file}"
        end
      end
      @log.debug "Config(load_cfg):Configuration file set to: #{cfg}"
      
      if File.file?(cfg)
        begin
          require cfg
          return true
        rescue Exception => e
          @log.error "Config(load_cfg):#{e}"
        end
      else
        @log.error 'Config(load_cfg):unable to locate config file'
      end
      return false
    end
    
    def config
      @config ||= GeneralConfig.new
    end
    
    def self.configure(&block)
      class_eval(&block)
    end
    
    class << self
      def config
        Config.instance.config
      end
    end
    
    protected
    
    class GeneralConfig
      attr_accessor :app_dir, :cfg_file, :cache_dir, :google, :ldap
      
      def initialize
        c = Google::GroupSync::Constants.instance
        
        @app_dir              = nil
        @cfg_file             = c.cfg_file
        @cache_dir            = nil
        @google               = GoogleConfig.new
        @ldap                 = LdapConfig.new
      end
    end
    
    class GoogleConfig
      attr_accessor :app_name, :app_version, :timeout, :secrets_file, :refresh_token, :domain
      
      def initialize
        @app_name             = nil
        @app_version          = nil
        @timeout              = 20
        @secrets_file         = nil
        @refresh_token        = nil
        @domain               = nil
      end
    end
    
    class LdapConfig
      attr_accessor :timeout, :server, :port, :secure, :bind_dn, :bind_pass, :search
      
      def initialize
        @timeout              = 10
        @server               = nil 
        @port                 = nil
        @secure               = false
        
        @bind_dn              = nil
        @bind_pass            = nil
        
        @search               = SearchConfig.new
      end
      
      class SearchConfig
        attr_accessor :timeout, :groups_base, :groups_base, :groups_filter, :groups_obj_class,
                      :groups_name_attr, :groups_mail_attr, :groups_member_attr, :groups_owner_attr,
                      :groups_descr_attr, :groups_alias_attr, :groups_manager_attr, :users_base,
                      :users_filter, :users_obj_class, :users_mail_attr
        
        def initialize
          @timeout              = 60
          
          @groups_base          = nil
          @groups_filter        = nil
          @groups_obj_class     = nil
          @groups_name_attr     = nil
          @groups_mail_attr     = nil
          @groups_member_attr   = nil
          @groups_owner_attr    = nil
          @groups_manager_attr  = nil
          @groups_descr_attr    = nil
          @groups_alias_attr    = nil
          
          @users_base           = nil
          @users_filter         = nil
          @users_obj_class      = nil
          @users_mail_attr      = nil
        end
      end
    end
    
  end
end
