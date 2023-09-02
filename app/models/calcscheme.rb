class Calcscheme 
  include ActiveModel::Model
  attr_accessor :tags, :input, :output, :metadata, :schemelines, :schemes_versions, :setscheme_version, :scheme, :result, :debuglog, :countrycode, :country, :title, :comment1 #, :content 
  
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
  
  def load(countrycode, type)
    filepath="jsonlib/" + countrycode + "_" + type + ".scheme.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      @content=JSON.parse(file)
      @country=@content["country"]
      @title=@content["title"]
      @comment1=@content["comment1"]
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
      # Call Outputgenerator
      self.pulloutput
      return "OK"
    elsif self.tags.include? scheme
      # Scheme exists, version not. Most recent (top) version to be pulled
      recentversion=@content[scheme].first[0]
      if recentversion.nil?
        self.state="Error"
        return "Error: No version available for selected scheme."
      else
        self.setscheme_version=(scheme + "_" + recentversion).to_s
        # Call Outputgenerator
        self.pulloutput
        return "Corrected: Scheme exists but version had to be set to "+ recentversion +"."
      end
    else
      # Scheme does not exist
      self.state="Error"
      return "Error: Scheme does not exist in this localisation."
    end
  end
  
  def run(inputs, xdebug)
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
		when "additionIf"
			# Label and Var / Labelvar are added and saved as label, if the basevalue (inlcuding part) is within the range.
			if (self.result[s["base"]].to_d * s["part"].to_d) >= s["from"].to_d and (self.result[s["base"]].to_d * s["part"].to_d) <= s["to"].to_d then
            self.result[s["label"]] = self.result[s["label"]].to_d + (self.result[s["base"]].to_d + s["var"].to_d)
            self.result[s["label"]] = self.result[s["label"]].to_d + (self.result[s["base"]].to_d + self.result[s["labelvar"]].to_d)
			end
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
      @debuglog[index] = self.result.map{|k,v| "#{k}=#{v}"}.join(' | ') if xdebug=="x"
      #Helper to debug schemes
      #puts self.result
    end
    self.result.each do |r|
      self.result[r[0]]='%.2f' % r[1].round(2)
    end
    self.result["disclaimer"]=@content[sel[0]]["Disclaimer"] unless @content[sel[0]]["Disclaimer"].nil?
    self.result["source"]=@content[sel[0]]["Source"] unless @content[sel[0]]["Source"].nil?
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
  def meta_load(countrycode, type)
    filepath="jsonlib/" + countrycode + "_" + type + ".meta.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      @content=JSON.parse(file)
      @countrycode=countrycode
      @country=@content["country"]
      @title=@content["title"]
      @comment1=@content["comment1"]
      # Due to inputs being defined on scheme level, these can only be added later, when the setting has been done.
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
  
  # SET scheme for Metascheme:
  # Once loaded, setting works with standard as above (set)
  
  def meta_consistency(detail)
    # Switch console output on and off
    #temporary
    self.meta_load("tax","DE")
    self.set("income","2021")
    # Check whether all is good to go on Model side
    return "Error, not prepared. Run load and set first." if self.setscheme_version.nil? or self.state=="Error"
    # Instantiate input_types
    input_obligatory=[]
    input_other=[]
    input_sequence=[]
    # Go through schemes to fetch input factors
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each_with_index do |s,index|
      subscheme=Calcscheme.new
      subscheme.load(self.countrycode, s["scheme"])
      # Set Scheme
      subscheme.set(s["type"], s["version"])
      input_sequence << (self.countrycode + "|" + s["scheme"] + "|" + s["type"] + "|" + s["version"])
      subscheme.input.each do |i|
        input_obligatory << i["label"] if i["obligatory"]=="yes"
        input_other << i["label"] if i["obligatory"]=="no"
        input_sequence << "Requires: " + i["label"] if i["obligatory"]=="yes"
        input_sequence << "Found in: " + i["label"] if i["obligatory"]=="yes"
      end
    end
    if detail=="x" 
      puts "--- INPUT Obligatory ---"
      puts input_obligatory.uniq
      puts "--- INPUT Possible ---"
      puts input_other.uniq
      puts "--- Overview of Scheme and variable usage ---"
      # Iterate over entries in schemes
      puts input_sequence
    end
    # In the end the list of required fields must remain
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
  
  def meta_inputs
    # Requires metascheme to be loaded and version to be set.
    # Check whether all is good to go on Model side
    return "Error, not prepared. Run load and set first." if self.setscheme_version.nil? or self.state=="Error"
    inputs={}
    inputs["obligatory"]=[]
    inputs["optional"]=[]
    # Load the schemes in sequence of the metascheme
    # Get their inputs and check whether they are covered by previous input or output
    # If they are not covered, add the label to one of the two input categories: obligatory and optional
    available_info=[] # This is an array that includes the available input (obligatory and results.)
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each_with_index do |s,index|
      # Load Scheme
      subscheme=Calcscheme.new
      subscheme.load(self.countrycode, s["scheme"])
      # Set Scheme (needed for outputs)
      subscheme.set(s["type"], s["version"])
      # Get Input and check inclusion
      subscheme.input.each do |i|
        if i["obligatory"]=="yes"
          # Check if the obligatory information is available, otherwise include it in the inputs requirements
          inputs["obligatory"] << i["label"] unless i["label"].in?(available_info)
          # Record that this information is available after the scheme
          available_info << (i["label"]) unless i["label"].in?(available_info)
        else
          inputs["optional"] << i["label"] unless i["label"].in?(inputs["optional"])
        end
      end
      # Now all Outputs of this schemetype are added to the available info:
      subscheme.output.each do |o|
        available_info.push(o)
      end
    end
    # Return the joined inputs field with category.
    return inputs
  end
  
  def meta_run(inputs)
    # Inputs is a simple hash with the provided data, but it is enhanced after each step with the results from the scheme that has been run.
    # Check whether all is good to go on Model side
    return "Error, not prepared. Run load and set first." if self.setscheme_version.nil? or self.state=="Error"
    # Start calculation by iterating over the items in the selected scheme
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each_with_index do |s,index|
      # Load Scheme
      subscheme=Calcscheme.new
      subscheme.load(self.countrycode, s["scheme"])
      # Set Scheme
      subscheme.set(s["type"], s["version"])
      # Run Scheme
      debug=""
      check=subscheme.run(inputs,debug)
      unless check=="OK" then
        return check
      end
      # Add Result to input
      #puts subscheme.result
      inputs=inputs.merge(subscheme.result) unless subscheme.result.nil?
    end
    @result=inputs
    puts @result
    return "OK"
  end
  
  # HELPERS
  def pulloutput
    self.output=[]
    # Get Scheme and Version
    sel=self.setscheme_version.split("_")
    @content[sel[0]][sel[1]].each_with_index do |s,index|
      self.output << s["label"]
    end
    self.output=self.output.uniq
  end
  
  # MANIPULATE SCHEMES
  def create_schemefile(type, countrycode)
    filepath="jsonlib/" + countrycode + "_" + type + ".scheme.json"
    if not File.exists?(filepath) then
      file = File.open(filepath,"w")
      # Create metadata and frame
      metadata={}
      metadata["country"]=countrycode
      metadata["title"]=type
      metadata["comment1"]=""
      metadata["input"]=""
      file.puts(JSON.pretty_generate(metadata))
      file.close
    end
  end
  def load_scheme_edit(type, countrycode, scheme, version)
    filepath="jsonlib/" + countrycode + "_" + type + ".scheme.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      @content=JSON.parse(file)
      self.metadata={}
      self.metadata["country"]=@content["country"]
      self.metadata["title"] = @content["title"]
      self.metadata["comment1"] = @content["comment1"]
      # Obtain Input fields
      self.input=@content["input"]
      
      # Initiate collections
      self.tags=[]
      self.schemes={}
      self.schemes_versions=[]
      self.schemelines=[{}]
      
      # Read all tags
      @content.each do |s|
        self.tags << s[0]
      end
      
      # Get all Schemes, exclude tags that do not have a third level and the Disclaimer and Source Tags
      self.tags.each do |t|
        if t=="input" or t=="title" or @content[t].first[1].nil? then
        else
          self.schemes[t] = @content[t]
          @content[t].each do |tt|
            self.schemes_versions << (t + "_" + tt[0]).to_s unless (tt[0]=="Disclaimer" or tt[0]=="Source")
          end
        end
      end
      
      # Read the specified scheme and version into schemelines
      return "Error: Scheme and/or Version do not exist" if @content[scheme][version].nil?
      self.setscheme_version=(scheme + "_" + version).to_s
      @content[scheme][version].each_with_index do |entry, line|
        self.schemelines[line]=entry
      end
      
      # Fill Output-Array
      self.pulloutput
      
      self.state="OK"
      return "OK"
    else
      self.state="Error"
      return "Error: Type or Localization not available"
    end
  end
  def copy_scheme_version(newversion)
    # Requires Load Scheme Edit with an existing version
    sel=self.setscheme_version.split("_")
    #@content[sel[0]][newversion]=@content[sel[0]][sel[1]]
    addhash={}
    addhash[newversion]=@content[sel[0]][sel[1]]
    @content[sel[0]]=addhash.merge(@content[sel[0]])
    return "OK"
    # Needs to be saved with old version to take effect and before switching
  end
  def get_operands
    return ["addition","percent","steppercent","absolute","multiply"]
  end
  def template_line
    template={}
    template["type"]=""
    template["base"]=""
    template["from"]=""
    template["to"]=""
    template["label"]=""
    template["var"]=""
    return template
  end
  def add_scheme_lines(entry, position)
    checkreturn=check_line(entry)
    if checkreturn=="OK"
      self.schemelines.insert(position, entry)
      return "OK"
    else
      return checkreturn
    end
  end 
  def remove_scheme_lines(position)
    self.schemelines.delete_at(position)
  end
  def save_scheme(type, countrycode, scheme, version)
    filepath="jsonlib/" + countrycode + "_" + type + ".scheme.json"
    @content["country"]=self.metadata["country"]
    @content["title"]=self.metadata["title"]
    @content["comment1"]=self.metadata["comment1"]
    @content[scheme][version]=self.schemelines
      file = File.open(filepath,"w")
      file.puts(JSON.pretty_generate(@content))
      file.close
    return "OK"
  end
  
  private
  attr_accessor :content, :state, :schemes
  def check_line(entry)
    return "Error, not matching hash" if entry["type"].nil?
    return "Error, no type" if entry["type"].blank?
    return "Error, not a permissible type: "+entry["type"].to_s if not entry["type"].in? self.get_operands
    return "Error, no base" if entry["base"].blank?
    return "Error, no label" if entry["label"].blank?
    return "OK"
  end
  
end
