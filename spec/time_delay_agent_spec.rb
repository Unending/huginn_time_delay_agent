require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::TimeDelayAgent do
  before(:each) do
    @valid_options = Agents::TimeDelayAgent.new.default_options
    @checker = Agents::TimeDelayAgent.new(:name => "TimeDelayAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
