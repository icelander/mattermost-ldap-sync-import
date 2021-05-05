FROM ruby:3.0.1

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

VOLUME ["/usr/src/app/sync-mapping.yaml"]

COPY mattermost.rb .
COPY ldap-sync-import.rb .
COPY entrypoint.sh .

CMD ["./entrypoint.sh"]