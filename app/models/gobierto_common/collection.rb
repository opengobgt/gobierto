module GobiertoCommon
  class Collection < ApplicationRecord
    include User::Subscribable
    include GobiertoCommon::Sluggable

    belongs_to :site
    belongs_to :container, polymorphic: true
    has_many :collection_items, dependent: :destroy
    has_one :calendar_configuration, class_name: 'GobiertoCalendars::CalendarConfiguration'

    translates :title

    validates :site, :title, :item_type, presence: true
    validates :slug, uniqueness: { scope: :site }
    validates :container_id, uniqueness: { scope: [:container_type, :item_type] }

    attr_reader :container

    scope :by_item_type, ->(item_type) { where(item_type: item_type) }

    def news_in_collection
      collection_items.where(item_type: 'GobiertoCms::News').pluck(:item_id)
    end

    def pages_in_collection
      collection_items.where(item_type: 'GobiertoCms::Page').pluck(:item_id)
    end

    def pages_or_news_in_collection
      collection_items.where(item_type: %W(GobiertoCms::News GobiertoCms::Page)).pluck(:item_id)
    end

    def file_attachments_in_collection
      collection_items.where(item_type: 'GobiertoAttachments::Attachment').pluck(:item_id)
    end

    def events_in_collection
      collection_items.where(item_type: 'GobiertoCalendars::Event').pluck(:item_id)
    end

    def container
      if container_id.present?
        super
      else
        container_type.constantize
      end
    end

    def global_container
      container.to_global_id if container.present?
    end

    def global_container=(container)
      self.container = GlobalID::Locator.locate container
    end

    def self.collector_classes
      [Site, Issue, GobiertoParticipation::Area]
    end

    def self.type_classes(item_type)
      if item_type == "Page"
        [[::GobiertoCms::Page.model_name.human, ::GobiertoCms::Page.name],
         [I18n.t("activerecord.models.gobierto_cms/news"), "GobiertoCms::News"]]
      elsif item_type == "Attachment"
        [[::GobiertoAttachments::Attachment.model_name.human, ::GobiertoAttachments::Attachment.name]]
      elsif item_type == "Event"
        [[::GobiertoCalendars::Event.model_name.human, ::GobiertoCalendars::Event.name]]
      else
        [[::GobiertoCms::Page.model_name.human, ::GobiertoCms::Page.name],
         [I18n.t("activerecord.models.gobierto_cms/news"), "GobiertoCms::News"],
         [::GobiertoAttachments::Attachment.model_name.human, ::GobiertoAttachments::Attachment.name],
         [::GobiertoCalendars::Event.model_name.human, ::GobiertoCalendars::Event.name]]
      end
    end

    def append(item)
      item_type = if item.class_name == "GobiertoAttachments::Attachment"
                    "GobiertoAttachments::Attachment"
                  else
                    self.item_type
                  end

      containers_hierarchy(container).each do |container_type, container_id|
        CollectionItem.find_or_create_by! collection_id: id,
                                          container_type: container_type,
                                          container_id: container_id,
                                          item_id: item.id,
                                          item_type: item_type
      end

      if container_type == "GobiertoParticipation::Process"
        process = GobiertoParticipation::Process.find(container_id)

        if process.issue
          CollectionItem.find_or_create_by! collection_id: id,
                                            container: process.issue,
                                            item_id: item.id,
                                            item_type: item_type
        end

        if process.scope
          CollectionItem.find_or_create_by! collection_id: id,
                                            container: process.scope,
                                            item_id: item.id,
                                            item_type: item_type
        end
      end
    end

    def calendar_integration
      if calendar_configuration
        case calendar_configuration.integration_name
        when 'ibm_notes'
          GobiertoPeople::IbmNotes::CalendarIntegration
        when 'google_calendar'
          GobiertoPeople::GoogleCalendar::CalendarIntegration
        when 'microsoft_exchange'
          GobiertoPeople::MicrosoftExchange::CalendarIntegration
        end
      end
    end

    def container_printable_name
      container.try(:name) || container.try(:title)
    end

    private

    def containers_hierarchy(container)
      [
        site_for_container(container), gobierto_module_for_container(container),
        area_for_container(container), issue_for_container(container),
        gobierto_module_instance_for_container(container)
      ].compact.uniq
    end

    def site_for_container(container)
      if container.is_a?(Site)
        [container.class.name, container.id]
      else
        [site.class.name, site.id]
      end
    end

    def gobierto_module_for_container(container)
      if container.is_a?(Module)
        [container.name, nil]
      elsif !container_is_a_collector?(container)
        [container.class.parent.name, nil]
      end
    end

    def area_for_container(container)
      if container.is_a?(GobiertoParticipation::Area)
        [container.class.name, container.id]
      end
    end

    def issue_for_container(container)
      if container.is_a?(Issue)
        [container.class.name, container.id]
      end
    end

    def gobierto_module_instance_for_container(container)
      if !container.is_a?(Module) && !container_is_a_collector?(container)
        [container.class.name, container.id]
      end
    end

    def container_is_a_collector?(container)
      self.class.collector_classes.include?(container.class)
    end

    def parameterize
      { slug: slug }
    end

    def attributes_for_slug
      [ title ]
    end
  end
end
