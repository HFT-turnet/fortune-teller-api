class Calcscheme 
  include ActiveModel::Model
  attr_accessor :tags, :input, :schemes_versions, :setscheme_version, :scheme, :result #, :content 
  
  # General approach. load => check existence of file and prepare scheme selection. set => set scheme to be used or pull alternatives. run => apply scheme to values given
  
  def load(type, countrycode)
    filepath="jsonlib/" + countrycode + "_" + type + ".json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      @content=JSON.parse(file)
      # Obtain Input fields
      self.input=@content["input"]
      
      # Initiate collections
      self.tags=[]
      self.schemes_versions=[]
      
      # Read all tags
      @content.each do |s|
        self.tags << s[0]
      end
      
      # Get all Schemes, exclude tags that do not have a third level and the Disclaimer and Source Tags
      self.tags.each do |t|
        if t=="input" or @content[t].first[1].nil? then
        else
          @content[t].each do |tt|
            self.schemes_versions << (t + "_" + tt[0]).to_s unless (tt[0]=="Disclaimer" or tt[0]=="Source") 
          end
        end
      end
      self.state="OK"
      return "OK"
    else
      self.state="Error"
      return "Error: Type or Localization not available"
    end
    # to Write back to file
    #data_hash = JSON.parse(file)
    #File.write('./sample-data.json', JSON.dump(data_hash))
  end
  
  def set(scheme, version)
    if self.schemes_versions.include? (scheme + "_" + version).to_s then
      # Direct selection of Scheme and Version
      self.setscheme_version=(scheme + "_" + version).to_s
      return "OK"
    elsif self.tags.include? scheme
      # Scheme exists, version not. Most recent (top) version to be pulled
      recentversion=@content[scheme].first[0]
      if recentversion.nil?
        self.state="Error"
        return "Error: No version available for selected scheme."
      else
        self.setscheme_version=(scheme + "_" + recentversion).to_s
        return "Corrected: Scheme exists but version had to be set to "+ recentversion +"."
      end
    else
      # Scheme does not exist
      self.state="Error"
      return "Error: Scheme does not exist in this localisation."
    end
  end
  
  def run(inputs)
    # Where inputs is a hash of values
    #inputs={}
    #inputs["basevalue"]=1000
    # Check whether all is good to go on Model side
    return "Error, not prepared. Run load and set first." if self.setscheme_version.nil? or self.state=="Error"
    # Check whether inputs have been provided as hash
    return "Error, inputs not provided as hash." unless inputs.is_a? Hash
    # Initiate result 
    self.result={}
    # Check whether inputs match expectation based on json definition and add to result hash
    self.input.each do |i|
      return "Error, missing input: " + i["label"].to_s if inputs[i["label"]].nil? and i["obligatory"]=="yes"
      return "Error, input "+ i["label"].to_s + " available but not number format." unless inputs[i["label"]].is_a? Numeric or inputs[i["label"]].nil?
      self.result[i["label"]]=inputs[i["label"]] unless inputs[i["label"]].nil?
    end
    
    # Start calculation
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each do |s|
      s["part"]==1 if s["part"].blank?
      case s["type"]
        when "percent"
          # A percentage of the relevant part of the base value is added to the label category if the relevant part of the base amount is within the limits
          if (self.result[s["base"]].to_d * s["part"].to_d) >= s["from"].to_d and (self.result[s["base"]].to_d * s["part"].to_d) <= s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + ( s["var"].to_d * s["part"].to_d * self.result[s["base"]].to_d)
          end
        when "steppercent"
          # A percentage of the limit range or the range between low limit and base value is added to the label category if the relevant part of the base amount is above or within the limits. NO consideration of the relevant part.
          if self.result[s["base"]].to_d > s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + ( (s["to"].to_d-s["from"].to_d + 1) * s["var"].to_d )
          end
          if (self.result[s["base"]].to_d ) >= s["from"].to_d and (self.result[s["base"]].to_d ) <= s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + ( (self.result[s["base"]].to_d - s["from"].to_d + 1) * s["var"].to_d )
          end
        when "absolute"
          # An absolute value is added to the label category if the relevant part of the base amount is within the limits
          if (self.result[s["base"]].to_d * s["part"].to_d) >= s["from"].to_d and (self.result[s["base"]].to_d * s["part"].to_d) <= s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + s["var"].to_d
          end
      end
    end
    
    return "OK"
  end
  
  private
  attr_accessor :content, :state
  
end
