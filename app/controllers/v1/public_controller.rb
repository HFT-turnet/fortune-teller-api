class V1::PublicController < ApplicationController
  #controller=V1::PublicController.new
  #controller.test
  
  # Base math (Single Value functions)
  
  # Transformations
    # Use Timevalue Models for transformations
  def timemorph
    # Inflation and Deflation
    #information = request.raw_post
    data_parsed = parse_json_body!
    return unless data_parsed
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
      if File.exist?(filepath) then
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
      if File.exist?(filepath) then
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
    public_payload = public_payload!
    return unless public_payload
    environment_payload = public_payload[:environment]
    if environment_payload.blank?
      render_bad_request("public.environment is required.")
      return
    end

    @expensename="Ausgaben"
    @incomename="Einnahmen"
    @info="Hallo Info"
    @disclaimer=""
    # Instantiate Header as per JSON
    @envelope=envelope_head(environment_payload)
    expenses=Timeslice.new(envelope_expenses_head(public_payload)) unless public_payload[:expenses].blank?
    incomes=Timeslice.new(envelope_incomes_head(public_payload)) unless public_payload[:incomes].blank?
    # Load named TVs into Timeslice
    expenses.tvs_attributes=envelope_expenses_tvs(public_payload) unless public_payload[:expenses].blank?
    incomes.tvs_attributes=envelope_incomes_tvs(public_payload) unless public_payload[:incomes].blank?
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
    if File.exist?(filepath) then
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
    if File.exist?(filepath) then
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
  
  # Gross to Net Calculator
  def grossnet
    # Parameters are sent as JSON body, so they're in params directly
    gross_salary = params.dig(:gross_salary).to_d
    sv_region = params.dig(:sv_westost) || "sv-west"
    year = params.dig(:year)&.to_s || Time.current.year.to_s

    if year.blank?
      render json: { error: "year is required" }, status: :bad_request
      return
    end

    # Set SV region flags
    sv_west = sv_region == "sv-west" ? 1 : 0
    sv_ost = sv_region == "sv-ost" ? 1 : 0

    # 1. Calculate social insurance (SV) using Calcscheme directly
    sv_calc = Calcscheme.new
    sv_calc.meta_load("DE", "sv")
    sv_calc.set("allsv", year)
    
    sv_inputs = {
      "bruttogehalt" => gross_salary,
      "sv_west" => sv_west,
      "sv_ost" => sv_ost
    }
    sv_check = sv_calc.meta_run(sv_inputs)
    
    unless sv_check == "OK"
      render json: { error: "SV calculation failed: #{sv_check}" }, status: :bad_request
      return
    end

    # 2. Calculate taxes using Calcscheme directly
    tax_calc = Calcscheme.new
    tax_calc.meta_load("DE", "tax")
    tax_calc.set("income", year)
    
    # Prepare tax inputs with SV results
    tax_inputs = sv_calc.result.merge(
      "sv_gkv_an" => sv_calc.result.dig("sv_gkv_an12"),
      "sv_pv_an" => sv_calc.result.dig("sv_pv_an12"),
      "sv_drv" => sv_calc.result.dig("sv_drv12")
    )
    
    tax_check = tax_calc.meta_run(tax_inputs)
    
    unless tax_check == "OK"
      render json: { error: "Tax calculation failed: #{tax_check}" }, status: :bad_request
      return
    end

    # Combine results
    result = sv_calc.result.merge(tax_calc.result)

    render json: result
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
  
  ## Work with Calculation Models
  # How long will money last?
  def lastingmoney
    # Annahme: nachschüssige Auszahlung.
    flow=Valueflow.new
    flow.initialfix
    flow.rm=params[:marketrate].to_d
    flow.tvs[0].sv=params[:startfunds].to_d
    if params[:payout].to_d < params[:startfunds].to_d * (params[:marketrate].to_d-params[:inflation].to_d)
      render json: "Market-return above payout, would run endlessly."
    else
      flow.payallout(-1 * params[:payout].to_d, params[:inflation].to_d)
      render json: flow
    end
  end
  
  private
  def parse_json_body!
    JSON.parse(request.raw_post)
  rescue JSON::ParserError
    render_bad_request("Invalid JSON body.")
    nil
  end

  def public_payload!
    params.require(:public)
  rescue ActionController::ParameterMissing
    render_bad_request("public payload is required.")
    nil
  end

  def render_bad_request(message)
    render json: { error: message }, status: :bad_request
  end

  # Params definition  
  def timeslice_head_params(public_payload = params[:public])
    #params.require(:tvs).permit!
    public_payload.permit(:t,:i,:tvs)
  end
  def timeslice_tvs_params(public_payload = params[:public])
    #params.require(:tvs).permit!
    public_payload.permit(tvs: [
     :label,
     :cto, 
     :fromt,
     :tot, 
     :inflation]
     ).require(:tvs)#.permit(:sv, :tax, :fee, :interest, :valuation, :cto, :t, :ev)
  end
  def valueflow_head_params(public_payload = params[:public])
    #params.require(:tvs).permit!
    public_payload.permit(:label, :type, :r, :rm, :rf, :annuity,:from,:to,:periods,:tvs)
  end
  def valueflow_tvs_params(public_payload = params[:public])
    #params.require(:tvs).permit!
    public_payload.permit(tvs: [
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
  def envelope_head(public_payload = params[:public])
    public_payload[:environment].permit(:from,:to,:i)
  end
  def envelope_expenses_head(public_payload = params[:public])
    public_payload[:expenses].permit(:t,:i,:tvs) 
  end
  def envelope_incomes_head(public_payload = params[:public])
    public_payload[:incomes].permit(:t,:i,:tvs)
  end
  def envelope_expenses_tvs(public_payload = params[:public])
    public_payload[:expenses].permit(tvs: [
     :label,
     :cto, 
     :fromt,
     :tot, 
     :inflation]
     ).require(:tvs)
  end
  def envelope_incomes_tvs(public_payload = params[:public])
    public_payload[:incomes].permit(tvs: [
      :label,
      :cto, 
      :fromt,
      :tot, 
      :inflation]
      ).require(:tvs)
  end
  
end
