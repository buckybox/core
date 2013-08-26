BuckyBox.Router = Ember.Router.extend({
  location: 'hash',

  root: Ember.DeliveryService.extend({
    index: Ember.DeliveryService.extend({
      delivery_service: '/'

      // You'll likely want to connect a view here.
      // connectOutlets: function(router) {
      //   router.get('applicationController').connectOutlet(App.MainView);
      // }

      // Layout your delivery_services here...
    })
  })
});

