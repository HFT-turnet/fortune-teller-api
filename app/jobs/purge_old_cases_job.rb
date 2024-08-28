class PurgeOldCasesJob < ApplicationJob
  queue_as :default

  # PurgeOldCasesJob.perform_now

  # PATH=/var/www/vhosts/SERVERPATH/.rbenv/shims:$PATH
  # cd SERVERPATH
  # bin/rails runner -e production PurgeOldCasesJob.perform_now
  
  def perform()
    # This job is to clean user data from the database within a given timeframe. It is intended to be run on a regular basis.
    # The first check is in simulation data, because most client interactions should have led to simulations.
    # The second check is in case data, if a case does not have any simulations, it can also run out of validity.

    validity=60.days.ago
    # Get the case IDs and most recent simulation date
    sql="
        SELECT case_id, updated_at FROM ( SELECT case_id, updated_at,
        ROW_NUMBER() OVER (PARTITION
        BY case_id ORDER BY updated_at DESC)
        as rn
        FROM simulations
        ) subquery
        WHERE rn = 1;"
    data=ActiveRecord::Base.connection.exec_query(sql)
    # Extract the case IDs that must be considered for removal
    cases_with_simulation_overdue=data.rows.select{|x| x[1]<validity}
    # Get the cases without simulations
    cases_without_simulations = Case.left_outer_joins(:simulations)
                                    .where(simulations: { id: nil }).pluck(:id)
    # Merge the two arrays
    cases_to_check=cases_without_simulations + cases_with_simulation_overdue.map{|x| x[0]}
    cases_to_delete=Case.where(id: cases_to_check).where(nodelete: 0).where("updated_at < ?", validity)
    cases_to_delete.each do |deletecase|
      deletecase.delete_all
    end
   end
end