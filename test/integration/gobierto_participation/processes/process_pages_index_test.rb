# frozen_string_literal: true

require "test_helper"

module GobiertoParticipation
  class ProcessPagesIndexTest < ActionDispatch::IntegrationTest
    def site
      @site ||= sites(:madrid)
    end

    def user
      @user ||= users(:peter)
    end

    def process
      @process ||= gobierto_participation_processes(:gender_violence_process)
    end

    def process_pages_path
      @process_pages_path ||= gobierto_participation_process_pages_path(
        process_id: process.slug
      )
    end

    def process_pages
      @process_pages ||= process.news
    end

    def test_breadcrumb_items
      with_current_site(site) do
        visit process_pages_path

        within ".main-nav" do
          assert has_link? "Participation"
          assert has_link? process.title
        end
      end
    end

    def test_menu_subsections
      with_current_site(site) do
        visit process_pages_path

        within ".sub-nav" do
          assert has_link? "Information"
          assert has_link? "Meetings"

          if process.polls_stage?
            assert has_link? "Polls"
          else
            refute has_link? "Polls"
          end

          assert has_link? "Contributions"
          assert has_link? "Results"
        end
      end
    end

    def test_secondary_nav
      with_current_site(site) do
        visit process_pages_path

        within "menu.secondary_nav" do
          assert has_link? "News"
          assert has_link? "Agenda"
          assert has_link? "Documents"
          assert has_link? "Activity"
        end
      end
    end

    def test_subscription_block
      with_javascript do
        with_current_site(site) do
          with_signed_in_user(user) do
            visit process_pages_path

            within ".slim_nav_bar" do
              assert has_link? "Follow process"
            end

            click_on "Follow process"
            assert has_link? "Process followed!"

            click_on "Process followed!"
            assert has_link? "Follow process"
          end
        end
      end
    end

    def test_process_pages_index
      with_current_site(site) do
        visit process_pages_path

        assert_equal process_pages.size, all(".news_teaser").size
        assert has_content? "Notice 1 body"
        assert has_link? "Notice 1 title"
        assert has_content? "Notice 2 body"
        assert has_link? "Notice 2 title"
      end
    end
  end
end
