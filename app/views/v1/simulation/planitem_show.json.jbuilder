json.planitem do
	json.planitem_id @planitem.id
	json.title @planitem.title
	json.category @planitem.category
	json.category_text @planitem.category_text
	json.fromt @planitem.fromt
	json.tot @planitem.tot
	json.leadt @planitem.leadt
	json.trailt @planitem.trailt
end

json.cslices @planitem.cslices.each do |csl|
	json.cslice_id csl.id
	json.valuetype csl.cvaluetype
	json.valuetype_text csl.cvaluetype_text
	json.label csl.label
	json.t csl.t
	json.cslice_values csl.cvalues.each do |csl_cv|
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

json.cvalues @planitem.cvalues.where(cslice_id: nil).each do |cv|
	json.cvalue_id cv.id
	json.valuetype cv.cvaluetype
	json.valuetype_text cv.cvaluetype_text
	json.label cv.label
	json.t cv.t
	json.value (cv.ev + cv.cto)
	json.fromt cv.fromt
	json.tot cv.tot
	json.interest cv.interest
end
