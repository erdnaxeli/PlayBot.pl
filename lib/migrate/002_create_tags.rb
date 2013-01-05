class CreateTags < ActiveRecord::Migration
    def self.up
        create_table :tags do |t|
            t.string :tag
            t.integer :video
        end
        
        add_index :tags, [:tag, :video], :unique
    end

    def self.down
        drop_table :tags
    end
end
