namespace :db do
  namespace :backup do

    def interesting_tables
      return ENV['TABLES'].split(',') if ENV['TABLES']
      ActiveRecord::Base.connection.tables.sort.reject! do |tbl|
        ['schema_info', 'sessions'].include?(tbl) ||
        ( ENV['IGNORE'] && ENV['IGNORE'].split(',').include?(tbl) )
      end
    end

    desc "Dump db to yaml. Use TABLES=x,y,z to specifiy just certain tables. Use IGNORE=a,b to exclude certain tables. DIR=/some/path to specify a backup directory."
    task :write => :environment do

      dir = RAILS_ROOT + (ENV['DIR'] || '/db/backup')
      FileUtils.chdir(dir)

      written = []

      interesting_tables.each do |tbl|
        begin
          klass = tbl.classify.constantize
        rescue NameError
          nil
        else
          puts "Writing #{tbl}..."
          File.open("#{tbl}.yml", 'w+') { |f| 
            YAML.dump(klass.find(:all).collect(&:attributes), f)
          }
          written << tbl
          
          klass.reflect_on_all_associations(:has_and_belongs_to_many).reject {|join|
            written.include?(join.options[:join_table])
          }.each {|join|
            assocs = []
            join_tbl = join.options[:join_table]
            puts "Writing #{join_tbl}..."
            File.open("#{join_tbl}.yml", 'w+') {|f|
              YAML.dump(ActiveRecord::Base.connection.select_all("SELECT * FROM #{join_tbl}"), f)
            }
            written << join_tbl
          }
        end #begin
      end #each table
    end #:write

    desc "Load tables from yaml backup. Use TABLES=x,y,z to specify just certain tables. Use IGNORE=a,b to exclude certain tables. DIR=/some/path to specify a backup directory."
    task :load => :environment do

      dir = ENV['DIR'] || RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
      FileUtils.chdir(dir)
      
      read = []

      interesting_tables.each do |tbl|

        begin
          klass = tbl.classify.constantize
        rescue NameError
          nil
        else
          insert_fixtures_for(tbl)
          read << tbl

          klass.reflect_on_all_associations(:has_and_belongs_to_many).reject {|join|
            read.include?(join.options[:join_table])
          }.each do |join|
            insert_fixtures_for(join.options[:join_table])
            read << join.options[:join_table]
          end

        end #begin

      end #each table

    end #:load
    
    def insert_fixtures_for(tbl)
      puts "Loading #{tbl}..."
      ActiveRecord::Base.transaction do
        YAML.load_file("#{tbl}.yml").each do |fixture|
          begin
            ActiveRecord::Base.connection.execute "INSERT INTO #{tbl} (#{fixture.keys.join(",")}) VALUES (#{fixture.values.collect { |value| ActiveRecord::Base.connection.quote(value) }.join(",")})", 'Fixture Insert'
          rescue
            puts "Insert of #{tbl}:#{fixture['id']} failed."
          end
        end
      end
    end

  end #:backup
end #:db