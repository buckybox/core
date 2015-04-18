collection @boxes

# XXX: We cannot cache this easilly since there are too many associations
# rendered in the `show` template... However, it should be fine to have a 5
# minute lag when a box is updated and this allows us to pre-render web store
# home pages and cache most requests for actual visitors
cache [@boxes], expires_in: 5.minutes

extends 'api/v1/boxes/show'
