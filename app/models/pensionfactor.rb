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
  def self.drv_punkte_aus_svgehalt(sv_gehaelter, provider)
    minyear=sv_gehaelter.map{|k,v| k[:year]}.compact.min
    maxyear=sv_gehaelter.map{|k,v| k[:year]}.compact.max
    drv_bbmg=Pensionfactor.where("year >= ? AND year <= ? AND provider = ? AND factor='bbmg'", minyear, maxyear, provider)
    drv_av_gehalt=Pensionfactor.where("year >= ? AND year <= ? AND provider = ? AND factor='av_gehalt'", minyear, maxyear, provider)
    sv_gehaelter.each do |geh|
      # Add a sv_value column that takes the min of the drv_bbmg entry and the actual value.
      geh[:sv_value]=[geh[:value].to_d, drv_bbmg.where(:year=>geh[:year]).first.value.to_d].min
      # Add a drv_points column that takes the sv_value and divides it by the drv_av_gehalt.
      geh[:drv_points]=(geh[:sv_value]/drv_av_gehalt.where(:year=>geh[:year]).first.value).to_d
    end
    # Summe der so ermittelten Punkte zurückgeben.
    return sv_gehaelter.map{|k,v| k[:drv_points]}.sum.round(2)
  end
end