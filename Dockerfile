# Builder
FROM --platform=$BUILDPLATFORM node:20.2.0-bullseye as builder

# Support custom branches of the react-sdk and js-sdk. This also helps us build
# images of element-web develop.
ARG USE_CUSTOM_SDKS=true
ARG REACT_SDK_REPO="https://github.com/SciCatProject/matrix-react-sdk.git"
ARG REACT_SDK_BRANCH="master"
ARG JS_SDK_REPO="https://github.com/matrix-org/matrix-js-sdk.git"
ARG JS_SDK_BRANCH="master"

ARG RIOT_OG_IMAGE_URL="https://github.com/SciCatProject/riot-web/raw/develop/ess-branding/esslogo.png"

RUN apt-get update && apt-get install -y git dos2unix 

WORKDIR /src

COPY . /src

RUN dos2unix /src/scripts/docker-link-repos.sh && bash /src/scripts/docker-link-repos.sh
RUN yarn --network-timeout=200000 install

RUN dos2unix /src/scripts/docker-package.sh && bash /src/scripts/docker-package.sh



# Copy the config now so that we don't create another layer in the app image
RUN cp /src/config.json /src/webapp/config.json

# App
FROM nginx:alpine-slim

COPY --from=builder /src/webapp /app


# Override default nginx config
COPY /nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

RUN rm -rf /usr/share/nginx/html \
  && ln -s /app /usr/share/nginx/html
