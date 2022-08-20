class V1::SchemeController < ApplicationController
  #controller=V1::SchemeController.new
  #controller.income
  
  def test
    puts "Hallo"
  end
  
  def listschemes
    if params[:countrycode].blank? then
      render json: "Please submit parameter 'countrycode'."
    else
      render json: Calcscheme.new.listall(params["countrycode"])
    end
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
