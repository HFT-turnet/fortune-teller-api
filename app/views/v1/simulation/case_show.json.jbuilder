json.case do
	json.external_id @case.external_id
	json.byear @case.byear
	json.dyear @case.dyear
	json.sex @case.sex
	json.country @case.country
	json.nodelete @case.nodelete
	json.chat_active @case.chat_active
end

json.cvalues @case.cvalues.where(:cslice_id=>nil).each do |cv|
	json.cvalue_id cv.id
	json.planitem_id cv.planitem_id
	json.cvaluetype cv.cvaluetype
	json.cvaluetype_text cv.cvaluetype_text
	json.label cv.label
	json.t cv.t
	json.cto cv.cto
	json.ev cv.ev
	json.fromt cv.fromt
	json.tot cv.tot
	json.interest cv.interest
	json.cf_type cv.cf_type
	json.inflation cv.inflation
end

json.cslices @case.cslices.each do |csl|
	json.cslice_id csl.id
	json.planitem_id csl.planitem_id
	json.cvaluetype csl.cvaluetype
	json.cvaluetype_text csl.cvaluetype_text
	json.label csl.label
	json.t csl.t
	json.cvalues csl.cvalues.each do |csl_cv|
		json.cvalue_id csl_cv.id
		json.cvaluetype csl_cv.cvaluetype
		json.cvaluetype_text csl_cv.cvaluetype_text
		json.label csl_cv.label
		json.t csl_cv.t
		json.cto csl_cv.cto
		json.ev csl_cv.ev
		json.fromt csl_cv.fromt
		json.tot csl_cv.tot
		json.interest csl_cv.interest
		json.cf_type csl_cv.cf_type
		json.inflation csl_cv.inflation
	end
end

json.cflows do
	json.message "Not implemented"
end

json.cpensionflows do
	json.message "Not implemented"
end