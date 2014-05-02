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
      @cfg = Google::GroupSync::Config.instance.get
      @log = Google::GroupSync::Log.instance
      @log.info 'LdapHandler:Initializing LDAP Handler'
      
      @configured = false
      @base = @cfg[:ldap][:base]
      
      auth = { 
        :method => :simple,
        :username => @cfg[:ldap][:adm_dn],
        :password => @cfg[:ldap][:adm_pass] }
      @ldap = Net::LDAP.new :host => @cfg[:ldap][:server], :port => @cfg[:ldap][:port], :auth => auth
      
      begin
        Timeout::timeout(@cfg[:ldap][:timeout]) do
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
    
    def ent_from_dn(dn=nil,attrs=['objectClass','mail'],&block)
      @log.debug 'LdapHandler(ent_from_dn):Searching for LDAP entity from DN'
      if !dn.nil? && dn != ''
        filter = Net::LDAP::Filter.eq :objectClass, 'top'
        run_handler dn, filter, attrs, &block
      else
        @log.error 'LdapHandler(ent_from_dn):LDAP dn is blank or invalid'
      end
    end
    
    def get_std_groups(attrs=['cn','mail','uniqueMember','owner', 'description', 'mailAlternateAddress'],&block)
      @log.debug 'LdapHandler(get_std_groups):Searching for LDAP groups'
      filter = Net::LDAP::Filter.eq :objectClass, 'groupofuniquenames'
      run_handler @base, filter, attrs, &block
    end
    
    def get_all_users(attrs=['uid','mail'],&block)
      @log.debug 'LdapHandler(get_std_groups):Searching for all LDAP users'
      filter = Net::LDAP::Filter.eq :objectClass, 'person'
      run_handler 'CHANGE HERE', filter, attrs, &block
    end
    
    def get_ldap_groups
      @log.debug 'LdapHandler(get_ldap_groups):Running LDAP query to get groups'
      groups = Hash.new
      
      begin
        get_std_groups do |ent,ldap|
          if !ent.nil?
            grp = Hash.new
            grp[:ent] = ent
            grp[:members] = Array.new
            grp[:owners] = Array.new
            
            if !ent['cn'].nil? && ent['cn'].any?
              grp[:cn] = ent['cn'].first
              @log.debug "LdapHandler(get_ldap_groups):Found LDAP group: #{grp[:cn]}"
              
              if !ent['mail'].nil? && ent['mail'].any?
                grp[:mail] = ent['mail'].first.downcase
                
                if !ent['mailAlternateAddress'].nil? && ent['mailAlternateAddress'].any?
                  grp[:mailAlternateAddress] = ent['mailAlternateAddress']
                end
                
                if !ent['description'].nil? && ent['description'].any?
                  grp[:description] = ent['description'].first
                else
                  grp[:description] = grp[:cn]
                end
                
                groups[grp[:mail].downcase.to_sym] = grp
              else
                @log.error "LdapHandler(get_ldap_groups):LDAP group does not have valid email address - skipping: #{grp[:cn]}"
              end
            end
          end
        end
      rescue Exception => e
        @log.error "App(get_ldap_groups):#{e}"
        groups = nil
      end
      
      groups
    end
    
    def get_ldap_users
      @log.debug 'LdapHandler(get_ldap_users):Running LDAP query to get users'
      users = Hash.new
      
      begin
        get_all_users do |ent,ldap|
          if !ent.nil?
            dn = ent[:dn].first
            dn.downcase!
            dn.delete! "\s"
            dn.strip!
            
            if !ent[:mail].nil? && ent[:mail].any?
              user = Hash.new
              user[:mail] = ent[:mail].first.downcase.to_s
              user[:type] = 'USER'
              users[dn.to_sym] = user
            end
          end
        end
      rescue Exception => e
        @log.error "LdapHandler(get_ldap_users):#{e}"
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
