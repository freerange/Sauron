ENV["RAILS_ENV"] = "test"
require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)
require 'active_support/test_case'
require 'mocha'
require 'fakes/fake_gmail'
require 'minitest/autorun'

class ActiveSupport::TestCase
end

module Rails
  def self.root
    File.expand_path("../..", __FILE__)
  end
end

Mocha::Configuration.prevent(:stubbing_non_existent_method)
