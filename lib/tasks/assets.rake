# frozen_string_literal: true

# The stylesheet has to exist before the first page is rendered. Propshaft
# raises rather than serving an asset that is not there, and in production it
# serves only from `public/assets`, so a node started from an image that was
# never precompiled renders every screen unstyled with nothing in the log to
# say why.
#
# Boot is where this belongs, not a file watcher. The watcher writes
# `app/assets/builds`, which a production node never reads, and it starts beside
# the web process rather than before it — which is how a new installation serves
# its first pages bare while the watcher looks perfectly healthy.
#
# It runs only when the file is missing, so an image built by the Dockerfile,
# which precompiles, and every boot after the first both skip it.
namespace :assets do
  desc "Build what this environment serves the stylesheet from, when it is missing"
  task :prepare do
    if Rails.env.production?
      manifest = Rails.root.join("public/assets/.manifest.json")
      next if manifest.exist?

      puts "assets:prepare — precompiling, because public/assets/.manifest.json is missing"
      Rake::Task["assets:precompile"].invoke
    else
      stylesheet = Rails.root.join("app/assets/builds/tailwind.css")
      next if stylesheet.exist?

      puts "assets:prepare — building the stylesheet, because app/assets/builds/tailwind.css is missing"
      Rake::Task["tailwindcss:build"].invoke
    end
  end
end
