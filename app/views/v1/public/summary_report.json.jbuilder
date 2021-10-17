# app/views/public/summary_report.json.jbuilder
#json.array! @categories do |category|

#json.array!(@list) do |l|
#    json.tsd l
#end

json.entries do
  json.positions do
  	json.child! {
		json.label @expensename
    	json.cto_now @expenselist.sum {|h| h["cto_now"].to_d } * -1
    	json.cto_then @expenselist.sum {|h| h["cto_then"].to_d } * -1
		json.positions @expenselist.each do |t|
			json.label t["label"]
			json.cto_now t["cto_now"].to_d * -1
			json.cto_then t["cto_then"].to_d * -1
		end
		}
  	json.child! {
		json.label @incomename
    	json.cto_now @incomelist.sum {|h| h["cto_now"].to_d }
    	json.cto_then @incomelist.sum {|h| h["cto_then"].to_d }
		json.positions @incomelist.each do |t|
			json.label t["label"]
			json.cto_now t["cto_now"]
			json.cto_then t["cto_then"]
		end
		}
  	json.child! {
		json.label 'TOTAL'
    	json.cto_now @incomelist.sum {|h| h["cto_now"].to_d } - @expenselist.sum {|h| h["cto_now"].to_d }
    	json.cto_then @incomelist.sum {|h| h["cto_then"].to_d } - @expenselist.sum {|h| h["cto_then"].to_d }
		}
  end 
end
json.environment do
  json.year_now @envelope[:from]
  json.year_then @envelope[:to]
  json.info @info
  json.disclaimer @disclaimer
end