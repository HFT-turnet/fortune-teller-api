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
        render json: "Case with id #{@case.external_id} destroyed."
    end

    # Show existing case and all attached data
    def case_show
        #render json: @case.as_json(except: [:id, :created_at, :updated_at])
        # Being rendederd with json.jbuilder in Views.
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