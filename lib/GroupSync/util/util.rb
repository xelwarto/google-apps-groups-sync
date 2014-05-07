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
  class Util
    
    def self.get_command
      if ARGV.length > 0
        return ARGV.shift unless ARGV[0] =~ /^-/
      end
      return nil
    end
    
    def self.get_argvs
      argvs = Hash.new
      cur_argv = String.new

      if ARGV.length > 0
        argvs[:cmd] = ARGV.shift unless ARGV[0] =~ /^-/
        
        ARGV.each do |x|
          if x =~ /^-/
            cur_argv = x.sub(/^-+/,'')
            if cur_argv != ''
              argvs[cur_argv.to_sym] = ''
            end
          else
            if cur_argv != ''
              if argvs[cur_argv.to_sym].instance_of? Array
                argvs[cur_argv.to_sym].push x
              else
                if argvs[cur_argv.to_sym] != ''
                  cur_value = argvs[cur_argv.to_sym]
                  argvs[cur_argv.to_sym] = Array.new
                  argvs[cur_argv.to_sym].push cur_value
                  argvs[cur_argv.to_sym].push x
                else
                  argvs[cur_argv.to_sym] = x
                end
              end

            end
          end
        end
      end
      argvs
    end

    def self.show_use
      usage = <<EOF
      
Usage:
#{$0} <setup|cache|sync> OPTIONS

Options:
    --help                  Display this help screen
    --cfg <file>            Specify alternate config file location
    --quiet                 Messages are not displayed to the console
    --nocolor               Turn off colors in console output
    --debug                 Run application in debug mode
    
    setup --verify          Request authorization verification URI
    setup --validate <code> Validate authorization with verification
                            code, this will display the refresh token
                            value to be added to the configuration
    
    cache --refresh         Refresh the Google group cache to ensure 
                            the cache matches the groups in LDAP
    cache --rebuild         Reduild the Google group cache, this will
                            clear the cache and rebuild it with groups
                            matched in the LDAP
                      
    sync --update           Run the group update to sync group updates
                            to Google, this will refresh the group cache
                            before performing the sync update

EOF
      usage
    end

    def self.show_banner
      c = Google::GroupSync::Constants.instance
      banner = <<EOF
 _____                   _         ___                    _____                             _____                  
|  __ \\                 | |       / _ \\                  |  __ \\                           /  ___|                 
| |  \\/ ___   ___   __ _| | ___  / /_\\ \\_ __  _ __  ___  | |  \\/_ __ ___  _   _ _ __  ___  \\ `--. _   _ _ __   ___ 
| | __ / _ \\ / _ \\ / _` | |/ _ \\ |  _  | '_ \\| '_ \\/ __| | | __| '__/ _ \\| | | | '_ \\/ __|  `--. \\ | | | '_ \\ / __|
| |_\\ \\ (_) | (_) | (_| | |  __/ | | | | |_) | |_) \\__ \\ | |_\\ \\ | | (_) | |_| | |_) \\__ \\ /\\__/ / |_| | | | | (__ 
 \\____/\\___/ \\___/ \\__, |_|\\___| \\_| |_/ .__/| .__/|___/  \\____/_|  \\___/ \\__,_| .__/|___/ \\____/ \\__, |_| |_|\\___|
                    __/ |              | |   | |                               | |                 __/ |           
                   |___/               |_|   |_|                               |_|                |___/            

 #{c.name} 
 Version: #{c.version}
 Written by: #{c.author}
EOF
      banner
    end
    
  end
end
