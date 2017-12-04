# frozen_string_literal: true

module GobiertoCms
  class PagesController < GobiertoCms::ApplicationController
    before_action :find_page_by_id_and_redirect

    def show
      @section = find_section if params[:slug_section]
      @page = find_page
      @section_item = find_section_item if params[:slug_section]
      @collection = @page.collection
      @pages = ::GobiertoCms::Page.where(id: @collection.pages_in_collection).active

      if params[:process]
        @process = find_process
        @groups = current_site.processes.group_process
      end
    end

    def index
      # TODO: params['from'] == 'participation' Add to process layout hidden_field
      @issues = current_site.issues
      @issue = find_issue if params[:issue_id]

      @pages = if params[:issue_id]
                 find_issue_news.page(params[:page])
               else
                 current_site.pages.active.page(params[:page])
               end
    end

    private

    # Load page by ID is necessary to keep the search results page unified and simple
    def find_page_by_id_and_redirect
      if params[:id].present? && params[:id] =~ /\A\d+\z/
        page = current_site.pages.active.find(params[:id])
        redirect_to(gobierto_cms_page_path(page.slug)) && (return false)
      end
    end

    def find_issue
      Issue.find_by_slug!(params[:issue_id])
    end

    def find_issue_news
      GobiertoParticipation::Process.find_by(issue: @issue).extend_news
    end

    def find_section
      current_site.sections.find_by!(slug: params[:slug_section])
    end

    def find_section_item
      ::GobiertoCms::SectionItem.find_by!(item: @page, section: @section)
    end

    def find_process_news
      @process.news.sort_by_updated_at.limit(5)
    end

    def find_page
      pages_scope.find_by!(slug: params[:id])
    end

    def pages_scope
      valid_preview_token? ? current_site.pages.draft : current_site.pages.active
    end
  end
end
