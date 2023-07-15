class Calcscheme 
  include ActiveModel::Model
  attr_accessor :tags, :input, :schemes_versions, :setscheme_version, :scheme, :result, :debuglog, :countrycode #, :content 
  
  # General approach. load => check existence of file and prepare scheme selection. set => set scheme to be used or pull alternatives. run => apply scheme to values given
  # ESt: zu versteuerndes Einkommen: zve
  
  def listall(countrycode)
    filepath="jsonlib/" + countrycode + "_" + "*"
    schemes=Dir[filepath].select { |x| x.include?(".scheme.json") }
    schemelist={}
    schemes.each do |s|
      file = File.read(s)
      content=JSON.parse(file)
      schemetable={}
      schemetable["title"]=content["title"]
      schemetable["inputs"]=content["input"]
      tags=[]
      content.each do |t|
          tags << t[0] unless t[0]=="input" or content[t[0]].first[1].nil?
      end
      schemetable["calculations"]=tags
      #puts content
      schemelist[s.split("/")[1].split(".scheme.json").to_s]=schemetable
    end
    return schemelist  
  end
  
  def load(type, countrycode)
    filepath="jsonlib/" + countrycode + "_" + type + ".scheme.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      @content=JSON.parse(file)
      @countrycode=countrycode
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
        if t=="input" or t=="title" or @content[t].first[1].nil? then
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
    # Check whether all is good to go on Model side
    return "Error, not prepared. Run load first." if self.state.nil? or self.state=="Error"
    
    # Check for Scheme and version.
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
  
  def inputhash
    # Provide a hash for all inputs and set as input
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
    # Initiate log for debug
    @debuglog=[] #if debug=="yes"
    # Check whether inputs match expectation based on json definition and add to result hash
    self.input.each do |i|
      # Missing input
      return "Error, missing input: " + i["label"].to_s if inputs[i["label"]].nil? and i["obligatory"]=="yes"
      # Try to convert value to decimal, if possible
      inputs[i["label"]]=inputs[i["label"]].to_d unless inputs[i["label"]].is_a? Numeric or inputs[i["label"]].nil?
      # If conversion was not possible: stop
      return "Error, input "+ i["label"].to_s + " available but not number format." unless inputs[i["label"]].is_a? Numeric or inputs[i["label"]].nil?
      self.result[i["label"]]=inputs[i["label"]] unless inputs[i["label"]].nil?
    end
    
    # Start calculation
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each_with_index do |s,index|
      s["part"]=1 if s["part"].blank?
      case s["type"]
        when "addition"
          # Two amounts are added, "-1" as part can revert the amount listed as "base". No limits apply.
          self.result[s["label"]] = self.result[s["var"]].to_d + ( s["part"].to_d * self.result[s["base"]].to_d) unless self.result[s["var"]].nil?
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
          # An absolute value or a labelvalue is added to the label category if the relevant part of the base amount is within the limits
          if (self.result[s["base"]].to_d * s["part"].to_d) >= s["from"].to_d and (self.result[s["base"]].to_d * s["part"].to_d) <= s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + s["var"].to_d
            self.result[s["label"]] = self.result[s["label"]].to_d + self.result[s["labelvar"]].to_d
          end
        when "multiply"
          # An absolute value or a labelvalue is multiplied with the label category if the relevant part of the base amount is within the limits
          if (self.result[s["base"]].to_d * s["part"].to_d) >= s["from"].to_d and (self.result[s["base"]].to_d * s["part"].to_d) <= s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + (self.result[s["base"]].to_d * s["var"].to_d)
            self.result[s["label"]] = self.result[s["label"]].to_d + (self.result[s["base"]].to_d * self.result[s["labelvar"]].to_d)
          end
      end
      @debuglog[index] = self.result.map{|k,v| "#{k}=#{v}"}.join(' | ') #if debug=="yes"
      #Helper to debug schemes
      #puts self.result
    end
    self.result.each do |r|
      self.result[r[0]]='%.2f' % r[1].round(2)
    end
    
    return "OK"
  end
  
  # Handle Metaschemes
  
  # Get all Metaschemes for a countrycode
  def meta_listall(countrycode)
    filepath="jsonlib/" + countrycode + "_" + "*"
    schemes=Dir[filepath].select { |x| x.include?(".meta.json") }
    schemelist={}
    schemes.each do |s|
      file = File.read(s)
      content=JSON.parse(file)
      schemetable={}
      schemetable["title"]=content["title"]
      tags=[]
      content.each do |t|
          tags << t[0] unless t[0]=="input" or content[t[0]].first[1].nil?
      end
      schemetable["calculations"]=tags
      #puts content
      schemelist[s.split("/")[1].split(".meta.json").to_s]=schemetable
    end
    return schemelist  
  end
  
  # Load a metascheme
  def meta_load(type, countrycode)
    filepath="jsonlib/" + countrycode + "_" + type + ".meta.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      @content=JSON.parse(file)
      @countrycode=countrycode
      # Initiate collections
      self.tags=[]
      self.schemes_versions=[]
      
      # Read all tags
      @content.each do |s|
        self.tags << s[0]
      end
      
      # Get all Schemes, exclude tags that do not have a third level and the Disclaimer and Source Tags
      self.tags.each do |t|
        if t=="input" or t=="title" or @content[t].first[1].nil? then
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
  end
  
  # SET scheme
  # Once loaded, setting works with standard as above (set)
  
  def meta_trialrun(inputs)
    # Input is a simple hash with the provided data, but it is enhanced after each step with the results from the scheme that has been run.
    # Start calculation by iterating over the items in the selected scheme
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each_with_index do |s,index|
      # Load Scheme
      subscheme=Calcscheme.new
      subscheme.load(s["scheme"], self.countrycode)
      # Set Scheme
      subscheme.set(s["type"], s["version"])
      # Run Scheme
      subscheme.run(inputs)
      # Add Result to input
      puts subscheme.result
      inputs=inputs.merge(subscheme.result)
      puts inputs
      puts s
    end
  end
  
    # Go through schemes and identify input and output variables
  # Put them in sequence to identify gaps and assumptions to be set if a variable is missing
  # Output in a console format to allow Reading it on screen
  def meta_listinputs
    # Switch console output on and off
    #temporary
    self.meta_load("tax","DE")
    self.set("income","2021")
    # Check whether all is good to go on Model side
    return "Error, not prepared. Run load and set first." if self.setscheme_version.nil? or self.state=="Error"
    # Go through schemes to fetch input factors
    
    puts "--- Overview of Scheme and variable usage ---"
    # Iterate over entries in schemes
    
    #Example
    puts "Scheme 1 receives"
    puts "Obligatory: zve, einkommen, tax"
    puts "Voluntary: username, rate"
    puts "Scheme 1 then provides"
    puts "Resultvariables: taxrate, y1, z3, q1"
    puts ""
    puts "Scheme 2 receives"
    puts "Obligatory: taxrate, y443, zert"
    puts "Voluntary: ."
    puts "MATCHED: taxrate" 
    puts "ASSUMING: zert=12" # This would be included in the metascheme
    puts "ASSUMING: love=0" # This would be included in the metascheme
    puts "MISSING: y443"
    puts "Scheme 1 then provides"
    puts "Resultvariables: taxrate, y1, z3, q1"
    
    puts "--- In Summary ---"
    puts "Required INPUT"
    puts "List all Inputs from above, that are not matched"
    puts "Avoid assumptions if providing INPUT"
    puts "List all Inputs from above, that are listed as assumptions"
  end
  
  def meta_run
    # Ensure the variable hash includes all needed variables
    # Post those variables that will be assumed
    
    # Run the scheme and provide output of each step with
    # Each subscheme to be called individually
    # prefix: scheme and then the variable
    return "OK"
  end
  
  # HELPERS
  
  private
  attr_accessor :content, :state
  
  def get_variables
    
  end
  
end
