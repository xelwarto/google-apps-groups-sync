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
  class GapiHandler
    class Authorization
      include Singleton
      attr_accessor :access_token, :refresh_token, :expires_in, :issued_at
      
      def initialize
        @cfg = Google::GroupSync::Config.instance.get
        @log = Google::GroupSync::Log.instance
        @log.debug 'GapiHandler::Authorization:Initializing Google API authorization'

        @secrets = nil
        @access_token = ''
        @refresh_token = @cfg[:gapi][:refresh_token]
        @expires_in = 0
        @issued_at = Time.now
        
        @log.debug 'GapiHandler::Authorization:Loading client secrets file'
        @secrets = Google::APIClient::ClientSecrets.load(@cfg[:gapi][:secrets_file])
      end
      
      def authorization
        @log.debug 'GapiHandler::Authorization:Creating Google API authorization'
        auth = @secrets.to_authorization
        auth.update_token! :access_token => self.access_token,
          :refresh_token => self.refresh_token, 
          :expires_in => self.expires_in,
          :issued_at => self.issued_at
        
        if auth.expired?
          @log.debug 'GapiHandler::Authorization:Access token has expired, request refresh of token'
          
          begin
            Timeout::timeout(@cfg[:gapi][:timeout]) do
              auth.fetch_access_token!
            end
            
            @log.debug 'GapiHandler::Authorization:Updating stored access token'
            self.access_token = auth.access_token
            self.expires_in = auth.expires_in
            self.issued_at = Time.now
          rescue Exception => e
            @log.error 'GapiHandler::Authorization:Error fetching auth access token'
            @log.error "GapiHandler::Authorization:#{e}"
          end
        end
        
        auth
      end
    end
    
    attr_reader :configured
    
    def initialize
      @cfg = Google::GroupSync::Config.instance.get
      @log = Google::GroupSync::Log.instance
        
      @configured = false
      @gapi_client = nil
      @apis = Hash.new
      
      @log.info 'GapiHandler:Initializing Google API Handler'
      begin
        @auth = GapiHandler::Authorization.instance
        
        Timeout::timeout(@cfg[:gapi][:timeout]) do
          @log.debug 'GapiHandler:Loading Google Admin Directory API'
          @apis[:dir] = client.discovered_api('admin', 'directory_v1')
          
          @configured = true
        end
      rescue Exception => e
        @log.error "GapiHandler:#{e}"
        @configured = false
      end
    end
    
    def get_user(userKey=nil)
      @log.debug 'GapiHandler(get_user):API Call - Get Google user information'
      user = nil
      
      if @configured
        if !userKey.nil?
          @log.debug "GapiHandler(get_user):Attempting to get user from key: #{userKey}"
          begin
            results = execute(
              :api_method => @apis[:dir].users.get,
              :parameters => {'userKey' => userKey},
              :body => nil
            )
            
            if !results.nil?
              @log.debug "GapiHandler(get_user):requested URI: #{results.request.uri}"
              @log.debug "GapiHandler(get_user):results status code: #{results.status}"
              if results.status == 200
                user = results.data
              end
            else
              if !results.data.nil?
                @log.error 'GapiHandler(get_user):API results return invalid status'
              end
            end
          rescue Exception => e
            @log.error "GapiHandler(get_user):#{e}"
            user = nil
          end
        else
          @log.error 'GapiHandler(get_user):group key paramater is not valid'
        end
      else
        @log.debug 'GapiHandler(get_user):not configured - skipping API call'
      end
      
      user
    end
    
    def get_group(groupKey=nil)
      @log.debug 'GapiHandler(get_group):API Call - Get Google group information'
      group = nil
      
      if @configured
        if !groupKey.nil?
          @log.debug "GapiHandler(get_group):Attempting to get group from key: #{groupKey}"
          begin
            results = execute(
              :api_method => @apis[:dir].groups.get,
              :parameters => {'groupKey' => groupKey},
              :body => nil
            )
            
            if !results.nil?
              @log.debug "GapiHandler(get_group):requested URI: #{results.request.uri}"
              @log.debug "GapiHandler(get_group):results status code: #{results.status}"
              if results.status == 200
                group = results.data
              end
            else
              if !results.data.nil?
                @log.error 'GapiHandler(get_group):API results return invalid status'
              end
            end
          rescue Exception => e
            @log.error "GapiHandler(get_group):#{e}"
            group = nil
          end
        else
          @log.error 'GapiHandler(get_group):group key paramater is not valid'
        end
      else
        @log.debug 'GapiHandler(get_group):not configured - skipping API call'
      end
      
      group
    end
    
    def remove_grp_member(groupKey=nil,memberKey=nil)
      @log.debug 'GapiHandler(remove_grp_member):API Call - Remove Google group member'
      
      if @configured
        if !groupKey.nil?
          if !memberKey.nil?
            @log.debug "GapiHandler(remove_grp_member):Attempting to remove group member (#{memberKey}) from group key: #{groupKey}"
            begin
              results = execute(
                :api_method => @apis[:dir].members.delete,
                :parameters => {'groupKey' => groupKey, 'memberKey' => memberKey},
                :body => nil
              )
              
              if !results.nil?
                @log.debug "GapiHandler(remove_grp_member):requested URI: #{results.request.uri}"
                @log.debug "GapiHandler(remove_grp_member):results status code: #{results.status}"
                if results.status == 200 || results.status == 204
                  return true
                else
                  if !results.data.nil?
                    @log.debug "GapiHandler(remove_grp_member):#{results.data['error']}"
                  end
                end
              else
                @log.error 'GapiHandler(remove_grp_member):API results return invalid status'
              end
            rescue Exception => e
              @log.error "GapiHandler:#{e}"
              return false
            end
          else
            @log.error 'GapiHandler(remove_grp_member):member key is not valid'
          end
        else
          @log.error 'GapiHandler(remove_grp_member):group key is not valid'
        end
      else
        @log.debug 'GapiHandler(remove_grp_member):not configured - skipping API call'
      end
      
      return false
    end
    
    def add_group(params)
      @log.debug 'GapiHandler(add_group):API Call - Add Google Group'
      group = nil
      
      if @configured
        if !params.nil?
          @log.debug 'GapiHandler(add_group):Attempting to add group to Google'
          begin
            results = execute(
              :api_method => @apis[:dir].groups.insert,
              :parameters => {},
              :body => params
            )
            
            if !results.nil?
              @log.debug "GapiHandler(add_group):requested URI: #{results.request.uri}"
              @log.debug "GapiHandler(add_group):results status code: #{results.status}"
              if results.status == 200 || results.status == 201
                group = results.data
              else
                if !results.data.nil?
                  @log.debug "GapiHandler(add_group):#{results.data['error']}"
                end
              end
            else
              @log.error 'GapiHandler(add_group):API results return invalid status'
            end
          rescue Exception => e
            @log.error "GapiHandler:#{e}"
            group = nil
          end
        else
          @log.error 'GapiHandler(add_group):parameters is not valid'
        end
      else
        @log.debug 'GapiHandler(add_group):not configured - skipping API call'
      end
      
      group
    end
    
    def add_grp_member(groupKey=nil,params)
      @log.debug 'GapiHandler(add_grp_member):API Call - Add Google group member'
      
      if @configured
        if !groupKey.nil?
          if !params.nil?
            @log.debug "GapiHandler(add_grp_member):Attempting to add group member to group key: #{groupKey}"
            begin
              results = execute(
                :api_method => @apis[:dir].members.insert,
                :parameters => {'groupKey' => groupKey},
                :body => params
              )
              
              if !results.nil?
                @log.debug "GapiHandler(add_grp_member):requested URI: #{results.request.uri}"
                @log.debug "GapiHandler(add_grp_member):results status code: #{results.status}"
                if results.status == 200 || results.status == 204
                  return true
                else
                  if !results.data.nil?
                    @log.debug "GapiHandler(add_grp_member):#{results.data['error']}"
                  end
                end
              else
                @log.error 'GapiHandler(add_grp_member):API results return invalid status'
              end
            rescue Exception => e
              @log.error "GapiHandler:#{e}"
              return false
            end
          else
            @log.error 'GapiHandler(add_grp_member):parameters is not valid'
          end
        else
          @log.error 'GapiHandler(add_grp_member):group key is not valid'
        end
      else
        @log.debug 'GapiHandler(add_grp_member):not configured - skipping API call'
      end
      
      return false
    end
    
    def get_groups
      @log.debug 'GapiHandler:API Call - Get Groups'
      groups = Array.new
      
      if @configured
        @log.debug 'GapiHandler:Attempting to get all domain groups'
        page_token = ''
        
        while !page_token.nil? do
          begin
            @log.debug 'GapiHandler:Getting page of group results'
            results = execute(
              :api_method => @apis[:dir].groups.list,
              :parameters => {'domain' => @cfg[:gapi][:domain], 'pageToken' => page_token},
              :body => nil
            )
            
            if !results.nil?
              @log.debug "GapiHandler(get_groups):requested URI: #{results.request.uri}"
              @log.debug "GapiHandler(get_groups):results status code: #{results.status}"
              if results.status == 200
                data = results.data
                
                if !data['groups'].nil?
                  groups.concat data['groups']
                end
                
                if data['nextPageToken'].nil?
                  page_token = nil
                else
                  page_token = data['nextPageToken']
                end
              else
                if !results.data.nil?
                  @log.debug "GapiHandler(get_groups):#{results.data['error']}"
                end
              end
            else
              @log.error 'GapiHandler(get_groups):API results return invalid status'
              page_token = nil
            end
          rescue Exception => e
            @log.error "GapiHandler:#{e}"
            page_token = nil
          end
        end
      else
        @log.debug 'GapiHandler:not configured - skipping API call'
      end
      
      groups
    end
    
    def get_grp_members(g_id=nil)
      @log.debug 'GapiHandler(get_grp_mems):API Call - Get Group Members'
      members = Array.new
      
      if @configured
        if !g_id.nil?
          @log.debug "GapiHandler(get_grp_mems):Attempting to get members of group id: #{g_id}"
          page_token = ''
          
          while !page_token.nil? do
            begin
              @log.debug 'GapiHandler(get_grp_mems):Getting page of member results'
              results = execute(
                :api_method => @apis[:dir].members.list,
                :parameters => {'groupKey' => g_id, 'pageToken' => page_token},
                :body => nil
              )
              
              if !results.nil?
                @log.debug "GapiHandler(get_grp_members):requested URI: #{results.request.uri}"
                @log.debug "GapiHandler(get_grp_members):results status code: #{results.status}"
                if results.status == 200
                  data = results.data
                  
                  if !data['members'].nil?
                    members.concat data['members']
                  end
                  
                  if data['nextPageToken'].nil?
                    page_token = nil
                  else
                    page_token = data['nextPageToken']
                  end
                else
                  if !results.data.nil?
                    @log.debug "GapiHandler(get_grp_members):#{results.data['error']}"
                  end
                end
              else
                @log.error 'GapiHandler(get_grp_mems):API results return invalid status'
                page_token = nil
              end
            rescue Exception => e
              @log.error "GapiHandler(get_grp_mems):#{e}"
              page_token = nil
            end
          end
        else
          @log.error 'GapiHandler(get_grp_mems):Group id is blank or invalid'
        end
      else
        @log.debug 'GapiHandler(get_grp_mems):not configured - skipping API call'
      end
      
      members
    end
    
    private
    
    def client
      if @gapi_client.nil?
        @log.debug 'GapiHandler:Creating Google API client'
        @gapi_client = Google::APIClient.new :application_name => @cfg[:gapi][:app_name],
          :application_version => @cfg[:gapi][:app_version]
      end 
      
      @log.debug 'GapiHandler:Clearing client authorization'
      @gapi_client.authorization.clear_credentials!
      
      @gapi_client
    end
    
    def execute(params)
      results = nil
      if @configured 
        begin
          @log.debug 'GapiHandler:Executing client API method'
          @log.debug "GapiHandler:API method parameters: #{params[:parameters].to_s}"
          Timeout::timeout(@cfg[:gapi][:timeout]) do
            results = client.execute(
              :api_method => params[:api_method],
              :parameters => params[:parameters],
              :body_object => params[:body],
              :authorization => @auth.authorization
            )
          end
        rescue Exception => e
          @log.error "GapiHandler:#{e}"
          results = nil
        end
      end
      results
    end
  end
end
