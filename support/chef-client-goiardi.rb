#!/usr/bin/env ruby
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

require 'rubygems'
require 'chef/config'
require 'fileutils'

# Bust out of our self-imposed sandbox before running chef-client so
# gems installed via gem_package land in Chef's GEM_HOME.
#
# https://github.com/opscode/test-kitchen/issues/240
#
ENV['GEM_HOME'] = ENV['GEM_PATH'] = ENV['GEM_CACHE'] = nil

class ChefClientGoiardi

  def self.start
    new.run
  end

  def run
    create_chef_goiardi_server
    run_chef_client
  end

  private

  def create_chef_goiardi_server

  end

  # def repo_path
  #   ENV.fetch('CHEF_REPO_PATH', Dir.pwd)
  # end

  def run_chef_client
    system("chef-client", *ARGV)
    fail if $? != 0
  end
end
