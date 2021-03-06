this.GobiertoAdmin.GobiertoCalendarsCalendarConfigurationsController = (function() {
  function GobiertoCalendarsCalendarConfigurationsController() {}

  GobiertoCalendarsCalendarConfigurationsController.prototype.edit = function() {
    _updateVisibleFields();
  };

  function _updateVisibleFields() {
    $('#calendar_configuration_calendar_integration').on('change', function(){
      _hideAllIntegrationFields();

      var selectedIntegration = $(this).val();

      if (integrationNames().indexOf(selectedIntegration) >= 0) {
        $('#' +  selectedIntegration + '_fields').show('slow');
      }

      if (selectedIntegration === 'google_calendar' && $("[name='google_calendar_invitation_url']").length) {
        $('#update_button').hide('fast');
      } else {
        $('#update_button').show('fast');
      }
    });
  }

  function _hideAllIntegrationFields() {
    integrationNames().map(function(integrationName) {
      $('#' +  integrationName + '_fields').hide('slow');
    })
  }

  function integrationNames() {
    return ['ibm_notes', 'microsoft_exchange', 'google_calendar']
  }

  return GobiertoCalendarsCalendarConfigurationsController;
})();

this.GobiertoAdmin.gobierto_calendars_calendar_configurations_controller = new GobiertoAdmin.GobiertoCalendarsCalendarConfigurationsController;
