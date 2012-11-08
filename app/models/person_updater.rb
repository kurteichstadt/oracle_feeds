class PersonUpdater
  def self.update_people_from_ps
    pu = PersonUpdater.new # Even though this could be a fully static class, I think it's more readable to deal with variables within an instance
    pu.update_people
  end

  def update_people
    Rails.logger.info("Updating Staff/Person records from PS...")
    update_staff_records
    update_person_records
    Rails.logger.info("Done!")
  end

  private

  def update_staff_records
    insert_and_remove_staff_records
    update_staff_record_attributes
  end

  def insert_and_remove_staff_records
    staff = Staff.select("accountNo").where("removedFromPeopleSoft = 'N'").all.collect(&:accountNo)
    pstaff = PsEmployee.select("emplid, first_name, last_name").order("emplid")
    pstaff.each do |p_record|
      s_record = Staff.find_by_accountNo(p_record.emplid)
      if s_record # This record exists already
        # Check to make sure it's the right person
        if s_record.lastName.upcase == p_record.last_name.upcase && s_record.firstName.upcase == p_record.first_name.upcase
          staff.delete(p_record.emplid)
          #Rails.logger.info("Record #{p_record.emplid} exists (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}).")
        else # Name doesn't match
          maiden = PsCccPersData.where("emplid = ?", p_record.emplid).first
          if maiden && !maiden.maiden_emplid.blank? # Changed emplid at some point
            maiden_record = Staff.find_by_accountNo(maiden.maiden_emplid)
            # Check maiden record for name accuracy
            if maiden_record && maiden_record.lastName.upcase == p_record.last_name.upcase && maiden_record.firstName.upcase == p_record.first_name.upcase
              # Name is correct in maiden_record
              unless Staff.find_by_accountNo(s_record.accountNo + "_old")
                s_record.update_attribute(:accountNo, s_record.accountNo + "_old")
                s_record.removedFromPeopleSoft = "Y"
                s_record.person_id = nil
                s_record.save!
              else # There's already an _old record, so we'll just get rid of this one
                s_record.destroy
              end
              switch_account_number(maiden_record, p_record.emplid)
              staff.delete(p_record.emplid)
              Rails.logger.info("Record #{p_record.emplid} existed (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}), but name didn't match (#{s_record.firstName.to_s + " " + s_record.lastName.to_s}).  Found maiden record #{maiden.maiden_emplid} and switched account numbers.")
            elsif maiden_record
              # Name is incorrect in maiden_record, will switch anyway
              unless Staff.find_by_accountNo(s_record.accountNo + "_old")
                s_record.update_attribute(:accountNo, s_record.accountNo + "_old")
                s_record.removedFromPeopleSoft = "Y"
                s_record.person_id = nil
                s_record.save!
              else # There's already an _old record, so we'll just get rid of this one
                s_record.destroy
              end
              switch_account_number(maiden_record, p_record.emplid)
              staff.delete(p_record.emplid)
              Rails.logger.info("Record #{p_record.emplid} existed (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}), but name didn't match (#{s_record.firstName.to_s + " " + s_record.lastName.to_s}).  Found maiden record #{maiden.maiden_emplid} but name still didn't match (#{maiden_record.firstName.to_s + " " + maiden_record.lastName.to_s}).  Switched account numbers anyway.")
            else
              # Maiden record not found in our database, leave as is.
              staff.delete(p_record.emplid)
              Rails.logger.info("Record #{p_record.emplid} exists (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}), but name doesn't match (#{s_record.firstName.to_s + " " + s_record.lastName.to_s}).  Maiden record exists in PS, not in Staff table.  Leaving as is.")
            end
          else
            staff.delete(p_record.emplid)
            Rails.logger.info("Record #{p_record.emplid} exists (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}), but name doesn't match (#{s_record.firstName.to_s + " " + s_record.lastName.to_s}).  No maiden record found.  Leaving as is.")
          end
        end
      else # record does not exist
        maiden = PsCccPersData.where("emplid = ?", p_record.emplid).first
        if maiden && !maiden.maiden_emplid.blank? # Changed emplid at some point
          s_record = Staff.find_by_accountNo(maiden.maiden_emplid)
          if s_record
            switch_account_number(s_record, maiden.emplid)
            staff.delete(maiden.maiden_emplid)
            Rails.logger.info("Record #{p_record.emplid} did not exist (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}).  Found old record #{maiden.maiden_emplid} from maiden table and switched account numbers for staff record (#{s_record.firstName.to_s + " " + s_record.lastName.to_s}).")
          else
            s = Staff.new({:firstName => p_record.first_name, :lastName => p_record.last_name, :removedFromPeopleSoft => "N"})
            s.accountNo = p_record.emplid
            s.save!
            Rails.logger.info("Record #{p_record.emplid} did not exist (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}).  Did not find a record from maiden table.  Created new record.")
          end
        else
          s = Staff.new({:firstName => p_record.first_name, :lastName => p_record.last_name, :removedFromPeopleSoft => "N"})
          s.accountNo = p_record.emplid
          s.save!
          Rails.logger.info("Record #{p_record.emplid} did not exist (#{p_record.first_name.to_s + " " + p_record.last_name.to_s}).  Did not find a record in maiden table.  Created new record.")
        end
      end
    end

    # Staff records not accounted for in PS, check and set removedFromPeopleSoft to "Y"
    staff.each do |account_no|
      s_record = Staff.find_by_accountNo(account_no)
      if s_record
        if PsEmployee.find_by_emplid(s_record.accountNo)
          Rails.logger.info("Record #{s_record.accountNo} is in PS but was never checked off.  Why????????????????????????")
        else
          s_record.removedFromPeopleSoft = "Y"
          s_record.save!
          Rails.logger.info("Record #{s_record.accountNo} removed from PS.")
        end
      end
    end
  end

  def update_staff_record_attributes
    ps_records = PsEmployee.includes(:psTaxLocation).order(:emplid)
    ps_records.each do |ps_record|
      staff = Staff.where("accountNo = ?", ps_record.emplid).includes(:primary_address, :secondary_address).first
      if staff
        set_staff_attributes(staff, ps_record)
        staff.save!
      else
        Rails.logger.info("Could not find Record #{ps_record.emplid} (#{ps_record.first_name.to_s + " " + ps_record.last_name.to_s} in Staff table while performing attributes update.)")
      end
    end
  end

  def switch_account_number(staff, account_no)
    old_record = staff.dup
    staff.removedFromPeopleSoft = "N"
    staff.accountNo = account_no
    staff.save!
    old_record.removedFromPeopleSoft = "Y"
    old_record.person_id = nil
    old_record.save!
  end

  def set_staff_attributes(staff, ps_record)
    staff.isMale = ("M" == ps_record.sex) ? "T" : "F"
    staff.birthDate = ps_record.birthdate.to_date if ps_record.birthdate
    staff.maritalStatus = ps_record.mar_status.strip
    staff.marriageDate = ps_record.mar_status_dt.to_date if ps_record.mar_status_dt
    if "E" == ps_record.employee_flag
      staff.hireDate = ps_record.hire_dt.to_date if ps_record.hire_dt
      staff.rehireDate = ps_record.rehire_dt.to_date if ps_record.rehire_dt
      staff.origHiredate = ps_record.orig_hire_dt.to_date if ps_record.orig_hire_dt
    else
      staff.hireDate = nil
      staff.rehireDate = nil
      staff.origHiredate = nil
    end
    staff.serviceDate = ps_record.service_dt.to_date if ps_record.service_dt
    staff.workPhone = ps_record.work_phone.strip
    staff.deptId = ps_record.deptid.strip
    staff.jobCode = ps_record.jobcode.strip
    staff.accountCode = ps_record.acct_cd.strip
    staff.jobTitle = ps_record.jobtitle.strip
    staff.deptName = ps_record.deptname.strip

    staff.primaryEmpLocCity = ps_record.psTaxLocation.city.strip if ps_record.psTaxLocation
    staff.primaryEmpLocState = ps_record.psTaxLocation.state.strip if ps_record.psTaxLocation
    staff.primaryEmpLocCountry = ps_record.psTaxLocation.country.strip if ps_record.psTaxLocation
    staff.primaryEmpLocDesc = ps_record.psTaxLocation.descr.strip if ps_record.psTaxLocation

    staff.jobStatus = PsCccStatusTbl.translate_status(ps_record.status_code.strip)
    staff.ministry = PsDeptTbl.translate_ministry(ps_record.ccc_ministry.strip)
    staff.region = PsRegion.translate_region(ps_record.ccc_sub_ministry.strip)
    staff.strategy = PsStrategy.translate_strategy(ps_record.lane_outreach.strip)
    staff.position = PsRespScope.translate_resp_scope(ps_record.respons_scope.strip)

    staff.middleName = ps_record.middle_name.strip
    staff.statusDescr = ps_record.status_descr.strip
    staff.internationalStatus = ps_record.internation_status.strip
    staff.balance = ps_record.balance
    staff.cccHrSendingDept = ps_record.ccc_hr_sndng_dept.strip
    staff.cccHrCaringDept = ps_record.ccc_hr_caring_dept.strip
    staff.cccCaringMinistry = ps_record.ccc_carng_ministry.strip
    staff.assignmentLength = ps_record.assignment_lngth.strip


    # guarentees that if a staff is reloaded at night, they are said to be on peoplesoft.  (I.E., seen on Infobase)
    staff.removedFromPeopleSoft = "N"

    # Update spousal info
    update_spouse_info(staff, ps_record)

    staff.reportingDate = ps_record.reporting_date.to_date if ps_record.reporting_date
    staff.coupleTitle = ps_record.couple_name_prefix.strip
    staff.firstName = ps_record.first_name.strip
    staff.lastName = ps_record.last_name.strip
    staff.email = ps_record.email_addr.strip
    staff.preferredName = ps_record.pref_first_name.strip
    staff.homePhone = ps_record.home_phone.strip
    staff.otherPhone = ps_record.phone.strip # Actually a duplicate of home phone
    staff.mobilePhone = ps_record.cell_phone.strip

    staff.countryCode = ps_record.nid_country.strip

    if "SECURE" != staff.countryCode.upcase 
      set_addr(staff, ps_record)
    end

    staff.isSecure = (ps_record.secure_employee == "Y") ? "T" : "F"

    Rails.logger.info("Changes for Staff #{ps_record.emplid} (#{ps_record.first_name.to_s + " " + ps_record.last_name.to_s}):  #{staff.changes}") if staff.changed?
  end

  def update_spouse_info(staff, ps_record)
    staff.spouseFirstName = ps_record.spouse_name.strip
    staff.spouseLastName = ps_record.last_name.strip

    accountNo = ps_record.emplid.strip

    # If husband account
    if accountNo.size == 9 && accountNo.last != 'S'
      wife_account_no = accountNo + "S";
      wife = Staff.find_by_accountNo(wife_account_no)
      if wife
        staff.spouseAccountNo = wife_account_no      
        wife.spouseAccountNo = accountNo
        wife.save!
      end
    elsif accountNo.size == 10 && accountNo.last == 'S'
      husband_account_no = accountNo[0,9]
      husband = Staff.find_by_accountNo(husband_account_no)
      if husband
        staff.spouseAccountNo = husband_account_no     
        husband.spouseAccountNo = accountNo
        husband.save!
      end
    end
  end

  def set_addr(staff, ps_record)
    add1 = staff.primary_address
    unless add1
      add1 = StaffAddress.new
      Rails.logger.info("Address1 for " + staff.firstName + " " + staff.lastName + " not persistant; creating new one");
    end
    add1.address1 = ps_record.address1.strip
    add1.address2 = ps_record.address2.strip
    add1.address3 = ps_record.address3.strip
    add1.address4 = ps_record.address4.strip
    add1.city = ps_record.city.strip
    add1.state = ps_record.state.strip
    add1.zip = ps_record.postal.strip
    add1.country = ps_record.country.strip
    add1.save!
    staff.primary_address = add1

    add2 = staff.secondary_address
    unless add2
      add2 = StaffAddress.new
      Rails.logger.info("Address2 for " + staff.firstName + " " + staff.lastName + " not persistant; creating new one");
    end
    add2.address1 = ps_record.address1_other.strip
    add2.address2 = ps_record.address2_other.strip
    add2.address3 = ps_record.address3_other.strip
    add2.city = ps_record.city_other.strip
    add2.state = ps_record.state_other.strip
    add2.zip = ps_record.postal_other.strip
    add2.country = ps_record.country_other.strip
    add2.save!
    staff.secondary_address = add2
  end


  def update_person_records
    Staff.where("removedFromPeopleSoft <> 'Y'").includes(:primary_address, :secondary_address, :person => [:current_address, :permanent_address, :email_addresses, :phone_numbers])
      .find_each do |staff|
        unless staff.person
          find_or_create_person(staff)
        end
        update_person_attributes(staff)
    end
  end

  def find_or_create_person(staff)
    p = Person.find_by_accountNo(staff.accountNo)
    if p && !p.staff && p.firstName.upcase == staff.firstName.upcase && p.lastName.upcase == staff.lastName.upcase
      staff.person = p
      staff.save!
      Rails.logger.info("Staff record #{staff.accountNo} associated with Person record #{staff.person.id} by account number.")
    end

    u = User.find_by_username(staff.email) unless staff.person
    if !staff.person && u && u.person && !u.person.staff && u.person.firstName.upcase == staff.firstName.upcase && u.person.lastName.upcase == staff.lastName.upcase
      staff.person = u.person
      staff.save!
      Rails.logger.info("Staff record #{staff.accountNo} associated with Person record #{staff.person.id} by username.")
    end

    addr = Address.where("addressType = 'current'").where("email = ?", staff.email).first unless staff.person
    if !staff.person && addr && addr.person && !addr.person.staff && addr.person.firstName.upcase == staff.firstName.upcase && addr.person.lastName.upcase == staff.lastName.upcase
      staff.person = addr.person
      staff.save!
      Rails.logger.info("Staff record #{staff.accountNo} associated with Person record #{staff.person.id} by email address.")
    end

    unless staff.person
      p = Person.new(:accountNo => staff.accountNo, :firstName => staff.firstName, :lastName => staff.lastName)
      p.save!
      staff.person = p
      staff.save!
      Rails.logger.info("Staff record #{staff.accountNo} not found in Person table.  Created new Person record.")
    end
  end

  def update_person_attributes(staff)
    person = staff.person

    person.accountNo = staff.accountNo
    person.isSecure = staff.isSecure
    person.firstName = staff.firstName
    person.preferredName = staff.preferredName
    person.lastName = staff.lastName

    person.gender = staff.isMale == "T" ? "1" : "0"
    person.maritalStatus = staff.maritalStatus
    spouse = Staff.find_by_accountNo(staff.spouseAccountNo)
    if spouse && spouse.person
      spouse_person = spouse.person
      person.fk_spouseID = spouse_person.id
      spouse_person.fk_spouseID = person.id
      if spouse_person.changed?
        spouse_person.fk_ssmUserId = nil if spouse_person.fk_ssmUserId == 0
        Rails.logger.info("Changes for Spouse #{spouse_person.id} (#{spouse_person.firstName.to_s + " " + spouse_person.lastName.to_s}):  #{spouse_person.changes}")
        spouse_person.save!
      end
    end

    person.ministry = staff.ministry
    if ("NC SE MA MS GP GL NW RR UM SW NE HLIC KEY").include?(staff.region)
      person.region = staff.region
    else 
      person.region = ""
    end
    person.strategy = staff.strategy
    person.isStaff = staff.removedFromPeopleSoft == "N" && Staff.staff_positions.include?(staff.jobStatus)

    if staff.birthDate > '1/1/1901'.to_date
      person.birth_date = staff.birthDate
    else
      person.birth_date = nil
    end
    if person.changed?
      person.fk_ssmUserId = nil if person.fk_ssmUserId == 0
      Rails.logger.info("Changes for Person #{person.id} (#{person.firstName.to_s + " " + person.lastName.to_s}):  #{person.changes}")
      person.save!
    end

    unless person.current_address
      address = Address.new(:addressType => 'current')
      address.person = person
      address.save!
      person.current_address(true)
    end
    current_address = person.current_address
    home_address = staff.primary_address
    push_address(home_address, current_address, staff);

    unless person.permanent_address
      address = Address.new(:addressType => 'permanent')
      address.person = person
      address.save!
      person.permanent_address(true)
    end
    permanent_address = person.permanent_address
    mailing_address = staff.secondary_address
    push_address(mailing_address, permanent_address, staff);
    
    person.primary_email_address = staff.email if !staff.email.blank?
    
    person.set_phone_number(staff.homePhone, "home", true) if !staff.homePhone.blank?
    person.set_phone_number(staff.workPhone, "work", true) if !staff.workPhone.blank?
    person.set_phone_number(staff.mobilePhone, "mobile", true) if !staff.mobilePhone.blank?
  end

  def push_address(staff_address, person_address, staff)
    person_address.address1 = staff_address.address1
    person_address.address2 = staff_address.address2
    person_address.address3 = staff_address.address3
    person_address.address4 = staff_address.address4
    person_address.city = staff_address.city
    person_address.state = staff_address.state
    person_address.zip = staff_address.zip
    person_address.country = staff_address.country
    person_address.city = staff_address.city

    person_address.homePhone = staff.homePhone
    person_address.workPhone = staff.workPhone
    person_address.cellPhone = staff.mobilePhone
    person_address.fax = staff.fax
    person_address.email = staff.email
    if person_address.changed?
      person_address.save!
    end
  end
end

