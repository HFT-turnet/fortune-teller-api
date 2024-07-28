class V1::SimulationController < ApplicationController
    before_action :findcase, except: [:case_create]
    # Grundsätzlicher Flow:
    # Open Case
    # Adjust Case assumptions
    # Feed assumptions / select defaults from templates
    # Run Simulation
    # Adjust assumptions
    # Delete Case and all related data

    # Create a new case
    def case_create
        @case=Case.create(case_permitted_params)
        render json: @case.as_json(except: [:id, :created_at, :updated_at])
    end
    
    # Adjust assumptions in the case
    def case_update
        @case.update(case_permitted_params)
        render json: @case.as_json(except: [:id, :created_at, :updated_at])
    end

    # Destroy a case
    def case_destroy
        # Destroy simulations
        @case.simulations.destroy_all
        # Destroy Cvalues, Cslices, Cflows, CPensionFlows
        @case.cvalues.destroy_all
        @case.cslices.destroy_all
        #@case.cflows.destroy_all
        #@case.cpensionflows.destroy_all
        # Destroy the case
        @case.destroy
        message={}
        message["message"]="Case with id #{@case.external_id} destroyed."
        render json: message
    end

    # Show existing case and all attached data
    def case_show
        #render json: @case.as_json(except: [:id, :created_at, :updated_at])
        # Being rendederd with json.jbuilder in Views.
    end

    def case_entries
        # Show all objects in the case
        render json: @case.as_json(include: [:cvalues, :cslices])
    end

    # Create an entry in the case
    def entry_create
        case params[:type]
            when "Cvalue"
                # Enter a value in a point in time = Cvalue
                # i.e. receive an amount X in year Y
                entry=Cvalue.create(
                    case_id: @case.id,
                    cvaluetype: params[:cvalue]["cvaluetype"],
                    label: params[:cvalue]["label"],
                    cto:  params[:cvalue]["cto"],
                    ev:  params[:cvalue]["ev"],
                    t:  params[:cvalue]["t"],
                    fromt:  params[:cvalue]["fromt"],
                    tot:  params[:cvalue]["tot"],
                    interest:  params[:cvalue]["interest"]
                )
                # Check some logic on the new entry.
                entry.ev=0 if entry.cvaluetype<3
                entry.cto=0 if entry.cvaluetype>2
                entry.save
                entry.simulate_cashbalance
            when "Cslice"
                # Enter a recurring value = Cslice
                # i.e. pay an amount X every year from year Y to year Z
                cslice=Cslice.create(
                    case_id: @case.id,
                    cvaluetype: params[:cslice]["cvaluetype"],
                    label: params[:cslice]["label"],
                    t: params[:cslice]["t"],
                    disclaimer: params[:cslice]["disclaimer"],
                    source: params[:cslice]["source"],
                    info: params[:cslice]["info"]
                )
                cslice.save
                # Create all Cvalues in the slice:
                params[:cslice]["cvalues"].each do |v|
                    entry=cslice.cvalues.create(
                        case_id: @case.id,
                        cvaluetype: v["cvaluetype"],
                        label: v["label"],
                        cto:  v["cto"],
                        ev:  v["ev"],
                        t:  v["t"],
                        fromt:  v["fromt"],
                        tot:  v["tot"],
                        inflation:  v["inflation"],
                        interest:  v["interest"]
                    )
                    # Check some logic on the new entry.
                    entry.inflation=0 if entry.inflation.nil?
                    entry.save
                end
                cslice.sync_cvalues
                cslice.simulate
        end
        # Simulate the Cashbalance
        @case.simulate_cashbalance
        return "OK."
    end

    # Remove entries
    def cvalue_destroy
        # Only execute, if the entry is not part of something bigger.
        if @case.cvalues.find(params[:cvalue_id]).cslice_id.nil?
            @case.cvalues.find(params[:cvalue_id]).destroy
            @case.simulations.where(sourcetype: 1, sourceid: params[:cvalue_id]).destroy_all
            @case.simulate_cashbalance
        end
        return "OK."
    end

    def cslice_destroy
        @case.cslices.find(params[:cslice_id]).destroy
        @case.cvalues.where(cslice_id: params[:cslice_id]).destroy_all
        @case.simulations.where(sourcetype: 2, sourceid: params[:cslice_id]).destroy_all
        @case.simulate_cashbalance
    end

    # Simulate the case
    def simulate
        # If frequency is provided, take the value, otherwise in steps of 5 years.
        frequency=params[:frequency] || 5 
        render json: @case.timeline(frequency)
    end

    def simulate_detail
        # If frequency is provided, take the value, otherwise in steps of 5 years.
        render json: "No year provided for detail" if params[:t].to_i==0
        render json: @case.details(params[:t].to_i)
    end


    private
    def findcase
        @case=Case.find_by_external_id(params[:case_id])
        message={}
        message["error"]="Case not found." unless @case
        render json: message unless @case
    end
    def case_permitted_params
        params.permit(:byear, :dyear, :sex)
    end
end