class Person < ActiveRecord::Base 
  self.table_name = "ministry_person"
  self.primary_key = "personID"

  has_one :current_address, :foreign_key => "fk_PersonID", :conditions => "addressType = 'current'", :class_name => '::Address'
  has_one :permanent_address, :foreign_key => "fk_PersonID", :conditions => "addressType = 'permanent'", :class_name => '::Address'
  belongs_to :user, :foreign_key => "fk_ssmUserId"  #Link it to SSM
  has_one :staff
end
