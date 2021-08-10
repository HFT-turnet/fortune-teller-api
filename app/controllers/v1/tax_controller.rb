class V1::TaxController < ApplicationController
  #controller=V1::TaxController.new
  #controller.income
  
  def income
    puts "Hallo"
  end
  
  def getjson(countrycode)
    filepath="jsonlib/" + countrycode + "_tax.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      scheme=JSON.parse(file)
    else
      return "Error"
    end
    #data_hash = JSON.parse(file)
    #File.write('./sample-data.json', JSON.dump(data_hash))
  end
  
  def runscheme(scheme, taxbase)
    
  end
  
end
