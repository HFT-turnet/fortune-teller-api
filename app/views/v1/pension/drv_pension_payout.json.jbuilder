json.pension_simulation do
	json.case_id "dummy"
	json.byear @byear
	json.queried @queried_payout
	json.alternatives @variants
	json.assumptions @assumptions
end
