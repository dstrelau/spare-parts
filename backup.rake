namespace :db do
  namespace :backup do

    def interesting_tables
      return ENV['TABLES'].split(',') if ENV['TABLES']
      ActiveRecord::Base.connection.tables.sort.reject! do |tbl|
        ['schema_info', 'sessions'].include?(tbl)
      end
    end

    desc "Dump db to yaml. Use TABLES=x,y,z to specifiy just certain tables."
    task :write => :environment do

      dir = RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
      FileUtils.chdir(dir)

      interesting_tables.each do |tbl|

        klass = tbl.classify.constantize
        puts "Writing #{tbl}..."
        File.open("#{tbl}.yml", 'w+') { |f| YAML.dump klass.find(:all).collect(&:attributes), f }
      end

    end

    desc "Load tables from yaml backup. Use TABLES=x,y,z to specify just certain tables."
    task :read => :environment do

      dir = RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
      FileUtils.chdir(dir)

      interesting_tables.each do |tbl|

        klass = tbl.classify.constantize
        ActiveRecord::Base.transaction do

          puts "Loading #{tbl}..."
          YAML.load_file("#{tbl}.yml").each do |fixture|
            ActiveRecord::Base.connection.execute "INSERT INTO #{tbl} (#{fixture.keys.join(",")}) VALUES (#{fixture.values.collect { |value| ActiveRecord::Base.connection.quote(value) }.join(",")})", 'Fixture Insert'
          end
        end
      end

    end

  end
end