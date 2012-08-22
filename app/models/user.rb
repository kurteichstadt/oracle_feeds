class User < ActiveRecord::Base
  self.table_name = "simplesecuritymanager_user"
  self.primary_key = "userID"
  
  has_one :person, :foreign_key => 'fk_ssmUserID' 
end