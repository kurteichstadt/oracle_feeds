class Person < ActiveRecord::Base 
  self.table_name = "ministry_person"
  self.primary_key = "personID"
end
