require 'rubygems'
require 'bundler/setup'

class CreateMusics < ActiveRecord::Migration
    def self.up
        create_table :musics do |t|
            t.string :title, :null => false
            t.string :author, :null => false
            t.string :sender, :null => false
            t.string :url, :null => false
            t.string :file
            t.timestamps
        end

        add_index :musics, :url, :unique
    end

    def self.down
        drop_table :musics
    end
end
