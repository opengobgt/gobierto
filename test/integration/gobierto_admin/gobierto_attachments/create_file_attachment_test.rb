require 'test_helper'
require "support/file_uploader_helpers"

module GobiertoAdmin
  module GobiertoAttachments
    class CreateFileAttachmentTest < ActionDispatch::IntegrationTest
      include FileUploaderHelpers

      def setup
        super
        @path = admin_cms_file_attachments_path
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def pdf_file
        @pdf_file ||= file_fixture('gobierto_attachments/attachment/pdf-collection-attachment.pdf')
      end

      def test_create_file_attachments_errors
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit @path

              click_link 'Files'
              assert has_selector?('h1', text: 'Files')

              click_link 'New'
              assert has_selector?('h1', text: 'New document')
              click_button 'Create'
              assert has_alert?("File can't be blank")
            end
          end
        end
      end

      def test_create_file_attachments
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit @path

              click_link 'Files'
              assert has_selector?('h1', text: 'Files')

              click_link 'New'
              assert has_selector?('h1', text: 'New document')

              fill_in 'file_attachment_name', with: 'My file_attachment'
              fill_in 'file_attachment_description', with: 'My file_attachment description'
              attach_file('file_attachment_file', pdf_file)

              with_stubbed_s3_file_upload do
                click_button 'Create'
              end

              assert has_message?('Attachment created successfully.')
              file_attachment = ::GobiertoAttachments::Attachment.find_by(name: 'My file_attachment', description: 'My file_attachment description')
              activity = Activity.last
              assert_equal file_attachment, activity.subject
              assert_equal admin, activity.author
              assert_equal site.id, activity.site_id
              assert_equal 'gobierto_attachments.attachment_created', activity.action
            end
          end
        end
      end
    end
  end
end