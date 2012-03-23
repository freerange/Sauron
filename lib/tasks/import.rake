namespace :messages do
  task :import do
    require 'account_message_importer'
    AccountMessageImporter.import_for(ENV["EMAIL"], ENV["PASSWORD"])
  end
end