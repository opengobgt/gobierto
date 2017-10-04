module GobiertoAdmin
  module GobiertoAttachments
    class FileAttachmentsController < BaseController
      before_action :load_collection, only: [:new, :edit, :create, :update, :destroy]

      def index
        @collections = current_site.collections.by_item_type('GobiertoAttachments::Attachment')
        @file_attachments = ::GobiertoAttachments::Attachment.file_attachments_in_collections(current_site).sort_by_updated_at(10)
      end

      def new
        @file_attachment_form = FileAttachmentForm.new(site_id: current_site.id, collection_id: @collection)
      end

      def edit
        @file_attachment = find_file_attachment
        @file_attachment_form = FileAttachmentForm.new(
          @file_attachment.attributes.except(*ignored_file_attachment_attributes).merge(site_id: current_site.id, collection_id: @collection)
        )
      end

      def create
        @file_attachment_form = FileAttachmentForm.new(
          file_attachment_params.merge(
            site_id: current_site.id,
            collection_id: @collection,
            admin_id: current_admin.id
          )
        )
        if @file_attachment_form.save
          if params[:file_attachment][:collection_id]
            redirect_to(
              edit_admin_attachments_file_attachment_path(@file_attachment_form.file_attachment.id, collection_id: params[:file_attachment][:collection_id]),
              notice: t(".success_html", link: @file_attachment_form.file_attachment.to_url(host: current_site.domain))
            )
          end
        else
          if params[:file_attachment][:collection_id]
            render :edit
          else
            head :bad_request
          end
        end
      end

      def update
        @file_attachment = find_file_attachment
        @file_attachment_form = FileAttachmentForm.new(file_attachment_params.merge(id: params[:id], admin_id: current_admin.id, site_id: current_site.id, collection_id: @collection.id))
        if @file_attachment_form.save

          redirect_to(
            edit_admin_attachments_file_attachment_path(@file_attachment_form.file_attachment.id, collection_id: @collection),
            notice: t(".success_html", link: @file_attachment_form.file_attachment.to_url(host: current_site.domain))
          )
        else
          @collection = @page.file_attachment
          render :edit, collection_id: @collection.id
        end
      end

      private

      def load_collection
        @collection = current_site.collections.find(params[:collection_id])
      end

      def default_activity_params
        { ip: remote_ip, author: current_admin, site_id: current_site.id }
      end

      def find_file_attachment
        current_site.attachments.find(params[:id])
      end

      def find_collection(collection_id)
        ::GobiertoCommon::Collection.find_by(id: collection_id)
      end

      def ignored_file_attachment_attributes
        %w(created_at updated_at site_id file_size current_version collection_id)
      end

      def file_attachment_params
        params.require(:file_attachment).permit(:id, :file, :name, :description, :file_name, :slug, :collection_id)
      end
    end
  end
end
