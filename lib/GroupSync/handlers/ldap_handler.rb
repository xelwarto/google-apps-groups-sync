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
  class LdapHandler
    attr_reader :configured
    
    def initialize
      @config = Google::GroupSync::Config.instance.config.ldap
      @search = @config.search
      @log = Google::GroupSync::Log.instance
      @log.info 'LdapHandler:Initializing LDAP Handler'
      
      @configured = false
      
      auth = { 
        :method => :simple,
        :username => @config.bind_dn,
        :password => @config.bind_pass }
      @ldap = Net::LDAP.new :host => @config.server, :port => @config.port, :auth => auth
      
      begin
        Timeout::timeout(@config.timeout) do
          if @ldap.bind
            @configured = true
          end
        end
      rescue Exception => e
        @log.error 'LdapHandler:Failed to initialize LDAP Handler'
        @log.error "LdapHandler:#{e}"
        @configured = false
      end
    end
    
    def ent_from_dn(dn=nil,attrs=['objectClass'],&block)
      @log.debug 'LdapHandler(ent_from_dn):Searching for LDAP entity from DN'
      if !dn.nil? && dn != ''
        filter = Net::LDAP::Filter.eq :objectClass, 'top'
        run_handler dn, filter, attrs, &block
      else
        @log.error 'LdapHandler(ent_from_dn):LDAP dn is blank or invalid'
      end
    end
    
    def search(base=nil,filter=nil,attrs=['objectClass'],&block)
      @log.debug 'LdapHandler(search):Performing LDAP Search'
      if !base.nil?
        if !filter.nil?
          filter = Net::LDAP::Filter.construct filter
          run_handler base, filter, attrs, &block
        else
          @log.error 'LdapHandler(search):Search filter is invalid'
        end
      else
        @log.error 'LdapHandler(search):Search base is invalid'
      end
    end
    
    def get_groups
      @log.debug 'LdapHandler(get_groups):Running LDAP query to get groups'
      groups = Hash.new
      
      attrs = ['objectClass']
      attrs.push @search.groups_name_attr
      attrs.push @search.groups_mail_attr
      attrs.push @search.groups_member_attr
      
      if !@search.groups_owner_attr.nil? && !@search.groups_owner_attr.eql?('')
        attrs.push @search.groups_owner_attr
      end
      if !@search.groups_manager_attr.nil? && !@search.groups_manager_attr.eql?('')
        attrs.push @search.groups_manager_attr
      end
      if !@search.groups_descr_attr.nil? && !@search.groups_descr_attr.eql?('')
        attrs.push @search.groups_descr_attr
      end
      if !@search.groups_alias_attr.nil? && !@search.groups_alias_attr.eql?('')
        attrs.push @search.groups_alias_attr
      end
      
      begin
        search @search.groups_base, @search.groups_filter, attrs do |ent,ldap|
          if !ent.nil?
            grp = Hash.new
            grp[:ent] = ent
            grp[:members] = Array.new
            grp[:owners] = Array.new
            
            if !ent[@search.groups_name_attr].nil? && ent[@search.groups_name_attr].any?
              grp[:name] = ent[@search.groups_name_attr].first
              @log.debug "LdapHandler(get_groups):Found LDAP group: #{grp[:name]}"
              
              if !ent[@search.groups_mail_attr].nil? && ent[@search.groups_mail_attr].any?
                grp[:mail] = ent[@search.groups_mail_attr].first.downcase
                
                if !@search.groups_alias_attr.nil? && !@search.groups_alias_attr.eql?('')
                  if !ent[@search.groups_alias_attr].nil? && ent[@search.groups_alias_attr].any?
                    grp[:alias] = ent[@search.groups_alias_attr]
                  end
                end
                
                if !@search.groups_manager_attr.nil? && !@search.groups_manager_attr.eql?('')
                  if !ent[@search.groups_manager_attr].nil? && ent[@search.groups_manager_attr].any?
                    grp[:manager] = ent[@search.groups_manager_attr]
                  end
                end
                
                if !@search.groups_descr_attr.nil? && !@search.groups_descr_attr.eql?('')
                  if !ent[@search.groups_descr_attr].nil? && ent[@search.groups_descr_attr].any?
                    grp[:description] = ent[@search.groups_descr_attr].first
                  else
                    grp[:description] = grp[@search.groups_name_attr.to_sym]
                  end
                else
                  grp[:description] = grp[@search.groups_name_attr.to_sym]
                end
                
                groups[grp[:mail].downcase.to_sym] = grp
              else
                @log.error "LdapHandler(get_groups):LDAP group does not have valid email address - skipping: #{grp[:name]}"
              end
            end
          end
        end
      rescue Exception => e
        @log.error "App(get_groups):#{e}"
        groups = nil
      end
      
      groups
    end
    
    def get_users
      @log.debug 'LdapHandler(get_users):Running LDAP query to get users'
      users = Hash.new
      
      attrs = ['objectClass']
      attrs.push @search.groups_mail_attr
      begin
        search @search.users_base, @search.users_filter, attrs do |ent,ldap|
          if !ent.nil?
            dn = ent[:dn].first
            dn.downcase!
            dn.delete! "\s"
            dn.strip!
            
            if !ent[@search.groups_mail_attr].nil? && ent[@search.groups_mail_attr].any?
              user = Hash.new
              user[:mail] = ent[@search.groups_mail_attr].first.downcase.to_s
              user[:type] = 'USER'
              users[dn.to_sym] = user
            end
          end
        end
      rescue Exception => e
        @log.error "LdapHandler(get_users):#{e}"
        users = nil
      end
      
      users
    end
    
    private
    
    def run_handler(s_base=nil,s_filter=nil,s_attrs=['uid'])
      @log.debug 'LdapHandler(run_handler):Running LDAP search'
      if @configured
        if !s_filter.nil?
          @log.debug "LdapHandler(run_handler):LDAP search filter set to: #{s_filter.to_s}"
          if !s_base.nil?
            @log.debug "LdapHandler(run_handler):LDAP search base set to: #{s_base.to_s}"
            
            @log.debug 'LdapHandler(run_handler):Executing LDAP search'
            begin
              Timeout::timeout(@cfg[:ldap][:search_timeout]) do
                @ldap.open do |l|
                  res = l.search :base => s_base, :filter => s_filter, :attributes => s_attrs, :return_result => true
                  if res != nil && res.any?
                    res.each do |ent|
                      yield ent,l if block_given?
                    end
                  else
                    @log.error 'LdapHandler(run_handler):Search returned empty result set'
                  end
                end
              end
            rescue Exception => e
              @log.error 'LdapHandler:Failed to execute LDAP search'
              @log.error "LdapHandler:#{e}"
            end
          else
            @log.error 'LdapHandler(run_handler):LDAP search base is blank or invalid'
          end
        else
          @log.error 'LdapHandler(run_handler):LDAP search filter is blank or invalid'
        end
      else
        @log.debug 'LdapHandler(run_handler):LDAP handler not initialized - skipping LDAP execution'
      end
    end
  end
end
