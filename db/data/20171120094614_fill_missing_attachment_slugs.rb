class FillMissingAttachmentSlugs < ActiveRecord::Migration[5.1]

    def up
      attachmenents_with_blank_slug = GobiertoAttachments::Attachment.where(slug: '')

      attachmenents_with_blank_slug.each do |attachment|
        base_slug = attachment.attributes_for_slug.join('-').gsub('_', ' ').parameterize

        if base_slug.blank?
          new_slug = attachment.id
        else
          new_slug  = base_slug

          count = 2
          while GobiertoAttachments::Attachment.exists?(site: attachment.site, slug: new_slug)
            new_slug = "#{base_slug}-#{count}"
            count += 1
          end
        end

        puts "\t=> Updating attachment(id: #{attachment.id}, name: #{attachment.name}, slug: #{attachment.slug}) with slug: #{new_slug}"

        attachment.update_attribute('slug', new_slug)
      end
    end

    def down
      raise ActiveRecord::IrreversibleMigration
    end

  end