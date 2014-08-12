#!/usr/bin/env ruby

specs = ["../../spec/QA/telesign_json_spec.rb"]

def separator(text, double=false)
  puts('#' * 78) if double
  puts text
  puts('#' * 78)
end

def header(text)
  separator(text, true)
end

success = true

header("Mock TeleSign QA Tests Running Locally")

separator("Chrome")
ENV['TEST_ENV'] = 'local'
ENV['BROWSER'] = 'chrome'
ENV['ENVIRONMENT'] = 'local'
success = system("rspec #{specs.join(' ')}") && success

exit(success)
