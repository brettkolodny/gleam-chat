
FROM ghcr.io/gleam-lang/gleam:v0.25.3-erlang-alpine

ENV ENV prod

# Add project code
COPY . /build/

RUN mkdir /app
RUN mkdir /app/back-end
RUN mkdir /app/front-end
RUN apk add --update --no-cache nodejs npm
RUN npm install -g yarn 
RUN npm install -g elm 
RUN cd /build/front-end \ 
  && yarn \
  && yarn build \ 
  && mv dist /app/front-end/dist
RUN cd build/back-end \
  && gleam build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app/back-end/build
RUN rm -r /build
RUN addgroup -S app
RUN adduser -S app -G app
RUN chown -R app /app

# Run the application
USER app
WORKDIR /app
ENTRYPOINT ["/app/back-end/build/entrypoint.sh"]
CMD ["run"]