web: rails db:migrate && rails server -b 0.0.0.0 -p $PORT
worker: bundle exec sidekiq -C config/sidekiq.yml
release: rails db:migrate