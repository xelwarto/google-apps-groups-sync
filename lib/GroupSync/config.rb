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

    attr_accessor :params

    def initialize
      @params = Hash.new
      @c = Google::GroupSync::Constants.instance
      @log = Google::GroupSync::Log.instance
      @log.info 'Config:Initializing Application Configuration'
    end
    
    def get
      self.params[:cfg]
    end
    
    def load_cfg
      @log.debug 'Config(load_cfg):Loading Configuration File'
      @params[:cfg_file] ||= @c.cfg_file
      
      cfg = @params[:cfg_file]
      if cfg !~ /^\//
        cfg = "#{@params[:app_dir]}/#{@params[:cfg_file]}"
      end
      @log.debug "Config(load_cfg):Configuration file set to: #{cfg}"
      
      if File.file?(cfg)
        begin
          @log.debug 'Config(load_cfg):Attempting to load YAML file'
          yaml = YAML.load_file(cfg)
          
          if yaml[:general]
            if !yaml[:gapi][:secrets_file].nil?
              if yaml[:gapi][:secrets_file] !~ /^\//
                yaml[:gapi][:secrets_file] = "#{@params[:app_dir]}/#{yaml[:gapi][:secrets_file]}"
              end
            end
            
            if !yaml[:general][:cache_dir].nil?
              if yaml[:general][:cache_dir] !~ /^\//
                yaml[:general][:cache_dir] = "#{@params[:app_dir]}/#{yaml[:general][:cache_dir]}"
              end
            end
            @params[:cfg] = yaml
            return true
          else
            @log.error 'Config(load_cfg):unable to read correct config'
          end
        rescue Exception => e
          @log.error "Config(load_cfg):#{e}"
        end
      else
        @log.error 'Config(load_cfg):unable to locate config file'
      end
      return false
    end
    
  end
end
