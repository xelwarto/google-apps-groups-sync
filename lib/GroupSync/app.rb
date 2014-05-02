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
  class App

    def self.run(app_dir)
      @log = Google::GroupSync::Log.instance
      
      run_cmd = Google::GroupSync::Util.get_command
      argvs = Google::GroupSync::Util.get_argvs
      
      @log.set_debug if argvs[:debug]
      @log.no_color if argvs[:nocolor]
      
      @log.set_quiet if argvs[:quiet] && ( !argvs[:help] && !argvs[:h] )
      @log.set_quiet if argvs[:q] && ( !argvs[:help] && !argvs[:h] )
      
      @log.show_c Google::GroupSync::Util.show_banner

      if argvs[:help] || argvs[:h]
        @log.show Google::GroupSync::Util.show_use, false
        exit 0
      end
      
      config = Google::GroupSync::Config.instance
      config.params[:app_dir] = app_dir
      config.params[:cfg_file] = argvs[:cfg]
      if !config.load_cfg
        @log.show Google::GroupSync::Util.show_use, false
        exit 1
      end
      
      if run_cmd.nil?
        @log.show Google::GroupSync::Util.show_use, false
        exit 1
      else
        @cfg = config.get
        @ldap_groups = nil
        @ldap_users = nil
        @google_groups = nil
        
        @gapi =  Google::GroupSync::GapiHandler.new
        @ldap =  Google::GroupSync::LdapHandler.new
        
        @cache =  Google::GroupSync::CacheHandler.instance
        @cache.dir = @cfg[:general][:cache_dir]
        @cache.verify
        
        if run_cmd.eql? 'cache'
          if argvs[:refresh] && argvs[:rebuild]
            @log.show Google::GroupSync::Util.show_use, false
            exit 1
          elsif argvs[:refresh]
            refresh_grp_cache
          elsif argvs[:rebuild]
            rebuild_grp_cache
          else
            @log.show Google::GroupSync::Util.show_use, false
            exit 1
          end
        elsif run_cmd.eql? 'sync'
          if argvs[:update]
            update_groups
          else
            @log.show Google::GroupSync::Util.show_use, false
            exit 1
          end
        else
          @log.show Google::GroupSync::Util.show_use, false
          exit 1
        end
      end
    end
    
    private
    
    def self.update_groups
      @log.info 'App(update_groups):Updating group information in Google'
      get_ldap_groups
      
      if !@ldap_groups.nil? && !@ldap_groups.empty?
        get_google_groups
        refresh_grp_cache
        if !@google_groups.nil? && !@google_groups.empty?
          get_ldap_grp_mems
          
          @log.info 'App(update_groups):Processing updates to Google groups'
          updated_groups = Array.new
          @ldap_groups.each do |l_mail,l_grp|
            begin
              l_cn = l_grp[:cn]
              l_descr = l_grp[:description]
              l_grp_members = l_grp[:members]
              l_grp_owners = l_grp[:owners]
              
              @log.debug "App(update_groups):Processing LDAP group: #{l_cn} (#{l_mail.to_s})"
              
              if !l_grp_members.empty? || !l_grp_owners.empty?
                if !@google_groups.has_key? l_mail
                  @log.info "App(update_groups):Adding group to Google: #{l_cn} (#{l_mail.to_s})"
                  n_grp = @gapi.add_group({
                    'email' => l_mail.to_s,
                    'description' => l_descr,
                    'name' => l_cn
                    })
                  
                  if !n_grp.nil?
                    c_grp = Hash.new
                    c_grp['group'] = n_grp
                    c_grp['members'] = Array.new

                    @google_groups[l_mail] = c_grp
                  else
                    @log.error "App(update_groups):Failed add group to Google: #{l_cn} (#{l_mail.to_s})"
                  end
                end
              
                if @google_groups.has_key? l_mail
                  has_updates = false
                  
                  g_grp = @google_groups[l_mail]
                  g_grp_info = g_grp['group']
                  id = g_grp_info['id']
                  
                  @log.debug "App(update_groups):Google group found with group id: #{id}"
                  
                  g_grp_members = Hash.new
                  g_grp_owners = Hash.new
                  
                  g_grp['members'].each do |mem|
                    mail = mem['email'].downcase
                    role = mem['role']
                    
                    if role.eql? 'MEMBER'
                      g_grp_members[mail] = mem
                    elsif role.eql? 'OWNER'
                      g_grp_owners[mail] = mem
                    else
                      #MANAGER MEMBER TYPE - NOT USED
                    end
                  end
                  
                  l_grp_members.each do |l_mem|
                    mail = l_mem[:mail].downcase
                    type = l_mem[:type]
                    
                    if g_grp_members.has_key? mail
                      @log.debug "App(update_groups):Matching Google group member found : #{mail} - #{l_cn}"
                      g_grp_members.delete mail
                    else
                      @log.info "App(update_groups):Adding member (#{mail}) to Google Group: #{l_cn}"
                      
                      g_mem = nil
                      if type.eql? 'GROUP'
                        g_mem = @gapi.get_group mail
                      else
                        g_mem = @gapi.get_user mail
                      end
                      
                      if !g_mem.nil?
                        m_id = g_mem['id']
                        
                        if @gapi.add_grp_member(id, {
                          'kind' => 'admin#directory#member',
                          'id' => m_id,
                          'email' => mail,
                          'role' => 'MEMBER',
                          'type' => type
                          })
                          has_updates = true
                        else
                          @log.error "App(update_groups):Failed to add member (#{mail}) to Google Group: #{l_cn}"
                        end
                      else
                        @log.error "App(update_groups):Failed to locate member information for: #{mail}"
                      end
                    end
                  end
                  
                  l_grp_owners.each do |l_owner|
                    mail = l_owner[:mail].downcase
                    type = l_owner[:type]
                    
                    if g_grp_owners.has_key? mail
                      @log.debug "App(update_groups):Matching Google group owner found : #{mail} - #{type}"
                      g_grp_owners.delete mail
                    else
                      @log.info "App(update_groups):Adding owner (#{mail}) to Google Group: #{l_cn}"
                      
                      g_mem = nil
                      if type.eql? 'GROUP'
                        g_mem = @gapi.get_group mail
                      else
                        g_mem = @gapi.get_user mail
                      end
                      
                      if !g_mem.nil?
                        m_id = g_mem['id']
                        
                        if @gapi.add_grp_member(id, {
                          'kind' => 'admin#directory#member',
                          'id' => m_id,
                          'email' => mail,
                          'role' => 'OWNER',
                          'type' => type
                          })
                          has_updates = true
                        else
                          @log.error "App(update_groups):Failed to add owner (#{mail}) to Google Group: #{l_cn}"
                        end
                      else
                        @log.error "App(update_groups):Failed to locate owner information for: #{mail}"
                      end
                    end
                  end
                  
                  @log.debug 'App(update_groups):Removing Google group members which are not in the LDAP group'
                  g_grp_members.each do |mail,mem|
                    m_id = mem['id']
                    @log.info "App(update_groups):Removing member (#{mail}) from Google Group: #{l_cn}"
                    if @gapi.remove_grp_member id, m_id
                      has_updates = true
                    else
                      @log.error "App(update_groups):Failed to remove member (#{mail}) from Google Group: #{l_cn}"
                    end
                  end
                  
                  @log.debug 'App(update_groups):Removing Google group owners which are not in the LDAP group'
                  g_grp_owners.each do |mail,mem|
                    m_id = mem['id']
                    @log.info "App(update_groups):Removing owner (#{mail}) from Google Group: #{l_cn}"
                    if @gapi.remove_grp_member id, m_id
                      has_updates = true
                    else
                      @log.error "App(update_groups):Failed to remove owner (#{mail}) from Google Group: #{l_cn}"
                    end 
                  end
                  
                  if has_updates
                    updated_groups.push id
                  end
                else
                  @log.error "App(update_groups):Matching Google group not found for: #{l_cn} (#{l_mail.to_s})"
                end
              else
                @log.error "App(update_groups):LDAP Group has no members or owners - skipping sync for: #{l_cn} (#{l_mail.to_s})"
              end
            rescue Exception => e
              @log.error "App(update_groups):#{e}"
            end
          end
        
          if !updated_groups.nil? && !updated_groups.empty?
            refresh_grp_cache updated_groups
          end
        else
          @log.error 'App(update_groups):Google group information is empty or invalid'
        end
      else
        @log.error 'App(update_groups):LDAP group information is empty or invalid'
      end
      
    end
    
    def self.get_ldap_users
      if @ldap_users.nil? || @ldap_users.empty?
        @log.info 'App(get_ldap_users):Retrieving LDAP Users'
        @ldap_users = @ldap.get_ldap_users
        
        if !@ldap_users.nil?
          @log.info "App(get_ldap_users):Found LDAP users: #{@ldap_users.size}"
        else
          @log.error 'App(get_ldap_users):Retrieving LDAP users returned invalid results'
        end
      end
    end
    
    def self.get_ldap_groups
      if @ldap_groups.nil? || @ldap_groups.empty?
        @log.info 'App(get_ldap_groups):Retrieving LDAP Standard Groups'
        @ldap_groups = @ldap.get_ldap_groups
        
        if !@ldap_groups.nil?
          @log.info "App(get_ldap_groups):Found LDAP groups: #{@ldap_groups.size}"
        else
          @log.error 'App(get_ldap_groups):Retrieving LDAP groups returned invalid results'
        end
      end
    end
    
    def self.get_ldap_grp_mems
      @log.info 'App(get_ldap_grp_mems):Retrieving LDAP Group Members'
    
      if !@ldap_groups.nil? && !@ldap_groups.empty?
        get_ldap_users
        
        @log.info 'App(get_ldap_grp_mems):Processing LDAP Group Members'
        @ldap_groups.each do |mail,grp|
          @log.debug "App(get_ldap_grp_mems):Attempting to find group members for: #{grp[:cn]}"
          ent = grp[:ent]
          if !ent['uniqueMember'].nil? && ent['uniqueMember'].any?
            @log.debug "App(get_ldap_grp_mems):Members found: #{ent['uniqueMember'].size}"
            ent['uniqueMember'].each do |dn|
              test_dn = dn.downcase
              test_dn.delete! "\s"
              test_dn.strip!
              
              m_found = false
              if !@ldap_users.nil? && !@ldap_users.empty?
                if @ldap_users.has_key? test_dn.to_sym
                  @log.debug "App(get_ldap_grp_mems):Adding group member: #{@ldap_users[test_dn.to_sym]}"
                  grp[:members].push @ldap_users[test_dn.to_sym]
                  m_found = true
                end
              end
              
              if !m_found
                begin
                  @ldap.ent_from_dn dn do |ent2,ldap2|
                    if !ent2.nil?
                      if !ent2['mail'].nil? && ent2['mail'].any?
                        m_ent = Hash.new
                        m_ent[:mail] = ent2['mail'].first.downcase
                        m_ent[:type] = 'USER'
                        
                        ent2['objectClass'].each do |obj|
                          if obj.downcase.eql? 'groupofuniquenames'
                            m_ent[:type] = 'GROUP'
                          end
                        end
                        
                        grp[:members].push m_ent
                      else
                        @log.error "App(get_ldap_grp_mems):Member NOT FOUND: #{grp[:cn]} - #{dn}"
                      end
                    else
                      @log.error "App(get_ldap_grp_mems):Member NOT FOUND: #{grp[:cn]} - #{dn}"
                    end
                  end
                rescue Exception => e
                  @log.error "App(get_ldap_grp_mems):#{e}"
                end
              end
            end
          end
          
          @log.debug "App(get_ldap_grp_mems):Attempting to find group owners for: #{grp[:cn]}"
          if !ent['owner'].nil? && ent['owner'].any?
            @log.debug "App(get_ldap_grp_mems):Owners found: #{ent['owner'].size}"
            ent['owner'].each do |dn|
              test_dn = dn.downcase
              test_dn.delete! "\s"
              test_dn.strip!
              
              o_found = false
              if !@ldap_users.nil? && !@ldap_users.empty?
                if @ldap_users.has_key? test_dn.to_sym
                  @log.debug "App(get_ldap_grp_mems):Adding group owner: #{@ldap_users[test_dn.to_sym]}"
                  grp[:owners].push @ldap_users[test_dn.to_sym]
                  o_found = true
                end
              end
              
              if !o_found
                begin
                  @ldap.ent_from_dn dn do |ent2,ldap2|
                    if !ent2.nil?
                      if !ent2['mail'].nil? && ent2['mail'].any?
                        o_ent = Hash.new
                        o_ent[:mail] = ent2['mail'].first.downcase
                        o_ent[:type] = 'USER'
                        
                        ent2['objectClass'].each do |obj|
                          if obj.downcase.eql? 'groupofuniquenames'
                            o_ent[:type] = 'GROUP'
                          end
                        end
                        
                        grp[:owners].push o_ent
                      else
                        @log.error "App(get_ldap_grp_mems):Owner NOT FOUND: #{grp[:cn]} - #{dn}"
                      end
                    else
                      @log.error "App(get_ldap_grp_mems):Owner NOT FOUND: #{grp[:cn]} - #{dn}"
                    end
                  end
                rescue Exception => e
                  @log.error "App(get_ldap_grp_mems):#{e}"
                end
              end
            end
          end
        end
      else
        @log.error 'App(get_ldap_grp_mems):LDAP groups are empty or invalid'
      end
    end
    
    def self.get_google_groups(from_cache=true)
      if @google_groups.nil? || @google_groups.empty?
        if from_cache
          @log.info 'App(get_google_groups):Retrieving Google groups via group cache'
          @google_groups = Hash.new
          
          @cache.read do |file|
            begin
              j_file = JSON.load file
              
              if !j_file.nil?
                g_mail = j_file['group']['email']
                @google_groups[g_mail.downcase.to_sym] = j_file
              end
            rescue Exception => e
              @log.error "App(get_google_groups):#{e}"
            end
          end
        else
          @log.info 'App(get_google_groups):Retrieving Google groups via Google API'
          @google_groups = Hash.new
          
          @log.debug 'App(get_google_groups):Running Google API to get groups'
          begin
            @gapi.get_groups.each do |grp|
              g_mail = grp['email']
              
              c_grp = Hash.new
              c_grp['group'] = grp
              c_grp['members'] = Array.new
              
              @google_groups[g_mail.downcase.to_sym] = c_grp
            end
          rescue Exception => e
            @log.error "App(get_google_groups):#{e}"
            @google_groups = nil
          end
        end
        
        @log.info "App(get_google_groups):Found Google groups: #{@google_groups.size}"
      end
    end
    
    def self.refresh_grp_cache(grps=[])
      @log.info 'App(refresh_grp_cache):Attempting to Refresh the Google Groups Cache Information'
      
      if grps.nil? || grps.empty?
        grps = Array.new
        get_ldap_groups
        
        if !@ldap_groups.nil? && !@ldap_groups.empty?
          get_google_groups
          
          if @google_groups.nil?
            @google_groups = Hash.new
          end
          
          @ldap_groups.each do |mail,l_grp|
            if !@google_groups.has_key? mail.to_sym
              @log.debug "App(refresh_grp_cache):Matching LDAP group not found: #{mail}"
              grps.push mail
            end
          end
        else
          @log.error 'App(refresh_grp_cache):LDAP group results are empty or invalid'
        end
      end
      
      if !grps.nil? && !grps.empty?
        @log.info 'App(refresh_grp_cache):Refreshing Google group cache'
        grps.each do |id|
          begin
            @log.debug "App(refresh_grp_cache):Attempting to retrieve group from Google with id: #{id}"
            g_grp = @gapi.get_group id
            
            if !g_grp.nil?
              @log.debug "App(refresh_grp_cache):Building group cache for id: #{id}"
              c_grp = Hash.new
              c_grp['group'] = g_grp
              c_grp['members'] = Array.new
            
              g_id = g_grp['id']
              g_mail = g_grp['email']
              g_mems = @gapi.get_grp_members g_id
              c_grp['members'] = g_mems
              @log.debug "App(refresh_grp_cache):Found groups members: #{g_mems.size}"

              @google_groups[g_mail.downcase.to_sym] = c_grp
              @cache.write g_id, JSON.fast_generate(c_grp)
            else
              @log.error "App(refresh_grp_cache):Failed to retrieve group from Google with id: #{id}"
            end
          rescue Exception => e
            @log.error "App(refresh_grp_cache):#{e}"
          end
        end
      end
    end
    
    def self.rebuild_grp_cache
      @log.info 'App(rebuild_grp_cache):Attempting to Rebuild the Google Groups Cache Information'
      @cache.clear
      get_ldap_groups
      
      if !@ldap_groups.nil? && !@ldap_groups.empty?
        get_google_groups false
        
        if !@google_groups.nil? && !@google_groups.empty?
          @log.info 'App(rebuild_grp_cache):Processing Google groups / building group cache'
          @ldap_groups.each do |mail,l_grp|
            begin
              if @google_groups.has_key? mail.to_sym
                @log.debug "App(rebuild_grp_cache):Found matching Google group in LDAP: #{mail}"
                g_grp = @google_groups[mail.to_sym]
                g_id = g_grp['group']['id']
                
                g_mems = @gapi.get_grp_members g_id
                g_grp['members'] = g_mems
                @log.debug "App(rebuild_grp_cache):Found groups members: #{g_mems.size}"
                
                @cache.write g_id, JSON.fast_generate(g_grp)
              end
            rescue Exception => e
              @log.error "App(rebuild_grp_cache):#{e}"
            end
          end
        else
          @log.error 'App(rebuild_grp_cache):Google group results are empty or invalid'
        end
      else
        @log.error 'App(rebuild_grp_cache):LDAP group results are empty or invalid'
      end
    end
  end
end
