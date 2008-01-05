namespace :db do
  namespace :backup do

    def interesting_tables
      return ENV['TABLES'].split(',') if ENV['TABLES']
      ActiveRecord::Base.connection.tables.sort.reject! do |tbl|
        ['schema_info', 'sessions'].include?(tbl) ||
        ( ENV['IGNORE'] && ENV['IGNORE'].split(',').include?(tbl) )
      end
    end

    desc "Dump db to yaml. Use TABLES=x,y,z to specifiy just certain tables. Use IGNORE=a,b to exclude certain tables."
    task :write => :environment do

      dir = RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
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
            puts "Writing #{join_tbl}"
            File.open("#{join_tbl}.yml", 'w+') {|f|
              YAML.dump(ActiveRecord::Base.connection.select_all("SELECT * FROM #{join_tbl}"), f)
            }
            written << join_tbl
          }
        end #begin
      end #each table
    end #:write

    desc "Load tables from yaml backup. Use TABLES=x,y,z to specify just certain tables. Use IGNORE=a,b to exclude certain tables."
    task :load => :environment do

      dir = RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
      FileUtils.chdir(dir)

      interesting_tables.each do |tbl|

        begin
          klass = tbl.classify.constantize
        rescue NameError
          nil
        else
          ActiveRecord::Base.transaction do
            puts "Loading #{tbl}..."
            YAML.load_file("#{tbl}.yml").each do |fixture|
              ActiveRecord::Base.connection.execute "INSERT INTO #{tbl} (#{fixture.keys.join(",")}) VALUES (#{fixture.values.collect { |value| ActiveRecord::Base.connection.quote(value) }.join(",")})", 'Fixture Insert'
            end
          end #transaction
        end #begin
        
      end #each table

    end #:load

  end #:backup
end #:db