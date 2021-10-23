class V1::PublicController < ApplicationController
  #controller=V1::PublicController.new
  #controller.test
  
  # Base math (Single Value functions)
  # tbd
  
  # Transformations
    # Use Timevalue Models for transformations
  def timemorph
    # Inflation and Deflation
    #information = request.raw_post
    data_parsed = JSON.parse(request.raw_post)
    #p data_parsed
    jsonout=[]
    data_parsed.each do |json|
      ts=Valueflow.new(json)
      ts.tvs=[]
      ts.tvs_attributes=json["tvs"]
  # OPEN: include check whether the relevant fields are available
      ts.twoperiodcomplete
      jsonout << ts.as_json
    end
    render json: jsonout
  end

  # Work with TIMESLICES (as in timeslize model)
    # Timeslices are driven by spending and time-morph by inclusion / exclusion and inflation
  
  def get_timeslice
    # Get request to get a timeslize JSON without values
    countrycode="DE"
    language="de"
    template_i=0.02
    params[:type]="expense" if params[:type].blank?
    
    #Incomes
    if params[:type]=="income" then
      filepath="jsonlib/" + countrycode + "_" + language + "_incomesample.json"
      if File.exists?(filepath) then
        file = File.read(filepath)
        scheme=JSON.parse(file)
        sample=Timeslice.new(scheme)
        sample.i=template_i
        sample.t=Time.current.year
      end
    end
    
    if params[:type]=="expense" then
      #Expenses
      filepath="jsonlib/" + countrycode + "_" + language + "_expensesample.json"
      if File.exists?(filepath) then
        file = File.read(filepath)
        scheme=JSON.parse(file)
        sample=Timeslice.new(scheme)
        sample.i=template_i
        sample.t=Time.current.year
      end      
    end
    
    if params[:type]=="single" then
      sample=Timeslice.new()
      sample.i=template_i
      sample.tvs=[]
      #sample.tvs.push('{"label": "Value","cto":"0","fromt": "0","tot": "9999","inflation": "0"}')
      sample.tvs.push(:label => "Value",:fromt => 0, :tot => 9999, :inflation =>0 ) 
      sample.t=Time.current.year    
    end
    render json: sample
  end
  
  def summary_report
    @expensename="Ausgaben"
    @incomename="Einnahmen"
    @info="Hallo Info"
    @disclaimer=""
    # Instantiate Header as per JSON
    @envelope=envelope_head    
    expenses=Timeslice.new(envelope_expenses_head) unless params[:public][:expenses].blank?
    incomes=Timeslice.new(envelope_incomes_head) unless params[:public][:incomes].blank?    
    # Load named TVs into Timeslice
    expenses.tvs_attributes=envelope_expenses_tvs unless params[:public][:expenses].blank?
    incomes.tvs_attributes=envelope_incomes_tvs unless params[:public][:incomes].blank?    
# Add an info box that allows to review API comments
    # Backup (if needed: find a specific label in entries)
    #a=expenses.tvs.select {|tv| tv.label == e.label}
    
    # Expenses First
    # freeze function leads to a freeze of timevalues and considers limits (values set to zero if not in limit)    
    expenses_t0=expenses.freeze
    expenses.move_to(@envelope["to"])
    expenses_tf=expenses.freeze

    # Prepare for Json_parse
    @expenselist=[]
    expenses_t0.tvs.each_with_index do |t,i|
      @expenselist.push({"label"=>t.label,"cto_now"=>t.cto,"cto_then"=>expenses_tf.tvs[i].cto})
    end
        
  unless incomes.blank?
  # Incomes Next (as above)
    incomes_t0=incomes.freeze
    incomes.move_to(@envelope["to"])
    incomes_tf=incomes.freeze 

  # Prepare for Json_parse
    @incomelist=[]
    incomes_t0.tvs.each_with_index do |t,i|
      @incomelist.push({"label"=>t.label,"cto_now"=>t.cto,"cto_then"=>incomes_tf.tvs[i].cto}) 
    end
  end
  
  #rendered= render template: "/v1/public/summary_report"
  #p rendered
  end
  
  def get_envelope
    # Instantiate Header as per JSON
    envelope={}
    envelope[:environment]={}
    envelope[:environment][:i]=0.025
    # Datum year
    envelope[:environment][:from]=Time.current.year
    envelope[:environment][:to]=Time.current.year+20
    countrycode="DE"
    language="de"
    
    #Incomes
    filepath="jsonlib/" + countrycode + "_" + language + "_incomesample.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      scheme=JSON.parse(file)
      sample=Timeslice.new(scheme)
      sample.i=envelope[:environment][:i]
      sample.t=envelope[:environment][:from]
      envelope[:incomes]=sample
      #else
      #return "Error"
    end
    
    #Expenses
    filepath="jsonlib/" + countrycode + "_" + language + "_expensesample.json"
    if File.exists?(filepath) then
      file = File.read(filepath)
      scheme=JSON.parse(file)
      sample=Timeslice.new(scheme)
      sample.i=envelope[:environment][:i]
      sample.t=envelope[:environment][:from]
      envelope[:expenses]=sample
      #else
      #return "Error"
    end

    render json: envelope
  end
  
  def timeslice
    # params: targetyear & Json-Load as Post
    # Return: just converted timeslice

    # Instantiate Header as per JSON
    ts=Timeslice.new(timeslice_head_params)
    # Load named TVs into Timeslize
    ts.tvs_attributes=timeslice_tvs_params
    
    # Run Targetyear transformation
    ts.move_to(params[:targetyear])
    
    # Reduce tvs to those in the timeframe
    output=Timeslice.new
    output.t=ts.t
    output.i=ts.i
    output.tvs=ts.list
    
    render json: output
  end
  
  def timeslice_series
    # Turn timeslize into series with interval
    # params: targetyear
    # params: interval
    
    # Instantiate Header as per JSON
    ts=Timeslice.new(timeslice_head_params)

    # Load named TVs into Timeslize
    ts.tvs_attributes=timeslice_tvs_params
    
    # Instantiate Output
    jsonout=[]
    #json << ts.as_json
    
    # Calc runs
    source_t=ts.t.to_i
    timeframe=params[:targetyear].to_i - source_t
    runs=(timeframe/params[:interval].to_i).ceil+1
    # Perform runs
    runs.times do |i|
      ts.move_to(source_t + params[:interval].to_i*(i)) unless i==0
      
      # Reduce tvs to those in the timeframe without deletion from original timeslice
      output=Timeslice.new
      output.t=ts.t
      output.i=ts.i
      output.tvs=ts.list
          
      jsonout << output.as_json
    end
    
    render json: jsonout
  end
  
  # Work with VALUEFLOWS (as in valueflows model). Includes Financial Assets and Debt Outlook
    # Valueflows are driven by contracts, the financial market or do not change
  
  def valueflow_complete
    # Get an incomplete valueflow and hand it back complete
    # Complete: in case of debt: EV=0
    
    # Params Interval accepted to limit feedback
    ts=Valueflow.new(valueflow_head_params)
    ts.tvs_attributes=valueflow_tvs_params
    ts.initialfix
    # Type dependent treatments
    ts.debtcalc if ts.type=="debt"
    ts.assetcalc if ts.type=="asset"
    
    #p ts
    #ts.tvs.each do |tv|
    #  p tv.sv.to_s + " " +tv.fee.to_s+ " " +tv.valuation.to_s+ " " + tv.ev.to_s
    #end
    render json: ts
  end  
  
  def draft
    # TV Get only knows two periods in the model: 0 and 1, the number of periods to be discounted is in the header
    # Set the Header and initiate
    ts=Valueflow.new(valueflow_head_params)
    # Set t=0 data
    ts.tvs.first.update(valueflow_tvs_params[0])
    # Create t=1 dataset
    ts.getorcreate_tv_at_t(1)
    ts.tvs.last.update(valueflow_tvs_params[1])
    # Call TV calculation
    ts.setTwoPeriodEv
    # Play back the dataset
    render json: ts.as_json
  end
  
  # Work with Calculation Models
  
  # Params definition  
  def timeslice_head_params
    #params.require(:tvs).permit!
    params[:public].permit(:t,:i,:tvs)
  end
  def timeslice_tvs_params
    #params.require(:tvs).permit!
    params[:public].permit(tvs: [
     :label,
     :cto, 
     :fromt,
     :tot, 
     :inflation]
     ).require(:tvs)#.permit(:sv, :tax, :fee, :interest, :valuation, :cto, :t, :ev)
  end
  def valueflow_head_params
    #params.require(:tvs).permit!
    params[:public].permit(:label, :type, :r, :rm, :rf, :annuity,:from,:to,:periods,:tvs)
  end
  def valueflow_tvs_params
    #params.require(:tvs).permit!
    params[:public].permit(tvs: [
     :sv,
     :tax, 
     :fee, 
     :interest, 
     :valuation, 
     :cto, 
     :t, 
     :ev]
     ).require(:tvs)
  end
  def envelope_head
    params[:public][:environment].permit(:from,:to,:i)
  end
  def envelope_expenses_head
    params[:public][:expenses].permit(:t,:i,:tvs) 
  end
  def envelope_incomes_head
    params[:public][:incomes].permit(:t,:i,:tvs)
  end
  def envelope_expenses_tvs
    params[:public][:expenses].permit(tvs: [
     :label,
     :cto, 
     :fromt,
     :tot, 
     :inflation]
     ).require(:tvs)
  end
  def envelope_incomes_tvs
    params[:public][:incomes].permit(tvs: [
      :label,
      :cto, 
      :fromt,
      :tot, 
      :inflation]
      ).require(:tvs)
  end
  
end
