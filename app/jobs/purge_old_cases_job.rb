class PurgeOldCasesJob < ApplicationJob
  queue_as :default

  # Retention periods
  NORMAL_RETENTION   = 90.days
  NODELETE_RETENTION = 3.years

  # Run twice a day via cron (e.g. 06:00 and 18:00 server time):
  # PATH=/var/www/vhosts/SERVERPATH/.rbenv/shims:$PATH
  # 0 6,18 * * * cd SERVERPATH && bin/rails runner -e production "PurgeOldCasesJob.perform_now"

  def perform
    # Determine the most recent "last access" for every case by taking the
    # maximum updated_at across the case itself and all directly associated
    # records: simulations, planitems, cslices and cvalues.
    sql = <<~SQL
      SELECT c.id, c.nodelete,
             GREATEST(
               c.updated_at,
               COALESCE(MAX(s.updated_at),  '1970-01-01 00:00:00'),
               COALESCE(MAX(p.updated_at),  '1970-01-01 00:00:00'),
               COALESCE(MAX(cs.updated_at), '1970-01-01 00:00:00'),
               COALESCE(MAX(cv.updated_at), '1970-01-01 00:00:00')
             ) AS last_access
      FROM cases c
      LEFT JOIN simulations s  ON s.case_id  = c.id
      LEFT JOIN planitems   p  ON p.case_id  = c.id
      LEFT JOIN cslices     cs ON cs.case_id = c.id
      LEFT JOIN cvalues     cv ON cv.case_id = c.id
      GROUP BY c.id, c.nodelete, c.updated_at
    SQL

    data = ActiveRecord::Base.connection.exec_query(sql)

    normal_cutoff   = NORMAL_RETENTION.ago
    nodelete_cutoff = NODELETE_RETENTION.ago

    data.each do |row|
      last_access = row["last_access"].to_time
      nodelete    = row["nodelete"].to_i == 1
      cutoff      = nodelete ? nodelete_cutoff : normal_cutoff

      next unless last_access < cutoff

      c = Case.find_by(id: row["id"])
      c&.delete_all
    end
  end
end