FROM ruby:2.5

ADD . /app
WORKDIR /app
RUN bundle install -j4

ENTRYPOINT ["rerun", "--background", "/app/web.rb"]