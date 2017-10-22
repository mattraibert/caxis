FROM ruby:2.3.5
RUN gem install rest-client
ADD ./cactus.rb /code/cactus.rb
RUN mkdir /code/images
WORKDIR /code
CMD ruby cactus.rb