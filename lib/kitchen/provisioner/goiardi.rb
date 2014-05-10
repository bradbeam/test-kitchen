# -*- encoding: utf-8 -*-
#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2013, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen/provisioner/chef_base'

module Kitchen

  module Provisioner

    # Chef Goiardi provisioner.
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class Goiardi < ChefBase

      default_config :client_rb, {}
      default_config :ruby_bindir, "/opt/chef/embedded/bin"
      default_config :json_attributes, true

      def create_sandbox
        super
        prepare_chef_client_goiardi_rb
        prepare_validation_pem
        prepare_client_rb
      end

      def prepare_command
        data = default_config_rb
        #ruby_bin = config[:ruby_bindir]
        <<-PREPARE
          sh -xc '
            if [ ! -f /tmp/goiardi ]; then
              echo "Downloading goiardi"
              wget https://github.com/bradbeam/goiardi/releases/download/v0.5.1/goiardi -O /tmp/goiardi
              chmod 755 /tmp/goiardi
            fi

            if [ -z "$(ps --no-header -C goiardi )" ]; then
              echo -n "Starting goiardi server... "
              sudo nohup /tmp/goiardi -V -H localhost -P 4545 --conf-root=/tmp/kitchen >/tmp/goiardi.log 2>&1 &
              #nohup /tmp/goiardi -V -H localhost -P 4545  &
            fi

            if [ ! -f /tmp/kitchen/client.pem  ]; then
              echo -n "Creating client..."
              chef-client -o "" -c /tmp/kitchen/client.rb >> /tmp/goiardi.log 2>&1
              #knife client create #{data[:node_name]} -c /tmp/kitchen/client.rb -e /bin/true | grep -iv created > /tmp/kitchen/client.pem
              # >> /tmp/goiardi.log 2>&1
              echo "done!"
            fi

            echo -n "Uploading cookbooks to goiardi..."
            for cookbook in $(ls /tmp/kitchen/cookbooks); do
              sudo knife cookbook upload -o /tmp/kitchen/cookbooks $cookbook -c /tmp/kitchen/client.rb
              #>> /tmp/goiardi.log 2>&1
            done
            echo "done!"
            '
        PREPARE
      end

      def run_command
        args = [
          "--config #{config[:root_path]}/client.rb",
          "--log_level #{config[:log_level]}"
        ]
        if config[:json_attributes]
          args << "--json-attributes #{config[:root_path]}/dna.json"
        end

        ["#{sudo('chef-client')} "].concat(args).join(" ")
      end

      private

      def prepare_chef_client_goiardi_rb

        source = File.join(File.dirname(__FILE__),
          %w{.. .. .. support chef-client-goiardi.rb})
        FileUtils.cp(source, File.join(sandbox_path, "chef-client-goiardi.rb"))
      end

      def prepare_validation_pem
        source = File.join(File.dirname(__FILE__),
          %w{.. .. .. support dummy-validation.pem})
        FileUtils.cp(source, File.join(sandbox_path, "validation.pem"))
      end

      def prepare_client_rb
        data = default_config_rb.merge(config[:client_rb])
        data[:chef_server_url] = "http://127.0.0.1:4545"
        data[:verify_peer] = :verify_peer
        File.open(File.join(sandbox_path, "client.rb"), "wb") do |file|
          file.write(format_config_file(data))
        end
      end

      # def chef_client_zero_env(extra = nil)
      #   args = [
      #     %{CHEF_REPO_PATH="#{config[:root_path]}"},
      #     %{GEM_HOME="#{config[:root_path]}/chef-client-zero-gems"},
      #     %{GEM_PATH="#{config[:root_path]}/chef-client-zero-gems"},
      #     %{GEM_CACHE="#{config[:root_path]}/chef-client-zero-gems/cache"}
      #   ]
      #   if extra == :export
      #     args << %{; export CHEF_REPO_PATH GEM_HOME GEM_PATH GEM_CACHE;}
      #   end
      #   args.join(" ")
      # end

      # Determines whether or not local mode (a.k.a chef zero mode) is
      # supported in the version of Chef as determined by inspecting the
      # require_chef_omnibus config variable.
      #
      # The only way this method returns false is if require_chef_omnibus has
      # an explicit version set to less than 11.8.0, when chef zero mode was
      # introduced. Otherwise a modern Chef installation is assumed.
      def local_mode_supported?
        version = config[:require_chef_omnibus]

        case version
        when nil, false, true, "latest"
          true
        else
          Gem::Version.new(version) >= Gem::Version.new("11.8.0") ? true : false
        end
      end
    end
  end
end
