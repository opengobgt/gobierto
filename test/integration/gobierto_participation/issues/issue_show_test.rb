# frozen_string_literal: true

require "test_helper"

module GobiertoParticipation
  class ProcessEventsShowTest < ActionDispatch::IntegrationTest
    def setup
      super
      @path = gobierto_participation_issue_path(:culture)
    end

    def user
      @user ||= users(:peter)
    end

    def site
      @site ||= sites(:madrid)
    end

    def issue
      @issue ||= issues(:culture)
    end

    def processes
      @processes ||= site.processes.process.where(issue: issue).open
    end

    def groups
      @groups ||= site.processes.group_process.where(issue: issue)
    end

    def test_menu_subsections
      with_current_site(site) do
        visit @path

        within ".sub-nav" do
          assert has_link? "About"
          assert has_link? "Issues"
          assert has_link? "Processes"
          assert has_link? "Ask"
          assert has_link? "Ideas"
        end
      end
    end

    def test_secondary_nav
      with_current_site(site) do
        visit @path

        within "menu.secondary_nav" do
          assert has_link? "News"
          assert has_link? "Agenda"
          assert has_link? "Documents"
          assert has_link? "Activity"
        end
      end
    end

    def test_secondary_nav_news
      with_current_site(site) do
        visit @path

        click_link "News"

        assert_equal gobierto_participation_issue_pages_path(issue_id: issue.slug), current_path

        within ".main-nav" do
          assert has_link? "Participation"
        end

        assert has_selector?("h2", text: "News")
      end
    end

    def test_secondary_nav_diary
      with_current_site(site) do
        visit @path

        click_link "Agenda"

        assert_equal gobierto_participation_issue_events_path(issue_id: issue.slug), current_path

        within ".main-nav" do
          assert has_link? "Participation"
        end
      end
    end

    def test_secondary_nav_documents
      with_current_site(site) do
        visit @path

        click_link "Documents"

        assert_equal gobierto_participation_issue_attachments_path(issue_id: issue.slug), current_path

        within ".main-nav" do
          assert has_link? "Participation"
        end

        assert has_selector?("h2", text: "Documents")
      end
    end

    def test_secondary_nav_activity
      with_current_site(site) do
        visit @path

        click_link "Activity"

        assert_equal gobierto_participation_issue_activities_path(issue_id: issue.slug), current_path

        within ".main-nav" do
          assert has_link? "Participation"
        end

        assert has_selector?("h2", text: "Updates")
      end
    end

    def test_subscription_block
      with_javascript do
        with_current_site(site) do
          with_signed_in_user(user) do
            visit @path

            within ".slim_nav_bar" do
              assert has_link? "Follow theme"
            end

            click_on "Follow theme"
            assert has_link? "Theme followed!"

            click_on "Theme followed!"
            assert has_link? "Follow theme"
          end
        end
      end
    end

    def test_issue
      with_current_site(site) do
        visit @path

        within ".container" do
          assert has_content? issue.name
          assert has_content? issue.description
        end
      end
    end

    def test_issue_news
      with_current_site(site) do
        visit @path

        assert_equal issue.active_pages.size, all(".place_news-item").size
      end
    end

    def test_issue_with_events
      with_current_site(site) do
        visit @path

        assert_equal issue.events.size, all(".place_events-item").size
      end
    end

    def test_issue_processes
      with_current_site(site) do
        visit @path

        assert_equal processes.size, all("div#processes/div").size
      end
    end
  end
end
