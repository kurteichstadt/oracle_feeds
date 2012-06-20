class SpDonation < ActiveRecord::Base

  def self.update_from_peoplesoft
    # last_date = SpDonation.maximum(:donation_date) || 2.years.ago
    rows = PsDonation.connection.select_all("select * from hrsdon.ps_student_load_vw")
    SpDonation.delete_all(["donation_date >  ?", 1.year.ago])
    SpDonation.transaction do
      rows.each do |row|
        row[:designation_number] = row.delete('designation')
        row[:donor_name] = row.delete('acct_name')
        row[:medium_type] = row.delete('don_medium_type')
        if donation = SpDonation.find_by_donation_id(row['donation_id'])
          donation.update_attributes(row)
        else
          SpDonation.create(row)
        end
      end
    end
    rows.length
  end


end

