Dependencies.mechanism                             = :require
ActionController::Base.consider_all_requests_local = false

ActionController::Base.fragment_cache_store = ActionController::Caching::Fragments::FileStore.new("/Users/jchappell/Sites/tracks/cache")

