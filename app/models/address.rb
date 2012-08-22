class Address < ActiveRecord::Base
  self.table_name = "ministry_newaddress"
	self.primary_key = "addressID"
	
	belongs_to :person, :foreign_key => "fk_PersonID"
end
