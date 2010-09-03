namespace :oa_notes do
  desc "Sync the oa_notes resources (javascripts, stylesheets, images ...) to the public dir"
  task :sync_resources do
    system "rsync -ruv vendor/plugins/oa_notes/public/javascripts/ public/javascripts/oa_notes"
    system "rsync -ruv vendor/plugins/oa_notes/public/stylesheets/ public/stylesheets/oa_notes"
    system "rsync -ruv vendor/plugins/oa_notes/public/images/ public/images/oa_notes"
  end
end