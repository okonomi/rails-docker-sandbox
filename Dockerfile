FROM ruby:2.6.3-alpine3.9 AS builder

ENV RAILS_ENV production

WORKDIR /app

RUN apk add --update --no-cache \
    build-base \
    libxml2-dev \
    libxslt-dev \
    sqlite-dev \
    nodejs \
    yarn \
    tzdata

# install gems
RUN gem install bundler
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --clean --frozen --jobs $(nproc) --without development test

# install npm packages
COPY package.json .
COPY yarn.lock .
RUN yarn install --frozen-lockfile

# compile assets
COPY app/assets app/assets
COPY app/javascript app/javascript
COPY config config
COPY bin bin
COPY Rakefile .
RUN bin/rails assets:precompile


FROM ruby:2.6.3-alpine3.9

ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT 1
ENV RAILS_SERVE_STATIC_FILES 1

WORKDIR /app

RUN apk add --update --no-cache \
    sqlite-libs \
    tzdata

COPY . .
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app/public/assets /app/public/assets
COPY --from=builder /app/public/packs /app/public/packs

RUN bin/rails db:schema:load

EXPOSE 3000
