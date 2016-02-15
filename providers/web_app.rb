use_inline_resources

action :uninstall do

	service new_resource.name do
		action [ :stop, :disable ]
	end
	
	file "/etc/systemd/system/#{new_resource.name}.service" do
		action :delete
	end
	
	directory "/opt/spring-boot/#{name}" do
		action :delete
	end
	
end

action :install do

	jar_directory = "/opt/spring-boot/#{new_resource.name}"
	jar_path = jar_directory + "/" + new_resource.name + '.boot_web_app.jar'

	user new_resource.user
	
	group new_resource.group do
		append true
		members [ new_resource.user ]
	end

	directory jar_directory do
		owner new_resource.user
		group new_resource.group
		mode '0774'
		action :create
		recursive true
	end
	
	bootapp_remote_file = remote_file jar_path do
		source new_resource.jar_remote_path
		owner new_resource.user
		group new_resource.group
		mode '0774'
		action :create
	end
	
	bootapp_service_template = template "/etc/systemd/system/#{new_resource.name}.service" do
		source 'bootapp.service.erb'
		mode '0755'
		owner 'root'
		group 'root'
		variables ({
			:description => new_resource.name,
			:user => new_resource.user,
			:jar_path => jar_path,
			:port => new_resource.port
		})
	end
	
	service new_resource.name do
		action :enable
	end
	
	execute '/usr/bin/systemctl daemon-reload' do
		only_if { bootapp_service_template.updated_by_last_action? }
	end
	
	service new_resource.name do
		action :restart
		only_if { bootapp_service_template.updated_by_last_action? || bootapp_remote_file.updated_by_last_action? }
	end
	
	execute "Ensure web app is started up" do
		command "curl http://localhost:#{new_resource.port}"
		retries 12
		retry_delay 5
	end
	
end