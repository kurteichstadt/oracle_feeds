class Person < ActiveRecord::Base 
  self.table_name = "ministry_person"
  self.primary_key = "personID"

  has_one :current_address, :foreign_key => "fk_PersonID", :conditions => "addressType = 'current'", :class_name => '::Address'
  has_one :permanent_address, :foreign_key => "fk_PersonID", :conditions => "addressType = 'permanent'", :class_name => '::Address'
  has_many :email_addresses, :foreign_key => "person_id", :class_name => '::EmailAddress'
  has_many :phone_numbers, :foreign_key => "person_id", :class_name => '::PhoneNumber'
  belongs_to :user, :foreign_key => "fk_ssmUserId"  #Link it to SSM
  has_one :staff
  
  def primary_email_address=(email)
    old_primary = email_addresses.select{ |email| email.primary == true }.first
    if old_primary
      old_primary.primary = 0
      old_primary.save!
    end

    old_email_record = email_addresses.select{ |email_record| email_record.email == email }.first
    if old_email_record
      old_email_record.primary = 1
      old_email_record.save!
    else
      EmailAddress.create!(:email => email, :person_id => self.id, :primary => 1)
    end
  end
  
  def set_phone_number(phone, location, primary=false, extension=nil)
    if primary
      old_primary = phone_numbers.select{ |phone| phone.primary == true }.first
      if old_primary
        old_primary.primary = 0
        old_primary.save!
      end
    end
        
    old_phone_record = phone_numbers.select{ |phone| phone.location == location }.first
    if old_phone_record
      old_phone_record.number = phone
      old_phone_record.extension = extension
      old_phone_record.primary = primary
      old_phone_record.save!
    else
      PhoneNumber.create!(:number => phone, :location => location, :extension => extension, :primary => primary, :person_id => self.id)
    end
  end
end
