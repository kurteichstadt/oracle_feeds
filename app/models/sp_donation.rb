class SpDonation < ActiveRecord::Base

  def self.update_from_peoplesoft
    rows = PsDonation.connection.select_all("select * from hrsdon.ps_student_load_vw")
    donation_ids = []
    rows.each do |row|
      row[:designation_number] = row.delete('designation')
      row[:donor_name] = row.delete('acct_name')
      row[:medium_type] = row.delete('don_medium_type')
      if donation = SpDonation.find_by_donation_id(row['donation_id'])
        donation.update_attributes(row)
      else
        SpDonation.create(row)
      end
      donation_ids << row['donation_id']
    end

    # Delete any donations not found in this dump
    SpDonation.delete_all(["donation_date >  ? and donation_id not in (?)", 1.year.ago, donation_ids])

    rows.length
  end


end

