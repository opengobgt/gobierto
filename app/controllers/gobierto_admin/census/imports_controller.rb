module GobiertoAdmin
  class Census::ImportsController < BaseController
    def new
      @census_import_form = CensusImportForm.new
      @latest_import = CensusImport.latest_by_site(current_site)
    end

    def create
      @census_import_form = CensusImportForm.new(
        census_import_params.merge(
          admin_id: current_admin.id,
          site_id: current_site.id
        )
      )

      if @census_import_form.save
        redirect_to(
          new_admin_census_imports_path,
          notice: "#{@census_import_form.record_count} valid records have been imported."
        )
      else
        @latest_import = CensusImport.latest_by_site(current_site)

        flash.now[:alert] = "There was an error when importing your file. Please try again."
        render :new
      end
    end

    private

    def census_import_params
      params.require(:census_import).permit(:file)
    end
  end
end