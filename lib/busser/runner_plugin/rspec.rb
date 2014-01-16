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
class Busser::RunnerPlugin::Rspec < Busser::RunnerPlugin::Base
  postinstall do
    install_gem("rspec")
    install_gem("bundler")
  end

  def test
    rspec_path = suite_path('rspec').to_s

    setup_file = File.join(rspec_path, "setup-recipe.rb")

    Dir.chdir(rspec_path) do
      if File.exists?(setup_file) && File.exists?("/opt/chef/bin/chef-apply")
        run("/opt/chef/bin/chef-apply #{setup_file}")
      end

      if File.exists?(File.join(rspec_path, "Gemfile"))
        run("env PATH=#{ENV['PATH']}:#{Gem.bindir} bundle install --local || bundle install")
      end

      runner = File.expand_path(File.join(File.dirname(__FILE__), "..", "rspec", "runner.rb"))
      run_ruby_script!("#{runner} -I #{rspec_path} -I #{rspec_path}/lib #{rspec_path}")
    end
  end
end
