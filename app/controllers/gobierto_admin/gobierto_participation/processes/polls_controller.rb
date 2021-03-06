# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoParticipation
    module Processes
      class PollsController < Processes::BaseController
        helper_method :poll_visibility_levels, :gobierto_participation_process_poll_preview_url

        def index
          @polls = current_process.polls
        end

        def new
          @poll_form = PollForm.new(process: current_process)
        end

        def edit
          @poll_form = PollForm.new(
            find_poll.attributes.except(*ignored_poll_attributes).merge(process: current_process)
          )
        end

        def create
          remove_scaffold_keys_from_params

          @poll_form = PollForm.new(poll_params.merge(process: current_process))

          if @poll_form.save
            track_create_poll
            redirect_to(
              edit_admin_participation_process_poll_path(current_process, @poll_form.poll),
              notice: t(".success_html", link: gobierto_participation_process_poll_preview_url(current_process, @poll_form.poll, host: current_site.domain))
            )
          else
            render :new
          end
        end

        def update
          remove_scaffold_keys_from_params

          @poll_form = PollForm.new(poll_params.merge(id: params[:id],
                                                      process: current_process))

          if @poll_form.save
            track_update_poll
            redirect_to(
              edit_admin_participation_process_poll_path(current_process, @poll_form.poll),
              notice: t(".success_html", link: gobierto_participation_process_poll_preview_url(current_process, @poll_form.poll, host: current_site.domain))
            )
          else
            render :edit
          end
        end

        private

        def find_poll
          current_process.polls.find(params[:id])
        end

        def poll_params
          params.require(:poll).permit(
            :starts_at,
            :ends_at,
            :visibility_level,
            title_translations: [*I18n.available_locales],
            description_translations: [*I18n.available_locales],
            questions_attributes: [
              :id,
              :answer_type,
              :order,
              :_destroy,
              title_translations: [*I18n.available_locales],
              answer_templates_attributes: [
                :id,
                :text,
                :order,
                :_destroy
              ]
            ]
          )
        end

        # HACK: this is needed so Rails strong parameters does not detect question_attributes
        # '0', '1' keys as unpermitted params.
        def remove_scaffold_keys_from_params
          if params[:poll][:questions_attributes]
            params[:poll][:questions_attributes].delete(:scaffold)
          end
        end

        def ignored_poll_attributes
          %w(process_id title description created_at updated_at)
        end

        def poll_visibility_levels
          ::GobiertoParticipation::Poll.visibility_levels
        end

        def default_activity_params
          { ip: remote_ip, author: current_admin, site_id: current_site.id }
        end

        def track_create_poll
          Publishers::GobiertoParticipationPollActivity.broadcast_event("poll_created", default_activity_params.merge(subject: @poll_form.poll))
        end

        def track_update_poll
          Publishers::GobiertoParticipationPollActivity.broadcast_event("poll_updated", default_activity_params.merge(subject: @poll_form.poll))
        end

        def gobierto_participation_process_poll_preview_url(process, poll, options = {})
          if poll.answerable? || poll.process.draft?
            options.merge!(preview_token: current_admin.preview_token)
          end
          new_gobierto_participation_process_poll_answer_url(process.slug, poll, options)
        end
      end
    end
  end
end
