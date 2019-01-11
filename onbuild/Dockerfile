FROM skillsengine/se-2019-rails-base-squashed:latest

ENV HOME=/home/app
CMD ["/sbin/my_init"]
EXPOSE 9292
WORKDIR /home/app/webapp

ONBUILD COPY Gemfile Gemfile.lock /home/app/webapp/
ONBUILD COPY vendor/ /home/app/webapp/vendor/
ONBUILD RUN chown -R app:app Gemfile Gemfile.lock vendor/ && \
  chpst -u app bundle install --deployment --jobs 4 --without development test && \
  find vendor/bundle -name *.gem -delete

ONBUILD COPY package.json yarn.lock ./
ONBUILD RUN yarn install

ONBUILD COPY . /home/app/webapp/
ONBUILD RUN mkdir -p db public/assets log tmp vendor && \
  chown -R app:app app db public log tmp vendor && chpst -u app /opt/rails-assets.sh && \
  /opt/custom-services.sh
