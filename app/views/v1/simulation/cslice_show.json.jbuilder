json.case do
	json.external_id @case.external_id
	json.byear @case.byear
	json.dyear @case.dyear
	json.sex @case.sex
	json.country @case.country
	json.nodelete @case.nodelete
	json.chat_active @case.chat_active
end

json.cslices do
	json.cslice_id @cslice.id
	json.planitem_id @cslice.planitem_id
	json.cvaluetype @cslice.cvaluetype
	json.cvaluetype_text @cslice.cvaluetype_text
	json.label @cslice.label
	json.t @cslice.t
	json.cvalues @cslice.cvalues.each do |csl_cv|
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