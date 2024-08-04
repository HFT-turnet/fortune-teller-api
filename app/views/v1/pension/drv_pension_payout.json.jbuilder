json.pension_simulation do
	json.case_id "hallo"
	json.byear 1920
	json.dyear 1930
	json.sex "m"
	json.queried @queried_payout
	json.alternatives @variants
	json.assumptions @assumptions
end
