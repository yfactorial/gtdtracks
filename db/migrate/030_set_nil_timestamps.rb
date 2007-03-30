class SetNilTimestamps < ActiveRecord::Migration

  class Project < ActiveRecord::Base; end
  class Context < ActiveRecord::Base; end

  def self.up
    Project.find_all_by_created_at(nil).each do |p|
      Project.update( p.id, {:created_at => Time.now.utc} )
    end
    Project.find_all_by_updated_at(nil).each do |p|
      Project.update( p.id, {:updated_at => Time.now.utc} )
    end
    Context.find_all_by_created_at(nil).each do |p|
      Context.update( p.id, {:created_at => Time.now.utc} )
    end
    Context.find_all_by_updated_at(nil).each do |p|
      Context.update( p.id, {:updated_at => Time.now.utc} )
    end
    
  end

  def self.down
    #nothing to do here...
  end
end
