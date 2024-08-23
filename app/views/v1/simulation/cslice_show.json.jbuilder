json.case do
	json.case_id @case.external_id
	json.byear @case.byear
	json.dyear @case.dyear
	json.sex @case.sex
end

json.cslices do
	json.cslice_id @cslice.id
	json.valuetype @cslice.cvaluetype
	json.valuetype @cslice.cvaluetype_text
	json.label @cslice.label
	json.t @cslice.t
	json.cslice_values @cslice.cvalues.each do |csl_cv|
		json.cvalue_id csl_cv.id
		json.valuetype csl_cv.cvaluetype
		json.valuetype_text csl_cv.cvaluetype_text
		json.label csl_cv.label
		json.t csl_cv.t
		json.value csl_cv.cto
		json.fromt csl_cv.fromt
		json.tot csl_cv.tot
		json.inflation csl_cv.inflation
	end
end