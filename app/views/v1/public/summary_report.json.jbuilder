# app/views/public/sample2.json.jbuilder
#json.array! @categories do |category|

#json.array!(@list) do |l|
#    json.tsd l
#end

json.entries do
  json.positions do
    json.label 'Expenses'
    json.cto_now @expenselist.sum {|h| h["cto_now"].to_d }
    json.cto_then @expenselist.sum {|h| h["cto_then"].to_d }
	json.positions @expenselist.each do |t|
		json.label t["label"]
		json.cto_now t["cto_now"]
		json.cto_then t["cto_then"]
	end
  end 
end
json.environment do
  json.year_now @envelope[:from]
  json.year_then @envelope[:to]
end