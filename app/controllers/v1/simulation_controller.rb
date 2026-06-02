class V1::SimulationController < ApplicationController
    before_action :findcase, except: [:case_create, :template_index, :template_planitems, :template_show, :template_flows]
    before_action :findplanitem, only: [:planitem_show, :planitem_update, :planitem_destroy, :planitem_entries_show, :planitem_entries_create, :run_autopension]
    # Grundsätzlicher Flow:
    # Open Case
    # Adjust Case assumptions
    # Feed assumptions / select defaults from templates
    # Run Simulation
    # Adjust assumptions
    # Delete Case and all related data

    include V1::TemplateHandler

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
        # Destroy Planitems
        @case.planitems.destroy_all
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
                        planitem_id: v["planitem_id"],
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
                        planitem_id: v["planitem_id"],
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
                            planitem_id: v["planitem_id"],
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
    def cvalue_update
        cvalue=@case.cvalues.find(params[:cvalue_id])
        if cvalue.update(cvalue_permitted_params)
            if cvalue.cslice_id.nil?
                @case.simulate_cashbalance
            else
                cvalue.cslice.simulate
                @case.simulate_cashbalance
            end
            render json: cvalue
        else
            render json: { errors: cvalue.errors.full_messages }, status: :unprocessable_entity
        end
    end

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

    def cvalue_show
        cvalue=@case.cvalues.find(params[:cvalue_id])
        render json: cvalue
    end

    def cslice_update
        @cslice=@case.cslices.find(params[:cslice_id])
        cslice_attributes=cslice_permitted_params.to_h

        if @cslice.update(cslice_attributes)
            if params[:cvalues]
                errors=[]
                params[:cvalues].each do |v|
                    cvalue_id=v["cvalue_id"] || v[:cvalue_id] || v["id"] || v[:id]
                    cvalue_attributes=cvalue_from_cslice_params(v)

                    if cvalue_id.present?
                        cvalue=@cslice.cvalues.find_by(id: cvalue_id)
                        unless cvalue
                            errors << "Cvalue #{cvalue_id} not found in this cslice."
                            next
                        end
                        errors.concat(cvalue.errors.full_messages) unless cvalue.update(cvalue_attributes)
                    else
                        entry=@cslice.cvalues.create(cvalue_attributes.merge(case_id: @case.id))
                        errors.concat(entry.errors.full_messages) unless entry.persisted?
                    end
                end

                if errors.any?
                    render json: { errors: errors.uniq }, status: :unprocessable_entity
                    return
                end
            end

            @cslice.sync_cvalues
            @cslice.simulate
            @case.simulate_cashbalance
            render :cslice_show
        else
            render json: { errors: @cslice.errors.full_messages }, status: :unprocessable_entity
        end
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

    # Planitem actions
    def planitem_index
        render json: @case.planitems.map { |pi| planitem_json(pi) }.to_json
    end

    def planitem_create
        @planitem=@case.planitems.create(planitem_permitted_params)
        render json: planitem_json(@planitem).to_json
    end

    def planitem_show
        # Renders via jbuilder view
    end

    def planitem_update
        @planitem.update(planitem_permitted_params)
        render json: planitem_json(@planitem).to_json
    end

    def planitem_destroy
        @planitem.destroy
        message={}
        message["message"]="Planitem #{@planitem.id} destroyed."
        render json: message
    end

    def planitem_entries_show
        cslices=@planitem.cslices
        # Only cvalues directly linked to the planitem (not via cslice)
        cvalues=@planitem.cvalues.where(cslice_id: nil)
        render json: {
            planitem_id: @planitem.id,
            cslices: cslices.map { |csl| { cslice_id: csl.id, label: csl.label, cvaluetype: csl.cvaluetype } },
            cvalues: cvalues.map { |cv| { cvalue_id: cv.id, label: cv.label, cvaluetype: cv.cvaluetype } }
        }
    end

    def planitem_entries_create
        case params[:type]
        when "Cvalue"
            cv_params=params.require(:cvalue).permit(:cvaluetype, :label, :cto, :ev, :t, :fromt, :tot, :interest, :inflation, :cf_type)
            entry=@case.cvalues.create(cv_params.merge(planitem_id: @planitem.id))
            entry.ev=0 if entry.cvaluetype < 3
            entry.save
            @case.simulate_cashbalance
            render json: { cvalue_id: entry.id, label: entry.label }
        when "Cslice"
            csl_params=params.require(:cslice).permit(:cvaluetype, :label, :t, :disclaimer, :source, :info)
            cslice=@case.cslices.create(csl_params.merge(planitem_id: @planitem.id))
            if params[:cvalues]
                params[:cvalues].each do |v|
                    entry=cslice.cvalues.create(
                        case_id: @case.id,
                        cvaluetype: v["cvaluetype"],
                        label: v["label"],
                        cto: v["cto"],
                        ev: v["ev"],
                        t: v["t"],
                        fromt: v["fromt"],
                        tot: v["tot"],
                        inflation: v["inflation"],
                        interest: v["interest"],
                        cf_type: v["cf_type"]
                    )
                    entry.inflation=0 if entry.inflation.nil?
                    entry.save
                end
                cslice.sync_cvalues
                cslice.simulate
            end
            @case.simulate_cashbalance
            render json: { cslice_id: cslice.id, label: cslice.label }
        else
            render json: { error: "Unknown type. Use Cvalue or Cslice." }, status: :unprocessable_entity
        end
    end


    def run_autopension
        unless @planitem.plan_type == Planitem::PLAN_TYPES["ruhestand"]
            render json: { error: "run_autopension is only valid for planitem type 'ruhestand'." }, status: :unprocessable_entity
            return
        end

        result = V1::PensionController.calculate_drv(
            birthyear: @case.byear,
            startpayout: @planitem.fromt
        )

        if result[:error]
            render json: { error: result[:error] }, status: :unprocessable_entity
            return
        end

        cslice = @case.cslices.create!(
            planitem_id: @planitem.id,
            cvaluetype: 1,
            label: "Gesetzliche Rente (DRV)",
            t: result[:queried_year],
            source: "autopension",
            info: "#{result[:rentenpunkte]} Entgeltpunkte, Rentenbeginn #{result[:queried_year]}"
        )

        cslice.cvalues.create!(
            case_id: @case.id,
            cvaluetype: 1,
            label: "Jährliche Rente (DRV)",
            cto: result[:annually],
            ev: 0,
            t: result[:queried_year],
            fromt: result[:queried_year],
            tot: @case.dyear,
            inflation: 0,
            interest: 0
        )

        cslice.sync_cvalues
        cslice.simulate
        @case.simulate_cashbalance

        render json: {
            message: "Autopension created.",
            cslice_id: cslice.id,
            queried_year: result[:queried_year],
            monthly: result[:monthly],
            annually: result[:annually],
            rentenpunkte: result[:rentenpunkte]
        }
    end


    private
    def findcase
        @case=Case.find_by_external_id(params[:case_id])
        message={}
        message["error"]="Case not found." unless @case
        render json: message unless @case
    end
    def findplanitem
        @planitem=@case.planitems.find_by_id(params[:planitem_id])
        unless @planitem
            render json: { error: "Planitem not found." }, status: :not_found
        end
    end
    def case_permitted_params
        params.permit(:byear, :country, :dyear, :sex, :nodelete, :chat_active)
    end
    def planitem_permitted_params
        params.permit(:title, :category, :plan_type, :fromt, :tot, :leadt, :trailt)
    end
    def cvalue_permitted_params
        params.permit(:planitem_id, :cvaluetype, :label, :cto, :ev, :t, :fromt, :tot, :interest, :inflation, :cf_type)
    end
    def cslice_permitted_params
        params.permit(:planitem_id, :cvaluetype, :label, :t, :disclaimer, :source, :info)
    end
    def cvalue_from_cslice_params(raw)
        raw=ActionController::Parameters.new(raw) unless raw.respond_to?(:permit)
        raw.permit(:planitem_id, :cvaluetype, :label, :cto, :ev, :t, :fromt, :tot, :interest, :inflation, :cf_type).to_h
    end
    def planitem_json(pi)
        {
            planitem_id: pi.id,
            title: pi.title,
            category: pi.category,
            category_text: pi.category_text,
            plan_type: pi.plan_type,
            plan_type_text: pi.plan_type_text,
            plan_type_icon: pi.plan_type_icon,
            fromt: pi.fromt,
            tot: pi.tot,
            leadt: pi.leadt,
            trailt: pi.trailt
        }
    end
end