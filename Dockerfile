FROM ruby:2.6.3-alpine3.9 AS base

RUN apk add --no-cache \
    build-base \
    libxml2-dev \
    libxslt-dev \
    sqlite-dev \
    nodejs \
    yarn \
    tzdata

RUN gem install bundler


FROM base AS development

WORKDIR /app

# add any settings for development environment


FROM base AS builder

ENV RAILS_ENV production

WORKDIR /app

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
COPY Rakefile .
COPY bin bin
COPY .browserslistrc .
COPY postcss.config.js .
COPY babel.config.js .
COPY config config
COPY app/assets app/assets
COPY app/javascript app/javascript
RUN bin/rails assets:precompile


FROM ruby:2.6.3-alpine3.9 AS production

ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT 1
ENV RAILS_SERVE_STATIC_FILES 1

WORKDIR /app

RUN apk add --no-cache \
    sqlite-libs \
    tzdata

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app/public/assets /app/public/assets
COPY --from=builder /app/public/packs /app/public/packs
COPY . .

RUN bin/rails db:schema:load

EXPOSE 3000
ENTRYPOINT ["bin/rails"]
