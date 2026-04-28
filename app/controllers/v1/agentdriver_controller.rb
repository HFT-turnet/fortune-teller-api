class V1::AgentdriverController < ApplicationController
    # Main entry point: dispatches based on what the agent sends.
    # - No JSON body (or missing area/activity and no case_id): returns general instructions.
    # - case_id present but no area/activity: returns status and plan.
    # - area + activity present: routes to the appropriate handler.
    def drive
        area     = params[:area]
        activity = params[:activity]
        case_id  = params[:case_id]

        # No meaningful input provided → return general instructions.
        if area.blank? && case_id.blank?
            render json: build_general_instructions
            return
        end

        # case_id given without an area/activity → status and plan.
        if case_id.present? && area.blank?
            render_status_and_plan(case_id)
            return
        end

        # Both area and activity are required.
        if area.blank? || activity.blank?
            render json: build_general_instructions
            return
        end

        case area
        when "simulation"
            handle_simulation(activity)
        when "calc"
            handle_calc(activity)
        else
            render json: { error: "Unknown area '#{area}'.", instructions: build_general_instructions }
        end
    end

    # GET v1/agentdriver/:case_id – status and plan for an existing case.
    def case_status
        render_status_and_plan(params[:case_id])
    end

    private

    def build_general_instructions
        {
            instructions: "To interact with the fortune-teller API via the agent driver, submit a POST " \
                          "request to v1/agentdriver with a JSON body that specifies 'area' and 'activity'. " \
                          "To work with the simulation module you first need a case_id, which you can obtain " \
                          "by calling area: 'simulation', activity: 'create_case'. Once you have a case_id " \
                          "you can include it in subsequent requests or call GET v1/agentdriver/:case_id to " \
                          "retrieve the current status and plan.",
            activities: list_activities
        }
    end

    def list_activities
        [
            { area: "calc",       activity: "list" },
            { area: "simulation", activity: "create_case" }
        ]
    end

    def render_status_and_plan(case_id)
        @case = Case.find_by_external_id(case_id)
        unless @case
            render json: { error: "Case with id '#{case_id}' not found." }
            return
        end
        render json: {
            case_id: @case.external_id,
            status:  "Case found.",
            plan:    "Status and plan: to be further implemented."
        }
    end

    def handle_simulation(activity)
        case activity
        when "create_case"
            @case = Case.create(case_permitted_params)
            unless @case.persisted?
                render json: { error: "Case could not be created.", details: @case.errors.full_messages }
                return
            end
            render json: {
                case_id: @case.external_id,
                message: "Case created. Use this case_id for further simulation interactions."
            }
        else
            render json: { error: "Unknown activity '#{activity}' for area 'simulation'." }
        end
    end

    def handle_calc(activity)
        case activity
        when "list"
            render json: { area: "calc", activity: "list", result: "Calc list: to be implemented." }
        else
            render json: { error: "Unknown activity '#{activity}' for area 'calc'." }
        end
    end

    def case_permitted_params
        params.permit(:byear, :dyear, :sex, :nodelete)
    end
end
