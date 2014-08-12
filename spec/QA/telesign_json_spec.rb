# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Our JSON file' do
  it 'Should exist and not have blank attributes' do
    @driver.goto url
    @driver.page_source.scan("url").should_not be_nil
    @driver.page_source.scan("count").should_not be_nil
    @driver.page_source.scan("imdb_id").should_not be_nil
  end
end
