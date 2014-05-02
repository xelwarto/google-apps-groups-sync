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
  class CacheHandler
    include Singleton
  
    attr_accessor :dir
    
    def initialize
      @log = Google::GroupSync::Log.instance
      @log.info 'CacheHandler:Initializing Group Cache Handler'
      @dir = nil
    end
    
    def write(id=nil,data=nil)
      @log.debug 'CacheHandler(write):Writing cache file'
      if !id.nil?
        if !data.nil?
          @log.debug "CacheHandler(write):Creating cache file: #{id}"
          begin
            File.open("#{@dir}/#{id}", "w") do |file|
              file.puts data
            end
          rescue Exception => e
            @log.error "CacheHandler(write):#{e}"
          end
        else
          @log.error 'CacheHandler(write):Cache data is invalid'
        end
      else
        @log.error 'CacheHandler(write):Cache id is invalid'
      end
    end
    
    def read
      @log.info 'CacheHandler(read):Reading group cache directory'
      if !@dir.nil? && !@dir.eql?('')
        if File.exists? @dir
          if File.directory? @dir
            @log.debug 'CacheHandler(read):Reading files from group cache directory'
            begin
              if Dir.glob("#{@dir}/*").any?
                Dir.glob "#{@dir}/*" do |file|
                  f = File.open file, 'r'
                  yield f if block_given?
                  f.close if !f.closed?
                end
              else
                @log.error 'CacheHandler(read):Group cache directory is empty or invalid'
              end
            rescue Exception => e
              @log.error "CacheHandler(read):#{e}"
            end
          else
            @log.error "CacheHandler(read):Unable to locate or access the group cache directory: #{@dir}"
          end
        else
          @log.error "CacheHandler(read):Unable to locate or access the group cache directory: #{@dir}"
        end
      else
        @log.error 'CacheHandler(read):Configuration paramater for the group cache directory is missing or invalid'
      end
    end
    
    def clear
      @log.info 'CacheHandler(clear):Attempting to clear group cache directory'
      if !@dir.nil? && !@dir.eql?('')
        if File.exists? @dir
          if File.directory? @dir
            @log.debug 'CacheHandler(clear):Clearing files from group cache directory'
            begin
              Dir.glob "#{@dir}/*" do |file|
                File.delete file
              end
            rescue Exception => e
              @log.error "CacheHandler(clear):#{e}"
            end
          else
            @log.error "CacheHandler(clear):Unable to locate or access the group cache directory: #{@dir}"
          end
        else
          @log.error "CacheHandler(clear):Unable to locate or access the group cache directory: #{@dir}"
        end
      else
        @log.error 'CacheHandler(clear):Configuration paramater for the group cache directory is missing or invalid'
      end
    end
    
    def verify
      @log.info 'CacheHandler(verify):Verifying the group cache directory exists and is writable'
      if @dir.nil? || @dir.eql?('')
        @log.error 'CacheHandler(verify):Configuration paramater for the group cache directory is missing or invalid'
        exit 1
      else
        begin
          if File.exists? @dir
            @log.debug 'CacheHandler(verify):Group cache directory location exists'
            if !File.directory? @dir
              @log.error "CacheHandler(verify):Unable to locate or access the group cache directory: #{@dir}"
              exit 1
            else
              if !File.writable? @dir
                @log.error "CacheHandler(verify):Unable to locate or access the group cache directory: #{@dir}"
                exit 1
              end
            end
          else
            @log.info "CacheHandler(verify):Creating cache directory: #{@dir}"
            Dir.mkdir @dir
            
            if !File.writable? @dir
              @log.error "CacheHandler(verify):Unable to locate or access the group cache directory: #{@dir}"
              exit 1
            end
          end
        rescue Exception => e
          @log.error "CacheHandler(verify):#{e}"
          @log.error 'CacheHandler(verify):Failed to locate, access or create the group cache directory'
          exit 1
        end
      end
    end
  end
end
