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
        # There is a better version now with @case.delete_all
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
        # Very general solution, case_show actually provides better information.
        render json: @case.as_json(include: [:cvalues, :cslices])
    end

    # Create an entry (or multiple) in the case
    def entry_create
        # This has been empowered to use params["cvalue"] and params["cslice"] for one entry and the plurals for multiple entries.
        case params[:type]
            when "Cvalue"
                if params[:cvalue]
                    # initialize the array as if a multitude of entries had been submitted.
                    params[:cvalues]=[]
                    params[:cvalues] << params[:cvalue]
                end
                # Work with multitude of entries.
                params[:cvalues].each do |v|
                    entry=Cvalue.create(
                        case_id: @case.id,
                        cvaluetype: v["cvaluetype"],
                        label: v["label"],
                        cto:  v["cto"],
                        ev:  v["ev"],
                        t:  v["t"],
                        fromt:  v["fromt"],
                        tot:  v["tot"],
                        interest:  v["interest"],
                        inflation:  v["inflation"],
                        cf_type:  v["cf_type"]
                    )
                    # Check some logic on the new entry.
                    entry.ev=0 if entry.cvaluetype<3
                    entry.save
                end

            when "Cslice"
                # Enter a recurring value = Cslice or multiple Cslices.
                # i.e. pay an amount X every year from year Y to year Z
                if params[:cslice]
                    # initialize the array as if a multitude of entries had been submitted.
                    params[:cslices]=[]
                    params[:cslices] << params[:cslice]
                end
                # Work with multitude of entries.
                params[:cslices].each do |v|
                    cslice=Cslice.create(
                        case_id: @case.id,
                        cvaluetype: v["cvaluetype"],
                        label: v["label"],
                        t: v["t"],
                        disclaimer: v["disclaimer"],
                        source: v["source"],
                        info: v["info"]
                    )
                    cslice.save
                    # Create all Cvalues in the slice:
                    v["cvalues"].each do |v|
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
                            interest:  v["interest"],
                            cf_type:  v["cf_type"]
                        )
                        # Check some logic on the new entry.
                        entry.inflation=0 if entry.inflation.nil?
                        entry.save
                    end
                    cslice.sync_cvalues
                    cslice.simulate
                end
        end
        # Simulate the Cashbalance
        @case.simulate_cashbalance
        return "OK."
    end

    # Remove entries
    def cvalue_destroy
        # Only do a flat execute, if the entry is not part of something bigger.
        if @case.cvalues.find(params[:cvalue_id]).cslice_id.nil?
            @case.cvalues.find(params[:cvalue_id]).destroy
            @case.simulations.where(sourcetype: 1, sourceid: params[:cvalue_id]).destroy_all
            @case.simulate_cashbalance
        else
            cslice=@case.cvalues.find(params[:cvalue_id]).cslice
            @case.cvalues.find(params[:cvalue_id]).destroy
            cslice.simulate
            @case.simulate_cashbalance
        end
        return "OK."
    end

    def cslice_show
        @cslice=@case.cslices.find(params[:cslice_id])
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
        params.permit(:byear, :dyear, :sex, :nodelete)
    end
end