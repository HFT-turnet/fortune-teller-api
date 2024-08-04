class Pensionfactor < ApplicationRecord
  
  def self.drv_rentenwert(year, provider, annahme_rentenanpassung)
    # Future values need to be guessed / assumed.
    entry=Pensionfactor.where("year = ? AND provider = ? AND factor='rentenwert'", year, provider).first
    unless entry.nil?
      # Value has been found, the amount is clear.
      value=entry.value
    else
      # The table contains the full history, therefore the year can only be bigger than the latest amount.
      entry=Pensionfactor.where("provider = ? AND factor='rentenwert'", provider).order(year: :desc).first
      # Now apply the correction factor by difference of years:
      value=entry.value * (1+annahme_rentenanpassung) ** (year-entry.year)
    end
    return value 
  end
end