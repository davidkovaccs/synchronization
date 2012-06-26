#class ItemToSync < Refinery::Core::BaseModel
#  attr_accessible :name, :length
#  synchronizable
#  json_attrs :fields => [:name, :length]
#end
#
#FactoryGirl.define do
#  factory :item_to_sync, :class => ItemToSync do
#    sequence(:name) { |n| "name_of_item_to_sync#{n}" }
#    sequence(:length) { |n| n }
#  end
#end
