require 'rubygems'
require 'bundler/setup'
require 'active_record'

# Music Object
#
# Its attribut are :
#  * title
#  * author
#  * url
#  * sender
#  * file
#  * created_ad
class Music < ActiveRecord::Base
end
