class BalanceUpdater
  def self.update_balances_from_ps
    pu = BalanceUpdater.new
    pu.update_balances
  end

  def update_balances
    balances = PsEmployee.connection.select_rows("select lm.emplid as emplid, (lm.last_month_bal + nvl(tm.dasum,0)) as cur_bal from " + 
                                                 "(select emplid, last_month_bal from staff_last_bal_vw) lm left join (select emplid, sum(trans_amount) as dasum from SYSADM.PS_STAFF_TRNSACTNS a " +
                                                 "where a.stf_acct_type = 'PRIME' and a.trans_date > '01-may-2010' and a.posted_flag = 'N' group by emplid) tm " + 
                                                 "on lm.emplid = tm.emplid order by lm.emplid")

    balances.each do |balance_row|
      p = Person.find_by_accountNo(balance_row[0])
      if p
        p.balance_daily = balance_row[1]
        p.fk_ssmUserId = nil if p.fk_ssmUserId == 0
        Rails.logger.info("Balance updated for Person #{p.id} (#{p.firstName.to_s + " " + p.lastName.to_s}):  #{p.changes}")
        p.save!(:validate => false)
      end
    end
  end
end

