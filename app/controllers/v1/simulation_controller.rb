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
        
    end


    private
    def findcase
        @case=Case.find_by_external_id(params[:case_id])
        render json: "Case not found." unless @case
    end
    def case_permitted_params
        params.permit(:byear, :dyear, :sex)
    end
end