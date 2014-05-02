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
   class Log
      include Singleton

      def initialize
         @log_file = ''
         @is_quiet = false
         @is_debug = false
         @color = true
      end

      def show_c(msg,quiet=@is_quiet)
        show msg,quiet,true
      end
      
      def show(msg,quiet=@is_quiet,in_color=false)
         if msg
            if @color && in_color
              msg = "\e[33m#{msg}\e[0m"
            end
            puts msg unless quiet
         end
      end

      def info(msg)
         if msg
            write msg
         end
      end

      def debug(msg)
         if msg && @is_debug
            write msg, '36m', 'DEBUG'
         end
      end

      def error(msg)
         if msg
            write msg, '31m', 'ERROR', false
         end
      end

      def fatal(msg)
         if msg
            write msg, '31m', 'ERROR', false
         end
      end

      def set_log_file(file)
         @log_file = file
      end

      def set_quiet
         @is_quiet = true unless @is_debug
      end

      def set_debug
         @is_debug = true
      end
      
      def no_color
         @color = false
      end
      
      private
      
      def write(msg, color='32m', severity='INFO', quiet=@is_quiet)
        if msg
          f_severity = sprintf("%-5s", severity.to_s)
          f_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
          if @color
            puts "\e[#{color}[#{f_severity} #{f_time}] #{msg.to_s.strip}\e[0m" unless quiet
          else
            puts "[#{f_severity} #{f_time}] #{msg.to_s.strip}" unless quiet
          end
        end
      end
   end
end
