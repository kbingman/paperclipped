namespace :radiant do
  namespace :extensions do
    namespace :paperclipped do
      
      desc "Runs the migration of the Assets extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          PaperclippedExtension.migrator.migrate(ENV["VERSION"].to_i)
          Rake::Task['db:schema:dump'].invoke
        else
          PaperclippedExtension.migrator.migrate
          Rake::Task['db:schema:dump'].invoke
        end
      end
      
      desc "Copies public assets of the Assets to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[PaperclippedExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(PaperclippedExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
        
        # unless PaperclippedExtension.starts_with? RAILS_ROOT # don't need to copy vendored tasks
        #   puts "Copying rake tasks from PaperclippedExtension"
        #   local_tasks_path = File.join(RAILS_ROOT, %w(lib tasks))
        #   mkdir_p local_tasks_path, :verbose => false
        #   Dir[File.join PaperclippedExtension.root, %w(lib tasks *.rake)].each do |file|
        #     cp file, local_tasks_path, :verbose => false
        #   end
        # end

        desc "Syncs all available translations for this ext to the English ext master"
        task :sync => :environment do
          # The main translation root, basically where English is kept
          language_root = PaperclippedExtension.get_translation_keys(language_root)

          Dir["#{language_root}/*.yml"].each do |filename|
            next if filename.match('_available_tags')
            basename = File.basename(filename, '.yml')
            puts "Syncing #{basename}"
            (comments, other) = TranslationSupport.read_file(filename, basename)
            words.each { |k,v| other[k] ||= words[k] }  # Initializing hash variable as empty if it does not exist
            other.delete_if { |k,v| !words[k] }         # Remove if not defined in en.yml
            TranslationSupport.write_file(filename, basename, comments, other)
          end
        end
      end
      
      desc "Exports assets from database to assets directory"
      task :export => :environment do
        asset_path = File.join(RAILS_ROOT, "assets")
        mkdir_p asset_path
        Asset.find(:all).each do |asset|
          puts "Exporting #{asset.asset_file_name}"
          cp asset.asset.path, File.join(asset_path, asset.asset_file_name)
        end
        puts "Done."
      end

      desc "Imports assets to database from assets directory"
      task :import => :environment do
        asset_path = File.join(RAILS_ROOT, "assets")
        if File.exist?(asset_path) && File.stat(asset_path).directory?
          Dir.glob("#{asset_path}/*").each do |file_with_path|
            if File.stat(file_with_path).file?
              new_asset = File.new(file_with_path) 
              puts "Creating #{File.basename(file_with_path)}"
              Asset.create :asset => new_asset
            end
          end
        end
      end
      
      desc "Migrates page attachments from the original page attachments extension into new Assets"
      task :migrate_from_page_attachments => :environment do
        puts "This task can clean up traces of the page_attachments (think table records and files currently in /public/page_attachments).
If you would like to use this mode type \"yes\", type \"no\" or just hit enter to leave them untouched for now."
        answer = STDIN.gets.chomp
        erase_tracks = answer.eql?('yes') ? true : false
        OldPageAttachment.find_all_by_parent_id(nil).each do |opa|
          asset = opa.create_paperclipped_record
          # move the actual file
          old_dir = "#{RAILS_ROOT}/public/page_attachments/0000/#{opa.id.to_s.rjust(4,'0')}"
          new_dir = "#{RAILS_ROOT}/public/assets/#{asset.id}"
          puts "Copying #{old_dir.gsub(RAILS_ROOT, '')}/#{opa.filename} to #{new_dir.gsub(RAILS_ROOT, '')}/#{opa.filename}..."
          mkdir_p new_dir
          cp old_dir + "/#{opa.filename}", new_dir + "/#{opa.filename}"
          # remove old record and remainings
          if erase_tracks
            rm_rf old_dir
          end
        end
        # regenerate thumbnails
        @assets = Asset.find(:all)
        @assets.each do |asset|
          asset.asset.reprocess!
          asset.save
        end
        puts "Done."
      end
      
      desc "Migrates from old 'assets' extension."
      task :migrate_from_assets => :environment do
        Asset.delete_all("thumbnail IS NOT NULL OR parent_id IS NOT NULL")
        ActiveRecord::Base.connection.tap do |c|
          c.rename_column :assets, :filename, :asset_file_name
          c.rename_column :assets, :content_type, :asset_content_type
          c.rename_column :assets, :size, :asset_file_size
          c.remove_column :assets, :parent_id
          c.remove_column :assets, :thumbnail
        end

        PaperclippedExtension.migrator.new(:up, PaperclippedExtension.migrations_path).send(:assume_migrated_upto_version, 3)
        PaperclippedExtension.migrator.migrate
      end
    end
  end
end
