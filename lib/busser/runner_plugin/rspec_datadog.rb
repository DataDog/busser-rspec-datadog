# -*- encoding: utf-8 -*-
#
# Author:: HIGUCHI Daisuke (<d-higuchi@creationline.com>)
#
# Copyright (C) 2013, HIGUCHI Daisuke
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

require 'busser/runner_plugin'
require 'rubygems'

# A Busser runner plugin for Rspec.
#
# @author Adam Jacob <adam@opscode.com>
#
class Busser::RunnerPlugin::RspecDatadog < Busser::RunnerPlugin::Base
  postinstall do
    install_gem("rspec")
    install_gem("bundler", "2.3.26")
  end

  def test
    rspec_path = suite_path('rspec_datadog').to_s

    setup_file = File.join(rspec_path, "setup-recipe.rb")

    Dir.chdir(rspec_path) do

      # Referred from busser-serverspec
      gemfile_path = File.join(rspec_path, 'Gemfile')
      if File.exists?(gemfile_path)
        # Bundle install local completes quickly if the gems are already found locally
        # it fails if it needs to talk to the internet. The || below is the fallback
        # to the internet-enabled version. It's a speed optimization.
        banner('Bundle Installing..')
        ENV['PATH'] = [ENV['PATH'], Gem.bindir, RbConfig::CONFIG['bindir']].join(File::PATH_SEPARATOR)
        bundle_exec = "#{File.join(RbConfig::CONFIG['bindir'], 'ruby')} " +
          "#{File.join(Gem.bindir, 'bundle')} install --gemfile #{gemfile_path} 2>&1"
        run("#{bundle_exec} --local || #{bundle_exec}")
      end

      if File.exists?(setup_file)
        if !File.exists?("/opt/chef/bin/chef-apply")
          raise "You have a chef setup file at #{setup_file}, but /opt/chef/bin/chef-apply does not if exist"
        end
        run("/opt/chef/bin/chef-apply #{setup_file}")
      end

      runner = File.expand_path(File.join(File.dirname(__FILE__), "..", "rspec_datadog", "runner.rb"))
      run_ruby_script!("#{runner} -I #{rspec_path} -I #{rspec_path}/lib #{rspec_path}")
    end
  end
end
