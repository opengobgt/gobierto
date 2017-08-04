module GobiertoParticipation
  class ProcessesController < GobiertoParticipation::ApplicationController

    def index
      @processes = current_site.processes.process
      @groups    = current_site.processes.group_process
    end

    def show
      @process = GobiertoParticipation::Process.find_by!(slug: params[:id])

      @process_news   = find_process_news
      @process_events = find_process_events
      @activities     = [] # TODO: implementation not yet defined
      @process_stages = @process.stages
    end

    private

    def find_person
      people_scope.find_by!(slug: params[:slug])
    end

    def find_process_news
      @process.news.sort_by(&:created_at).reverse.first(5)
      # TODO: rewrite using Rails chainable scopes. Maybe something like this:
      # @process.news.upcoming.sort(created_at: :desc).limit(5)
    end

    def find_process_events
      @process.events.sort_by(&:starts_at).first(5)
      # TODO: rewrite using Rails chainable scopes. Maybe something like this:
      # @process.events.upcoming.sort(starts_at: :asc).limit(5)
    end

  end
end